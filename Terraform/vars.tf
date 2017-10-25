
variable "packet_auth_token" {
  description = "Your packet API key"
}

variable "packet_project_id" {
  description = "Packet Project ID"
}

variable "packet_facility" {
  description = "Packet facility: US East(ewr1), US West(sjc1), Tokyo (nrt1) or EU(ams1). Default: ewr1"
  default = "ewr1"
}

variable "openstack_controller_count" {
  description = "Number of controllers to deploy"
  default = "10"
}

variable "packet_controller_type" {
  description = "Instance type of OpenStack controller"
  default = "baremetal_1"
}

variable "cloud_ssh_public_key_path" {
  description = "Path to your public SSH key path"
  default = "./packet-key.pub"
}

variable "cloud_ssh_key_path" {
  description = "Path to your private SSH key for the project"
  default = "./packet-key"
}

variable "create_dns" {
  description = "If set to true, DNSSimple will be setup"
  default = false
}
