#cloud-config

# Useful links
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/

# Aggressively update
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Install needed packages
packages:
# Fix time on BHYVE
 - chrony

# Standard bits n bobs
 - apt-transport-https
 - ca-certificates
 - curl
 - gnupg-agent
 - software-properties-common
 - unattended-upgrades
 - unzip
 - whois
 - traceroute
 - mtr-tiny

# Docker as our CRI
 - docker-ce
 - docker-ce-cli
 - containerd.io

# Kubernetes
 - kubelet=${kubernetes_version}-00
 - kubeadm=${kubernetes_version}-00
 - kubectl=${kubernetes_version}-00

# Run commands and stuff
runcmd:

 # Fix hostname so x509 certificate matches server name
 - echo "master.${dns_suffix}" > /etc/hostname
 - hostname "master.${dns_suffix}"

 # Fix /etc/hosts so internal IP is used instead of the external IP
 # https://github.com/kubernetes/kubeadm/issues/1987
 - echo $(hostname -i | xargs -n1 | grep ^10.) $(hostname) >> /etc/hosts

 # Sort out kubernetes and docker
 - apt-mark hold kubelet kubeadm kubectl docker-ce docker-ce-cli containerd.io
 - mkdir -p /etc/systemd/system/docker.service.d
 - systemctl daemon-reload
 - systemctl restart docker

 # Initialise Kubernetes, specifying internal IPs for the cluster
 - kubeadm init --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint=$(hostname -i | xargs -n1 | grep ^10.) > /root/kubernetes-init.log 2>&1
 - mkdir -p $HOME/.kube
 - cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 - chown $(id -u):$(id -g) $HOME/.kube/config

 # Initialise calico networking
 - wget -q -O- https://docs.projectcalico.org/v${calico_version}/manifests/calico.yaml | sed 's/Always/Never/g' > /var/tmp/calico.yaml
 - kubectl apply -f /var/tmp/calico.yaml

 # Initialise metallb ingress
 - kubectl apply -f https://raw.githubusercontent.com/google/metallb/v${metallb_version}/manifests/namespace.yaml
 - kubectl apply -f https://raw.githubusercontent.com/google/metallb/v${metallb_version}/manifests/metallb.yaml
 - kubectl apply -f /var/tmp/metallb-conf.yaml
 - kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# This breaks Percona XtraDB cluster (PXC) and Rook Ceph - disable for now
# # Initialise Kured for automatic safe reboots of the cluster
# - wget -O /var/tmp/kured.yaml https://github.com/weaveworks/kured/releases/download/${kured_version}/kured-${kured_version}-dockerhub.yaml
# - echo "            - --reboot-days=sun" >> /tmp/kured.yaml
# - echo "            - --start-time=2am" >> /tmp/kured.yaml
# - echo "            - --end-time=8am" >> /tmp/kured.yaml
# - echo "            - --time-zone=Europe/London" >> /tmp/kured.yaml
# - kubectl apply -f /var/tmp/kured.yaml

 # Initialise the Kubernetes Dashboard
 - kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${dashboard_version}/aio/deploy/recommended.yaml
 - kubectl apply -f /var/tmp/dash-user.yaml
 - kubectl apply -f /var/tmp/dash-cb.yaml

 # Get helm
 - wget -O- -q https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz | tar -C /tmp/ -zxf-
 - mv /tmp/linux-amd64/helm /usr/local/bin/
 - /usr/local/bin/helm repo add stable https://charts.helm.sh/stable

 # Get kubetail
 - wget -q -O /usr/local/bin/kubetail https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
 - chmod 755 /usr/local/bin/kubetail

 # Deal with HOME not being set right
 - mv /.kube /root/

# Don't mount secondary disk
disk_setup:

fs_setup:

mounts:
 - [ vdb, null ]

