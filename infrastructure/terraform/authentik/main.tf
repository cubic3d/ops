terraform {
    cloud {
    organization = "yachthafen"

    workspaces {
      name = "authentik"
    }
  }

  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2024.6.1"
    }
    sops = {
      source = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

provider "authentik" {
  url   = local.secrets.url
  token = local.secrets.token
}

data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}

locals {
  secrets = sensitive(yamldecode(nonsensitive(data.sops_file.secrets.raw)))
}
