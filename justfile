#!/usr/bin/env -S just --justfile

set lazy
set positional-arguments
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

mod vyos "infrastructure/vyos"
mod bootstrap "kubernetes/bootstrap"
mod talos "kubernetes/talos"
mod k8s "kubernetes"

[private]
[script]
default:
    just -l

[private]
[script]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
[script]
template file *args:
    minijinja "{{ file }}" {{ args }} | op inject


# Rotate all SOPS secrets
[script]
sops-rotate:
    find . -type f -name '*.sops.yaml' ! -name ".sops.yaml" -exec sh -c 'sops rotate --in-place "$0"' {} \;
