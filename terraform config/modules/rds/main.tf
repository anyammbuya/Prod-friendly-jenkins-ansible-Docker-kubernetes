resource "aws_db_instance" "zeus_mysql" {
  identifier                  = "zeus-db"
  engine                      = "mysql"
  engine_version              = "8.0.42"
  allow_major_version_upgrade = true
  apply_immediately           = true
  instance_class              = "db.t3.micro"
  storage_type                = "gp2"
  allocated_storage           = 20
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  multi_az                    = false
    
  db_name                     = "zeus_project_db"
  username                    = "admin"
  password                    = var.db_admin_secret_string
    
  skip_final_snapshot         = true
  publicly_accessible         = false
  vpc_security_group_ids      = [var.rds_sg_id]

  iam_database_authentication_enabled = true

  tags                                = var.tags
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "zeus-db-subnet-group"
  subnet_ids = var.subnet_id_private
}