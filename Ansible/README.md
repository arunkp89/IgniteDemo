# Ansible Playbooks to setup Kubernetes HA in Azure  

The playbooks are mainly inspired by Kubeadm documentation and other ansible tentatives on github.


# Prerequisites: 

The Kubernetes infrastructure on Azure is provisioned using the Terraform templates in this repo. Once you have the setup the infrastructure, you can run the playbooks to install/configure Kubernetes cluster in HA.
On your manager machine install python pip, you can also use Azure CLI, which has Ansible pre-installed in it.
```
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum install python-pip
```
# Install Ansible on your Ansible manager machine

* You can do: 
```
pip install ansible[azure]
```

# Environment preparation:

* Clone the repo:
 In the machine that you want to use as ansible manager (can be your laptop or any other machine that has ssh access to the target machines):
 ```
 git clone https://github.com/arunkp89/IgniteDemo.git
 cd Ansible
 ```

* Create inventory/cluster
Declare the VMs and other variables to be used.

# Install a highly available kubernetes using kubeadm

Once you have the inventory setup run the playbook to install Kubernetes on the nodes.

```
ansible-playbook -i inventory/cluster  playbooks/k8build.yaml
```

# What k8build.yaml does:

- Installs all the required packages in all the nodes.
- Installs and configures Docker
- Installing kubeadm, kubelet and kubectl
- Setup Kubernetes Masters
- Adds the nodes to the cluster
- Configures Pod Network in the K8 cluster.

****Note****
These Ansible playbooks are only for Demo and should not be considered Production ready.
