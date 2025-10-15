#!/usr/bin/env -S just --justfile

set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']

mod vyos "infrastructure/vyos"
mod k8s-bootstrap "kubernetes/bootstrap"
mod talos "kubernetes/talos"

[private]
default:
  just -l

[private]
log lvl msg *args:
  gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
  minijinja "{{ file }}" {{ args }} | op.exe inject
