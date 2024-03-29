#cloud-config

# Work around Canonical / Joyent missing modules
cloud_final_modules:
 - package-update-upgrade-install
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - keys-to-console
 - phone-home
 - final-message

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

# Install a newer kernel and associated packages to avoid hangs and crashes with cephfs
 - linux-generic-hwe-18.04

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
 # Partition the system
 - swapoff -a
 - parted -s /dev/vda rm 2
 - growpart /dev/vda 1
 - partprobe
 - resize2fs /dev/vda1

 # Fix hostname so internal IP is used instead of the external IP
 # https://github.com/kubernetes/kubeadm/issues/1987
 - echo $(hostname -i | xargs -n1 | grep ^10.) $(hostname) >> /etc/hosts

 # Fix time
 - systemctl stop --no-block systemd-timesyncd.service
 - systemctl disable systemd-timesyncd.service
 - systemctl mask systemd-timesyncd.service

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

 # Initialise Kured for automatic safe reboots of the cluster
 - wget -O /var/tmp/kured.yaml https://github.com/weaveworks/kured/releases/download/${kured_version}/kured-${kured_version}-dockerhub.yaml
 - echo "            - --reboot-days=sun" >> /tmp/kured.yaml
 - echo "            - --start-time=2am" >> /tmp/kured.yaml
 - echo "            - --end-time=8am" >> /tmp/kured.yaml
 - echo "            - --time-zone=Europe/London" >> /tmp/kured.yaml
 - kubectl apply -f /var/tmp/kured.yaml

 # Initialise the Kubernetes Dashboard
 - kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${dashboard_version}/aio/deploy/recommended.yaml
 - kubectl apply -f /var/tmp/dash-user.yaml
 - kubectl apply -f /var/tmp/dash-cb.yaml

 # Get helm
 - wget -O- -q https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz | tar -C /tmp/ -zxf-
 - mv /tmp/linux-amd64/helm /usr/local/bin/
 - /usr/local/bin/helm repo add stable https://kubernetes-charts.storage.googleapis.com

 # Get kubetail
 - wget -q -O /usr/local/bin/kubetail https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail
 - chmod 755 /usr/local/bin/kubetail

 # Deal with HOME not being set right
 - mv /.kube /root/

# Remove swap, sort out disks
swap:

disk_setup:

fs_setup:

mounts:
 - [ swap ]
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

