data "template_file" "cc-k8s-master" {
    template = "${path.module}/g2-ubuntu18-k8s-master.tpl"
    vars = {
      kubernetes_version = "${var.kubernetes_version}"
      rook_version = "${var.rook_version}"
    }
}

data "template_file" "cc-k8s-worker" {
    filename = "${path.module}/g2-ubuntu18-k8s-worker.tpl"
}
