set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir() + '/kubernetes'
talos_dir := kubernetes_dir + '/talos'
controller := `talosctl config info --output json | jq --raw-output '.endpoints[]' | shuf -n 1`

[private]
default:
    just -l talos

# Generate schematic ID from Talos schematic
gen-schematic-id:
    curl -sX POST --data-binary @<(just template "{{ talos_dir }}/schematic.yaml.j2") "https://factory.talos.dev/schematics" | jq -r '.id'
