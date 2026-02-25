#!/bin/bash
set -e
#########################
#Terraform Init, Plan, Apply
#########################
terraform init -backend-config=backend.prod.tfvars
terraform plan -var-file=values.prod.tfvars
terraform apply -auto-approve -var-file=values.prod.tfvars


#########################
#Update KubeConfig, and export Varibles
#########################
aws eks update-kubeconfig --region `terraform output eks_cluster_arn | cut -d':' -f4` --name `terraform output eks_cluster_name | tr -d '"'`
export CLUSTER_NAME=`terraform output eks_cluster_name | tr -d '"'` && export AUTOSCALER_ROLE=`terraform output cluster-autosclaer-role-arn| tr -d '"'` && envsubst < cluster-autoscaler.yml > cluster-autoscaler-with-envs.yml

#########################
#Helm and Kubectl commands
#########################
kubectl create namespace utilities || true

######## Ingress-Nginx installation ########
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx -f ../ingress-nginx/values.external.prod.yaml --version 4.9.0 -n ingress-nginx-public --create-namespace
helm upgrade -i ingress-nginx-internal ingress-nginx/ingress-nginx -f ../ingress-nginx/values.internal.prod.yaml --version 4.9.0  -n ingress-nginx-private --create-namespace

######## metrics-server installation ########
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade -i metrics-server metrics-server/metrics-server -n utilities -f metrics-server.values.yaml

######## Updating Storge class to gp3 ########
kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class="false" --overwrite
kubectl apply -f gp2-to-gp3.yml

######## prometheus helm chart ########
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade -i prometheus prometheus-community/prometheus -f ../prometheus/values.prod.yaml --version 25.9.0 -n utilities

######## K8s Dashboard Installation ########
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl apply -f ../k8s-dashboard/k8s-dashboard-admin.yml
kubectl apply -f ../k8s-dashboard/k8s-dashboard-readonly.yml
kubectl apply -f ../k8s-dashboard/k8s-dashboard-ingress.prod.yml

######## Cluster Autoscaler Installation ########
kubectl apply -f cluster-autoscaler-with-envs.yml
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
kubectl set image deployment cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.28.2

######## FluentBit Helm Installation ########
helm repo add fluent https://fluent.github.io/helm-charts
helm upgrade -i fluent-bit fluent/fluent-bit -f ../fluent-bit/values.prod.yaml --version 0.42.0 -n utilities

######## botkube Installation ########
helm repo add infracloudio https://charts.botkube.io/
helm upgrade -i botkube infracloudio/botkube -f ../botkube/values.prod.yaml --version 0.12.4 -n botkube --create-namespace
kubectl apply -f ../botkube/prod.ingress.yaml

######## Airflow Secret and Ingress Installation ########
chmod +x secrets.prod.sh
./secrets.prod.sh
kubectl apply -f ../airflow/airflow-web-ingress.prod.yml

#Uptime Kuma Status Page
helm repo add uptime-kuma https://dirsigler.github.io/uptime-kuma-helm
helm upgrade -i uptime-kuma ../uptime-kuma -f ../uptime-kuma/values.prod.yaml -n monitoring --create-namespace

#AWS Loadbalancer Controller
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -f eks/AWS_Loadbalancer_controller_configs/values.prod.yaml -n kube-system