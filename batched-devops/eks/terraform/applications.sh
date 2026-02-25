helm repo add airflow-stable https://airflow-helm.github.io/charts
helm upgrade -i airflow airflow-stable/airflow --version 8.3.0 -f values.yml -n airflow            #Copy Values File from https://bitbucket.org/batched/batched-airflow-db-provisioning/

#Backend API
##Before this update the Ingress To Point it to public ingressclass
##Also currently disable Autoscaling
kubectl create ns backend-api
helm upgrade -i backend-api backendapi-eks-dev -n backend-api

#Backend Dal API
kubectl create ns dal-backend-api
helm upgrade -i dal-backend-api dal-backendapi-eks-dev -n dal-backend-api