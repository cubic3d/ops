set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l vyos

# Check configuration and list changes
check:
  ansible-playbook --check site.yaml

# Apply configuration
apply:
  ansible-playbook site.yaml
