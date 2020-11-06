terraform {
  required_version = "> 0.12.20"

## Terraform Cloud Config
#  backend "remote" {
#    hostname = "app.terraform.io"
#    organization = ""
#
#    workspaces {
#      name = ""
#    }
#  }
}

provider "triton" {
  version = "~> 0.8"
  insecure_skip_tls_verify = false
  #account  = ""
  #key_id   = ""
  #url	   = ""
  #key_material = var.triton_ssh_private_key
}

provider "template" {
  version = "~> 2.2"
}
