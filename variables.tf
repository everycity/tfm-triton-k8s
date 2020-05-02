# Since we could have multiple k8s environments per Triton account, we need
# a way of differentiating them
variable "project_name" {
  type = "string"
}

###
## Versions Of Stuff
###
variable "kubernetes_version" {
  type = "string"
}

variable "calico_version" {
  type = "string"
}

variable "metallb_version" {
  type = "string"
}

variable "rook_version" {
  type = "string"
}

variable "ceph_version" {
  type = "string"
}

variable "kured_version" {
  type = "string"
}

variable "dashboard_version" {
  type = "string"
}

variable "helm_version" {
  type = "string"
}

