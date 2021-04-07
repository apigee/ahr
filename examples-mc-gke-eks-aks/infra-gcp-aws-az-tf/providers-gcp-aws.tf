provider "google" {
  project = var.gcp_project_id
}



provider "aws" {
  region = var.aws_region
}
