data "triton_network" "external" {
  name = var.external_network
}

data "triton_network" "internal" {
  name = var.internal_network
}

