# SSH Rules
resource "triton_firewall_rule" "ssh_in" {
  description = "Allow SSH from VPN"
  rule        = "FROM (ip 91.194.74.23 OR ip 95.131.252.106) TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW tcp PORT 22"
  enabled     = true
}

# Allow intercluster comms TCP
resource "triton_firewall_rule" "tcp" {
  description = "Allow communication between k8s hosts - tcp"
  rule        = "FROM tag \"k8s-cluster\" = \"${var.dns_suffix}\" TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW tcp PORT all"
  enabled     = true
}

# Allow intercluster comms UDP
resource "triton_firewall_rule" "udp" {
  description = "Allow communication between k8s hosts - udp"
  rule        = "FROM tag \"k8s-cluster\" = \"${var.dns_suffix}\" TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW udp PORT all"
  enabled     = true
}

# Allow Calico L3 routed traffic ICMP
resource "triton_firewall_rule" "calico-icmp" {
  description = "Allow communication between k8s hosts - calico icmp"
  rule        = "FROM subnet 192.168.0.0/16 TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW icmp TYPE all"
  enabled     = true
}

# Allow Calico L3 routed traffic TCP
resource "triton_firewall_rule" "calico-tcp" {
  description = "Allow communication between k8s hosts - calico tcp"
  rule        = "FROM subnet 192.168.0.0/16 TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW tcp PORT all"
  enabled     = true
}

# Allow Calico L3 routed traffic UDP
resource "triton_firewall_rule" "calico-udp" {
  description = "Allow communication between k8s hosts - calico udp"
  rule        = "FROM subnet 192.168.0.0/16 TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW udp PORT all"
  enabled     = true
}

# Allow Calico L3 routed traffic ICMP
resource "triton_firewall_rule" "calico2-icmp" {
  description = "Allow communication between k8s hosts - calico icmp"
  rule        = "FROM subnet ${var.internal_range} TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW icmp TYPE all"
  enabled     = true
}

# Allow Calico L3 routed traffic TCP
resource "triton_firewall_rule" "calico2-tcp" {
  description = "Allow communication between k8s hosts - calico tcp"
  rule        = "FROM subnet ${var.internal_range} TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW tcp PORT all"
  enabled     = true
}

# Allow Calico L3 routed traffic UDP
resource "triton_firewall_rule" "calico2-udp" {
  description = "Allow communication between k8s hosts - calico udp"
  rule        = "FROM subnet ${var.internal_range} TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW udp PORT all"
  enabled     = true
}

# Allow port 80
resource "triton_firewall_rule" "http_in" {
  description = "Allow web in"
  rule        = "FROM any TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW tcp PORT 80"
  enabled     = true
}

# Allow port 443
resource "triton_firewall_rule" "https_in" {
  description = "Allow web in"
  rule        = "FROM any TO tag \"k8s-cluster\" = \"${var.dns_suffix}\" ALLOW tcp PORT 443"
  enabled     = true
}
