#!/bin/bash

# userdata for EKS worker nodes to properly configure Kubernetes applications on EC2 instances
# https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
# https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
# https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh#L97

/etc/eks/bootstrap.sh --apiserver-endpoint '${API_SERVER_URL}' --b64-cluster-ca '${B64_CLUSTER_CA}' '${CLUSTER_NAME}'

