set lazy
set positional-arguments
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
[script]
default:
    just -l vyos

# Check configuration and list changes
[script]
check:
    ansible-playbook --check site.yaml

# Apply configuration
[script]
apply:
    ansible-playbook site.yaml
