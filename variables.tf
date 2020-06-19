# Cluster DNS Suffix. Used to uniquely identify this cluster, and
# to generate instance aliases. e.g. k8s.clientname.cloud.ec
variable "dns_suffix" {
  type = string
}

# MetalLB needs to know the IP range it can use - takes the format:
# x.x.x.x-y.y.y.y, e.g. 1.1.2.2-1.1.3.3
variable "metallb_range" {
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
variable "image" {
  type = string
  default = "ubuntu-certified-18.04"

# Master node instance package type. E.g. g1-virtualmachine-bhyve-4G
variable "master_package" {
  type = string
  default = "g1-virtualmachine-bhyve-4G"
}

# Worker node instance package. E.g. g2-virtualmachine-bhyve-8G
variable "worker_package" {
  type = string
  default = "g2-virtualmachine-bhyve-8G"
}

# Worker node instance count
variable "worker_count" {
  type = number
  default = 3
}

# For use with the Terraform Cloud
variable "triton_ssh_private_key" {
  type = string
  default = ""
}

###
## Cluster software versions. Check versions.auto.tfvars for defaults.
###
variable "kubernetes_version" {
  type = string
}

variable "calico_version" {
  type = string
}

variable "metallb_version" {
  type = string
}

variable "rook_version" {
  type = string
}

variable "ceph_version" {
  type = string
}

variable "kured_version" {
  type = string
}

variable "dashboard_version" {
  type = string
}

variable "helm_version" {
  type = string
}

