#!/bin/bash
terraform output|tr -d '[],=""'|tr '   ' '\n'|sed 's/controller-pip/[controlvms]/g'|sed 's/worker-pip/[datavms]/g'|tail -n +4 > ../Ansible/inventory/cluster
echo -e \n
echo "[all:vars]" >> ../Ansible/inventory/cluster
echo azure_lb_pip=`terraform output azure_lb_pip` >> ../Ansible/inventory/cluster
echo "ansible_connection=ssh" >> ../Ansible/inventory/cluster
echo "ansible_user=kuberoot" >> ../Ansible/inventory/cluster


#ansible_ssh_user=kuberoot
#ansible_ssh_private_key_file=/home/arun/clouddrive/.ssh/pkey.pem
