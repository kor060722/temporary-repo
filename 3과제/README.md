# README.md !!!

01. 다음 순으로 Terraform apply 진행합니다.

    -> terraform init -> terraform apply --auto-approve

02. 01번 진행 후 바로 RDS Console로 이동하여 DB를 생성해줍니다. (Support Database*.png 참고)

03. all.tf에 있는 Networking , Identity , storage , Server 주석처리를 해제한 후, RDS Console로 이동하여 Endpoint 생성까지 대기합니다.

    RDS Endpoint와 Proxy Endpoint 생성이 되었다면 Copy 후 ./terraform.tfvars에 알맞게 변수로 지정합니다.

    이후 01번과 같은 순으로 Terraform apply를 진행합니다.

04. apdev-pvt-sn-a , apdev-pvt-sn-b 라는 NameTag를 가진 Subnet에 Key=kubernetes.io/cluster/apdev-eks-cluster를 달아줍니다.

05. 전체 Terraform apply 가 완료되면 ssh 접속 후 sudo su - ec2-user , cd ~ , watch -n 1 ls -al 명령어를 순차적으로 실행 후 ec2-user로 권한이 변경되길 확인합니다.

    변경이 확인되면 157,158번 줄에 명령어를 그대로 수동 실행합니다.

06. LoadBalancer 까지 생성이 완료 되었다면 CloudFront Console로 이동하여 CloudFront를 생성해줍니다. (Support CloudFront*.png 참고)

07. CloudFront 까지 생성이 완료 되었다면 CloudWatch로 이동하여 Monitoring을 구성해줍니다. (Support Monitoring*.png,Notion 참고)

08. https://developer-jiing.tistory.com/48 <- 다음 사이트 참고하여 무중단 배포 진행합니다.