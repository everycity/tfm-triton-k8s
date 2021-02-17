resource "triton_machine" "db02" {
  name        = "db02.${var.dns_suffix}"
  package     = var.instance_package
  image       = data.triton_image.image.id
  networks    = [data.triton_network.external.id,data.triton_network.internal.id]

  # Magtia use iptables
  firewall_enabled = false

  tags {
    terraform_managed = "true"
    krystal_managed = "true"
  }

  cloud_config = data.template_file.cloud-config.rendered

  lifecycle {
    ignore_changes = [
      cloud_config
    ]
  }
}

