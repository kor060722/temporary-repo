# --------------- VPC --------------- #
output "vpcId" {
  value = aws_vpc.vpc.id
}
# --------------- Subnet --------------- #
output "pubSnA_Id" {
  value = aws_subnet.pubSnA.id
}
output "pubSnB_Id" {
  value = aws_subnet.pubSnB.id
}
output "pvtSnA_Id" {
  value = aws_subnet.pvtSnA.id
}
output "pvtSnB_Id" {
  value = aws_subnet.pvtSnB.id
}
# --------------- SecuritGroup --------------- #
output "BastionSg_Id" {
  value = aws_security_group.bastionSg.id
}