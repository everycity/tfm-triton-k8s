data "local_file" "cc-k8s-master" {
    filename = "${path.module}/g2-ubuntu18-k8s-master.txt"
}

data "local_file" "cc-k8s-worker" {
    filename = "${path.module}/g2-ubuntu18-k8s-worker.txt"
}