write_files:
  - path: /etc/apt/apt.conf.d/10periodic
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Download-Upgradeable-Packages "1";
      APT::Periodic::AutocleanInterval "7";
      APT::Periodic::Unattended-Upgrade "1";

  - path: /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf
    content: |
      [Timer]
      OnCalendar=
      OnCalendar=*-*-* 2:00
      RandomizedDelaySec=4h
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
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPTfvbrQ+fYetDai28oITISVw5A50DPEfn24swxyy3xYRStsLdPd0Ouj9KDy6pMl7Ldsvj/1n5om7+Jd3Y8MF1sfq5O7SXf9ghRWdtShllNb9Z0omRKgimOJDEDyKo462qJghnfQQnIivKMoUC5aitIaBe1CLeYKJveQ/BiyufoZ01SsRoKFuE7LgA62cK7OnTlpksBxwjXvLLQnE0kIWMqUAfVLbApmqTwLMmiIvxh+FOa2SVYaLoxIBpfKYqLvI0PpjhGW1WZkFukjWVSIiZps0ZcNRAOvnpn22IZRzIB3/yoqE3IBg/5PeExrBPSVdAaxQzYlIMkIH0R1LmjgJby2TRWGJoTR1jiE4ZEa99VIW6HzKmLaIT54zLPonvYkfpFsl32ie4pK2xgjXE5EMCiy8mq1hw557Kbs1mcNbpyHY7zMtlW9tK/1Dj793aa/ZhG4sBdbHR5mJwQ9bUQ735KE6szB+h1RNJPFgeBJz9SfgBMAVg0/FTqtfxcgpeQyMmgPbeZNHUAq61W0VyWiJTb0a8TLzKDK9AxeVTqOlje2TYnr91IpCN0mZdyBqR5RdBoNyXQgPXqJDqCELlnLtFpbsro1MgCAFYq7yuG+X7hhT8tkak1vChENi03fd3qFM/riX3aLoyMY31IHAWqDPhCUhWd+G3QcXOEK6iuMULyw== as@everycity.com 2019-06-01 Work
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpXNLVjGFf0Om54xWfMGCNXB+O4iD34FDaDWIBKLpDIIEbUaWqhoWp4/M38VBjFSlOm0Wtsea0D0rBDfwWqYgMer5KzCYrNlHXd7U04hPlOUtych46O+aUfx7m1OKGEbiwZ4PFAXMck9bu+K29m4/bnNxAHePqQb+eJRL9wYFdV65F5fO4Q20+DKQ2z0T2dWJLSeDR/CzASrdp6uSfIlvG5SuD5tdisAxv4D0pw3qxOcyHKRwX1hwqJLtpbAmXTQjtfOntsGAiVdW0fQRUH9xgMw/5OR4Bg38e204muTnrCM2i9jrkWHLX1nw51P1xjkYooMPa+ZgUOKFBJIzRCPEv7WUvy1nvQUBc229bAEcQ8CHICwKBm5gCYGO5JsiV3mahYH5VolO59nUK/nWqL8v8padGR3/kaodVMd13rGIlawouKDgCXSwAHFS1fFV5bBAmnU3w7W0vCLxVOmjhFlhqth1e7eGaWwGqIlzmQFGz4EoT2CjuAk4OdoUIVwX4/g0spX9CCCIH10wop9gwLEu9M+dPNoF4hyIJv8WoxHac5myEqOHMySoPhKDiwysbW/K+HwTB/mWIuIPym/vV7MBrxrqzmAdHdo0CJ/PakiFzg9LFFGo9Cgd2OZf5TXEz4Np2Exfuk8KI1/0XTnmjK6I5AGMTtB3WKnUuk6D+wVl2yw== jt@everycity.com_2020-01-16
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6erlvwYGvK3y0NyK3Wuo//Z8YAcS6Nbm8TecjLSeaWRhaSel7RaYE+aRgVJZiZ/pmtw/dFpgdUdu+q9md3ITvKglBhkkV/KC1Vw4mLoWC0nwolPTRLDy/12PHUdaUdRZJU4ywdwn86YYM8yHzDFrX03s+FpWin/BbesXuXxY/BcwclLuichHMb9vh7t7t+hFWtIZE+xpHNs8PNdk5zQrF1CewUbrtz1uFEBGt1GCQ+rDdg3MKQuMT7qWZXs4K+2QMRlIIJGa42o0AkFDLIQ29dajdvEVNbaUQIFX+BMVwJBx5Zadb0y+027kP6SqG3ELHhskqWb/50l9BBGcHMWAlxZOTX53eiN51epggS//BrRtjdaLh5veIDQLmbc2BdY3IsjyrFR6ObqwJE9FVRQt8ECvO6TrxR1zF5oodt53YWRZuNSv12om90cdr0iqGwC3YMhKE5U19kggGtID08mF/L2Jw0Zj/4oh85v9LVBz8QLkTbIPxnPoHcE6n8UzOY+CU4E2Xy7AG5o9Fud82TgP8tvyuSrpQda9OiHoLBHrXV26H8iOZ214f95fXxwRA62sjBLWcOA/zcmR70q8hK9ZSXLva0Qo90Lr7UO4mzQ0JSz9LllYlpl1buce/FaHPmJD6sbMlEceIqkh6P6f9vPK2+B097levLjSvb/Ru5Xv0zQ== dw@everycity.com_2019-07-01
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDo5CR7LW/hC3TqaWPr+kp9jvGPy6YfzUMy6eYJaGQ6crnNkzvCl014/dZHqmYwXZYOETl111eZmWHd5PRlOBbGnRHKBay2HY9wGy2kUHb6rC4rdEG7eJVyrX9gLvRNHZHOIZaU2hnniKDHh3IzI7q0Egy0m2+UXVnm4DX6txxAScUAYa5GythQLEgHK33UbvQF9Zoj2G6EUoFF7ZYvEEttDXHlsjn5utc5Ejv1Cz9fS+z5DyLHZF8rei9Y+UMEJp+/tjhZDEH69q8HTFvb+ISlYZkSJHRVd2fHgH/3XTbvIGYjVlSBoSlvCK8qQMzhZWAKOMrrdHX99iL9kVl87clCiM96NYtUXtjlxnJPYgleENsSPb2VmWa7MGOsA3NLryWPgRFfrz2XM8HwmFbeUEtml123RULDjqHreejPrRzKxjVhoxzDCBzQ3uY2WDdh4GgMajMGCRzqqfelrhmQUSWtQFLYBcnc1LhE0NB1afwFqOzkqxShiqBXXL0GSvftKGpu8PtnY2E4/skqYIOM6oEkFyckBVLVHMad5ZEeUweqa5xInU2/KWXskqXo6L6tlI/QG8E5LudYXJBWPwiJl/poNELmtw5zDhal1Dhsba1OQ8d9Folx0tgzHrQ8hNM/v6MaNp84fsL5yKSGvgu7GNfzRJu7pCqe1ik7myHWh4B3pQ== jam@everycity.com_2019-07-05
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwYaegqSlLZFSbDOKDZy2uHgb2lY0Y87zGcZL0U1FnlpbS5F8UvHfQb4Z8UYYjR2LHe9AAvEr0mBL1GIUBJCQ5M1KN39BLPp4mVTWd3fEukzee95nRErbvrTStrjtdjVZimUw0QiwiNmoJ+PGN2gk1cAOhtwsfE29fPsmrUsOBJPJhvGNImGx7O5x/feaw9k/nkEYzkep0isnFUJxbl0tzXlWXLSfCzQUWWgH7fgTPXI8Y/xJ8ko989Bf0gmxu/olL7byoQS/JBLHt9GPGOe3pN2D778Qz8tmtAnbr3Q10db4FycC5Ph/SPetcxVj0aUEeqwGPHpi9W4STVAEc/F1PB0WX9cSOfP0xwibL2TaI3PINGiyBjawM+8FMJGwy8nBKP0r0a+K7dvnKxPS//Xo8v1L0UHGnN2s/uAmIhFJ6VgDXwxxMhuBE3vcX6jWx/j5mt9DC/qql5LoAut+nC7PbRYe6iZr8GfjB7d3Za21Gwi9wL1F3USlHCgT/xRxOdSJxMTMZ8JRINgHlFeRT24vRLI/VwhpNFdmiALA3iIr+wTeKKcuH2/j6Am2+ujQyeTNNpaDh0tJRmvTv3i30FqIRguu8VDMV/yy/Vth6mlkzOGfw3+jmElCyHHwKqw8G2f+LP7/bRQthXP+e3F3eL7OYCJD/HwBwjvsjubu4mbJszw== mic@everycity.com_2019-07-22
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZigSGk5qK3K1DJrwAmriHAggGCL3Bz08zWzQ6Oov2+mKqTFBdA4cUdHRtrNMKOton3XICMr4Vw7IHXjo0um4JzsWxmRbtR/RwwB8tlyLrlHplEI/IV3d9iZFwTvQ48UrX5cA0+AXAFxLrbfI0s83MOObrLzheV6d8b3AsoGtv52mI8AoSM0IOx//lZpnQLHU2uFt8KGps7v71qiC2XKxx/N2Lc2AFX5G/Hbc9MswbHkAmyL5KAevM6SiVwyd9iDh/JhWyi9oytStDIBrTxWZJUSEIdUE03djaagYqa9BvjN2oB9Cy8Wj4D5WgTJdD9/Cfzr/S4aYoxKQi5Lb20EBhTzhJCQCt5S4t4R/w9qUuPIrb81Y26anGJwNSc9TFOQkWtNNZxh1YitmcPTdjoXb38a6hLVy128fr4RF8TZAUi4XQXN/V/0ALg/lu2W5vhU+kCccNAvoSr79PWbmETRZbTgnh3bBEeZUxVu4RAL4Wv4oNUnJ2oC2hbtPDNiw/wMWNf/uc9maSo25LWn7Go689TZrIa1xi/x9fChJRHcfWPvzs1aWKwanDbsS0si5XM+PWh60OGnkUgTlQMvPYUSxSK1KYzdL3eEl0cGdAn5WaVRqn71dGTYg7rXZDi4Kd7GNC6ek5gt+suzU9glfTKP6BFeT0WO1vYBOfg/dNF0em+w== hanif@everycity.com_2019-07-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7RDhJHSIOsR5whKRy4YHlUkZ/R+mqdRdMmG8CCYUrqTHmnL7NWme/h3tl6XS8gAXkDkTq4rAZ39emeFK2+YrIsywzlXfvtM86DKcdKuhqPUEsJcJIWfzzef8aGUzfLpkz/iX3QXqVftScNVSOdl3vYhhRIM2lTjjEL8IglDd9PxfJZ51tbZpHAbvbeaZkPrkDLk5AyDx2/ppc9OLxkbqU1kQMJwEeKWwgpqjUwhB8C4SdqD05H5GY1xLlYIjp6WKgVHXVPUOlJ1LQD8pBrLrpKDUw2TrFzoZNsUm7QAb5VQ2V2F5DIA0+NT9dhgAR2bmcLWEKUvsVG0XVVKfbjkidWM4IHD8XNStAB6m8MM7u62QlEaXDvX7bVdl46DnlRK3yb6GdDHGbGpl8yAZQJNNW+oJMxKhiKXDyKwDfjNvxRLmXaIH3hNLrU7KVisfYTqqkh2lnttg1PKrmU4o82Ptqcozr1ysodu1rj4lYqi1p8j6QBcy5xmt+NKlh7CQoH7Z5Lu4UmgylzzevS4DwQhpypDnNow/WjP/r7UennDgB+hoK/X70VRqXRs43gwxk484tMDJhLWMt4qbwA6NDb+zEI4f+lv+0gaG6b4A0wDr1iT9ipRIj1ndOOdebNjDz64NHSVv/KZvOf96wWDLdX+umIUWwKa/eZsW/FUwzhiESiw== h_barik_win@everycity.com_2019-07-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVnicvBg3ZUIh/EbnYzecRDpfkIjWn9xFUQRYvex7jAKY3Z2AwQVNYUQW1rOFhNzET1sPwwtQoRDoAhss17/6VGcC56lrn1fsiKoPTZWzUTpmFEKQFGk3zYt2YGvNMKYQovP56LQ2CWtXjGdYxUarERGSL4ddC5ghyJuPKiNEsGbH2BEEUBVqpXuJINAoS4KcTctArVYK5almpcR3ok+xv/7Y/lFgrAuYjLI5k5P8LVvwM+oFnt3qKji4Ezfnde72GMubmypgzXpiQqGGoU/Ku0o/pfkR+PHB+Wt6rZXS2ZJh15VFgqwdrZF1yoXMaxEt4WHYJDhYTM3wouaIcGZ7MibvLduNZWMkGXnPTL4xvHlTOiugAi3bUrnzkLz0bq0zb6sIHf6QhJbwgDS9XbgqJbL99A9UnqBe/NEziaW2MNfxyN5BihXXjrGW4D56MJeM+M7dsE4Uc/X+Yju/pDJU3V5XDP3F5NWxQxRg0i+VOiwYx2QMsYazyE23ePbxFx2FWmuzJpl/foL1kKlYuhTHaa0r40f7JgGHrtSI3W25t2raPyT4A0hhus+7acjXtDO3/RlePB82/R8zjLS6mr/z9WaXbnR7i2kU2vgzt9XVffTLk5HE36hzwcCuwB9K0qsPLI1Ki1MIpQU32MQcaMcxJnIp5QscHFVcJlur8/JDnYw== ob@everycity.com_2019-08-08
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD2EMza7nJTkU1zrpu/fEyNtQTRUFPkdYKOum6C8TMnvBNAhJqqdx72WRctfLacupmCReWH4MR6/8uqljt4sPOehFoxdMIA1VJC2UiyMMc9rl79DYcmyto/OlPoOae6h7zFuTFECNUFVjuvmEsAjjc4P+sg1oWKUDJfsfVRXed+o/k5OyxjNZmWTOeqMEr6Iz5qBh2MjCKAL4IX9HCkQAPVMuoSGnDwt5dGRyvPPuYot/aFcWVOH5DdvBZ8w26+FzaU9Yi39v5vtBaqnejij7sDDDdLQ4KfOPwVXxelIRcUbNEnrpq1siphkW9f4P+hEY/zZ3YCdzdX3m9Ve5nY2eNHsOmG7IUDz2lfOCh2YUoiPCqKQ++MPx1mM1wfChiO0WDkdOuzi/bqwH/KCPwppmLMcg5SYGtnG+AiKYy3FBIKQ19TbCcIOIgIGkqXG3N9x1FsP/y3qAHjmdJAv5FVxy6NnT0tgALFtgyDQ23pT1foJW1Icgj6grr8tGtNISpuIe3LQm3myRLh1ZtXa7EnMek/SHX7osTGZEmFY91k3bg9S8HOXrBAU+cie7/9Q7OkKV7xEBSYdlEvPJYgcej7tEeAC6pqFZdbfktcmE69tzsZytL/G0mHoWDFafz6lGiVBPaIiyxSJdgUefMZHfaLwe8SpHJWklcGnuq4qYSH8yffIQ== fmj@everycity.com_2019-08-28
