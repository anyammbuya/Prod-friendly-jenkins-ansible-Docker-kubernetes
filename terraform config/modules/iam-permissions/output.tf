
output "ec2iamrole_jenkins" {
  description = "IAM role name"
  value       = aws_iam_role.jenkins.name
}

output "ec2profileARN_jenkins" {
  description = "ec2 instance arn"
  value       = aws_iam_instance_profile.jenkins.arn
}

output "ec2iamrole_k8s" {
  description = "IAM role name"
  value       = aws_iam_role.k8s.name
}

output "ec2profileARN_k8s" {
  description = "ec2 instance arn"
  value       = aws_iam_instance_profile.k8s.arn
}

output "ec2iamrole_ansible" {
  description = "IAM role name"
  value       = aws_iam_role.ansible.name
}

output "ec2profileARN_ansible" {
  description = "ec2 instance arn"
  value       = aws_iam_instance_profile.ansible.arn
}



