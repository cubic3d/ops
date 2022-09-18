resource "vyos_config" "system-host_name" {
  key   = "system host-name"
  value = "gw"
}

resource "vyos_config_block_tree" "system-ntp" {
  path = "system ntp"

  configs = {
    "server time.cloudflare.com" = ""
    "server time.google.com"     = ""
  }
}

resource "vyos_config" "system-login-banner" {
  key   = "system login banner post-login"
  value = "This system is managed in https://github.com/cubic3d/ops"
}
