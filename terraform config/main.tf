provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

#data "aws_region" "current" {}

locals {
  rendered_policy = templatefile("${path.module}/modules/json-policy/kms-access-policy.json.tpl", {
    account_id     = data.aws_caller_identity.current.account_id
    region         = var.aws_region
    jenkinsiamrole = module.ec2_permissions.ec2iamrole_jenkins
    k8siamrole     = module.ec2_permissions.ec2iamrole_k8s
    ansibleiamrole = module.ec2_permissions.ec2iamrole_ansible

  })
  kms_policy = jsondecode(local.rendered_policy)
}

locals {
  rendered_jen_policy = templatefile("${path.module}/modules/json-policy/jenkins-perms.json.tpl", {
    account_id   = data.aws_caller_identity.current.account_id
    region       = var.aws_region
    kms_key_id   = module.zeus_kms.kms_key_id
    adminpassARN = module.zeus_secrets_manager.admin_user_secret_arn
    PATarn       = module.zeus_secrets_manager.github_PAT_secret_arn
    deployKeyArn = module.zeus_secrets_manager.github_deploy_key_arn
  })
  jenkins_policy = jsondecode(local.rendered_jen_policy)
}

locals {
  rendered_k8s_policy = templatefile("${path.module}/modules/json-policy/k8s-perms.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
    region     = var.aws_region
    kms_key_id = module.zeus_kms.kms_key_id
  })
  k8s_policy = jsondecode(local.rendered_k8s_policy)
}

locals {
  rendered_ans_policy = templatefile("${path.module}/modules/json-policy/ansible-perms.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
    region     = var.aws_region
    kms_key_id = module.zeus_kms.kms_key_id
  })
  ansible_policy = jsondecode(local.rendered_ans_policy)
}

locals {
  rendered_workerNode_policy = templatefile("${path.module}/modules/json-policy/worker-node-perms.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
    region     = var.aws_region
    kms_key_id = module.zeus_kms.kms_key_id
  })
  workerNode_policy = jsondecode(local.rendered_workerNode_policy)
}

locals {
  rendered_POD_policy = templatefile("${path.module}/modules/json-policy/webappPOD-policy.json.tpl", {
    account_id         = data.aws_caller_identity.current.account_id
    region             = var.aws_region
    db_admin_secretARN = module.zeus_secrets_manager.db_admin_secret_arn
    db_resource_id      = module.rds.db_resource_id
  })
  webappPOD_policy = jsondecode(local.rendered_POD_policy)
}




########################################################
#                         vpc
#########################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.15.0"

  cidr = var.vpc_cidr_block
  name = var.vpc_name

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, 4)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, 2)

  # This ensures that the dafault NACL for the VPC has rules only for ipv4

  default_network_acl_ingress = [
    {
      "action" : "allow",
      "cidr_block" : "0.0.0.0/0",
      "from_port" : 0,
      "protocol" : "-1",
      "rule_no" : 100,
      "to_port" : 0
    }
  ]

  default_network_acl_egress = [
    {
      "action" : "allow",
      "cidr_block" : "0.0.0.0/0",
      "from_port" : 0,
      "protocol" : "-1",
      "rule_no" : 100,
      "to_port" : 0
    }
  ]
  /*
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false
*/
  enable_ipv6 = false

  tags = var.vpc_tags

}

###########################################################
# Private subnet 0 and 1 tagging
###########################################################

module "private_subnet_tagging" {
  source = "./modules/tag-private-subnets"

  subnet_ids = slice(module.vpc.private_subnets, 0, 2)

}


###########################################################
# security groups
###########################################################

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id      = module.vpc.vpc_id
  cidr_blocks = module.vpc.private_subnets_cidr_blocks
  tags        = var.vpc_tags
}


###################################################
#                    KMS
###################################################

module "zeus_kms" {
  source = "./modules/kms"

  policy = local.kms_policy

  tags = var.vpc_tags

}
###################################################
# Secrets Manager
###################################################

module "zeus_secrets_manager" {
  source = "./modules/secrets_manager"

  tags       = var.vpc_tags
  kms_key_id = module.zeus_kms.kms_key_id

}

###################################################
# VPC Interface Endpoints
###################################################

