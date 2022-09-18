terraform import -allow-missing-config module.config.vyos_config_block_tree.interface-modem "interfaces ethernet eth1"
terraform import -allow-missing-config module.config.vyos_config_block_tree.service-https "service https"

terraform import -allow-missing-config module.config.vyos_config_block_tree.system-conntrack "system conntrack"
terraform import -allow-missing-config module.config.vyos_config_block_tree.system-console "system console"
terraform import -allow-missing-config module.config.vyos_config.system-host_name "system host-name"
terraform import -allow-missing-config module.config.vyos_config_block_tree.system-ntp "system ntp"
