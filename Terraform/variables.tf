variable "location" {
  default = "southcentralus"
}
variable "resource_group_name" {
  default = "kubernetesdemo"
}
variable "adress_prefix" {
  default = "10.240.0.0/24"
}
variable "port_ssh" {
  default = "22"
}
variable "port_apiserver" {
  default = "6443"
}
variable "count_controller" {
  default = "3"
}
variable "count_worker" {
  default = "3"
}
## These are the available parameters which are needed to deploy a 3X3 controlXworker infra