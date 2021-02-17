# Cluster DNS Suffix. Used to uniquely identify this cluster, and
# to generate instance aliases. e.g. k8s.clientname.cloud.ec
variable "dns_suffix" {
  type = string
}

# External network name. E.g. "public"
variable "external_network" {
  type = string
}

# Internal network name. E.g. "vlan1234"
variable "internal_network" {
  type = string
}

# Instance image name. E.g. ubuntu-certified-18.04
variable "instance_image" {
  type = string
  default = "ubuntu-certified-18.04"
}

# Instance package type. E.g. g1-virtualmachine-bhyve-4G
variable "instance_package" {
  type = string
  default = "g1-virtualmachine-bhyve-4G"
}

# For use with the Terraform Cloud
variable "triton_ssh_private_key" {
  type = string
  default = ""
}

