#Get IAM trust policy
resource "aws_iam_role" "node_role" {
  count              = var.create_node_group && var.create_node_group_iam_role ? 1 : 0
  name               = "eks-node-group-ar"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "example-node_group_policy" {
  for_each = var.create_node_group_iam_role && var.create_node_group ? concat([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]) : toset([])
  policy_arn = each.value
  role       = aws_iam_role.node_role[0].name
}

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "nodegrp-${local.cluster_name}"
  node_role_arn   = aws_iam_role.node_role[0].arn
  subnet_ids      = aws_subnet.private_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  launch_template {
    name    = data.aws_launch_template.example.name
    version = "1"
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example-node_group_policy,
  ]
}