module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  region             		    = var.aws_region
  vpc_id             		    = module.vpc.vpc_id
  subnet_ids         		    = module.vpc.private_subnets[0]
  vpc_endpt_sg_id_secretsM 	= [module.security_groups.endptsg_id]
  private_route_table_ids   =  module.vpc.private_route_table_ids

}

###################################################
# Github actions Access
###################################################

module "githubAssmaccess" {
  source = "./modules/github_actions"

  tags = var.vpc_tags

}

##################################################
# s3 logging
###################################################

module "s3-ssmlogs" {
  source = "./modules/s3-4ssmlogs"

  kms_key_id = module.zeus_kms.kms_key_id
  tags       = var.vpc_tags

}

###################################################  
# Session Manager Preferences
###################################################

module "ssm_preferences" {
  source = "./modules/ssm-preferences"

  kms_key_id  = module.zeus_kms.kms_key_id
  bucket_name = module.s3-ssmlogs.s3_bucket_name
  tags        = var.vpc_tags

  # Rectify issues with the existence of SSM-SessionManagerRunShell
  # aws ssm delete-document --name SSM-SessionManagerRunShell --region us-west-2
}

##############################################
#               ALB
##############################################
/*
module "zeus_load_balancer" {
  source  = "./modules/load-balancer"
 
  subnet_ids_public                 = module.vpc.public_subnets
  security_group_ids                = [module.security_groups.lbsg_id]
  vpc_id                            = module.vpc.vpc_id
  jenkins_autoscaling_group_name    = module.zeus_autoscaling_group.jenkins_autoscaling_group_name
  k8s_autoscaling_group_name        = module.zeus_autoscaling_group.k8s_autoscaling_group_name
  tags                              = var.vpc_tags
}
*/
##############################################
#   ec2 instance profile with permission
#############################################

module "ec2_permissions" {
  source = "./modules/ec2-permissions"

  jenkins_policy    = local.jenkins_policy
  k8s_policy        = local.k8s_policy
  ansible_policy    = local.ansible_policy
  workerNode_policy = local.workerNode_policy
  webappPOD_policy  = local.webappPOD_policy

  tags   = var.vpc_tags
  region = var.aws_region

}


##############################################
#   Launch template
#############################################

module "zeus_launch_template" {
  source = "./modules/launch-template"

  security_group_ids   = [module.security_groups.jksg_id, module.security_groups.k8ssg_id]
  instance_profile_arn = [module.ec2_permissions.ec2profileARN_jenkins, module.ec2_permissions.ec2profileARN_k8s, module.ec2_permissions.ec2profileARN_ansible]
  tags                 = var.vpc_tags

  depends_on = [
    #module.vpc_endpoints,
    module.nat
  ]
}

##############################################
#   Auto scaling group
#############################################

module "zeus_autoscaling_group" {
  source = "./modules/autoscaling-group"

  subnet_ids                 = slice(module.vpc.private_subnets, 0, 2)
  jenkins_launch_template_id = module.zeus_launch_template.jenkins_launch_template_id
  k8s_launch_template_id     = module.zeus_launch_template.k8s_launch_template_id
  ansible_launch_template_id = module.zeus_launch_template.ansible_launch_template_id
  #launch_template_version        = module.zeus_launch_template.launch_template_version
}

#################################################
#                   NAT
#################################################

module "nat" {
  source = "./modules/NAT"

  security_groups         = [module.security_groups.natsg_id]
  subnet_id_public        = module.vpc.public_subnets[0]
  subnet_id_private       = module.vpc.private_subnets[0]
  private_route_table_ids = module.vpc.private_route_table_ids
  cidr_blocks_private     = module.vpc.private_subnets_cidr_blocks
  #nat_ec2profile           = module.ec2_permissions.nat_ec2profile
  vpc_id = module.vpc.vpc_id
}

#################################################
#                   Relational Database
#################################################

module "rds" {
  source = "./modules/rds"

  db_admin_secret_string = module.zeus_secrets_manager.db_admin_secret_string
  rds_sg_id              = module.security_groups.rds_sg_id 
  subnet_id_private      = slice(module.vpc.private_subnets, 2, 4)
  tags                   = var.vpc_tags
}

