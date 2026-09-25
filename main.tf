
provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-security-group"
  description = "Allow SSH and Jenkins access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami                    = "ami-0f918f7e67a3323f0"
  instance_type          = "t2.medium"
  key_name               = "jenkins-key"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
   
#!/bin/bash
set -e

echo "Updating Jenkins signing key..."

sudo mkdir -p /usr/share/keyrings

sudo curl -fsSL \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /usr/share/keyrings/jenkins-keyring.asc

echo "Configuring Jenkins repository..."

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list

echo "Installing Java..."

sudo apt update
sudo apt install -y fontconfig openjdk-21-jre

echo "Installing Jenkins..."

sudo apt install -y jenkins

echo "Starting Jenkins..."

sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "Checking Jenkins status..."
sudo systemctl status jenkins --no-pager

echo "Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "Jenkins installation completed!"

  
sudo apt update
sudo apt install -y wget gpg ca-certificates

wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor \
  -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

sudo chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y terraform

terraform --version


