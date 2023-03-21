#!/usr/bin/env fish

cd (status dirname)
set cluster_dir (pwd)

echo "Generating initial CSR approver deploy manifest"
kubectl kustomize kubelet-csr-approver --enable-helm -o kubelet-csr-approver/deploy.yaml

echo "Generating Talos secrets and configs"
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
talhelper genconfig
set -x TALOSCONFIG "$cluster_dir/clusterconfig/talosconfig"

echo "Applying config to nodes"
talosctl apply-config --insecure --nodes (sops -d talenv.sops.yaml | yq -r ".ip") --file clusterconfig/island-triss.yaml

echo "Waiting for nodes"
sleep 120

echo "Running bootstrap"
talosctl --nodes triss bootstrap

echo "Wait for cluster"
sleep 180

echo "Getting kubeconfig"
talosctl --nodes triss kubeconfig -f clusterconfig/

set -x KUBECONFIG $cluster_dir/clusterconfig/kubeconfig
kubectl get nodes
