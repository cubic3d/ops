resource "vyos_config_block_tree" "dhcp-server-lan" {
  path = "service dhcp-server shared-network-name lan"
  configs = {
    "authoritative"                             = ""
    "description"                               = "LAN"
    "subnet 192.168.0.0/24 default-router"      = "192.168.0.1"
    "subnet 192.168.0.0/24 name-server"         = "192.168.0.1"
    "subnet 192.168.0.0/24 domain-name"         = "h.${var.secrets.domain}"
    "subnet 192.168.0.0/24 range default start" = "192.168.0.100"
    "subnet 192.168.0.0/24 range default stop"  = "192.168.0.254"
  }
}
