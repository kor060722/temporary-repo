# --------------- Bucket --------------- #
resource "random_pet" "randomBucketName" {
  length = 4
  separator = "-"
}
resource "aws_s3_bucket" "randomBucket" {
  bucket = "${random_pet.randomBucketName.id}"
}



# --------------- ApplicationUpload --------------- #
resource "aws_s3_bucket_object" "tokenUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "app/token"
  source  = "./App/token/token"
}
resource "aws_s3_bucket_object" "employeeUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "app/employee"
  source  = "./App/employee/employee"
}
resource "aws_s3_bucket_object" "dumpUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "app/load_employees.dump"
  source  = "./App/db/load_employees.dump"
}



# --------------- ScriptsUpload --------------- #
resource "aws_s3_bucket_object" "scalingUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "scaling/scaling.sh"
  content = <<ss
#!/bin/bash
aws eks update-kubeconfig --name apdev-eks-cluster --region ap-northeast-2
cat << cap > /home/ec2-user/2024/k8s/scaling/caPolicy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["*"]
    }
  ]
}
cap
cd /home/ec2-user/2024/k8s/scaling/
aws iam create-policy \
--policy-name AmazonEKSClusterAutoscalerPolicy \
--policy-document file://caPolicy.json
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install aws-cluster-autoscaler autoscaler/cluster-autoscaler -n kube-system \
--set autoDiscovery.clusterName=apdev-eks-cluster \
--set awsRegion=ap-northeast-2 \
--set rbac.serviceAccount.create=false \
--set rbac.serviceAccount.name=cluster-autoscaler \
--set image.tag="v1.23.0" \
--set extraArgs.scale-down-delay-after-add=1m \
--set extraArgs.scale-down-delay-after-delete=1m \
--set extraArgs.scale-down-delay-after-failure=1m \
--set extraArgs.scale-down-unneeded-time=1m \
--set extraArgs.scan-interval=10s \
--set extraArgs.balance-similar-node-groups=true \
--set extraArgs.expander=least-waste
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f /home/ec2-user/2024/k8s/scaling/hpa.yml
ss
}
resource "aws_s3_bucket_object" "scriptsUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "scripts.sh"
  content = <<scr
#!/bin/bash
kubectl apply -f /home/ec2-user/2024/k8s/manifest/system.yml
kubectl apply -f /home/ec2-user/2024/k8s/manifest/ingress.yml
cd /home/ec2-user/2024/k8s/scaling
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --version 4.10.0 --namespace ingress-nginx --create-namespace -f /home/ec2-user/2024/k8s/scaling/nginx.yml
kubectl apply -f envoyConfigmap.yml
kubectl apply -f nginxConfigmap.yml
kubectl patch deployment ingress-nginx-controller \
  -n ingress-nginx \
  --patch '{
    "spec": {
      "template": {
        "spec": {
          "volumes": [
            {
              "name": "envoy-config-volume",
              "configMap": {
                "name": "envoy-config"
              }
            }
          ]
        }
      }
    }
  }'
kubectl patch deployment ingress-nginx-controller \
  -n ingress-nginx \
  --patch '{
    "spec": {
      "template": {
        "spec": {
          "containers": [
            {
              "name": "envoy-sidecar",
              "image": "envoyproxy/envoy:v1.18.3",
              "imagePullPolicy": "IfNotPresent",
              "args": [
                "--config-path",
                "/etc/envoy/envoy.yaml"
              ],
              "resources": {
                "limits": {
                  "cpu": "1",
                  "memory": "200Mi"
                },
                "requests": {
                  "cpu": "0.5",
                  "memory": "100Mi"
                }
              },
              "volumeMounts": [
                {
                  "mountPath": "/etc/envoy",
                  "name": "envoy-config-volume"
                }
              ]
            }
          ]
        }
      }
    }
  }'
kubectl patch svc ingress-nginx-controller -n ingress-nginx --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value":10000}]'
kubectl delete -f /home/ec2-user/2024/k8s/manifest/system.yml
sleep 10
kubectl apply -f /home/ec2-user/2024/k8s/manifest/system.yml
scr
}



# --------------- ApplicationUpload --------------- #
resource "aws_s3_bucket_object" "clusterUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "cluster/cluster.yml"
  content = <<cy
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: apdev-eks-cluster
  version: "1.30"
  region: ap-northeast-2
vpc:
  id: ${var.vpcId}
  subnets:
    private:
      private-a: 
        id: ${var.pvtSnA_Id}
      private-b: 
        id: ${var.pvtSnB_Id}   
iamIdentityMappings:
  - arn: arn:aws:iam::$AWS_ACCOUNT_ID:role/root
    groups:
      - system:masters
    username: root-admin
iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true
  - metadata:
      name: cluster-autoscaler
      namespace: kube-system
    wellKnownPolicies:
      autoScaler: true
