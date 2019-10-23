# Terraform to build Kubernetes HA in Azure  

# Prerequisites: 

The Kubernetes infrastructure on Azure is provisioned using the Terraform templates in this repo. You can use the instructions available in the below KB article to either install Terraform binary or run via Azure cloud shell.

```
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure
```
# Environment preparation:

* Clone the repo:
 In the machine that you have downloaded Terraform binary or in Azure cloud shell
 ```
 git clone https://github.com/arunkp89/IgniteDemo.git
 cd Terraform
 ```

* Create variables.tf file as per your requirement, these include the ResourceGroup name, Location, No.of control nodes and worker nodes. The default variable.tf file builds 3 Control nodes in an Availability set and 3 worker nodes in AV.

# Deploy Kubernetes HA Infrastructure

Once you have the variables setup run the below commands to deploy Kubernetes infrastructure in Azure.

```
terraform init
terraform plan
terraform apply
```

# What Infrastructure does it build:

- Creates a Resource Group
- Creates the network for Kubernetes cluster
- Deploys 3 control nodes in an Availability set behind a LoadBalancer
- Deploys 3 worker nodes in an Availabiltiy set
- Deploys a security group and configures port 22 and 6443 for inbound traffic.
- Creates Public IP address for each of the nodes and configures NSG accordingly.

# What's Next:
After you have successfully deployed the Kubernetes infrastructure using this Terraform template, you can use the Ansible playbooks in this repo to configure Kubernetes control and worker plane.

****Note****
These templates are only for Demo and should not be considered Production ready.
