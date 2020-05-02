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

# Bleeding edge choices, i.e. highest minor and highest major, as of 2020-05-02
kubernetes_version = "1.18.2"
calico_version = "3.13"
metallb_version = "0.9.3"
rook_version = "1.3.2"
ceph_version = "15.2.1"
kured_version = "1.4.0"
dashboard_version = "2.0.0"
helm_version = "3.2.0"

# Conservative choices, i.e. highest minor of previous major, as of 2020-05-02
#kubernetes_version = "1.17.5"
#calico_version = "3.8"
#metallb_version = "0.8.3"
#rook_version = "1.2.7"
#ceph_version = "14.2.9"
#kured_version = "1.4.0"
#dashboard_version = "2.0.0"
#helm_version = "3.1.3"
