# Repository overview

This repository manages my home infrastructure as code. It contains Kubernetes
applications managed through Flux, Kustomize, and Helm; Talos node configuration
and cluster bootstrap templates; and Ansible roles and templates for a VyOS
network gateway. It also includes shared Kubernetes components, encrypted
secrets, dependency update configuration, and CI validation workflows.

## Working preferences

- Some tools are provided via `mise`.
- Some tasks are provided via `just`.
- Do not commit or push unless explicitly asked.
- Infrastructure changes mean local repository edits unless live operations are
  explicitly requested. Do not deploy, reconcile, or change running infrastructure
  as part of validation.
- Once an operation is authorized, proceed without asking for the same permission
  again.
