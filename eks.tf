#Get IAM trust policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com", "ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#Create Amazon EKS cluster IAM role with trust policy
resource "aws_iam_role" "example" {
  name               = "eks-cluster-test-ar"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

#Assign Amazon EKS managed policy (policy/AmazonEKSClusterPolicy)to role for operation or custom policy if any!
resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
# resource "aws_iam_role_policy_attachment" "example-AmazonEKSVPCResourceController" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
#   role       = aws_iam_role.example.name
# }

#Create EKS cluster
resource "aws_eks_cluster" "example" {
  name     = local.cluster_name
  role_arn = aws_iam_role.example.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    #security_group_ids      = 
    subnet_ids              = concat(aws_subnet.private_subnet[*].id, aws_subnet.public_subnet[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  kubernetes_network_config {
    service_ipv4_cidr = "192.168.0.0/16"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
  ]
}

#Addon Can be add as a - CoreDNS, VPC_CNI, Kube_Proxy, PodIdentity
