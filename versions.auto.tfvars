# Welcome to your Cloud Native dystopia, where versions change daily
#
# For information on the below releases, please see:
# 
# - https://github.com/kubernetes/kubernetes/releases
# - https://github.com/projectcalico/calico/releases (note, drop the minor minor, e.g. 3.13 not 3.13.3)
# - https://github.com/metallb/metallb/releases
# - https://github.com/rook/rook/releases
# - https://hub.docker.com/r/ceph/ceph/tags
# - https://github.com/weaveworks/kured/releases
# - https://github.com/kubernetes/dashboard/releases
# - https://github.com/helm/helm/releases

# Bleeding edge choices, i.e. highest minor and highest major, as of 2020-11-06
kubernetes_version = "1.19.3"
calico_version = "3.16"
metallb_version = "0.9.4"
rook_version = "1.4.7"
ceph_version = "15.2.5"
kured_version = "1.5.0"
dashboard_version = "2.0.4"
helm_version = "3.4.0"

# Conservative choices, i.e. highest minor of previous major, as of 2020-11-06
#kubernetes_version = "1.18.10"
#calico_version = "3.15"
#metallb_version = "0.8.3"
#rook_version = "1.3.11"
#ceph_version = "14.2.13"
#kured_version = "1.4.5"
#dashboard_version = "2.0.3"
#helm_version = "3.3.4"
