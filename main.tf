terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  public_subnet_count  = var.create_public_subnets ? length(var.azs) : 0
  private_subnet_count = var.create_private_subnets ? length(var.azs) : 0
  create_igw           = var.create_public_subnets && var.create_internet_gateway ? 1 : 0
  ngw_count            = var.create_public_subnets && var.create_nat_gateway ? var.shared_ngw ? 1 : length(var.azs) : 0
  ngw_route_count      = var.create_nat_gateway ? length(var.azs) : 0
  igw_route_count      = var.create_public_subnets && var.create_internet_gateway ? length(var.azs) : 0
  create_internal_dns  = var.create_r53_private_hosted_zone ? 1 : 0
  crate_flow_logs      = var.crate_flow_logs ? 1 : 0
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.name_tag}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  count = local.create_igw

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_tag}-igw"
  }
}

resource "aws_subnet" "public-subnets" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = format("${var.name_tag}-public-subnet-%s", count.index + 1)
  }
}

resource "aws_route_table" "public-rt" {
  count = local.public_subnet_count

  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("${var.name_tag}-public-rt-%s", count.index + 1)
  }
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.public-rt[count.index].id
}

resource "aws_route" "igw" {
  count = local.igw_route_count

  route_table_id         = aws_route_table.public-rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  timeouts {
    create = "5m"
  }
}


resource "aws_subnet" "private-subnets" {
  count = local.private_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.azs) + 1)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = format("${var.name_tag}-private-subnet-%s", count.index + 1)
  }
}

resource "aws_route_table" "private-rt" {
  count = local.private_subnet_count

  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("${var.name_tag}-private-rt-%s", count.index + 1)
  }
}

resource "aws_nat_gateway" "main" {
  count = local.ngw_count

  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = aws_subnet.public-subnets[count.index].id

  tags = {
    Name = format("${var.name_tag}-nat-gateway-%s", count.index + 1)
  }
}

resource "aws_eip" "ngw" {
  count = local.ngw_count

  vpc = true

  tags = {
    Name = format("${var.name_tag}-nat-eip-%s", count.index + 1)
  }
}

resource "aws_route" "ngw" {
  count = local.ngw_route_count

  route_table_id         = aws_route_table.private-rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.shared_ngw ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count          = local.private_subnet_count
  subnet_id      = aws_subnet.private-subnets[count.index].id
  route_table_id = aws_route_table.private-rt[count.index].id
}


resource "aws_vpc_dhcp_options" "internal" {
  count = local.create_internal_dns

  domain_name = var.r53_private_domain_name
  domain_name_servers = [
    "AmazonProvidedDNS",
  ]

  tags = {
    Name = "${var.name_tag}-dhcp-option"
  }
}

resource "aws_vpc_dhcp_options_association" "internal" {
  count = local.create_internal_dns

  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.internal[0].id
}

resource "aws_route53_zone" "internal" {
  count = local.create_internal_dns

  name    = var.r53_private_domain_name
  comment = "${var.name_tag}-internal-zone"
  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name = "${var.name_tag}-internal-dns"
  }
}

resource "aws_flow_log" "vpc" {
  count = local.crate_flow_logs

  iam_role_arn    = aws_iam_role.flow-logs[count.index].arn
  log_destination = aws_cloudwatch_log_group.flow-logs[count.index].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.name_tag}-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "flow-logs" {
  count = local.crate_flow_logs

  name = "${var.name_tag}-flow-logs"
}

resource "aws_iam_role" "flow-logs" {
  count = local.crate_flow_logs

  name = "${var.name_tag}-flow-logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flow-logs" {
  count = local.crate_flow_logs

  name = "${var.name_tag}-flow-logs"
  role = aws_iam_role.flow-logs[count.index].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}