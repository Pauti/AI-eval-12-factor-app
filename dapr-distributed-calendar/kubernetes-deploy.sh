#!/bin/sh

# # Replace 
# find kubernetes* -type f -exec sed -i -e "s//$USER_ID/g" {} \;

# # Replace 
# find kubernetes* -type f -exec sed -i -e "s//$ANIMAL/g" {} \;

# # Replace 
# find kubernetes* -type f -exec sed -i -e "s//$HOST_IP/g" {} \;

# # Replace 
# find kubernetes* -type f -exec sed -i -e "s//$ENVIRONMENT/g" {} \;

# # Replace 
# find kubernetes* -type f -exec sed -i -e "s//$DOMAIN/g" {} \;

# create namespace
# kubectl create namespace 12-factor-app

# install OTel Operator
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm install my-opentelemetry-operator open-telemetry/opentelemetry-operator \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.certManager.autoGenerateCert.enabled=true \
  --set manager.featureGates='operator.autoinstrumentation.go' \
  --wait

# create OTel collector and instrumentation
kubectl apply -f otel/.

# install cert-manager OPTIONAL
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.7.1 \
  --set installCRDs=true \
  --wait

# install jaeger (requires cert-manager) OPTIONAL
kubectl create namespace observability
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.38.0/jaeger-operator.yaml -n observability
kubectl wait --for=condition=ready pod --all --timeout=200s -n observability
kubectl apply -f jaeger/simplest.yaml

# install prometheus OPTIONAL
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
        --version 51.3.0 \
        --namespace default \
        --values prometheus/kube-prometheus-stack-values.yaml \
        --wait

# install elastic (requires namespace 'observability') OPTIONAL
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch --version 7.17.3 -n observability --set replicas=1 --wait
helm install kibana elastic/kibana --version 7.17.3 -n observability --wait
kubectl apply -f ./fluent/fluentd-config-map.yaml
kubectl apply -f ./fluent/fluentd-dapr-with-rbac.yaml
kubectl wait --for=condition=ready pod --all --timeout=200s -n observability

# install dapr
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update
helm upgrade --install dapr dapr/dapr \
    --namespace dapr-system \
    --create-namespace \
    --set global.logAsJson=true \
    --wait

# install dapr dashboard OPTIONAL
helm install dapr-dashboard dapr/dapr-dashboard --namespace dapr-system --wait

# install redis
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install redis bitnami/redis --wait

# deploy the 12-factor-app
kubectl apply -f kubernetes/.

# get redis password (for manual interactions with the redis cli) OPTIONAL
kubectl get secret redis -o jsonpath='{.data.redis-password}' | base64 --decode