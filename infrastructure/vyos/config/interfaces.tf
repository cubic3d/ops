resource "vyos_config_block_tree" "interface-wan" {
  path = "interfaces ethernet eth0"

  configs = {
    "address"     = "dhcp"
    "description" = "WAN"
  }
}

resource "vyos_config_block_tree" "interface-modem" {
  path = "interfaces ethernet eth1"

  configs = {
    "address"     = "192.168.178.2/24"
    "description" = "Modem"
  }
}

resource "vyos_config_block_tree" "interface-lan" {
  path = "interfaces ethernet eth2"

  configs = {
    "address"     = "192.168.0.1/24"
    "description" = "Management"
  }
}
