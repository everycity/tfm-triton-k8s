data "template_file" "cc-k8s-master" {
    template = file("${path.module}/g2-ubuntu2004-k8s-master.tpl")
    vars = {
      dns_suffix = var.dns_suffix
      metallb_range = var.metallb_range
      kubernetes_version = var.kubernetes_version
      calico_version = var.calico_version
      metallb_version = var.metallb_version
      rook_version = var.rook_version
      ceph_version = var.ceph_version
      kured_version = var.kured_version
      dashboard_version = var.dashboard_version
      helm_version = var.helm_version
    }
}

data "template_file" "cc-k8s-worker" {
    count = var.worker_count
    template = file("${path.module}/g2-ubuntu2004-k8s-worker.tpl")
    vars = {
      hostname = "worker${format("%d", count.index+1)}"
      dns_suffix = var.dns_suffix
      metallb_range = var.metallb_range
      kubernetes_version = var.kubernetes_version
      calico_version = var.calico_version
      metallb_version = var.metallb_version
      rook_version = var.rook_version
      ceph_version = var.ceph_version
      kured_version = var.kured_version
      dashboard_version = var.dashboard_version
      helm_version = var.helm_version
    }
}
