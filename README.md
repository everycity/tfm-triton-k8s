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

## Notes

- Versions for Kubernetes, Calico, Rook, Ceph, etc, can be found in versions.auto.tfvars - you may wish to adjust these.
- This installs Kubernetes on the hosts, but you'll need to join the workers to the master. Check /root/kubernetes-init.log after install on the master for the command to run to do this.
- MetalLB will require you to enable IP Spoofing on the interfaces within Triton to work properly.
- Triton Cloud Firewall isn't enabled on the instances. A basic firewall.tf has been included, but may need more work to function correctly.

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

