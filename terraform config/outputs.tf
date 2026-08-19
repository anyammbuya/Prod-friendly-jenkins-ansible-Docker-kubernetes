/*
output "jenkins_subnet_id" {
  description = "Public IP of Jenkins server"
  value       = module.ec2_instances.jenkins_subnet_id
}

output "jenkins_instance_id" {
  description = "id of Jenkins server ec2 instance"
  value       = module.ec2_instances.jenkins_instance_id
}

output "jenkins_server_ip" {
  description = "Public IP of Jenkins server"
  value       = module.ec2_instances.jenkins_server_ip
}

output "tomcat_server_ip" {
  description = "Public IP of Jenkins server"
  value       = module.ec2_instances.tomcat_server_ip
}

*/

output "valkey_serverless_endpoint" {
  description = "access point id"
  value       = module.valkey.valkey_serverless_endpoint             
}

output "primary_db_address" {
  description = "access point id"
  value       = module.rds.primary_db_address             
}

output "replica_db_address" {
  description = "access point id"
  value       = module.rds.replica_db_address             
}

output "lb_dns_name" {
  description = "DNS name of lb"
  value       = module.zeus_load_balancer.lb_dns_name
}
