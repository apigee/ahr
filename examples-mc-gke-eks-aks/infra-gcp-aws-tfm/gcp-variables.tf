

variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "gcp_region" {
  type = string
}



variable "gcp_zone" {
  type = string
}


variable "gcp_vpc" {
  type = string
}


variable "gcp_vpc_cidr" {
  type = string
}

variable "gcp_vpc_subnet" {
  type = string
}


variable "gcp_vpc_subnet_cidr" {
  type = string
}

variable "gcp_aws_vpc_target_gw" {
  type = string
}

variable "gcp_aws_vpc_gw_name" {
  type = string
}


variable "gcp_aws_vpn_tunnel1" {
  type = string
}

variable "gcp_aws_vpn_tunnel2" { type = string }

variable "gcp_os_username" { type = string }
variable "gcp_ssh_pub_key_file" { type = string }
