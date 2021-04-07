

variable "resource_group" { type = string }
variable "az_region" { type = string }

variable "az_vnet" { type = string }
variable "az_vnet_subnet" { type = string }


variable "az_vnet_cidr" { type = string }
variable "az_vnet_subnet_cidr" { type = string }

variable "az_gcp_lgw_ip1_name" { type = string }
variable "az_gcp_lgw_ip2_name" { type = string }

variable "az_gcp_lgw1_name" { type = string }
variable "az_gcp_lgw2_name" { type = string }

variable "az_gcp_vnet_gw_ip1_name" { type = string }
variable "az_gcp_vnet_gw_ip2_name" { type = string }

variable "az_vnet_gw" { type = string }
variable "az_vnet_gw_subnet_cidr" { type = string }

variable "az_local_gw1_name" { type = string }
variable "az_local_gw2_name" { type = string }


variable "az_vnet_gw_ip_name" { type = string }
variable "az_aws_vnet_gw_ip2_name" { type = string }

variable "az_username" { type = string }
variable "az_ssh_pub_key_file" { type = string }
