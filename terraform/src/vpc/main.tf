locals {
  subnet_map         = { for subnet in var.subnets : subnet.name => subnet }
  public_subnet_map  = { for name, subnet in local.subnet_map : name => subnet if subnet.public }
  private_subnet_map = { for name, subnet in local.subnet_map : name => subnet if !subnet.public }
  nat_subnet_key     = sort(keys(local.public_subnet_map))[0]
}

resource "aws_vpc" "default" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "default" {
  for_each = local.subnet_map

  vpc_id                  = aws_vpc.default.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.public

  tags = merge(
    var.tags,
    { Name = "${var.name}-${each.key}" },
    each.value.public ? {
      "kubernetes.io/role/elb"             = "1"
      "kubernetes.io/cluster/${var.name}"  = "owned"
    } : {
      "kubernetes.io/role/internal-elb"    = "1"
      "kubernetes.io/cluster/${var.name}"  = "owned"
    }
  )
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat" })
}

resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.default[local.nat_subnet_key].id

  tags = merge(var.tags, { Name = var.name })

  depends_on = [aws_internet_gateway.default]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id

  tags = merge(var.tags, { Name = "${var.name}-private" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default.id
}

resource "aws_route_table_association" "default" {
  for_each = local.subnet_map

  subnet_id      = aws_subnet.default[each.key].id
  route_table_id = each.value.public ? aws_route_table.public.id : aws_route_table.private.id
}
