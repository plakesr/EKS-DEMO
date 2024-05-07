resource "aws_eks_addon" "example" {
  for_each      = toset(["vpc-cni", "kube-proxy", "aws-ebs-csi-driver"])
  cluster_name  = aws_eks_cluster.example.name
  addon_name    = each.value
  service_account_role_arn = aws_iam_role.aws-node.arn
}