# All kids love apt
apt:
  sources:
    kubernetes:
      source: "deb [arch=amd64] http://apt.kubernetes.io/ kubernetes-xenial main"
      key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        mQENBFrBaNsBCADrF18KCbsZlo4NjAvVecTBCnp6WcBQJ5oSh7+E98jX9YznUCrN
        rgmeCcCMUvTDRDxfTaDJybaHugfba43nqhkbNpJ47YXsIa+YL6eEE9emSmQtjrSW
        IiY+2YJYwsDgsgckF3duqkb02OdBQlh6IbHPoXB6H//b1PgZYsomB+841XW1LSJP
        YlYbIrWfwDfQvtkFQI90r6NknVTQlpqQh5GLNWNYqRNrGQPmsB+NrUYrkl1nUt1L
        RGu+rCe4bSaSmNbwKMQKkROE4kTiB72DPk7zH4Lm0uo0YFFWG4qsMIuqEihJ/9KN
        X8GYBr+tWgyLooLlsdK3l+4dVqd8cjkJM1ExABEBAAG0QEdvb2dsZSBDbG91ZCBQ
        YWNrYWdlcyBBdXRvbWF0aWMgU2lnbmluZyBLZXkgPGdjLXRlYW1AZ29vZ2xlLmNv
        bT6JAT4EEwECACgFAlrBaNsCGy8FCQWjmoAGCwkIBwMCBhUIAgkKCwQWAgMBAh4B
        AheAAAoJEGoDCyG6B/T78e8H/1WH2LN/nVNhm5TS1VYJG8B+IW8zS4BqyozxC9iJ
        AJqZIVHXl8g8a/Hus8RfXR7cnYHcg8sjSaJfQhqO9RbKnffiuQgGrqwQxuC2jBa6
        M/QKzejTeP0Mgi67pyrLJNWrFI71RhritQZmzTZ2PoWxfv6b+Tv5v0rPaG+ut1J4
        7pn+kYgtUaKdsJz1umi6HzK6AacDf0C0CksJdKG7MOWsZcB4xeOxJYuy6NuO6Kcd
        Ez8/XyEUjIuIOlhYTd0hH8E/SEBbXXft7/VBQC5wNq40izPi+6WFK/e1O42DIpzQ
        749ogYQ1eodexPNhLzekKR3XhGrNXJ95r5KO10VrsLFNd8I=
        =TKuP
        -----END PGP PUBLIC KEY BLOCK-----
    docker:
      source: "deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable"
      key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        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
        YT90qFF93M3v01BbxP+EIY2/9tiIPbrd
        =0YYh
        -----END PGP PUBLIC KEY BLOCK-----

# Disabling automatic updates as these are breaking PXC and Rook/Ceph
write_files:
  - path: /etc/apt/apt.conf.d/10periodic
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Download-Upgradeable-Packages "1";
      APT::Periodic::AutocleanInterval "7";
      APT::Periodic::Unattended-Upgrade "0";

#  - path: /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf
#    content: |
#      [Timer]
#      OnCalendar=
#      OnCalendar=*-*-* 2:00
#      RandomizedDelaySec=4h

  - path: /etc/apt/apt.conf.d/80everycity
    content: |
      Unattended-Upgrade::Automatic-Reboot "false";
  - path: /etc/docker/daemon.json
    content: |
      {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "100m"
        },
        "storage-driver": "overlay2"
      }
  - path: /var/tmp/k8s-init.in
    content: |
  - path: /var/tmp/metallb-conf.yaml
    content: |
      apiVersion: v1
      kind: ConfigMap
      metadata:
        namespace: metallb-system
        name: config
      data:
        config: |
          address-pools:
          - name: default
            protocol: layer2
            addresses:
            - ${metallb_range}
  - path: /var/tmp/rook-conf.yaml
    content: |
      apiVersion: ceph.rook.io/v1
      kind: CephCluster
      metadata:
        name: rook-ceph
        namespace: rook-ceph
      spec:
        cephVersion:
          # For the latest ceph images, see https://hub.docker.com/r/ceph/ceph/tags
          image: ceph/ceph:v${ceph_version}
        dataDirHostPath: /var/lib/rook
        mon:
          count: 3
        dashboard:
          enabled: true
        storage:
          useAllNodes: true
          useAllDevices: true
          deviceFilter: vdb
  - path: /var/tmp/dash-user.yaml
    content: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: admin-user
        namespace: kubernetes-dashboard
  - path: /var/tmp/dash-cb.yaml
    content: |
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRoleBinding
      metadata:
        name: admin-user
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: ClusterRole
        name: cluster-admin
      subjects:
      - kind: ServiceAccount
        name: admin-user
        namespace: kubernetes-dashboard
  - path: /root/.bash_aliases
    content: |
      # Lazy Human
      alias k="kubectl"
      
      # Enable tab completion
      source <(kubectl completion bash)
      complete -F __start_kubectl k
      
      # Ain't nobody got time for typin' all that
      ceph() {
        TOOLS_POD=$(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}')
        kubectl -n rook-ceph exec -it $TOOLS_POD -- ceph $@
      }
  - path: /root/setup-rook.sh
    permissions: '0755'
    content: |
      #!/bin/bash

      # Initialise rook storage
      wget -O /var/tmp/rook.zip https://github.com/rook/rook/archive/v${rook_version}.zip
      unzip /var/tmp/rook.zip -d /var/tmp
      kubectl create -f /var/tmp/rook-${rook_version}/cluster/examples/kubernetes/ceph/common.yaml
      kubectl create -f /var/tmp/rook-${rook_version}/cluster/examples/kubernetes/ceph/operator.yaml
      kubectl create -f /var/tmp/rook-conf.yaml
      kubectl create -f /var/tmp/rook-${rook_version}/cluster/examples/kubernetes/ceph/filesystem.yaml
      kubectl create -f /var/tmp/rook-${rook_version}/cluster/examples/kubernetes/ceph/csi/cephfs/storageclass.yaml
      kubectl create -f /var/tmp/rook-${rook_version}/cluster/examples/kubernetes/ceph/toolbox.yaml
      echo "Sleeping for 5 seconds then setting rook-cephfs as default storageclass"
      sleep 5
      kubectl patch storageclass rook-cephfs  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


