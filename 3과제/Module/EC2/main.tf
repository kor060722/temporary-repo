# --------------- BastionKeyPair --------------- #
resource "tls_private_key" "bastionKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "bastionKeypair" {
  key_name   = "apdevKey.pem"
  public_key = tls_private_key.bastionKey.public_key_openssh
} 
resource "local_file" "bastionKeylocal" {
  filename        = "apdevKey.pem"
  content         = tls_private_key.bastionKey.private_key_pem
}


# --------------- BastionKeyPair --------------- #
data "aws_ami" "apdev_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["amazon"]
}

  resource "aws_instance" "bastionEc2" {
  subnet_id     = var.pubSnA_Id
  security_groups = [var.BastionSg_Id]
  ami           = data.aws_ami.apdev_ami.id
  iam_instance_profile   = var.bastionProfileName
  instance_type = "t3.small"
  key_name = "apdevKey.pem"
  user_data = <<usd
#!/bin/bash
mkdir /home/ec2-user/2024
mkdir /home/ec2-user/2024/app
mkdir /home/ec2-user/2024/app/token
mkdir /home/ec2-user/2024/app/employee
mkdir /home/ec2-user/2024/app/db
mkdir /home/ec2-user/2024/k8s
mkdir /home/ec2-user/2024/k8s/cluster
mkdir /home/ec2-user/2024/k8s/manifest
mkdir /home/ec2-user/2024/k8s/scaling



aws s3 cp s3://${var.randomBucketId}/app/token /home/ec2-user/2024/app/token/token
aws s3 cp s3://${var.randomBucketId}/app/employee /home/ec2-user/2024/app/employee/employee
aws s3 cp s3://${var.randomBucketId}/app/load_employees.dump /home/ec2-user/2024/app/db/load_employees.dump
aws s3 cp s3://${var.randomBucketId}/scripts.sh /home/ec2-user/2024/scripts.sh
aws s3 cp s3://${var.randomBucketId}/cluster/cluster.yml /home/ec2-user/2024/k8s/cluster/cluster.yml
aws s3 cp s3://${var.randomBucketId}/manifest/system.yml /home/ec2-user/2024/k8s/manifest/system.yml
aws s3 cp s3://${var.randomBucketId}/manifest/ingress.yml /home/ec2-user/2024/k8s/manifest/ingress.yml
aws s3 cp s3://${var.randomBucketId}/scaling/hpa.yml /home/ec2-user/2024/k8s/scaling/hpa.yml
aws s3 cp s3://${var.randomBucketId}/scaling/nginx.yml /home/ec2-user/2024/k8s/scaling/nginx.yml
aws s3 cp s3://${var.randomBucketId}/scaling/envoyConfigmap.yml /home/ec2-user/2024/k8s/scaling/envoyConfigmap.yml
aws s3 cp s3://${var.randomBucketId}/scaling/nginxConfigmap.yml /home/ec2-user/2024/k8s/scaling/nginxConfigmap.yml
aws s3 cp s3://${var.randomBucketId}/scaling/scaling.sh /home/ec2-user/2024/k8s/scaling/scaling.sh
aws s3 rm s3://${var.randomBucketId} --recursive
aws s3api delete-bucket --bucket ${var.randomBucketId}



chmod +x /home/ec2-user/2024/scripts.sh
chmod +x /home/ec2-user/2024/k8s/scaling/scaling.sh
chmod +x /home/ec2-user/2024/app/token/token
chmod +x /home/ec2-user/2024/app/employee/employee



yum update -y
yum install mariadb105-server -y
yum install docker -y
usermod -aG docker ec2-user
systemctl enable --now docker
systemctl restart docker
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/bin/
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.2/2024-07-12/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/bin/
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
yum install wget -y
wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Linux_amd64.tar.gz
tar -xvzf k9s_Linux_amd64.tar.gz
mv k9s /usr/local/bin/
sudo yum install dos2unix -y



aws ecr create-repository --repository-name apdev-repo
cd /home/ec2-user/2024/app/token/
cat <<td> /home/ec2-user/2024/app/token/Dockerfile
FROM alpine:3.18
WORKDIR /apdev/
COPY token /apdev/
RUN apk --no-cache add gcompat libc6-compat
CMD ["./token"]
td
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t apdev-repo .
docker tag apdev-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/apdev-repo:token
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/apdev-repo:token
cd /home/ec2-user/2024/app/employee/
cat <<ed> /home/ec2-user/2024/app/employee/Dockerfile
FROM alpine:3.18
WORKDIR /apdev/
COPY employee /apdev/
RUN apk --no-cache add gcompat libc6-compat
CMD ["./employee"]
ed
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t apdev-repo .
docker tag apdev-repo:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/apdev-repo:employee
docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/apdev-repo:employee



mysql -h ${var.rdsEndpoint} -u admin -P 3306 -pSkill53## <<SQL
use dev;
CREATE TABLE employees (
    emp_no      INT             NOT NULL,
    birth_date  DATE            NOT NULL,
    first_name  VARCHAR(14)     NOT NULL,
    last_name   VARCHAR(16)     NOT NULL,
    gender      ENUM ('M','F')  NOT NULL,
    hire_date   DATE            NOT NULL,
    PRIMARY KEY (emp_no),
    INDEX idx_first_name (first_name),
    INDEX idx_last_name (last_name)
);
source /home/ec2-user/2024/app/db/load_employees.dump
SQL



aws ec2 create-tags --resources ${var.pubSnA_Id} ${var.pubSnB_Id} --tags Key=kubernetes.io/role/elb,Value=1
aws ec2 create-tags --resources ${var.pvtSnA_Id} ${var.pvtSnB_Id} --tags Key=kubernetes.io/role/internal-elb,Value=1



eksctl create cluster -f /home/ec2-user/2024/k8s/cluster/cluster.yml



kubectl create ns apdev
kubectl create ns ingress-nginx


dos2unix /home/ec2-user/2024/k8s/scaling/scaling.sh
dos2unix /home/ec2-user/2024/scripts.sh



# /home/ec2-user/2024/k8s/scaling/scaling.sh
# /home/ec2-user/2024/scripts.sh



chown -R ec2-user:ec2-user /home/ec2-user/
usd
    tags = {
        Name = "apdev-bastion"
    }

}