managedNodeGroups:
  - name: apdev-eks-addon-ng
    amiFamily: Bottlerocket
    labels: { node.label/key: addon }
    instanceType: t3.micro
    instanceName: apdev-eks-addon-node
    desiredCapacity: 3
    minSize: 1
    maxSize: 100
    privateNetworking: true
    volumeEncrypted: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true
  - name: apdev-eks-token-ng
    amiFamily: Bottlerocket
    labels: { node.label/key: token }
    instanceType: t3.micro
    instanceName: apdev-eks-token-node
    desiredCapacity: 1
    minSize: 1
    maxSize: 100
    privateNetworking: true
    volumeEncrypted: true
    taints:
      - key: node.taint/key
        value: token
        effect: NoSchedule
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true
  - name: apdev-eks-employee-ng
    amiFamily: Bottlerocket
    labels: { node.label/key: employee }
    instanceType: t3.micro
    instanceName: apdev-eks-employee-node
    desiredCapacity: 1
    minSize: 1
    maxSize: 100
    privateNetworking: true
    volumeEncrypted: true
    taints:
      - key: node.taint/key
        value: employee
        effect: NoSchedule
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        cloudWatch: true
cloudWatch:
  clusterLogging:
    enableTypes: ["*"]
cy
}
resource "aws_s3_bucket_object" "systemUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "manifest/system.yml"
  content = <<sy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apdev-eks-token-deploy
  namespace: apdev
  labels:
    pod.label/key: token
spec:
  replicas: 2
  selector:
    matchLabels:
      pod.label/key: token
  template:
    metadata:
      labels:
        pod.label/key: token
    spec:
      tolerations:
      - key: node.taint/key
        operator: "Equal"
        value: token
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node.label/key
                operator: In
                values:
                - token
      containers:
      - name: token-container
        image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/apdev-repo:token
        imagePullPolicy: Always
        resources:
          requests:
            cpu: "0.5"
            memory: "100Mi"
          limits:
            cpu: "1"
            memory: "200Mi"
      - name: envoy-sidecar
        image: envoyproxy/envoy:v1.18.3
        imagePullPolicy: IfNotPresent
        args:
        - --config-path
        - /etc/envoy/envoy.yaml
        resources:
          limits:
            cpu: 1
            memory: 200Mi
          requests:
            cpu: 0.5m
            memory: 100Mi
        volumeMounts:
        - mountPath: /etc/envoy
          name: envoy-config-volume
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      volumes:
      - name: envoy-config-volume
        configMap:
          name: envoy-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apdev-eks-employee-deploy
  namespace: apdev
  labels:
    pod.label/key: employee
spec:
  replicas: 2
  selector:
    matchLabels:
      pod.label/key: employee
  template:
    metadata:
      labels:
        pod.label/key: employee
    spec:
      tolerations:
      - key: node.taint/key
        operator: "Equal"
        value: employee
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node.label/key
                operator: In
                values:
                - employee
      containers:
      - name: employee-container
        image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/apdev-repo:employee
        imagePullPolicy: Always
        env:
        - name: MYSQL_USER
          value: "admin"
        - name: MYSQL_PASSWORD
          value: "Skill53##"
        - name: MYSQL_HOST
          value: ${var.rdsProxy}
        - name: MYSQL_PORT
          value: "3306"
        - name: MYSQL_DBNAME
          value: "dev"
        resources:
          requests:
            cpu: "0.5"
            memory: "100Mi"
          limits:
            cpu: "1"
            memory: "200Mi"
      - name: envoy-sidecar
        image: envoyproxy/envoy:v1.18.3
        imagePullPolicy: IfNotPresent
        args:
        - --config-path
        - /etc/envoy/envoy.yaml
        resources:
          limits:
            cpu: 1
            memory: 200Mi
          requests:
            cpu: 0.5m
            memory: 100Mi
        volumeMounts:
        - mountPath: /etc/envoy
          name: envoy-config-volume
      volumes:
      - name: envoy-config-volume
        configMap:
          name: envoy-config
---
apiVersion: v1
kind: Service
metadata:
  name: apdev-eks-token-svc
  namespace: apdev
spec:
  selector:
    pod.label/key: token
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 10000
      protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: apdev-eks-employee-svc
  namespace: apdev
spec:
  selector:
    pod.label/key: employee
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 10000
      protocol: TCP
sy
}
resource "aws_s3_bucket_object" "hpaUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "scaling/hpa.yml"
  content = <<hy
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apdev-eks-token-hpa
  namespace: apdev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apdev-eks-token-deploy
  minReplicas: 2
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 50
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apdev-eks-employee-hpa
  namespace: apdev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apdev-eks-employee-deploy
  minReplicas: 2
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 50
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apdev-eks-controller-hpa
  namespace: ingress-nginx
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ingress-nginx-controller
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 88
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 77
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apdev-eks-ca-hpa
  namespace: kube-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: aws-cluster-autoscaler
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 88
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 77
hy
}
resource "aws_s3_bucket_object" "nginxUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "scaling/nginx.yml"
  content = <<ny
