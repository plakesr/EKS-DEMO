data "aws_launch_template" "example" {
  name       = aws_launch_template.node-cluster.name
  depends_on = [aws_launch_template.node-cluster]
}


resource "aws_launch_template" "node-cluster" {
  image_id               = "ami-06f07a5fc3f98f999"
  instance_type          = "t3.small"
  name                   = "EKS-TEST-node-eks-launch-template"
  update_default_version = true

  #key_name = var.ec2_ssh_key

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      encrypted             = true
      delete_on_termination = true
      volume_size           = 30
      volume_type           = "gp3"
      kms_key_id            = aws_kms_key.example-1.arn

    }
  }


  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      Name = "eks-node-group-instance-name"
    })

  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    #security_groups             = [aws_security_group.eks_additional.id]
    # device_index = 0
  }

  #vpc_security_group_ids = [aws_security_group.eks_additional.id]
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", { CLUSTER_NAME = aws_eks_cluster.example.name, B64_CLUSTER_CA = aws_eks_cluster.example.certificate_authority[0].data, API_SERVER_URL = aws_eks_cluster.example.endpoint }))
}
