data "triton_image" "image" {
  name        = var.instance_image
  type        = "zvol"
  most_recent = true
}

