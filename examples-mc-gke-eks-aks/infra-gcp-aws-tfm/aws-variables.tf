
variable "aws_region" {
  type = string
}



variable "aws_zone" {
  type = string
}


variable "aws_vpc" {
  type = string
}


variable "aws_vpc_cidr" {
  type = string
}


variable aws_public_subnet { type = string }
variable aws_public_cidr_block { type = string }


variable "aws_vpn_gw_name" {
  type = string
}

variable "aws_gcp_customer_gw" {
  type = string
}

variable "aws_gcp_vpn_connection" {
  type = string
}

variable aws_zone_1 { type = string }




variable "aws_key_name" { type = string }
variable "aws_ssh_pub_key_file" { type = string }
variable "aws_image_id" { type = string }

