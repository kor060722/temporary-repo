# --------------- VPC --------------- #
  resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "apdev-vpc"
  }
 }



# --------------- Subnet --------------- #
  resource "aws_subnet" "pubSnA" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "apdev-pub-sn-a"
  }
 }
  resource "aws_subnet" "pubSnB" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "apdev-pub-sn-b"
  }
 }
  resource "aws_subnet" "pvtSnA" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "apdev-pvt-sn-a"
  }
 }
  resource "aws_subnet" "pvtSnB" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "apdev-pvt-sn-b"
  }
 }
  resource "aws_subnet" "dbSnA" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.100.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "apdev-db-sn-a"
  }
 }
  resource "aws_subnet" "dbSnB" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.101.0/24"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "apdev-db-sn-b"
  }
 }
  resource "aws_subnet" "dbSnC" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.102.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "apdev-db-sn-c"
  }
 }



# --------------- Gateway --------------- # 
  resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.vpc.id
  tags = {
    Name = "apdev-igw"
  }
 }
  resource "aws_eip" "eipA" {
  domain   = "vpc"
  tags = {
    Name = "apdev-eip-a"
  }
 }
  resource "aws_eip" "eipB" {
  domain   = "vpc"
  tags = {
    Name = "apdev-eip-b"
  }
 }
  resource "aws_nat_gateway" "natgwA" {
  allocation_id = aws_eip.eipA.id
  subnet_id     = aws_subnet.pubSnA.id

  tags = {
    Name = "apdev-natgw-a"
  }
 }
  resource "aws_nat_gateway" "natgwB" {
  allocation_id = aws_eip.eipB.id
  subnet_id     = aws_subnet.pubSnB.id
  tags = {
    Name = "apdev-natgw-b"
  }
 }



# --------------- RouteTable --------------- #
  resource "aws_route_table" "pubRt" {
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "apdev-pub-rt"
  }
 }
  resource "aws_route_table_association" "pubAssociationA" {
  subnet_id      = aws_subnet.pubSnA.id
  route_table_id = aws_route_table.pubRt.id
}
  resource "aws_route_table_association" "pubAssociationB" {
  subnet_id      = aws_subnet.pubSnB.id
  route_table_id = aws_route_table.pubRt.id
}
  resource "aws_route_table" "pvtRtA" {
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgwA.id
  }
  tags = {
    Name = "apdev-pvt-rt-a"
  }
 }
  resource "aws_route_table_association" "pvtAssociationA" {
  subnet_id      = aws_subnet.pvtSnA.id
  route_table_id = aws_route_table.pvtRtA.id
}
  resource "aws_route_table" "pvtRtB" {
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgwB.id
  }
  tags = {
    Name = "apdev-pvt-rt-b"
  }
 }
  resource "aws_route_table_association" "pvtAssociationB" {
  subnet_id      = aws_subnet.pvtSnB.id
  route_table_id = aws_route_table.pvtRtB.id
}
  resource "aws_route_table" "dbRt" {
  vpc_id     = aws_vpc.vpc.id
  tags = {
    Name = "apdev-rds-rt"
  }
 }
  resource "aws_route_table_association" "dbAssociationA" {
  subnet_id      = aws_subnet.dbSnA.id
  route_table_id = aws_route_table.dbRt.id
}
  resource "aws_route_table_association" "dbAssociationB" {
  subnet_id      = aws_subnet.dbSnB.id
  route_table_id = aws_route_table.dbRt.id
}
  resource "aws_route_table_association" "dbAssociationC" {
  subnet_id      = aws_subnet.dbSnC.id
  route_table_id = aws_route_table.dbRt.id
}


# --------------- BastionSG --------------- #
  resource "aws_security_group" "bastionSg" {
  name        = "apdev-bastion-sg"
  description = "apdev-bastion-sg"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "apdev-bastion-sg"
  }
}
  resource "aws_security_group_rule" "bastionSgIngress22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastionSg.id}"
}
  resource "aws_security_group_rule" "bastionSgIngress8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastionSg.id}"
}
  resource "aws_security_group_rule" "bastionSgEgress80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastionSg.id}"
}
  resource "aws_security_group_rule" "bastionSgEgress443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastionSg.id}"
}
  resource "aws_security_group_rule" "bastionSgEgress3306" {
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastionSg.id}"
}




# --------------- RDS_SG --------------- #
  resource "aws_security_group" "rdsSg" {
  name        = "apdev-rds-sg"
  description = "apdev-rds-sg"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "apdev-rds-sg"
  }
}
  resource "aws_security_group_rule" "bastionSgIngressAll" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rdsSg.id
}
  resource "aws_security_group_rule" "bastionSgEgressAll" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rdsSg.id
}
