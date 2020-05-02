# SSH Rules
resource "triton_firewall_rule" "ssh_in" {
  description = "Allow SSH from VPN"
  rule        = "FROM (ip 91.194.74.23 OR ip 95.131.252.106) TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW tcp PORT 22"
  enabled     = true
}

# Allow intercluster comms TCP
resource "triton_firewall_rule" "k8s-tcp" {
  description = "Allow communication between k8s hosts - tcp"
  rule        = "FROM tag \"role\" = \"k8s-${var.project_name}\" TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW tcp PORT all"
  enabled     = true
}

# Allow intercluster comms UDP
resource "triton_firewall_rule" "k8s-udp" {
  description = "Allow communication between k8s hosts - udp"
  rule        = "FROM tag \"role\" = \"k8s-${var.project_name}\" TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW udp PORT all"
  enabled     = true
}

# Allow Calico L3 routed traffic TCP
resource "triton_firewall_rule" "k8s-calico-tcp" {
  description = "Allow communication between k8s hosts - calico tcp"
  rule        = "FROM subnet 10.28.0.0/24 TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW tcp PORT all"
  enabled     = true
}

# Allow Calico L3 routed traffic UDP
resource "triton_firewall_rule" "k8s-calico-udp" {
  description = "Allow communication between k8s hosts - calico udp"
  rule        = "FROM subnet 10.28.0.0/24 TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW udp PORT all"
  enabled     = true
}

# Allow port 80
resource "triton_firewall_rule" "http_in" {
  description = "Allow web in"
  rule        = "FROM any TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW tcp PORT 80"
  enabled     = true
}

# Allow port 443
resource "triton_firewall_rule" "https_in" {
  description = "Allow web in"
  rule        = "FROM any TO tag \"role\" = \"k8s-${var.project_name}\" ALLOW tcp PORT 443"
  enabled     = true
}
