set default-list
set default-script
set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

awk := require("awk")
crunchy_postgres_primary_selector := "postgres-operator.crunchydata.com/cluster=postgres,postgres-operator.crunchydata.com/role=master"

# Cleanup succeeded, pending, and failed pods
cleanup-pods:
    for phase in Failed Pending Succeeded; do
      kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true
    done

# Force resync of a ExternalSecret
sync-secret ns='' name='':
    if [ -z "{{ ns }}" ] && [ -z "{{ name }}" ]; then
      kubectl get externalsecret -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name --no-headers
        | while read -r ns name; do kubectl annotate externalsecret -n "$ns" "$name" force-sync="$(date +%s)" --overwrite; done
    elif [ -n "{{ ns }}" ] && [ -z "{{ name }}" ]; then
      kubectl get externalsecret -n "{{ ns }}" -o custom-columns=NAME:.metadata.name --no-headers
        | while read -r name; do kubectl annotate externalsecret -n "{{ ns }}" "$name" force-sync="$(date +%s)" --overwrite; done
    else
      kubectl annotate externalsecret -n "{{ ns }}" "{{ name }}" force-sync="$(date +%s)" --overwrite
    fi

# Mount a PVC to a temporary pod
browse-pvc namespace claim:
    kubectl browse-pvc -n {{ namespace }} -i mirror.gcr.io/alpine:edge {{ claim }}

# Shell on node
node-shell node:
    kubectl debug node/{{ node }} -it --profile=sysadmin --image='mirror.gcr.io/alpine:latest'
    kubectl delete pod -l app.kubernetes.io/managed-by=kubectl-debug

# Dump a database from the Crunchy Postgres primary pod to a local file
[no-cd]
postgres-dump db file:
    pod="$(kubectl get pod -n database -l '{{ crunchy_postgres_primary_selector }}' -o jsonpath='{.items[0].metadata.name}')"
    [ -n "$pod" ] || { echo "No Crunchy Postgres primary pod found" >&2; exit 1; }
    kubectl exec -n database "$pod" -c database -- pg_dump --username=postgres --dbname="{{ db }}" --format=custom > "{{ file }}"

# Restore a local dump file into a database on the Crunchy Postgres primary pod
[no-cd]
postgres-restore db file:
    pod="$(kubectl get pod -n database -l '{{ crunchy_postgres_primary_selector }}' -o jsonpath='{.items[0].metadata.name}')"
    [ -n "$pod" ] || { echo "No Crunchy Postgres primary pod found" >&2; exit 1; }
    kubectl exec -i -n database "$pod" -c database -- pg_restore --username=postgres --dbname="{{ db }}" --clean --if-exists --no-owner --no-privileges < "{{ file }}"

# Open a psql shell on the Crunchy Postgres primary pod
postgres-psql db='postgres':
    pod="$(kubectl get pod -n database -l '{{ crunchy_postgres_primary_selector }}' -o jsonpath='{.items[0].metadata.name}')"
    [ -n "$pod" ] || { echo "No Crunchy Postgres primary pod found" >&2; exit 1; }
    kubectl exec -it -n database "$pod" -c database -- psql --username=postgres --dbname="{{ db }}"

# Trigger kopiur snapshot
snapshot ns name:
    kubectl kopiur -n "{{ ns }}" snapshot now --policy "{{ name }}"

# Trigger kopiur snapshot for all snapshotpolicies
snapshot-all:
    kubectl get snapshotpolicies.kopiur.home-operations.com --no-headers -A | while read -r ns name _; do
      just k8s snapshot-kopiur "$ns" "$name"
    done

# Render local KS
render-ks ns name:
    flate build ks --namespace "{{ ns }}" "{{ name }}"

# Render local HelmRelease
render-hr ns name:
    flate build hr --namespace "{{ ns }}" "{{ name }}"
