#!/bin/sh

# set completion for kubectl

echo "set completion for kubectl"
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "source <(helm completion bash)" >> $HOME/.bashrc

# set kubectl alias
echo "set kubectl alias"
echo "alias k=kubectl" >> $HOME/.bashrc
echo "complete -F __start_kubectl k" >> $HOME/.bashrc

# kubeadm join

# run the following on the master node to get thediscovery token hash

sudo cat /etc/kubernetes/pki/ca.crt | openssl x509 -pubkey  | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'

# Run the following to get the token

sudo kubeadm token list