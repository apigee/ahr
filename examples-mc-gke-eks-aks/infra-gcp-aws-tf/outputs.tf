output "gcp_jumpbox_ip" {
  value = module.gcp_and_aws_infra.gcp_jumpbox_ip
}
output "aws_jumpbox_ip" {
  value = module.gcp_and_aws_infra.aws_jumpbox_ip
}

