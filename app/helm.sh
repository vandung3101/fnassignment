az config set defaults.group=w7-resources
az aks get-credentials --name aks --overwrite-existing

REGISTRY_NAME=acrw678
SOURCE_REGISTRY=k8s.gcr.io
CONTROLLER_IMAGE=ingress-nginx/controller
CONTROLLER_TAG=v1.0.4
PATCH_IMAGE=ingress-nginx/kube-webhook-certgen
PATCH_TAG=v1.1.1
DEFAULTBACKEND_IMAGE=defaultbackend-amd64
DEFAULTBACKEND_TAG=1.5

az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG --image $CONTROLLER_IMAGE:$CONTROLLER_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$PATCH_IMAGE:$PATCH_TAG --image $PATCH_IMAGE:$PATCH_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG --image $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG

az acr import --name $REGISTRY_NAME --source docker.io/vandung3101/be -t be 
az acr import --name $REGISTRY_NAME --source docker.io/vandung3101/fe -t fe


# docker push acrw678.azurecr.io/w7/be
# docker push acrw678.azurecr.io/w7/fe:v2

# helm uninstall nginx-ingress -n ingress-basic   

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.0.13 \
    --namespace ingress-basic --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.image.registry="acrw678.azurecr.io" \
    --set controller.image.image="ingress-nginx/controller" \
    --set controller.image.tag="v1.0.4" \
    --set controller.image.digest="" \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.image.registry="acrw678.azurecr.io" \
    --set controller.admissionWebhooks.patch.image.image="ingress-nginx/kube-webhook-certgen" \
    --set controller.admissionWebhooks.patch.image.tag="v1.1.1" \
    --set controller.admissionWebhooks.patch.image.digest="" \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.image.registry="acrw678.azurecr.io" \
    --set defaultBackend.image.image="defaultbackend-amd64" \
    --set defaultBackend.image.tag="1.5" \
    --set defaultBackend.image.digest="" \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"="aks-vandung-ingress"


kubectl create secret tls aks-ingress-tls \
    --namespace ingress-basic \
    --key ./ssl-cert/key.key \
    --cert ./ssl-cert/cert.crt



helm install app ./app/helm/charts-ingress -n ingress-basic

helm upgrade ingress-nginx ingress-nginx \
--repo https://kubernetes.github.io/ingress-nginx \
--namespace ingress-nginx \
--set controller.metrics.enabled=true \
--set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
--set-string controller.podAnnotations."prometheus\.io/port"="10254"

kubectl apply -f https://download.newrelic.com/install/kubernetes/pixie/latest/px.dev_viziers.yaml && \
kubectl apply -f https://download.newrelic.com/install/kubernetes/pixie/latest/olm_crd.yaml && \
helm repo add newrelic https://helm-charts.newrelic.com && helm repo update && \
kubectl create namespace ingress-basic ; helm upgrade --install newrelic-bundle newrelic/nri-bundle \
 --set global.licenseKey=081d9956d385f2e2d1e676b4697988f62881NRAL \
 --set global.cluster=aks \
 --namespace=ingress-basic \
 --set newrelic-infrastructure.privileged=true \
 --set global.lowDataMode=true \
 --devel \
 --set ksm.enabled=true \
 --set kubeEvents.enabled=true \
 --set prometheus.enabled=true \
 --set logging.enabled=true \
 --set newrelic-pixie.enabled=true \
 --set newrelic-pixie.apiKey=px-api-f47f9ed6-6a2f-4917-92c7-945749a72235 \
 --set pixie-chart.enabled=true \
 --set pixie-chart.deployKey=px-dep-cb1d3fd6-c26f-427d-8ce5-687e782a01b1 \
 --set pixie-chart.clusterName=aks 

