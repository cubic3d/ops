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

resource "vyos_config" "system-keyboard_layout" {
  key   = "system option keyboard-layout"
  value = "de"
}

resource "vyos_config" "system-time_zone" {
  key   = "system time-zone"
  value = "Europe/Berlin"
}

resource "vyos_config" "system-lldp" {
  key   = "service lldp"
  value = ""
}

resource "vyos_config_block" "system-name_server" {
  path = "system name-server"

  configs = {
    "1.1.1.1"              = ""
    "1.0.0.1"              = ""
    "2606:4700:4700::1111" = ""
    "2606:4700:4700::1001" = ""
  }
}

resource "vyos_config" "system-domain" {
  key   = "system domain-name"
  value = "h.${var.secrets.domain}"
}
