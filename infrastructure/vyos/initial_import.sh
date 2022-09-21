# Workaround for initial state that is required to configure the VyOS provider
terraform apply -refresh-only -target data.sops_file.secrets

# Import manually created resources to bootstrap API
terraform import -allow-missing-config module.config.vyos_config_block_tree.interface-modem "interfaces ethernet eth1"
terraform import -allow-missing-config module.config.vyos_config_block_tree.api "service https"

# Import defaults that needs to be removed or changed
terraform import -allow-missing-config module.config.vyos_config_block_tree.system-conntrack "system conntrack"
terraform import -allow-missing-config module.config.vyos_config_block_tree.system-console "system console"
terraform import -allow-missing-config module.config.vyos_config.system-host_name "system host-name"
terraform import -allow-missing-config module.config.vyos_config_block_tree.system-ntp "system ntp"
