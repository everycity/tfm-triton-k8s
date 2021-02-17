data "template_file" "cloud-config" {
    template = file("${path.module}/g1-centos7-magtia.tpl")
}
