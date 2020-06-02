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

1. Terraform does most of the work. You need Terraform 0.11 for Triton, 0.12 isn't supported yet. Run "terraform init" to start initialisation, then "terraform plan" to preview the provisioning and then "terraform apply".
1. You can customise the versions of the software installed by editing versions.auto.tfvars
1. You'll need to supply project_name and metallb_range variables, Terraform will ask for these. For the MetalLB range, ask IT Support.
1. The setup procedure involves performing updates, and doing a reboot, and continuing setup. So setup takes some time - be patient and check /var/log/cloud-init-output.log to see progress
1. After setup is complete, cat /root/kubernetes-init.log on the master node to obtain the worker kubeadm join command. Run this in sequence on the 3 worker nodes.
1. **ESSENTIAL STEP** Before continuing you need to go into Triton's Admin UI and enable IP Spoofing, MAC Spoofing and Allow Restricted Traffic on both the internal and external interfaces for all 4 nodes. **Failure to complete this step will result in your cluster having network issues**
1. Once that's done, you can set up Rook by running "/root/setup-rook.sh"
1. You can follow the Rook setup with "watch kubectl get pods --namespace=rook-ceph"

## Rook

### Overview
Rook has been chosen to provide Persistent Volume Claim support. The Cloud Config file (which can be customised) by default applies the CephFS StorageClass. This provides clustered storage and supports RWO and RWX claims.

It may be worth running a mix of Ceph RBD (RADOS Block Device) for RWO and CephFS for RWX for performance reasons but this hasn't been investigated fully.

### Ceph Toolbox

The Ceph toolbox is quite useful, please see:

https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md

There is a bash function to call out to the Ceph toolbox POD, so "ceph status" will work from the master node.

## Troubleshooting

### Triton Provider Key ID and Account

During terraform plan or terraform apply, if you see the following error after entering your metallb_range and project_name...

    data.template_file.cc-k8s-worker: Refreshing state...
    data.template_file.cc-k8s-master: Refreshing state...

    Error: Error refreshing state: 1 error occurred:
	    * provider.triton: 2 errors occurred:
	    * Key ID must be configured for the Triton provider
	    * Account must be configured for the Triton provider

...obtain your Triton profile details using the following command...

    cat ~/.triton/profiles.d/eu-staff-1.json

...and then update the following variables in main.tf...

    {
        "url": "",
        "account": "",
        "keyId": ""
    }

### Internal Network vlan2800 error

During terraform plan or terraform apply, if you see the following error...

    data.triton_network.internal: Refreshing state...

    Error: Error refreshing state: 1 error occurred:
	    * data.triton_network.internal: 1 error occurred:
	    * data.triton_network.internal: data.triton_network.internal: no matching Network with name "vlan2800" found
	
...check that you have a triton network attached using...

    triton networks

If this does not return a private LAN, contact IT Support. Otherwise, add your vLAN to networks.tf...

    name = "vlan2804"
