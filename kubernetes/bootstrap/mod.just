set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir() + '/kubernetes'
bootstrap_dir := kubernetes_dir + '/bootstrap'
controller := `talosctl config info --output json | jq --raw-output '.endpoints[]' | shuf -n 1`
nodes := `talosctl config info -o yaml | yq -e '.nodes | join (" ")'`

[private]
default:
    just -l k8s-bootstrap

# Fetch kubeconfig
kubeconfig:
  talosctl kubeconfig -n "{{ controller }}" -f --force-context-name ops {{ justfile_dir() }} \
  || just log fatal "Failed to fetch kubeconfig from controller {{ controller }}"

# Apply Kubernetes resources
resources:
  just template "{{ bootstrap_dir }}/resources.yaml.j2" | kubectl apply --server-side --dry-run=server -f - \
  || just log fatal "Failed to apply Kubernetes resources"

# Apply Helmfile apps
apps:
  helmfile -f "{{ bootstrap_dir }}/helmfile.d/01-apps.yaml" sync --hide-notes \
  || just log fatal "Failed to apply Helmfile apps"
