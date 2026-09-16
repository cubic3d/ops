set default-list
set default-script
set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

controller := `talosctl config info -o yaml | yq -r -e '.endpoints[0]'`
nodes := `talosctl config info -o yaml | yq -e '.nodes | join (" ")'`

# Bootstrap a Talos & Kubernetes cluster end-to-end
[confirm]
cluster: talos kubernetes kubeconfig base apps

[private]
talos:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    for n in {{ nodes }}; do
      if ! op=$(just --yes talos apply-node "$n" --insecure 2>&1); then
        if [[ "$op" == *"certificate required"* ]]; then
          just log info "Talos already configured, skipping apply of config" "stage" "{{ recipe_name() }}" "node" "$n"
          continue
        fi
        just log fatal "Failed to apply Talos configuration" "stage" "{{ recipe_name() }}" "node" "$n" "output" "$op"
      fi
    done

[private]
kubernetes:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    until op=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do
      just log info "Kubernetes bootstrap in progress. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}"
      sleep 5
    done

[private]
kubeconfig:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! talosctl kubeconfig -n "{{ controller }}" -f --force-context-name ops {{ justfile_dir() }}; then
      just log fatal "Failed to fetch kubeconfig" "stage" "{{ recipe_name() }}"
    fi

[private]
base: api-ready nodes-ready
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    just template "{{ source_directory() }}/resources.yaml.j2" | kubectl apply --server-side -f -
    if ! just template "{{ source_directory() }}/resources.yaml.j2" | kubectl apply --server-side --force-conflicts -f -; then
       just log fatal "Failed to apply manifests" "stage" "{{ recipe_name() }}"
    fi
    if ! helmfile -f "{{ source_directory() }}/helmfile/crds.yaml" template -q | yq ea -r -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply base crds" "stage" "{{ recipe_name() }}"
    fi

[private]
apps:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! helmfile -f "{{ source_directory() }}/helmfile/apps.yaml" sync --hide-notes; then
        just log fatal "Failed to sync helmfile" "stage" "{{ recipe_name() }}"
    fi

# Wait until every apiserver answers /readyz. Helm and kubectl calls after this stage are not retried.
[private]
api-ready:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    for n in {{ nodes }}; do
        until [[ "$(curl -ks -o /dev/null -w '%{http_code}' --connect-timeout 2 "https://${n}:6443/readyz")" == "200" ]]; do
            just log info "Waiting for kube-apiserver. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}" "node" "$n"
            sleep 5
        done
    done

# Wait until every node registers as Ready=False. They only become Ready=True once the CNI is healthy.
[private]
nodes-ready:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
            just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}"
            sleep 5
        done
    fi

# Regenerate the talosconfig file in case it's expired or missing
[confirm]
talosconfig:
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    op read 'op://cluster/talos/machine_ca_crt' | base64 -d > "$tmp/ca.crt"
    op read 'op://cluster/talos/machine_ca_key' | base64 -d > "$tmp/ca.key"

    (
      cd "$tmp"
      talosctl gen key --name admin
      talosctl gen csr --key admin.key --ip 127.0.0.1
      talosctl gen crt --ca ca --csr admin.csr --name admin --hours 8760
    )

    endpoints="$(find "{{ justfile_dir() }}/kubernetes/talos/nodes/controlplane" -name '*.yaml.j2' -printf '%f\n' | sed 's/\.yaml\.j2$//' | jq -Rsc 'split("\n")[:-1]')"
    nodes="$(find "{{ justfile_dir() }}/kubernetes/talos/nodes" -name '*.yaml.j2' -printf '%f\n' | sed 's/\.yaml\.j2$//' | sort | jq -Rsc 'split("\n")[:-1]')"

    CA="$(base64 -w0 "$tmp/ca.crt")" \
    CRT="$(base64 -w0 "$tmp/admin.crt")" \
    KEY="$(base64 -w0 "$tmp/admin.key")" \
    ENDPOINTS="$endpoints" \
    NODES="$nodes" \
    yq -n '
      {
        "context": "main",
        "contexts": {
          "main": {
            "endpoints": env(ENDPOINTS),
            "nodes": env(NODES),
            "ca": strenv(CA),
            "crt": strenv(CRT),
            "key": strenv(KEY)
          }
        }
      }
    ' > "$TALOSCONFIG"

    chmod 600 "$TALOSCONFIG"
