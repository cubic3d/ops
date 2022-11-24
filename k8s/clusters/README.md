## Bootstrapping
To bootstrap a new cluster the following is required:
- Install flux with just: `flux install`
- Create secret with age key: `grep age17pjdz3x48re0ahdw00eqdj0da02ltp3wkxswr755cvaqj3j5938s7put83 -B1 -A1 ~/.config/sops/age/keys.txt | kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=/dev/stdin`
- Deploy base ressources: `kubectl apply -k clusters/<name>`
