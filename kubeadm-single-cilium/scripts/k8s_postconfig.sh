#!/bin/sh

echo "get config file for kubernetes"

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# set completion for kubectl

echo "set completion for kubectl"
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "source <(helm completion bash)" >> $HOME/.bashrc

# set kubectl alias
echo "set kubectl alias"
echo "alias k=kubectl" >> $HOME/.bashrc
echo "complete -F __start_kubectl k" >> $HOME/.bashrc

# install gateway api prereq

echo "Installing Gateway API CRDs"

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

echo "untainting the node before install"

kubectl taint node cilium2 node-role.kubernetes.io/control-plane:NoSchedule-

# install cilium
echo "Installing Cilium"

echo "set variables for cilium installation"

API_SERVER_IP='192.168.56.71'
API_SERVER_PORT='6443'
POD_CIDR='100.64.0.0/16'

echo "Adding helm repo for cilium"

helm repo add cilium https://helm.cilium.io/

helm repo update

echo "Installing Cilium with Helm"

helm upgrade cilium cilium/cilium \
    --install \
    --namespace kube-system \
    --reuse-values \
    --version "1.18.1" \
    --set kubeProxyReplacement=true \
    --set gatewayAPI.enabled=true \
    --set hubble.enabled=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set ipam.operator.clusterPoolIPv4PodCIDRList=${POD_CIDR}

echo "Waiting for Cilium to be ready"



kubectl -n kube-system rollout restart deployment/cilium-operator
kubectl -n kube-system rollout restart ds/cilium

kubectl -n kube-system scale --replicas=0 deployment/cilium-operator
kubectl -n kube-system scale --replicas=1 deployment/cilium-operator
