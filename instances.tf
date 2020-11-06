# Kubernetes master
resource "triton_machine" "k8s-master" {
  name        = "master.${var.dns_suffix}"
  package     = var.master_package
  image       = data.triton_image.image.id
  networks    = [data.triton_network.external.id,data.triton_network.internal.id]

  firewall_enabled = true

  tags = {
    k8s-cluster = var.dns_suffix
  }

  affinity = ["k8s-cluster!=${var.dns_suffix}"]

  cloud_config = data.template_file.cc-k8s-master.rendered

  lifecycle {
    ignore_changes = [
      image,
      cloud_config
    ]
  }
}

output "master_hostname" { value = triton_machine.k8s-master.name }
output "master_ips" {  value = triton_machine.k8s-master.ips }

# Kubernetes workers
resource "triton_machine" "k8s-worker" {
  count       = var.worker_count
  name        = "worker${format("%d", count.index+1)}.${var.dns_suffix}"
  package     = var.worker_package
  image       = data.triton_image.image.id
  networks    = [data.triton_network.external.id,data.triton_network.internal.id]

  firewall_enabled = true

  tags = {
    k8s-cluster = var.dns_suffix
  }

  affinity = ["k8s-cluster!=${var.dns_suffix}"]

  cloud_config = data.template_file.cc-k8s-worker.*.rendered[count.index]

  lifecycle {
    ignore_changes = [
      image,
      cloud_config
    ]
  }
}

output "worker_ips" {
  value = {
    for worker in triton_machine.k8s-worker:
      worker.name => worker.ips
  }
}
