# Bootstrap Cluster

Commands use fish syntax.

## Talos

### Generate Secrets and Encrypt (already commited)

```bash
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
sops -e -i talenv.sops.yaml
```

### Generate Node Configs

```bash
talhelper genconfig
```

### Apply Configs to Fresh Nodes

Make sure nodes have booted a Talos ISO.

```bash
eval (talhelper gencommand apply --extra-flags --insecure)
```

Wait for about 2 minutes for the nodes to configure and bring up services.

### Bootstrap Nodes

```bash
eval (talhelper gencommand bootstrap)
```

Wait for about 3 minutes for the cluster to bootstrap.

### Retrieve Kubeconfig

```bash
eval (talhelper gencommand kubeconfig)
```

### List Nodes in Cluster

```bash
kubectl get nodes
```

### Install Secrets and Configs

```bash
kubectl apply -n flux-system -f ../components/namespace/namespace.yaml
sops --decrypt ../components/namespace/age.sops.yaml | kubectl apply -n flux-system -f -
sops --decrypt ../components/namespace/cluster-secrets.sops.yaml | kubectl apply -n flux-system -f -
kubectl apply -n flux-system -f ../components/namespace/cluster-settings.yaml
```

## Helmfile

### Install dependencies

```bash
helmfile --file helmfile.yaml apply --skip-diff-on-install --suppress-diff
```
