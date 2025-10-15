set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']

controller := `talosctl config info --output json | jq --raw-output '.endpoints[]' | shuf -n 1`

[private]
default:
    just -l k8s-bootstrap

# Fetch kubeconfig
kubeconfig:
  talosctl kubeconfig -n "{{ controller }}" -f --force-context-name ops {{ justfile_dir() }} \
  || just log fatal "Failed to fetch kubeconfig from controller {{ controller }}"
