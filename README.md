# terraform-triton-k8s
Terraform code for spinning up k8s on Triton. Creates:

- 1 x 4GB Master Node with 1 disk
- 3 x 8GB Worker Nodes with 2 disks each (2nd disks for Rook)

It installs:

- Ubuntu 20.04
- Docker as the CRI
- Calico as the CNI
- MetalLB for Load Balancing
- Rook, with CephFS as a storage backend
- Helm v3 under /usr/local/bin
- kubetail under /usr/local/bin
- Kubernetes Dashboard
- Weaveworks Kured for automatic cluster reboots post-os-updates

## Setup Instructions

1. You'll need to supply a set of variables specific to your environment. See variables.tf and the Variables section below for more information
1. You can customise the versions of the software installed by editing versions.auto.tfvars
1. Run "terraform init" to start initialisation, then "terraform plan" to preview the provisioning and then "terraform apply".
1. The setup procedure involves performing updates, and doing a reboot, and continuing setup. So setup takes some time - be patient and check /var/log/cloud-init-output.log to see progress
1. After setup is complete, cat /root/kubernetes-init.log on the master node to obtain the worker kubeadm join command

        kubeadm join 10.x.x.x:6443 --token sometoken --discovery-token-ca-cert-hash sha256:somecertkey

Run the extracted join command on the 3 worker nodes

1. **ESSENTIAL STEP** Before continuing you need to go into Triton's Admin UI and enable IP Spoofing, MAC Spoofing and Allow Restricted Traffic on both the internal and external interfaces for all 4 nodes. **Failure to complete this step will result in your cluster having network issues**
1. Once that's done, you can set up Rook by running "/root/setup-rook.sh" on the master node
1. You can follow the Rook setup with "watch kubectl get pods --namespace=rook-ceph" from the master node

## Variables

Variables must be specified unless there is a default.

| Variable               | Default                    | Description                                                                                                            |
|------------------------|----------------------------|------------------------------------------------------------------------------------------------------------------------|
| dns_suffix             |                            | Cluster DNS Suffix. Used to uniquely identify this cluster, and to generate instance aliases. E.g. k8s.client.cloud.ec |
| metallb_range          |                            | IP Range for MetalLB to use. Please speak to your network administrator. Takes the format x.x.x.x-y.y.y.y              |
| external_network       |                            | External network name. E.g. "public"                                                                                   |
| internal_network       |                            | Internal network name. E.g. "vlan1234"                                                                                 |
| image                  | ubuntu-20.04               | Instance image to provision with                                                                                       |
| master_package         | g1-virtualmachine-bhyve-4G | Master node instance package type                                                                                      |
| worker_package         | g2-virtualmachine-bhyve-8G | Worker node instance package type                                                                                      |
| worker_count           | 3                          | Worker node instance count                                                                                             |
| triton_ssh_private_key | ""                         | SSH Private Key used to authenticate with Triton, for use with Terraform Cloud                                         |

## Triton account details

You will need to edit main.tf and update the Triton provider authentication details.

If provisioning into your own account, you can obtain these via:

```
cat ~/.triton/profiles.d/*.json
```

## Terraform Cloud

If using this in the Terraform Cloud, you will need to edit main.tf and uncomment the backend block, and specify the organization and workspace name.

You'll also need to provide Triton key_material via the triton_ssh_private_key variable. This variable can be supplied securely within Terraform Cloud (don't use an environment variable, as these cannot contain newlines).

## Rook

### Overview
Rook has been chosen to provide Persistent Volume Claim support. The Cloud Config file (which can be customised) by default applies the CephFS StorageClass. This provides clustered storage and supports RWO and RWX claims.

### Ceph Toolbox

The Ceph toolbox is quite useful, please see:

https://github.com/rook/rook/blob/master/Documentation/ceph-toolbox.md

There is a bash function to call out to the Ceph toolbox POD, so "ceph status" will work from the master node.

## Troubleshooting

### Triton Provider Key ID and Account

During terraform plan or terraform apply, if you see the following error:

    data.template_file.cc-k8s-worker: Refreshing state...
    data.template_file.cc-k8s-master: Refreshing state...

    Error: Error refreshing state: 1 error occurred:
	    * provider.triton: 2 errors occurred:
	    * Key ID must be configured for the Triton provider
	    * Account must be configured for the Triton provider

...obtain your Triton profile details using the following command...

```
    cat ~/.triton/profiles.d/*.json
```

...and then update the following variables in main.tf...

```
    {
        "url": "",
        "account": "",
        "keyId": ""
    }
```
