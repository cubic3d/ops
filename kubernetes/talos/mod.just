set default-list
set default-script
set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

# Apply Talos machine configuration to a given node
[confirm]
apply-node node *args:
    just log info "Applying Talos configuration to node {{ node }}"
    just talos render-config "{{ node }}" | talosctl -n "{{ node }}" apply-config -f /dev/stdin {{ args }}

# Apply Talos machine configuration to all nodes in the cluster
[confirm]
apply-cluster *args:
    kubectl get nodes --no-headers | while read -r node _; do
      just talos apply-node ${node} {{ args }}
    done

# Render Talos machine configuration for a given node
render-config node:
    export SCHEMATIC="$(just talos schematic-id)"
    role="controlplane"
    if [[ -f "{{ source_directory() }}/nodes/worker/{{ node }}.yaml.j2" ]]; then
        role="worker"
    fi
    talosctl machineconfig patch <(just template "{{ source_directory() }}/cluster.yaml.j2" -D "schematic=${SCHEMATIC}") \
        -p @<(just template "{{ source_directory() }}/${role}.yaml.j2") \
        -p @<(just template "{{ source_directory() }}/nodes/${role}/{{ node }}.yaml.j2")

# Validate rendered configuration for a given node
validate-config node:
    just talos render-config "{{ node }}" | talosctl validate --config /dev/stdin --mode metal --strict

# Reset a node
[confirm]
reset-node node *args:
    talosctl -n "{{ node }}" reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --graceful=false {{ args }}

# Shutdown a node
[confirm]
shutdown-node node *args:
    talosctl -n "{{ node }}" shutdown --force {{ args }}

# Upgrade Kubernetes version on the cluster
[confirm]
upgrade-k8s version:
    talosctl -n "$(talosctl config info -o yaml | yq -r -e '.endpoints[0]')" upgrade-k8s --to {{ version }}

# Upgrade Talos version on a node
[confirm]
upgrade-node node *args:
    talosctl -n "{{ node }}" upgrade -i "$(just talos machine-image "{{ node }}")" -m powercycle --timeout=10m {{ args }}

# Download Talos machine image
download-image version node="":
    export SCHEMATIC="$(just talos schematic-id "{{ node }}")"
    curl -fL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar \
        -o "{{ source_directory() }}/talos-{{ version }}-${SCHEMATIC:0:8}.iso" \
        "https://factory.talos.dev/image/${SCHEMATIC}/{{ version }}/metal-amd64.iso"
    just log info "Downloaded Talos" version "{{ version }}" schematic "${SCHEMATIC}"

# Get the schematic file for a given node
[private]
schematic-file node="":
    file="{{ source_directory() }}/schematic.yaml.j2"
    if [[ -n "{{ node }}" ]]; then
        for f in "{{ source_directory() }}"/nodes/*/"{{ node }}".schematic.yaml.j2; do
            [[ -f "$f" ]] && file="$f"
        done
    fi
    echo "$file"

# Get the schematic ID for a given node
[private]
schematic-id node="":
    curl -sX POST --data-binary @<(just template "$(just talos schematic-file "{{ node }}")") "https://factory.talos.dev/schematics" | jq -r '.id'

# Get the Talos machine image for a given node
[private]
machine-image node="":
    export NODE="{{ node }}"
    if [[ -z "${NODE}" ]]; then
        NODE="$(talosctl config info -o yaml | yq -r -e '.nodes[0]')"
    fi
    just talos render-config "${NODE}"  | yq -r -e 'select(.kind == "UnattendedInstallConfig") | .installer.image'
