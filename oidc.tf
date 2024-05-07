data "tls_certificate" "name" {
  url = aws_eks_cluster.example.identity.0.oidc.0.issuer
}


#create openid procider to connect eks. EKS Openid url genrate by defult in aws.
resource "aws_iam_openid_connect_provider" "default" {
  url = aws_eks_cluster.example.identity.0.oidc.0.issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [data.tls_certificate.name.certificates[0].sha1_fingerprint]
}


#create policy to access aws resource.Which will sa "aws-node in kube-sytem ns"
data "aws_iam_policy_document" "example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.default.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.default.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws-node" {
 assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
 name = "aws-oidc-role"
}

#Assigning CNI policy to role.
resource "aws_iam_role_policy_attachment" "aws_node" {
  role       = aws_iam_role.aws-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
depends_on = [aws_iam_role.aws-node]
}

