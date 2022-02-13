## Bootstrapping
To bootstrap a new cluster the following is required:
- Install flux with just: `flux install`
- Create secret with age key: `cat ~/.config/sops/age/keys.txt | kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=/dev/stdin`
- Deploy base ressources: `kubectl apply -k clusters/<name>`
