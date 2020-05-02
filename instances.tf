# Kubernetes master
resource "triton_machine" "k8s-master" {
  name        = "k8s-${var.project_name}-master"
  package     = "g1-virtualmachine-bhyve-4G"
  image       = "${data.triton_image.ubuntu-1804.id}"
  networks    = ["${data.triton_network.external.id}","${data.triton_network.internal.id}"]

  firewall_enabled = true

  tags {
    role = "k8s-${var.project_name}"
  }

  affinity = ["role!=k8s-${var.project_name}"]

  cloud_config = "${data.template_file.cc-k8s-master.rendered}"

  lifecycle {
    ignore_changes = [
      "cloud_config"
    ]
  }
}

# Kubernetes workers
resource "triton_machine" "k8s-worker" {
  count       = 3
  name        = "k8s-${var.project_name}-worker${format("%d", count.index+1)}"
  package     = "g2-virtualmachine-bhyve-8G"
  image       = "${data.triton_image.ubuntu-1804.id}"
  networks    = ["${data.triton_network.external.id}","${data.triton_network.internal.id}"]

  firewall_enabled = true

  tags {
    role = "k8s-${var.project_name}"
  }

  affinity = ["role!=k8s-${var.project_name}"]

  cloud_config = "${data.template_file.cc-k8s-worker.rendered}"
}

