locals {
  public_subnet  = ["10.10.0.0/20", "10.10.16.0/20"]
  private_subnet = ["10.10.64.0/19", "10.10.96.0/19"]
  azs            = ["us-west-2a", "us-west-2b"]
  cluster_name   = "EKS-TEST-${random_string.suffix.result}"
  tags = {
    Name = "EKS-TEST"
  }
}
data "aws_caller_identity" "current" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
}