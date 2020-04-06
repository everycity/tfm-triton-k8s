data "triton_image" "ubuntu-1804" {
  name        = "ubuntu-certified-18.04"
  type        = "zvol"
  most_recent = true
}

