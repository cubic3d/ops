resource "vyos_config_block" "ssh-keys" {
  for_each = var.config.ssh.keys
  path     = "system login user vyos authentication public-keys ${each.key}"

  configs = {
    "type" = each.value.type
    "key"  = each.value.key
  }
}

resource "vyos_config_block" "ssh-config" {
  path = "service ssh"

  configs = {
    "disable-host-validation"         = ""
    "disable-password-authentication" = ""
  }
}
