# terraform-triton-k8s
Terraform code for spinning up k8s on Triton. Creates:

- 1 x 4GB Master Node with 1 disk
- 3 x 8GB Worker Nodes with 2 disks each

It installs:

- Docker as the CRI
- Calico as the CNI
- MetalLB for Load Balancing
- Rook, with Ceph and Cephfs for Storage
- Helm v3.0.2 under /usr/local/bin
- kubetail under /usr/local/bin

## Notes

- This installs Kubernetes on the hosts, but you'll need to join the workers to the master. Check /root/kubernetes-init.log after install on the master for the command to run to do this.
- MetalLB will require you to enable IP Spoofing on the interfaces within Triton to work properly.
- Triton Cloud Firewall isn't enabled on the instances. A basic firewall.tf has been included, but may need more work to function correctly.

## Rook

Rook has been chosen to provide Persistent Volume Claim support. The Cloud Config file (which can be customised) by default applies the CephFS StorageClass. This provides clustered storage and supports RWO and RWX claims.

It may be worth running a mix of Ceph RBD (RADOS Block Device) for RWO and CephFS for RWX for performance reasons but this hasn't been investigated fully.

Testing turning a worker node off did result in CephFS becoming globally unavailable - more investigation is needed to figure out why. A prelimary conversation on the Rook Slack went as follows:

Alasdair Lumsden  3:15 PM
- Hey there - I've set up a 4 node Kubernetes cluster (master + 3 workers), and set up Rook with cephfs using disks on the worker nodes. I've got the helm wordpress chart up and running, with an RWX PVC, and scaled up to 3 pods.
- If I halt one of the worker nodes, the storage locks up, and the wordpress site goes unavailable for approx 2m30-3m. The health checks also fail and kubernetes recreates the containers
- Is this type of behaviour expected in the case of failures?

travisn  7:42 PM
- @Alasdair Lumsden This doesn’t sound expected. The ceph pools have a “min_size” that should be one less than the number of replicas. So if you have replica size of 3, the default min_size for the pool should be 2. This means that it would be allowed to have one node down and only 2 OSDs would be required to be running in order for reads and writes to succeed.


