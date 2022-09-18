terraform {
  cloud {
    organization = "yachthafen"

    workspaces {
      name = "vyos"
    }
  }

  required_providers {
    vyos = {
      source  = "foltik/vyos"
      version = "0.3.3"
    }

    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
}

provider "vyos" {
  url = "https://192.168.178.2"
  key = local.secrets.api.key
}

data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}

locals {
  config  = yamldecode(file("configuration.yaml"))
  secrets = sensitive(yamldecode(nonsensitive(data.sops_file.secrets.raw)))
}

module "config" {
  source = "./config"

  config  = local.config
  secrets = local.secrets
}
