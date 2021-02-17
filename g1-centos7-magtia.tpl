#cloud-config

cloud_final_modules:
 - package-update-upgrade-install
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - keys-to-console
 - phone-home
 - final-message

runcmd:
 - growpart /dev/vda 3
 - partprobe
 - xfs_growfs /dev/vda3
 - systemctl stop firewalld
 - systemctl mask firewalld
 - systemctl enable iptables
 - systemctl enable nfs.service
 - perl -pi -e 's/sudo:x:[0-9]+:/sudo:x:333:/g' /etc/group
 - perl -pi -e 's/^everycity:x:[0-9]+:[0-9]+:/everycity:x:671:671:/g' /etc/passwd
 - perl -pi -e 's/^magtia:x:[0-9]+:[0-9]+:/magtia:x:1000:1000:/g' /etc/passwd
 - chown -R everycity:everycity /home/everycity
 - chown -R magtia:magtia /home/magtia
 - rm -f /etc/localtime
 - ln -s /usr/share/zoneinfo/Europe/London/etc/localtime

mounts:
 - [ vdb, null ]
 - [ "10.14.27.233:/ed3aa668822a4b8969e9e25834ada817", "/data", "nfs" ]

packages:
 - cloud-utils-growpart
 - chrony
 - ca-certificates
 - curl
 - unzip
 - whois
 - traceroute
 - mtr
 - yum-cron
 - yum-utils
 - nfs-utils
 - iptables-services
 - screen
 - tmux
 - rsync

package_update: true
package_upgrade: true
package_reboot_if_required: true

write_files:
  - path: /etc/yum/yum-cron.conf
    content: |
      [commands]
      update_cmd = default
      update_messages = yes
      download_updates = yes
      apply_updates = yes
      random_sleep = 180

      [emitters]
      system_name = None
      emit_via = stdio
      output_width = 80

      [email]
      email_from = root@localhost
      email_to = root
      email_host = localhost

      [groups]
      group_list = None
      group_package_types = mandatory, default

      [base]
      debuglevel = -2
      mdpolicy = group:main
  - path: /etc/sysconfig/iptables
    content: |
      *filter
      :INPUT DROP [3858817:335101148]
      :FORWARD DROP [0:0]
      :OUTPUT ACCEPT [605418306:629521341691]
      -A INPUT -s 91.194.74.23/32 -i net0 -p tcp -m tcp --dport 22 -j ACCEPT
      -A INPUT -s 95.131.252.106/32 -i net0 -p tcp -m tcp --dport 22 -j ACCEPT
      -A INPUT -i net1 -j ACCEPT
      -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
      -A INPUT -i lo -j ACCEPT
      -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
      -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
      -A OUTPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
      -A OUTPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
      COMMIT

