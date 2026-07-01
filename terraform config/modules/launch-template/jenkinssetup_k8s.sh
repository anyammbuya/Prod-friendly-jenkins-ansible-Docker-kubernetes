#!/bin/bash
set -e

# ------------------------
# Update OS and install dependencies
# ------------------------
dnf upgrade -y || dnf update -y
dnf install -y wget git java-21-amazon-corretto awscli

# ------------------------
# Install Maven manually into /opt
# ------------------------
MAVEN_VERSION=3.9.11
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz

tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
mv apache-maven-${MAVEN_VERSION} maven
rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz

# ------------------------
# Set environment variables
# ------------------------
cat <<'EOF' >> /etc/profile.d/maven.sh
export M2_HOME=/opt/maven
export M2=/opt/maven/bin
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto.x86_64
export PATH=$M2_HOME/bin:$JAVA_HOME/bin:$PATH
EOF
source /etc/profile.d/maven.sh

# ------------------------
# Create Jenkins user and group
# ------------------------
if ! id -u jenkins >/dev/null 2>&1; then
    groupadd jenkins
    useradd -r -g jenkins -d /var/lib/jenkins -s /sbin/nologin jenkins
fi

# ------------------------
# Prepare Jenkins home
# ------------------------
rm -rf /var/lib/jenkins/*
mkdir -p /var/lib/jenkins/plugins
chown -R jenkins:jenkins /var/lib/jenkins
chmod 755 /var/lib/jenkins

# ------------------------
# Download latest Jenkins WAR (Jenkins 2.531)
# ------------------------
mkdir -p /usr/share/java
wget -O /usr/share/java/jenkins.war https://updates.jenkins-ci.org/latest/jenkins.war
chown jenkins:jenkins /usr/share/java/jenkins.war

# Global Variables 
# ------------------------
AWS_REGION="us-west-2"

# ------------------------
# Install Plugin Manager and plugins
# ------------------------
curl -L -o /opt/jenkins-plugin-manager.jar \
  https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.13.2/jenkins-plugin-manager-2.13.2.jar
chown jenkins:jenkins /opt/jenkins-plugin-manager.jar

mkdir -p /etc/jenkins
GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id github-token \
  --region "$AWS_REGION" \
  --query "SecretString" \
  --output text)

curl -H "Authorization: token $GITHUB_TOKEN" \
     -L \
     "https://raw.githubusercontent.com/KingstonLtd/manage-jenkins/main/plugins.txt" \
     -o /etc/jenkins/plugins.txt

java -jar /opt/jenkins-plugin-manager.jar \
  --plugin-file /etc/jenkins/plugins.txt \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --war /usr/share/java/jenkins.war \
  --clean-download-directory

# ------------------------
# Create update-jenkins-plugins.sh script
# ------------------------
cat <<'EOF' > /etc/jenkins/update-jenkins-plugins.sh
#!/bin/bash
set -e
echo "Stopping Jenkins..."
systemctl stop jenkins

GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id github-token \
  --region us-west-2 \
  --query SecretString \
  --output text)

curl -H "Authorization: token $GITHUB_TOKEN" \
     -L \
     "https://raw.githubusercontent.com/KingstonLtd/manage-jenkins/main/plugins.txt" \
     -o /etc/jenkins/plugins.txt

java -jar /opt/jenkins-plugin-manager.jar \
  --plugin-file /etc/jenkins/plugins.txt \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --war /usr/share/java/jenkins.war \
  --clean-download-directory

chown -R jenkins:jenkins /var/lib/jenkins
systemctl start jenkins
EOF
chmod +x /etc/jenkins/update-jenkins-plugins.sh

# --------------------------------------------------------------------------------------
# Set up Jenkins SSH for GitHub private repos
# We need the ssh key setup in order to be able to obtain web app files from a our repo
# -----------------------------------------------------------------------

mkdir -p /var/lib/jenkins/.ssh
chown jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh

ssh-keyscan github.com >> /var/lib/jenkins/.ssh/known_hosts

chown jenkins:jenkins /var/lib/jenkins/.ssh/known_hosts
chmod 644 /var/lib/jenkins/.ssh/known_hosts

#-----------------------------------------------------------------------------------------------------
# Download the jenkins.yaml file from github so that Jenkins will read automatically when JCasC starts
# -------------------------------------------------------------------------------------------------------

# Download the latest jenkins.yml from repo
curl -H "Authorization: token $GITHUB_TOKEN" \
     -L \
     "https://raw.githubusercontent.com/KingstonLtd/manage-jenkins/main/jenkins.yaml" \
     -o /var/lib/jenkins/jenkins.yaml

echo "Waiting for jenkins.yaml to download"
until [ -f /var/lib/jenkins/jenkins.yaml ]; do sleep 2; done
chown jenkins:jenkins /var/lib/jenkins/jenkins.yaml

# ------------------------
# Set JCasC environment variable
# ------------------------
echo 'CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml' >>  /etc/environment 

# ------------------------
# Ensure /tmp has enough space
# ------------------------
mount -o remount,size=2G /tmp
grep -q '^tmpfs /tmp tmpfs' /etc/fstab || echo 'tmpfs /tmp tmpfs defaults,size=2G 0 0' | tee -a /etc/fstab

# ------------------------
# Create systemd service for Jenkins (WAR)
# ------------------------
cat <<EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins Daemon
After=network.target

[Service]
User=jenkins
Group=jenkins
Environment="JENKINS_HOME=/var/lib/jenkins"
Environment="CASC_RELOAD_TOKEN=$GITHUB_TOKEN"
ExecStart=/usr/bin/java -jar /usr/share/java/jenkins.war
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
#----------------------------------------------
# create the update-jenkins-config.sh file
#---------------------------------------------

cat <<'EOF' > /etc/jenkins/update-jenkins-config.sh
#!/bin/bash
set -e
echo "Updating JCasC YAML (hot reload)..."

JENKINS_URL="http://localhost:8080"

# Get PAT from Secrets Manager
TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id github-token \
  --region us-west-2 \
  --query SecretString \
  --output text)

# Download the latest jenkins.yml from repo
curl -H "Authorization: token $TOKEN" \
     -L \
     "https://raw.githubusercontent.com/KingstonLtd/manage-jenkins/main/jenkins.yaml" \
     -o /var/lib/jenkins/jenkins.yaml

echo "Waiting for jenkins.yaml to download"
sleep 15

chown jenkins:jenkins /var/lib/jenkins/jenkins.yaml

curl -X POST "$JENKINS_URL/reload-configuration-as-code/?casc-reload-token=$TOKEN"
EOF

chmod +x /etc/jenkins/update-jenkins-config.sh

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

echo "Jenkins installation and WAR-based setup completed successfully."

# cat /var/log/cloud-init-output.log   see logs on ec2 running jenkins
# journalctl -u jenkins    see logs on jenkins application server