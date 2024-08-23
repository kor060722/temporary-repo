# --------------- VPC --------------- #
variable "vpcId" {
  type = string
}
# --------------- Subnet --------------- #
variable "pubSnA_Id" {
  type = string
}
variable "pubSnB_Id" {
  type = string
}
variable "pvtSnA_Id" {
  type = string
}
variable "pvtSnB_Id" {
  type = string
}
# --------------- Bastion --------------- #
variable "bastionProfileName" {
  type = string
}
variable "BastionSg_Id" {
  type = string
}
# --------------- Bucket --------------- #
variable "randomBucketId" {
  type = string
}
# --------------- RDS --------------- #
variable "rdsEndpoint" {
  type = string
}
