# --------------- Environment --------------- #
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                  = var.region
}

# --------------- Networking --------------- #
module "VPC" {
  source = "./Module/VPC"
}

# # --------------- Identity --------------- #
# module "IAM" {
#   source = "./Module/IAM"
# }

# # --------------- storage --------------- #
# module "S3" {
#   source          = "./Module/S3"

#   vpcId               = module.VPC.vpcId
#   pvtSnA_Id           = module.VPC.pvtSnA_Id
#   pvtSnB_Id           = module.VPC.pvtSnB_Id
#   rdsEndpoint         = var.rdsEndpoint
#   rdsProxy            = var.rdsProxy
# }

# # --------------- Server --------------- #
# module "EC2" {
#   source              = "./Module/EC2"

#   vpcId               = module.VPC.vpcId
#   pubSnA_Id           = module.VPC.pubSnA_Id
#   pubSnB_Id           = module.VPC.pubSnB_Id
#   bastionProfileName  = module.IAM.bastionProfileName
#   randomBucketId      = module.S3.randomBucketId
#   pvtSnA_Id           = module.VPC.pvtSnA_Id
#   pvtSnB_Id           = module.VPC.pvtSnB_Id
#   rdsEndpoint         = var.rdsEndpoint
#   BastionSg_Id        = module.VPC.BastionSg_Id
# }