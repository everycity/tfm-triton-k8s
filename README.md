# terraform-triton-k8s
Terraform code for spinning up k8s on Triton. Creates:

- 1 x 4GB Master Node with 1 disk
- 3 x 8GB Worker Nodes with 2 disks each (2nd disks for Rook)

It installs:

- Ubuntu 18.04 with the 5.3 HWE Kernel (to avoid CephFS crashes)
- Docker as the CRI
- Calico as the CNI
- MetalLB for Load Balancing
- Rook, with CephFS as a storage backend
- Helm v3 under /usr/local/bin
- kubetail under /usr/local/bin
- Kubernetes Dashboard
- Weaveworks Kured for automatic cluster reboots post-os-updates

## Setup Instructions

1. Terraform does most of the work. You need Terraform 0.11 for Triton, 0.12 isn't supported yet. Run "terraform apply"
1. You can customise the versions of the software installed by editing versions.auto.tfvars
1. You'll need to supply project_name and metallb_range variables, Terraform will ask for these. For the MetalLB range, ask IT Support.
1. The setup procedure involves performing updates, and doing a reboot, and continuing setup. So setup takes some time - be patient and check /var/log/cloud-init-output.log to see progress
1. After setup is complete, cat /root/kubernetes-init.log on the master node to obtain the worker kubeadm join command. Run this in sequence on the 3 worker nodes.
1. Once "kubectl get nodes -o wide" shows all nodes as "Ready", you can set up Rook by running "/root/setup-rook.sh"
1. You can follow the Rook setup with "watch kubectl get pods --namespace=rook-ceph"
1. Lastly, for MetalLB to work, you'll need to enable IP Spoofing on the interfaces within Triton. Ask IT support for help with this.

## Rook

### Overview
Rook has been chosen to provide Persistent Volume Claim support. The Cloud Config file (which can be customised) by default applies the CephFS StorageClass. This provides clustered storage and supports RWO and RWX claims.

It may be worth running a mix of Ceph RBD (RADOS Block Device) for RWO and CephFS for RWX for performance reasons but this hasn't been investigated fully.

### Ceph Toolbox

The Ceph toolbox is quite useful, please see:

https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md

There is a bash function to call out to the Ceph toolbox POD, so "ceph status" will work from the master node.

