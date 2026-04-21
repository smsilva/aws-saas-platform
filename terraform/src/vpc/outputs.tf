output "id" {
  value = aws_vpc.default.id
}

output "instance" {
  value = aws_vpc.default
}

output "subnets" {
  value = {
    for name, subnet in aws_subnet.default : name => {
      id       = subnet.id
      instance = subnet
    }
  }
}

output "public_subnet_ids" {
  value = [
    for name, subnet in aws_subnet.default : subnet.id
    if local.subnet_map[name].public
  ]
}

output "private_subnet_ids" {
  value = [
    for name, subnet in aws_subnet.default : subnet.id
    if !local.subnet_map[name].public
  ]
}