users:
  - default
  - name: magtia
    groups: sudo
    uid:
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7JmCO8X68U2QfXLTIdA21SzARolpEsebV7FhSgjbwabMlWTCjg46AAZFe8Q88tsGs9l4WbwsSFJpo8UMFdeLA80TaW5AEKF0H5nmQdmxF8wW4zz1yl9tp4e6EakJnFQwh/nvxKPkrw7ICOLWASwTorHKQBF7glYq39/MP+hRvEUNuj1FXAU/RvD4IYDg+bU1+SI9DEH1MxcvD4Z5ASGHDXot9bvOyPcJY2/m0+Ih4Z9EWyy1vi40LPy49nWO4oWevDZ8jRtpwBrN6kIsJca1LQjhc77NvUgK28vX/Hc65id6M+PZWxT9+WdtsL6Enorq6Xj9qnoxY0VkIwzpfPZPL zoran@Zorans-MacBook-Pro.local
  - name: everycity
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDfvWsHdLxbg+o8McKeXUJsOINe/Zm6vilLv4x0mhlsliIOl276YtipYeN+t3QVZrREtm1GjWcTQgn5ax5hf+u9F0VWP1D4CbvAc/17D3woLlCWOyMkZth1EphCOBh95uYiYtmHNbDWCD0xRzUFBQpCDLEUYGNEJ0rsexpMXMMzDIZ7HWT1I+rIoQ2rwcq4MQ62DqkY8Q9UhI6jXzn85VDn9U6S6G5HJyg44CN64/JKdSDeYJNHl+220G0DRlLs/wAxq1YJDeqbejVQ8kcrOC075VQKsU6WJxgvBJlQjl8RDuuc+aMw9II/ZF4+b+zct0q2Yn3gMHJncXmzoz/RuTq8rvQ7OXkHeyDjHjraWkW6paRvhF3kKtCPVo1OWk5pz+O+sj5OikP0d8pXS58F5zmGMSztc1bt0h/tnNMp7lkwlSRQKdNzmJv1pg09gVhB0T14hMLB+kJaeIDccWc9lvbtPvZdJoqVfcw8kXrizvDQdysU4XXbsMEoyExQMAIVALcRekcy/OPIdN5yDrkfJX4TnRMPWwnI9gtzWdR377UUY2hIbm3MJvhcwjXvhpq9zVXUhqHVNyqdE/2O/Mr0TeiPo1wWynoJ0OOp+MQHd6VZUt0U1VBcC7SalyVXDkcPL8pPUihLoA2Z2lF7tbc2NeH2yFOb0qQ7hgfxL3Wpgkvw5w== al@everycity.com_2020-11-11
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDkHB5ugdswpxHrq+th66veBWMiD+db34pU//vDnCyjmd1EIZ8jbn2ADNZR3S2T8gshZKScgTaLB7s7y07k/IZQPTUTzNXlHQ8ZEfcqdr3+LKhR+z5vm37alvtJJNV+N47yMbsjEDF1zppJJLmoMXX65BWAehwU6Kh237UdDlBOTJoozHHo+bq3OwSa/qEBOTYiCWrjGMwI6PxydbeOJs/MW6E406oAI6AZ1ZLaPlkjoGiit4izc35VcrUNic/+93lAoYPjPHOhgQJcZdR1kFruNqL+JR7uS3+0WLK8xwv6HPCGI66u8cevlGY21PL3pv3iTu1SPLCvDQ9HRvugPjjeA2SSY/jvAzAy0wS3CSEXhgezm5XG9Ka1FwHMhoCBW0eVW193MSaMtGQGNkl9QKx2CQenc4Z+haMQvO5uXqFBck9S2TuLIBu6niyj/DySIbFYd3tFlQpDJ26QHl9RnnDqNw2GYEPvRTmUajCx/A0wsVpF6RMZE7Q/eo2y1A/3SNbZAlU6sT0c9O2g/uJxTs9euRSKg8INx00PXxYrkXh0rL+erjRKqT3ssgHrbM8HRzT6nzAuKd4krzaGuevFCqDj+zsm4uTz++bhPKphNEkCuFhszMkMV2gKSg8q3TwuHy8gbZgJKp/x6ZwuD+dgIUcfaTKAaFxBorMNK0Zr+NkTIw== as@everycity.com 2020-08-14
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpXNLVjGFf0Om54xWfMGCNXB+O4iD34FDaDWIBKLpDIIEbUaWqhoWp4/M38VBjFSlOm0Wtsea0D0rBDfwWqYgMer5KzCYrNlHXd7U04hPlOUtych46O+aUfx7m1OKGEbiwZ4PFAXMck9bu+K29m4/bnNxAHePqQb+eJRL9wYFdV65F5fO4Q20+DKQ2z0T2dWJLSeDR/CzASrdp6uSfIlvG5SuD5tdisAxv4D0pw3qxOcyHKRwX1hwqJLtpbAmXTQjtfOntsGAiVdW0fQRUH9xgMw/5OR4Bg38e204muTnrCM2i9jrkWHLX1nw51P1xjkYooMPa+ZgUOKFBJIzRCPEv7WUvy1nvQUBc229bAEcQ8CHICwKBm5gCYGO5JsiV3mahYH5VolO59nUK/nWqL8v8padGR3/kaodVMd13rGIlawouKDgCXSwAHFS1fFV5bBAmnU3w7W0vCLxVOmjhFlhqth1e7eGaWwGqIlzmQFGz4EoT2CjuAk4OdoUIVwX4/g0spX9CCCIH10wop9gwLEu9M+dPNoF4hyIJv8WoxHac5myEqOHMySoPhKDiwysbW/K+HwTB/mWIuIPym/vV7MBrxrqzmAdHdo0CJ/PakiFzg9LFFGo9Cgd2OZf5TXEz4Np2Exfuk8KI1/0XTnmjK6I5AGMTtB3WKnUuk6D+wVl2yw== jt@everycity.com_2020-01-16
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIlWYd21pTZPIKC4GI29ocESIN0g2cg3kkBJFYlj/9K7cCg2YHze4POE8Qxo6Tcu4QXY/5HTwmx/opQQUiFbWfAkFn5RGZ/SQnBOrFVbaWxwVXM8PFmqlVuNaEAcp3LI3CCA9kXkhtytjD7vH830CrcFu5xcSY8NugyXGEsRrO5pTmwbb38WppU9JEOSGMAMgENQSbj/UdwfXYphsArA/OlaDIRa5wRXRaamlLQYRDPjNpBPNT9ftTIRp7jevnmYY0gYerK0BCRewNFuOgtJv6H74/Sr63nYA4a0Eb1BPNIyKbrbjb2+KenZys7B5zYjk7o5ntpmdIERRZWFeP9h/CE6INe5rN9guCtHcmycX0v35TLnTOR1Y1rQGIagPPR5pm8hLOD824Yy/ypCOR4nkr7CgBZn+wId1W2262b9Mv5gv6CGGwh/86Kkbm/xEOloYHSP4hqCkQIivctwv9QKNNEwZmd7m4G50flQH9E61VVFioxwBzZiJrUGlA0sEoVllPIDiID9O7jPdsjgbO/a9mQeWN16Uhu1iiK7+nXg3pDJWyH0l4E2TLZ7J1mehItJzda43SR9pMF0KWDdiihhTtMWRj/oMezlr60dQqieMPwQnTlCq7PcwsBAugYwgoEsi5EKC2/4I79CHRnmi/rTyG0euGvwxtAun8adIY8xsGeQ== dw@everycity.com_2020-08-10
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPJOZdPMeFjCi5Xs7Uk6b9kX+BnxYBdfvMFB6+J4ahp98TUG/bGvySWgSY6yF0WFYOaMRmMfqL1mXIaOCWzoGwSZAsvZ2G2u2nG5qf5WIgnnESNgerMJfuGfRE1Ulhcw9RnkxfISD1bWYzKcWjzGwXUxYCgHL9s+2DqquLXyq6KYXaHHhKXlcBMAgIzVu54mDTf1cqpoYI2nSO8UL6K5EnXY0H3ujJavltR/zCBhIWRqEL7PYqQYOplNL54lwKvxOJfPH2Hy7BtzrmIV8wEnv0uPEUrPsa1G2U36C6H1p5XV4x1+u4jBZQGVaRQnuY8cyR3DIfc9FA2QXJHnThZVo40vbqCmrNkbqPf+2M6vLO+g2HXDaHCLZDEqZ2j6cRMwi0crwb9alKARWsZ/UT0kTV7OSRpFmEJqcFJQqWPm63P275KgqxoFRFqZWgx/SdyuVRKFKszB0SUmmbMYdyMH9JqAOGfeav0gP4hFzOp+8pLUjXLOzHC0o3LPHB1a4QXNlXTFMHH7pODu3/XEVo9D2cl8+3UteSUKjvY7FmPyBLDgjxJHZSuu61hXnLgkvZas/gzx/h7XILbE62zi1X5cBcAGD3Fv8VrO/vwjANrZimiWrJZsWzZZjSuHRSptjHo4bPrwkhpCe/Dou9J4b1s05kIiuRwlUsniHQRWijE6tYGw== jam@everycity.com_2020-11-06
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDymesF4IfJmryVZM7RIag2u3L31fRSI1VopkxzLWaLtTNxEH+cAGVI4xlXzEk1uNOKq059cn8/k+LYl9DEHERQ6sN2bQTDfbN04WHPdYOuXhQuZ9sAyADSs3w1LDK4KPJREzhSuIka9cVv6h8eD72hO6MHqj5iULj0Csg/5jU/F3vk/kCNBP64j47+PSSf26Lh8M032JP3P5fc4gzpKEeJUPSnJ+ltdQas+o9BO0qIBdeDGh+gwxtbhlLH3jlKbmU29+Avzg4mP+S6cRQ8vmR6cWJaBONIjVB8qLZtPZZ4hNawpu+WCtmoBh8rK9Lw/Wq1MP+PO9YgqBMQs7zXPSE92D+avUInKA16EJ3g44fFW2hE1tH4578MkeTLxNTEYF8cJ549o+REwbI1SdANH/NYbE8y25s82hVQ4EmUKEjV6gfTa2SjTVi0Rgye5d4IYgG7pkEXyLN/xiCKx+WFJXKPpvBdBBnA1Es2N3uz4TXCzLlHYTYIeIH2TZHI0oeKa0lu9mqT2tp8bJx7vaTe7wChYvMRzYGiiY4bthLhbykGwmdspk125ZQ9r2pAyjqIynsQ7dZsiGwsjEAiRtPW6qACvOd3NDqQiK4dyCmuwjT17J8pHYIkIeCFyPu+2hm0JYGYKQqptymfWXSnmezgtj+Jg2IKbxnYCrIIgmP3uruNQ== mic@everycity.com_2020-08-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEcH9T4Q5cUP9xIwW3tGizV8Mj7M8nuQbjOJRzY67FhPcGb9wuGi96waLUxMgtzObXx/osBdxHGhRM+olOxYV0bygbn+1plvd7DSKIBkZjLGLdKdS+5ahCPaEYtEclpJ8PdloskR9uRv+iEBU5OtRt5G3OmE/l6mjzCRYmw9egUSjLd6Dejrat/c7MMiT8uUVvHfNStUsXwJIkyY1kUbcDwu7TlJE3Wc6fTHDcw/rdt8OgIQ6ibklHsWsYYU8Mwg8N8+4v5avXtn+L1t91MCAIuNSbIQWl7UYXM+M8a2sfHIw1ApP4fw0ZK/MkUij0UsZkpLxtWFaRChLlItjTl05/G6Xpa+vrTGE/ACkonppb5wTbnsIiaScznEp6FrLgYMhLVLhqbfs8wyg0hsnUuoox/pKad04vTYfZKf7NqucvSP1szrv2gjSJipZQ4M7hx60Au8svAV0AkRMgmfL0EXudEPWziPa3NFLydWLxaFZ+3tt/yh+3HCFKeZVxsj5o1E5jttzih212q37HIWP8QNgAklwdBT42H3cb4YKfC+ohn9F/NtruJ8DQIrgfVtQ5VgdZUKXjxMWD/NvCwqiEUZ/WIrg+gNnznILHZGDjjiRZGsgYqjJIiyTEEP7yyvjtltUqC8nQ05jfFPjMEq+YKsF+YW3UX6a9Ku6sOOjw+iBJlw== ob@everycity.com_2020-08-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6+TEqyjPWcZMbXV3g7Eip66xNB8cMohOdZ7OEdbEQf08fuU2wG1QVKgIKbvy9tHo6UyZsgKA5ecRTmkPFbdv0wEPKG33jhnMbhgFHH5KcyFf6VO9tZP8YPrtjcasX2tz0noBdOYkcjAMIS1FG6Y83w5+cpb6Djny2CwgUqy4yJ1zWP7lJRA3QrWkZB5yC/ArS8LlocJBiI1m7pC1fLCcWtCJTy+OwBB/abdN1uSJz9ThvP4LBnAb81UZnZCkcdgHT5qBoZN0foDFlV6omIB1o+n0YlkhslGbE8Rfw5/99biB/h75dcao+hcCO8+uXSenZYiZrEpl/dIlh+HTM/HFF7PhWgbgpIrwkznEq69vOVl0xssabw7HXh8rNt8tAg6HJy5W6/KaiUZSua0wJjwMF4sYvqtHrRv8kWk+JsgqVs8ETOvCAiM9itquYyNxjajmhbCbFqTZhxo39IhtDps9FBjB7YDzkI7/m81yQs+QgWUrBy1bN+WwS33bXE6mKPiN7lp0Nm5KgioeVh18JX4QzQEGLmNsqWhoZcsTlG8gYkuHxexnls60wgpyvXuXbhN5U5tfn3hlI5nW6rAgv+j4lMh99bfYxbjpA29iCqcmVoPDYB5m3pxD74IdjJp2cAP66Ft/5Qz8I5XXr8zM2EN9Hv+OBksZVGvikkLc2vQXlzw== fmj@everycity.com_2020-08-25
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3TgPRr1BoL5YtCcG32JZuDOfuQF9WU4rGUqZ4IrPhX3l5jf5GM6xxE0jVh3qjdUY1A41a+8Ir61duabY4AsWcfed3ul4cVGG7k84eY9T83P7m65ucV3wCJOo3J07HbwCHJi7aD3imbk0Tb22+0dpsylQG+Vb9VH7V2QHoQYV7E/lZQv/dmms50AYkEH69GFxRJe4LjEPs/vXmUhATy8S9cIXrKsr4mfROTx4+2wcU6v8f9EsIb4V3TpMJpUY73Cwrf1AUnAWMNv7okPBJyY6esGGwu6ToPXTGB/BMrE+1Wqtw3YR5KXEZ1cH3ncDsjIhsshj1bmBFV3DVnHyvrpbjNyhjNuMtccvCgaPwdXJy7HA6j8pZH0StqvYubnauT8vjDoNPq4grnfCJ//GCf4vHNECXZ9qWuFYFE5c+e6fwGsAPc2EDZjwkfxWMmZZ0RRJPDJrtpCT8I92qXJHAEavMAhVunlN1GqY4FngUPiiqoefGYUc+xm7S1s7GXvex1VLQn5RoeyJhcGr/o3Z/fWC8QaZEj5BS1kaueZTgfcpFxUOKCwJzYyyYqJoWz12LeF8G30O6uafh1nyEJKNhCTQBbehSYmJQ/RxXgzLVIPN2GJKaq1Gt+NHGakvlFUd5uf+86lF5Q8w8+3IRpqaiuBfSab8xLVvUWMdhsIpjUKx5qw== ame@everycity.com_2020-06-10
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDjywIPDttK9ajq7admlYCE/qaVQZvykSvXikkiDazcu1V3uK7E7uqvAGGTpuRRHRZ0l1sCEKWt4OMU88t/6szWW7aHy9FYX66sEY1r9csY6qWlktvwHf24TruWnWFf8KFsHG6gZKZZ8TQW25xMCmfnhTPa9I5GzyZzZ8m1ZcIflsXexCLd2G7QbNvw+YvzE/txtdSPLQj4F7YEAfm4Uu4KXnbE/tsVbg8WK3SStVysfGzG2WI7iashntB3x6HszavNtaF1pnLo/4HLs28+6ZyTS9CDqEBqLtvIGctcTXMc1RNQF9Fujw8fhFWdpy725MVPHH6cAEicnUSsd3tcV3xBM144oyHtj72/6GgzCnMNNVk1UoWc8fOiXXH0Spd/9vxlpeCVKLXLJl968ZHFN9sgjU9X4GVPrJrEEzUV5PyG1QdND7XEJamnF2r8aQnaxtoP1bQzwKVXA5oo37DQ4G0fL53i/VSIsCN75ffQtlRKZIwinWj9u9BTFgUVi/y1TtUmc/bwvpCI4SGt2ZfQsVVafGkRQYVDU/DDQzGq0gozI+RgeOUaXYEUxFZgpslBdxNdxN1IFLKIc0osYTdFs9ieKDS/Lo84kbzdQK00/NW6jAEbA5uW6fLSph4y8/3+c1ysktSd3uzgX4X+pKMeu99FvB/3dtGL488SFVYce15Slw== hb@everycity.com_2020-08-31
    
