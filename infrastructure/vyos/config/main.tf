terraform {
  required_providers {
    vyos = {
      source  = "foltik/vyos"
      version = "0.3.3"
    }
  }
}

variable "config" {
}

variable "secrets" {
}
