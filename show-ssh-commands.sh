#!/bin/bash

terraform_output=$(mktemp)
trap "rm -f $temp_file" 0 2 3 15

terraform output --json > ${terraform_output}

master_hostname=$(cat ${terraform_output} | jq -r '.master_hostname.value')
master_ip=$(cat ${terraform_output} | jq -r '.master_ips.value[0]')

printf "\nssh everycity@%-30s # %s\n\n" ${master_ip} ${master_hostname}

for worker_hostname in $(cat ${terraform_output} | jq -r '.worker_ips.value | keys[]'); do
  worker_ip=$(cat ${terraform_output} | jq -r ".worker_ips.value[\"${worker_hostname}\"][0]")
  printf "ssh everycity@%-30s # %s\n" ${worker_ip} ${worker_hostname}
done

printf "\n"
