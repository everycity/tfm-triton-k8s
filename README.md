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
1. You need a project name (e.g. test), and a MetalLB IP range (ask your network admin for this)
1. Run terraform apply, and it will create 1 master node and 3 worker nodes
1. The setup procedure involves performing updates, and doing a reboot, and continuing setup. So setup takes some time - be patient and check /var/log/cloud-init-output.log to see progress
1. After setup is complete, cat /root/kubernetes-init.log on the master node to obtain the worker kubeadm join command. Run this in sequence on the 3 worker nodes.
1. Once "kubectl get nodes -o wide" shows all nodes as "Ready", you can set up Rook by running "/root/setup-rook.sh"

## Notes

- Versions for Kubernetes, Calico, Rook, Ceph, etc, can be found in versions.auto.tfvars - you may wish to adjust these.
- This installs Kubernetes on the hosts, but you'll need to join the workers to the master. Check /root/kubernetes-init.log after install on the master for the command to run to do this.
- MetalLB will require you to enable IP Spoofing on the interfaces within Triton to work properly.
- It can take over 20 minutes for the cluster to stablise after being created (in particular for Rook and Ceph to do its thing) - be patient and check "kubectl get pods --all-namespaces"

## MetalLB

It is necessary for you to supply MetalLB with a ConfigMap. A default one has been supplied under /root/metallb-conf.yml

Please edit this file supplying the IP range you wish to use (speak to your network administrator), and run:

```
kubectl apply -f /root/metallb-conf.yaml
```

You will also need to enable IP Spoofing on the Interfaces within Triton for these IPs to work as Triton will filter out any traffic from unknown IP addresses as a security precaution.

## Rook

### Overview
Rook has been chosen to provide Persistent Volume Claim support. The Cloud Config file (which can be customised) by default applies the CephFS StorageClass. This provides clustered storage and supports RWO and RWX claims.

It may be worth running a mix of Ceph RBD (RADOS Block Device) for RWO and CephFS for RWX for performance reasons but this hasn't been investigated fully.

### Ceph Toolbox

The Ceph toolbox is quite useful, please see:

https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md

