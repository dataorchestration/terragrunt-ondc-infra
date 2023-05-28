output "default_vpc" {
  value = aws_default_vpc.default_vpc.id
}

output "default_subnet" {
  value = aws_default_subnet.default_subnet.id
}
output "default_subnetb" {
  value = aws_default_subnet.default_subnet-b.id
}
output "default_subnetc" {
  value = aws_default_subnet.default_subnet-c.id
}

output "aws_default_security_group" {
  value = aws_default_security_group.default.id
}

output "default_vpc_cidr_block" {
  value = aws_default_vpc.default_vpc.cidr_block
}