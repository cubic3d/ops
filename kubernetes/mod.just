set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

awk := require("awk")

[private]
default:
    just -l k8s

# Cleanup VolSync resources created on first provisioning
cleanup-volsync:
    for r in pvc volumesnapshot; do \
      kubectl get $r -A --no-headers | awk '/volsync-.*-dest/ {print $1, $2}' | xargs -n 2 sh -c 'kubectl delete '$r' -n $0 $1'; \
    done

# Cleanup succeeded, pending, and failed pods
cleanup-pods:
    for phase in Failed Pending Succeeded; do \
      kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true; \
    done

# Force resync of a ExternalSecret
sync-secret ns='' name='':
    if [ -z "{{ ns }}" ] && [ -z "{{ name }}" ]; then \
      kubectl get externalsecret -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name --no-headers \
        | while read -r ns name; do kubectl annotate externalsecret -n "$ns" "$name" force-sync="$(date +%s)" --overwrite; done; \
    elif [ -n "{{ ns }}" ] && [ -z "{{ name }}" ]; then \
      kubectl get externalsecret -n "{{ ns }}" -o custom-columns=NAME:.metadata.name --no-headers \
        | while read -r name; do kubectl annotate externalsecret -n "{{ ns }}" "$name" force-sync="$(date +%s)" --overwrite; done; \
    else \
      kubectl annotate externalsecret -n "{{ ns }}" "{{ name }}" force-sync="$(date +%s)" --overwrite; \
    fi

# Mount a PVC to a temporary pod
mount-pvc ns name:
    kubectl run -n {{ ns }} mount-{{ name }} -i --tty --rm --image=null --privileged --overrides=' \
      { \
        "apiVersion": "v1", \
        "spec": { \
          "containers": [ \
            { \
              "name": "mount", \
              "image": "docker.io/library/alpine:edge", \
              "command": [ \
                "/bin/sh" \
              ], \
              "workingDir": "/data", \
              "stdin": true, \
              "stdinOnce": true, \
              "tty": true, \
              "volumeMounts": [ \
                { \
                  "name": "data", \
                  "mountPath": "/data" \
                } \
              ] \
            } \
          ], \
          "volumes": [ \
            { \
              "name": "data", \
              "persistentVolumeClaim": { \
                "claimName": "{{ name }}" \
              } \
            } \
          ], \
          "tolerations": [ \
            { \
              "operator": "Exists", \
              "effect": "NoSchedule" \
            } \
          ], \
          "restartPolicy": "Never" \
        } \
      }'

# Shell on node
node-shell node:
    kubectl debug node/{{ node }} -it --profile=sysadmin --image='mirror.gcr.io/alpine:latest'
    kubectl delete pod -l app.kubernetes.io/managed-by=kubectl-debug

# Create volsync snapshot
snapshot ns name:
    kubectl -n "{{ ns }}" patch replicationsources "{{ name }}" --type merge -p '{"spec":{"trigger":{"manual":"$(date +%s)"}}}'

# Create volsync snapshot for all replicationsources
snapshot-all:
    kubectl get replicationsources --no-headers -A | while read -r ns name _; do \
      just k8s snapshot "$ns" "$name"; \
    done
