###########################################################
# Load balancer security group
###########################################################

resource "aws_security_group" "lbsg" {
  name        = "lbsg"
  description = "Security group to allow traffic inbound over http/https"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  tags = var.tags 
}

#################################################
# Security Group (Jenkins only)
########################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow Jenkins UI"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lbsg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags 
}

#################################################
# Security Group (k8s)
########################################
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 9000
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags 
}


##########################################################
# NAT Instance Security Group
#########################################################
resource "aws_security_group" "nat_sg" {
  name        = "nat-instance-sg"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTP/HTTPS from private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }
  # allow from this security group to this security group
  ingress {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      self      = true
    }
  
  # Allow SSH for management (restrict this in production!)

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }


  tags = var.tags
}

##################################################
# Security Group (secrets manager endpoint)
####################################################


resource "aws_security_group" "secretsmanager_endpoint_sg" {
  name        = "secretsmanager_endpoint_sg"
  description = "Security group for Secrets Manager VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id, aws_security_group.k8s_sg.id]
  }

  egress = []

  tags = var.tags
}

##################################################
# Security Group (RDS MySQL)
####################################################

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow MySQL from Tomcat"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = var.tags
}