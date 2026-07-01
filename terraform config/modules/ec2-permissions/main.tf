
#############################################################################################
# -----------------------------------------
# IAM Role trust policy (assume role)
# -----------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# -----------------------------------------
# Jenkins IAM Role, Policy, and Instance Profile
# -----------------------------------------
resource "aws_iam_role" "jenkins" {
  name               = "ec2role-jenkins"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "jenkins" {
  name        = "ec2-jenkins-policy"
  description = "Allowed actions for Jenkins EC2 instance"
  policy      = jsonencode(var.jenkins_policy)
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "jenkins_attach" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins.arn
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins.name

  depends_on = [aws_iam_role_policy_attachment.jenkins_attach]
}

# -----------------------------------------
# k8sBootstrap IAM Role, Policy, and Instance Profile
# -----------------------------------------
resource "aws_iam_role" "k8s" {
  name               = "ec2role-k8s"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "k8s" {
  name        = "ec2-k8s-policy"
  description = "Allowed actions for k8s EC2 instance"
  policy      = jsonencode(var.k8s_policy)
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "k8s_attach" {
  role       = aws_iam_role.k8s.name
  policy_arn = aws_iam_policy.k8s.arn
}

resource "aws_iam_role_policy_attachment" "eksctl_managed_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ])

  role       = aws_iam_role.k8s.name
  policy_arn = each.value
}


resource "aws_iam_instance_profile" "k8s" {
  name = "k8s-ec2-profile"
  role = aws_iam_role.k8s.name

  depends_on = [
        aws_iam_role_policy_attachment.k8s_attach,
        aws_iam_role_policy_attachment.eksctl_managed_policies
  
  ]
}

# -----------------------------------------
# Ansible IAM Role, Policy, and Instance Profile
# -----------------------------------------
resource "aws_iam_role" "ansible" {
  name               = "ec2role-ansible"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "ansible" {
  name        = "ec2-ansible-policy"
  description = "Allowed actions for ansible EC2 instance"
  policy      = jsonencode(var.ansible_policy)
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "ansible_attach" {
  role       = aws_iam_role.ansible.name
  policy_arn = aws_iam_policy.ansible.arn
}

resource "aws_iam_instance_profile" "ansible" {
  name = "ansible-ec2-profile"
  role = aws_iam_role.ansible.name

  depends_on = [aws_iam_role_policy_attachment.ansible_attach]
}

# -----------------------------------------
# Kubernetes Worker Nodes IAM Role
# -----------------------------------------

resource "aws_iam_role" "workerNodeRole" {
  name               = "custom-node-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "workerNode" {
  name        = "workerNode-policy"
  description = "workerNode-policy"
  policy      = jsonencode(var.workerNode_policy)
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "node_managed_policies" {
   
   for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])

  role       = aws_iam_role.workerNodeRole.name
  policy_arn = each.value
  
}

resource "aws_iam_role_policy_attachment" "workerNode_attach" {
   role       = aws_iam_role.workerNodeRole.name
   policy_arn = aws_iam_policy.workerNode.arn
}

# --------------------------------------------------------------------------
# Kubernetes webapp Pod IAM Policy
# --------------------------------------------------------------------------

resource "aws_iam_policy" "web-app-pod-policy" {
  name        = "webappPOD-policy"
  description = "webappPOD-policy"
  policy      = jsonencode(var.webappPOD_policy)
  tags        = var.tags
}
/*
#-------- Added when using autoModeConfig: enable: true--------
#------ Creating an EKS Pod Identity ---------------------------

data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "webapp_pod_role" {
  name               = "webapp-pod-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy_attachment" "webapp_pod_policy" {
  role       = aws_iam_role.webapp_pod_role.name
  policy_arn = aws_iam_policy.web-app-pod-policy.arn
}
*/