controller:
  name: controller
  kind: Deployment
  dnsPolicy: ClusterFirst
  replicaCount: 1
  ingressClassByName: false
  ingressClassResource:
    name: nginx
    enabled: true
  scope:
    enabled: false
  config:
    proxy-real-ip-cidr: 10.1.0.0/16
    real-ip-header: "proxy_protocol"
    use-proxy-protocol: "false"
  service:
    enabled: true
    type: LoadBalancer
    externalTrafficPolicy: Cluster
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
    external:
      enabled: true
    internal:
      enabled: false
  configMapNamespace: ""
  tcp:
    configMapNamespace: ""
    annotations: {}
  udp:
    configMapNamespace: ""
    annotations: {}
  affinity: {}
rbac:
  create: true
  scope: false
serviceAccount:
  create: true
  name: ""
ny
}
resource "aws_s3_bucket_object" "envoyConfigUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "scaling/envoyConfigmap.yml"
  content = <<ecy
apiVersion: v1
data:
  envoy.yaml: |
    static_resources:
      listeners:
      - name: listener_0
        address:
          socket_address:
            address: 0.0.0.0
            port_value: 10000
        filter_chains:
        - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              stat_prefix: ingress_http
              codec_type: AUTO
              route_config:
                name: local_route
                virtual_hosts:
                - name: backend
                  domains: ["*"]
                  routes:
                  - match:
                      prefix: "/v1/token"
                    route:
                      cluster: token
                  - match:
                      prefix: "/v1/employee"
                    route:
                      cluster: employee
              http_filters:
              - name: envoy.filters.http.router
              access_log:
              - name: envoy.access_loggers.stdout
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                  log_format:
                    json_format:
                      timestamp: "%START_TIME%"
                      method: "%REQ(:METHOD)%"
                      path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                      protocol: "%PROTOCOL%"
                      response_code: "%RESPONSE_CODE%"
                      response_flags: "%RESPONSE_FLAGS%"
                      bytes_received: "%BYTES_RECEIVED%"
                      bytes_sent: "%BYTES_SENT%"
                      duration: "%DURATION%"
                      upstream_service_time: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
                      user_agent: "%REQ(USER-AGENT)%"
                      x_forwarded_for: "%REQ(X-FORWARDED-FOR)%"
                      request_id: "%REQ(X-REQUEST-ID)%"
                      authority: "%REQ(:AUTHORITY)%"
                      upstream_host: "%UPSTREAM_HOST%"
      clusters:
      - name: token
        connect_timeout: 0.25s
        type: STRICT_DNS
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: token
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 8080
      - name: employee
        connect_timeout: 0.25s
        type: STRICT_DNS
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: employee
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 8080
kind: ConfigMap
metadata:
  name: envoy-config
  namespace: apdev
ecy
}
resource "aws_s3_bucket_object" "nginxConfigUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "scaling/nginxConfigmap.yml"
  content = <<ncy
apiVersion: v1
data:
  envoy.yaml: |
    static_resources:
      listeners:
      - name: listener_0
        address:
          socket_address:
            address: 0.0.0.0
            port_value: 10000
        filter_chains:
        - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              stat_prefix: ingress_http
              codec_type: AUTO
              route_config:
                name: local_route
                virtual_hosts:
                - name: backend
                  domains: ["*"]
                  routes:
                  - match:
                      prefix: "/v1/token"
                    route:
                      cluster: token
                  - match:
                      prefix: "/v1/employee"
                    route:
                      cluster: employee
              http_filters:
              - name: envoy.filters.http.router
              access_log:
              - name: envoy.access_loggers.stdout
                typed_config:
                  "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                  log_format:
                    json_format:
                      timestamp: "%START_TIME%"
                      method: "%REQ(:METHOD)%"
                      path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                      protocol: "%PROTOCOL%"
                      response_code: "%RESPONSE_CODE%"
                      response_flags: "%RESPONSE_FLAGS%"
                      bytes_received: "%BYTES_RECEIVED%"
                      bytes_sent: "%BYTES_SENT%"
                      duration: "%DURATION%"
                      upstream_service_time: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
                      user_agent: "%REQ(USER-AGENT)%"
                      x_forwarded_for: "%REQ(X-FORWARDED-FOR)%"
                      request_id: "%REQ(X-REQUEST-ID)%"
                      authority: "%REQ(:AUTHORITY)%"
                      upstream_host: "%UPSTREAM_HOST%"
      clusters:
      - name: token
        connect_timeout: 0.25s
        type: STRICT_DNS
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: token
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 80
      - name: employee
        connect_timeout: 0.25s
        type: STRICT_DNS
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: employee
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 80

kind: ConfigMap
metadata:
  name: envoy-config
  namespace: ingress-nginx
ncy
}

resource "aws_s3_bucket_object" "ingressUpload" {
  bucket  = aws_s3_bucket.randomBucket.id
  key     = "manifest/ingress.yml"
  content = <<ig
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: apdev-ingress
  namespace: apdev
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /healthcheck
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP 

spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /healthcheck
            pathType: Prefix
            backend:
              service:
                name: apdev-eks-token-svc
                port:
                  number: 80
          - path: /v1/token
            pathType: Prefix
            backend:
              service:
                name: apdev-eks-token-svc
                port:
                  number: 80
          - path: /v1/employee
            pathType: Prefix
            backend:
              service:
                name: apdev-eks-employee-svc
                port:
                  number: 80
ig
}