data "template_file" "cc-k8s-master" {
    template = "${path.module}/g2-ubuntu18-k8s-master.tpl"
    vars = {
      kubernetes_version = "${var.kubernetes_version}"
      calico_version = "${var.calico_version}"
      metallb_version = "${var.metallb_version}"
      rook_version = "${var.rook_version}"
      ceph_version = "${var.ceph_version}"
      kured_version = "${var.kured_version}"
      dashboard_version = "${var.dashboard_version}"
      helm_version = "${var.helm_version}"
    }
}

data "template_file" "cc-k8s-worker" {
    template = "${path.module}/g2-ubuntu18-k8s-worker.tpl"
    vars = {
      kubernetes_version = "${var.kubernetes_version}"
      calico_version = "${var.calico_version}"
      metallb_version = "${var.metallb_version}"
      rook_version = "${var.rook_version}"
      ceph_version = "${var.ceph_version}"
      kured_version = "${var.kured_version}"
      dashboard_version = "${var.dashboard_version}"
      helm_version = "${var.helm_version}"
    }
}
