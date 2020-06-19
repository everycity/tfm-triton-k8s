data "triton_image" "image" {
  name        = var.image
  type        = "zvol"
  most_recent = true
}

