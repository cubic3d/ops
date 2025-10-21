set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

awk := require("awk")

[private]
default:
  just -l k8s

cleanup-volsync:
  for r in pvc volumesnapshot; do \
    kubectl get $r -A --no-headers | awk '/volsync-.*-dest/ {print $1, $2}' | xargs -n 2 sh -c 'kubectl delete '$r' -n $0 $1'; \
  done
