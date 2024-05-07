provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Environment = "Test"
      Service     = "K8S"
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.example.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.example.name]
    command     = "aws"
  }
}
