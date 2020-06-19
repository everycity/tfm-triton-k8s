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
  #account  = ""
  #key_id   = ""
  #url	   = ""
  #key_material = var.triton_ssh_private_key
}

