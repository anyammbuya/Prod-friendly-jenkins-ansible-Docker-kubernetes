output "primary_db_resource_id" {
  value = aws_db_instance.zeus_mysql.resource_id
}

output  "replica_db_resource_id"{
  
  value = aws_db_instance.zeus_mysql_replica.resource_id
}


output "primary_db_address" {
  value = aws_db_instance.zeus_mysql.address
}

output "replica_db_address" {
  value = aws_db_instance.zeus_mysql_replica.address
}

