resource "aws_iam_role" "eks-iam-role" {
 name = "k8s-eks-iam-role"

 path = "/"

 assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-iam-role.name
}

resource "aws_eks_cluster" "k8s-eks" {
 name = "eks-cluster"
 role_arn = aws_iam_role.eks-iam-role.arn
 

 vpc_config {
  subnet_ids   =  [aws_subnet.main_vpc_public_subnet_1.id, aws_subnet.main_vpc_public_subnet_2.id]
 
}

 depends_on = [
  aws_iam_role.eks-iam-role,
 ]
}

resource "aws_iam_role" "workernodes" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
   Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
     Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
 }

 resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role    = aws_iam_role.workernodes.name
 }

 resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role    = aws_iam_role.workernodes.name
 }

 resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role    = aws_iam_role.workernodes.name
 }

 resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role    = aws_iam_role.workernodes.name
}
resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.k8s-eks.name
  node_group_name = "k8s-workernodes"
  node_role_arn  = aws_iam_role.workernodes.arn
  subnet_ids   = [aws_subnet.main_vpc_public_subnet_1.id, aws_subnet.main_vpc_public_subnet_2.id]
  instance_types = ["t3.micro"]
  tags = {
     Name = "k8s-workernodes"
}
  scaling_config {
   desired_size = 2
   max_size   = 3
   min_size   = 2
  }
   lifecycle {
    prevent_destroy = false
  }
   capacity_type = "ON_DEMAND"
   update_config {
     max_unavailable = 1
  }
 
  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
   aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "null_resource" "install_tools" {
  provisioner "local-exec" {
    command = <<EOT
    sudo apt-get update &&/
    sudo apt-get install -y ca-certificates curl
    sudo    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo mv ./kubectl /usr/local/bin/kubectl
    sudo chmod +x /usr/local/bin/kubectl

    aws eks --region ap-south-1 update-kubeconfig --name eks-cluster
    EOT
  }
    depends_on = [
     aws_eks_cluster.k8s-eks
     ]

}
