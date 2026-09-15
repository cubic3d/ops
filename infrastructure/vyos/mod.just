set default-list
set default-script
set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

# Check configuration and list changes
check:
    ansible-playbook --check site.yaml

# Apply configuration
apply:
    ansible-playbook site.yaml
