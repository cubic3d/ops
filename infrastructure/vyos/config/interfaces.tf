resource "vyos_config_block_tree" "interface-modem" {
  path = "interfaces ethernet eth1"

  configs = {
    "address"     = "192.168.178.2/24"
    "description" = "Modem"
  }
}
