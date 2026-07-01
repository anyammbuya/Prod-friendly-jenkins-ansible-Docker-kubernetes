#!/bin/bash
set -e

echo "===== Updating system ====="
dnf update -y

# boto3/botocore enables ssm transport via the aws_ssm plugin
echo "===== Installing required packages ====="
dnf install -y \
  awscli \
  python3 \
  ansible \
  python3-boto3 \
  python3-botocore

# community.docker: Manage Docker containers remotely via SSM/ amazon.aws: install SSM, EC2, IAM modules
echo "===== Installing Ansible Collections ====="
ansible-galaxy collection install community.docker
ansible-galaxy collection install amazon.aws

# install the aws_ssm plugin
cd /tmp
dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm


# install Docker
dnf install docker -y

echo "===== Creating Ansible Admin and add him to docker group so he can execute docker commands ====="
useradd -m ansadmin   
groupadd ansible  
usermod -aG ansible ansadmin
usermod -aG docker ansadmin
#usermod -aG docker ssm-user

systemctl enable docker
systemctl start docker

echo "===== Creating Ansible directories ====="
mkdir -p /opt/ansible
mkdir -p /etc/ansible
mkdir -p /opt/docker

chown ansadmin:ansadmin /opt/docker

# create Dockerfile

cat <<'EOF' >> /opt/docker/Dockerfile
FROM tomcat:jre25-temurin-noble
RUN cp -r /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps
COPY ./*.war /usr/local/tomcat/webapps
EOF

chown -R ansadmin:ansadmin /opt/docker/

echo "===== Creating sample inventory ====="
cat << 'EOF' > /etc/ansible/inventory_aws_ec2.yml
plugin: aws_ec2
regions:
  - us-west-2

hostnames:
  - instance-id

filters:
  tag:SSMTag: ssmlinux

keyed_groups:
  - key: tags.Name
    prefix: ""
EOF

# Validate connectivity to host in the inventory_aws_ec2.yml file
# ansible-inventory -i aws_ec2.yml --graph

# Must login to dockerhub as root on the ansible-host for the playbook to push to dockerhub

echo "===== Creating sample playbook ====="
cat << 'EOF' > /etc/ansible/playbook.yml
- name: Build, push, and deploy Docker image
  hosts: all
  gather_facts: false

  vars:
    ansible_connection: aws_ssm
    ansible_aws_ssm_region: us-west-2
    ansible_aws_ssm_bucket_name: zeus-ec2ssm-logsbu

    image_name: anyammbuya/mywebapp
    image_tag: v1
    container_name: webapp_container
    app_port: 8082
    container_port: 8080
    war_local_path: /opt/docker/my-webapp.war
    war_s3_path: s3://zeus-ec2ssm-logsbu/artifacts/my-webapp.war

  tasks:

    # -----------------------------
    # Build & push Docker image
    # -----------------------------
    - block:
        - name: pull WAR
          raw: sudo aws s3 cp {{ war_s3_path }} {{ war_local_path }}

        - name: Build and tag Docker image
          raw: sudo docker build --pull -t {{ image_name }}:{{ image_tag }} -f /opt/docker/Dockerfile /opt/docker

        - name: Push Docker image to DockerHub
          raw: sudo docker push {{ image_name }}:{{ image_tag }}

      when: hostvars[inventory_hostname].tags.Name == "ansible-host"

    # -----------------------------
    # Deploy container on k8sBootstrapHost
    # -----------------------------
    - block:
        - name: Install AWS Load Balancer Controller
          raw: sudo /opt/albcontroller.sh

        - name: Wait for AWS Load Balancer Controller to be Ready
          raw: sudo kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=400s

        - name: Deploy my-webapp on k8s
          raw: sudo kubectl apply -f /opt/deployment.yml

        - name: Create a service for my-webapp
          raw: sudo kubectl apply -f /opt/service.yml

        - name: Create Ingress resource
          raw: sudo kubectl apply -f /opt/ingress.yml

        - name: Update deployment with new pods when the image gets updated in Dockerhub.
          raw: sudo kubectl rollout restart deployment.apps/webapp-deployment -n zeus-webapp

      when: hostvars[inventory_hostname].tags.Name == "k8sBootstrapHost"
EOF

chown -R ansadmin:ansadmin /etc/ansible/


echo "===== Setting hostname ====="
hostnamectl set-hostname ansible-host
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "===== Installation Complete ====="
echo "Test with: ansible all -m ping"
