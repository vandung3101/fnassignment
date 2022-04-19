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