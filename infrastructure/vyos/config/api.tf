resource "vyos_config_block_tree" "service-https" {
  path = "service https"

  configs = {
    "api keys id tf key" = var.secrets.api.key
  }
}