users:
  - name: everycity
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDo3JRaBbWiQ6QE/GGdnIH+BGMYSmbYuHyoQ8E3rLTaE4sltrApT0fSP0/5vHt3ObE++/XkNMF626HguiTv9NgHh6ogw+781rwp58LYPJI7efWs+dxM4mMfPxo6vRJpBf/uLVX2sc2s2uWmn8v3beQ7RDrNbttEUsxJV53t/Vz9beRNIEwON1wkzqcJ1Buq0INz4vLKjaDMtuf16KLaQOsLQdhUMoCu2MtAUJiaaSlB474UL1NNC5nZ+MB5C6coMMPsB/b65ItdhSjxOErFJPfQm16ApyAkYjb45KyGQZ6+sBGdjdpxlckT/sk6Y+FbokhLwdqqyfgGyLULN5MK0EJYPTKPTmFUk7eXqdJprvsl/e2QEz2DvvPujgUGcyZH9EoNNBfVLcSvOjzIQg+PkyqX9jhMW43UvJ4D9KcOFsxIjORKxlTYknU6m/DRM06EVz7gIYY1ULLP5kpLW1Vc3CROyUIyl3BkWcqx7nkRY1bfvmoxCj4EWYPjYRBK6PaaLXU3HqcmWPlFFsw328y7OR0I4OrHKLnkE0iFFidjWBA2pG4mx2R84Zzg1mCNxhHultF7mpQhnp0PQOa6qP9CLIpc/zkge5qsSUvNrdUM16zIL/yr9Xn834mk12kcMdGkWj9i9Mc2qrV01rBTarP6fAm+KJqHErZFVe8jAc9eIesIEQ== al@everycity.com_2019-11-09
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDkHB5ugdswpxHrq+th66veBWMiD+db34pU//vDnCyjmd1EIZ8jbn2ADNZR3S2T8gshZKScgTaLB7s7y07k/IZQPTUTzNXlHQ8ZEfcqdr3+LKhR+z5vm37alvtJJNV+N47yMbsjEDF1zppJJLmoMXX65BWAehwU6Kh237UdDlBOTJoozHHo+bq3OwSa/qEBOTYiCWrjGMwI6PxydbeOJs/MW6E406oAI6AZ1ZLaPlkjoGiit4izc35VcrUNic/+93lAoYPjPHOhgQJcZdR1kFruNqL+JR7uS3+0WLK8xwv6HPCGI66u8cevlGY21PL3pv3iTu1SPLCvDQ9HRvugPjjeA2SSY/jvAzAy0wS3CSEXhgezm5XG9Ka1FwHMhoCBW0eVW193MSaMtGQGNkl9QKx2CQenc4Z+haMQvO5uXqFBck9S2TuLIBu6niyj/DySIbFYd3tFlQpDJ26QHl9RnnDqNw2GYEPvRTmUajCx/A0wsVpF6RMZE7Q/eo2y1A/3SNbZAlU6sT0c9O2g/uJxTs9euRSKg8INx00PXxYrkXh0rL+erjRKqT3ssgHrbM8HRzT6nzAuKd4krzaGuevFCqDj+zsm4uTz++bhPKphNEkCuFhszMkMV2gKSg8q3TwuHy8gbZgJKp/x6ZwuD+dgIUcfaTKAaFxBorMNK0Zr+NkTIw== as@everycity.com 2020-08-14
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpXNLVjGFf0Om54xWfMGCNXB+O4iD34FDaDWIBKLpDIIEbUaWqhoWp4/M38VBjFSlOm0Wtsea0D0rBDfwWqYgMer5KzCYrNlHXd7U04hPlOUtych46O+aUfx7m1OKGEbiwZ4PFAXMck9bu+K29m4/bnNxAHePqQb+eJRL9wYFdV65F5fO4Q20+DKQ2z0T2dWJLSeDR/CzASrdp6uSfIlvG5SuD5tdisAxv4D0pw3qxOcyHKRwX1hwqJLtpbAmXTQjtfOntsGAiVdW0fQRUH9xgMw/5OR4Bg38e204muTnrCM2i9jrkWHLX1nw51P1xjkYooMPa+ZgUOKFBJIzRCPEv7WUvy1nvQUBc229bAEcQ8CHICwKBm5gCYGO5JsiV3mahYH5VolO59nUK/nWqL8v8padGR3/kaodVMd13rGIlawouKDgCXSwAHFS1fFV5bBAmnU3w7W0vCLxVOmjhFlhqth1e7eGaWwGqIlzmQFGz4EoT2CjuAk4OdoUIVwX4/g0spX9CCCIH10wop9gwLEu9M+dPNoF4hyIJv8WoxHac5myEqOHMySoPhKDiwysbW/K+HwTB/mWIuIPym/vV7MBrxrqzmAdHdo0CJ/PakiFzg9LFFGo9Cgd2OZf5TXEz4Np2Exfuk8KI1/0XTnmjK6I5AGMTtB3WKnUuk6D+wVl2yw== jt@everycity.com_2020-01-16
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIlWYd21pTZPIKC4GI29ocESIN0g2cg3kkBJFYlj/9K7cCg2YHze4POE8Qxo6Tcu4QXY/5HTwmx/opQQUiFbWfAkFn5RGZ/SQnBOrFVbaWxwVXM8PFmqlVuNaEAcp3LI3CCA9kXkhtytjD7vH830CrcFu5xcSY8NugyXGEsRrO5pTmwbb38WppU9JEOSGMAMgENQSbj/UdwfXYphsArA/OlaDIRa5wRXRaamlLQYRDPjNpBPNT9ftTIRp7jevnmYY0gYerK0BCRewNFuOgtJv6H74/Sr63nYA4a0Eb1BPNIyKbrbjb2+KenZys7B5zYjk7o5ntpmdIERRZWFeP9h/CE6INe5rN9guCtHcmycX0v35TLnTOR1Y1rQGIagPPR5pm8hLOD824Yy/ypCOR4nkr7CgBZn+wId1W2262b9Mv5gv6CGGwh/86Kkbm/xEOloYHSP4hqCkQIivctwv9QKNNEwZmd7m4G50flQH9E61VVFioxwBzZiJrUGlA0sEoVllPIDiID9O7jPdsjgbO/a9mQeWN16Uhu1iiK7+nXg3pDJWyH0l4E2TLZ7J1mehItJzda43SR9pMF0KWDdiihhTtMWRj/oMezlr60dQqieMPwQnTlCq7PcwsBAugYwgoEsi5EKC2/4I79CHRnmi/rTyG0euGvwxtAun8adIY8xsGeQ== dw@everycity.com_2020-08-10
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPJOZdPMeFjCi5Xs7Uk6b9kX+BnxYBdfvMFB6+J4ahp98TUG/bGvySWgSY6yF0WFYOaMRmMfqL1mXIaOCWzoGwSZAsvZ2G2u2nG5qf5WIgnnESNgerMJfuGfRE1Ulhcw9RnkxfISD1bWYzKcWjzGwXUxYCgHL9s+2DqquLXyq6KYXaHHhKXlcBMAgIzVu54mDTf1cqpoYI2nSO8UL6K5EnXY0H3ujJavltR/zCBhIWRqEL7PYqQYOplNL54lwKvxOJfPH2Hy7BtzrmIV8wEnv0uPEUrPsa1G2U36C6H1p5XV4x1+u4jBZQGVaRQnuY8cyR3DIfc9FA2QXJHnThZVo40vbqCmrNkbqPf+2M6vLO+g2HXDaHCLZDEqZ2j6cRMwi0crwb9alKARWsZ/UT0kTV7OSRpFmEJqcFJQqWPm63P275KgqxoFRFqZWgx/SdyuVRKFKszB0SUmmbMYdyMH9JqAOGfeav0gP4hFzOp+8pLUjXLOzHC0o3LPHB1a4QXNlXTFMHH7pODu3/XEVo9D2cl8+3UteSUKjvY7FmPyBLDgjxJHZSuu61hXnLgkvZas/gzx/h7XILbE62zi1X5cBcAGD3Fv8VrO/vwjANrZimiWrJZsWzZZjSuHRSptjHo4bPrwkhpCe/Dou9J4b1s05kIiuRwlUsniHQRWijE6tYGw== jam@everycity.com_2020-11-06
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDymesF4IfJmryVZM7RIag2u3L31fRSI1VopkxzLWaLtTNxEH+cAGVI4xlXzEk1uNOKq059cn8/k+LYl9DEHERQ6sN2bQTDfbN04WHPdYOuXhQuZ9sAyADSs3w1LDK4KPJREzhSuIka9cVv6h8eD72hO6MHqj5iULj0Csg/5jU/F3vk/kCNBP64j47+PSSf26Lh8M032JP3P5fc4gzpKEeJUPSnJ+ltdQas+o9BO0qIBdeDGh+gwxtbhlLH3jlKbmU29+Avzg4mP+S6cRQ8vmR6cWJaBONIjVB8qLZtPZZ4hNawpu+WCtmoBh8rK9Lw/Wq1MP+PO9YgqBMQs7zXPSE92D+avUInKA16EJ3g44fFW2hE1tH4578MkeTLxNTEYF8cJ549o+REwbI1SdANH/NYbE8y25s82hVQ4EmUKEjV6gfTa2SjTVi0Rgye5d4IYgG7pkEXyLN/xiCKx+WFJXKPpvBdBBnA1Es2N3uz4TXCzLlHYTYIeIH2TZHI0oeKa0lu9mqT2tp8bJx7vaTe7wChYvMRzYGiiY4bthLhbykGwmdspk125ZQ9r2pAyjqIynsQ7dZsiGwsjEAiRtPW6qACvOd3NDqQiK4dyCmuwjT17J8pHYIkIeCFyPu+2hm0JYGYKQqptymfWXSnmezgtj+Jg2IKbxnYCrIIgmP3uruNQ== mic@everycity.com_2020-08-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEcH9T4Q5cUP9xIwW3tGizV8Mj7M8nuQbjOJRzY67FhPcGb9wuGi96waLUxMgtzObXx/osBdxHGhRM+olOxYV0bygbn+1plvd7DSKIBkZjLGLdKdS+5ahCPaEYtEclpJ8PdloskR9uRv+iEBU5OtRt5G3OmE/l6mjzCRYmw9egUSjLd6Dejrat/c7MMiT8uUVvHfNStUsXwJIkyY1kUbcDwu7TlJE3Wc6fTHDcw/rdt8OgIQ6ibklHsWsYYU8Mwg8N8+4v5avXtn+L1t91MCAIuNSbIQWl7UYXM+M8a2sfHIw1ApP4fw0ZK/MkUij0UsZkpLxtWFaRChLlItjTl05/G6Xpa+vrTGE/ACkonppb5wTbnsIiaScznEp6FrLgYMhLVLhqbfs8wyg0hsnUuoox/pKad04vTYfZKf7NqucvSP1szrv2gjSJipZQ4M7hx60Au8svAV0AkRMgmfL0EXudEPWziPa3NFLydWLxaFZ+3tt/yh+3HCFKeZVxsj5o1E5jttzih212q37HIWP8QNgAklwdBT42H3cb4YKfC+ohn9F/NtruJ8DQIrgfVtQ5VgdZUKXjxMWD/NvCwqiEUZ/WIrg+gNnznILHZGDjjiRZGsgYqjJIiyTEEP7yyvjtltUqC8nQ05jfFPjMEq+YKsF+YW3UX6a9Ku6sOOjw+iBJlw== ob@everycity.com_2020-08-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6+TEqyjPWcZMbXV3g7Eip66xNB8cMohOdZ7OEdbEQf08fuU2wG1QVKgIKbvy9tHo6UyZsgKA5ecRTmkPFbdv0wEPKG33jhnMbhgFHH5KcyFf6VO9tZP8YPrtjcasX2tz0noBdOYkcjAMIS1FG6Y83w5+cpb6Djny2CwgUqy4yJ1zWP7lJRA3QrWkZB5yC/ArS8LlocJBiI1m7pC1fLCcWtCJTy+OwBB/abdN1uSJz9ThvP4LBnAb81UZnZCkcdgHT5qBoZN0foDFlV6omIB1o+n0YlkhslGbE8Rfw5/99biB/h75dcao+hcCO8+uXSenZYiZrEpl/dIlh+HTM/HFF7PhWgbgpIrwkznEq69vOVl0xssabw7HXh8rNt8tAg6HJy5W6/KaiUZSua0wJjwMF4sYvqtHrRv8kWk+JsgqVs8ETOvCAiM9itquYyNxjajmhbCbFqTZhxo39IhtDps9FBjB7YDzkI7/m81yQs+QgWUrBy1bN+WwS33bXE6mKPiN7lp0Nm5KgioeVh18JX4QzQEGLmNsqWhoZcsTlG8gYkuHxexnls60wgpyvXuXbhN5U5tfn3hlI5nW6rAgv+j4lMh99bfYxbjpA29iCqcmVoPDYB5m3pxD74IdjJp2cAP66Ft/5Qz8I5XXr8zM2EN9Hv+OBksZVGvikkLc2vQXlzw== fmj@everycity.com_2020-08-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3TgPRr1BoL5YtCcG32JZuDOfuQF9WU4rGUqZ4IrPhX3l5jf5GM6xxE0jVh3qjdUY1A41a+8Ir61duabY4AsWcfed3ul4cVGG7k84eY9T83P7m65ucV3wCJOo3J07HbwCHJi7aD3imbk0Tb22+0dpsylQG+Vb9VH7V2QHoQYV7E/lZQv/dmms50AYkEH69GFxRJe4LjEPs/vXmUhATy8S9cIXrKsr4mfROTx4+2wcU6v8f9EsIb4V3TpMJpUY73Cwrf1AUnAWMNv7okPBJyY6esGGwu6ToPXTGB/BMrE+1Wqtw3YR5KXEZ1cH3ncDsjIhsshj1bmBFV3DVnHyvrpbjNyhjNuMtccvCgaPwdXJy7HA6j8pZH0StqvYubnauT8vjDoNPq4grnfCJ//GCf4vHNECXZ9qWuFYFE5c+e6fwGsAPc2EDZjwkfxWMmZZ0RRJPDJrtpCT8I92qXJHAEavMAhVunlN1GqY4FngUPiiqoefGYUc+xm7S1s7GXvex1VLQn5RoeyJhcGr/o3Z/fWC8QaZEj5BS1kaueZTgfcpFxUOKCwJzYyyYqJoWz12LeF8G30O6uafh1nyEJKNhCTQBbehSYmJQ/RxXgzLVIPN2GJKaq1Gt+NHGakvlFUd5uf+86lF5Q8w8+3IRpqaiuBfSab8xLVvUWMdhsIpjUKx5qw== ame@everycity.com_2020-06-10
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDjywIPDttK9ajq7admlYCE/qaVQZvykSvXikkiDazcu1V3uK7E7uqvAGGTpuRRHRZ0l1sCEKWt4OMU88t/6szWW7aHy9FYX66sEY1r9csY6qWlktvwHf24TruWnWFf8KFsHG6gZKZZ8TQW25xMCmfnhTPa9I5GzyZzZ8m1ZcIflsXexCLd2G7QbNvw+YvzE/txtdSPLQj4F7YEAfm4Uu4KXnbE/tsVbg8WK3SStVysfGzG2WI7iashntB3x6HszavNtaF1pnLo/4HLs28+6ZyTS9CDqEBqLtvIGctcTXMc1RNQF9Fujw8fhFWdpy725MVPHH6cAEicnUSsd3tcV3xBM144oyHtj72/6GgzCnMNNVk1UoWc8fOiXXH0Spd/9vxlpeCVKLXLJl968ZHFN9sgjU9X4GVPrJrEEzUV5PyG1QdND7XEJamnF2r8aQnaxtoP1bQzwKVXA5oo37DQ4G0fL53i/VSIsCN75ffQtlRKZIwinWj9u9BTFgUVi/y1TtUmc/bwvpCI4SGt2ZfQsVVafGkRQYVDU/DDQzGq0gozI+RgeOUaXYEUxFZgpslBdxNdxN1IFLKIc0osYTdFs9ieKDS/Lo84kbzdQK00/NW6jAEbA5uW6fLSph4y8/3+c1ysktSd3uzgX4X+pKMeu99FvB/3dtGL488SFVYce15Slw== hb@everycity.com_2020-08-31
