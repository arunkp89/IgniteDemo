#!/bin/bash
terraform output|tr -d '[],=""'|tr '   ' '\n'|sed 's/controller-pip/[controlvms]/g'|sed 's/worker-pip/[datavms]/g'|tail -n +4 > ../Ansible/inventory/cluster
echo -e \n
echo "[all:vars]" >> ../Ansible/inventory/cluster
echo azure_lb_pip=`terraform output azure_lb_pip` >> ../Ansible/inventory/cluster
