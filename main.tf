
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
    set -eux

    # Update Ubuntu packages
    apt-get update -y
    apt-get install -y fontconfig openjdk-17-jre wget gnupg

    # Install Jenkins
    install -m 0755 -d /etc/apt/keyrings

    sudo mkdir -p /usr/share/keyrings

sudo curl -fsSL \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /usr/share/keyrings/jenkins-keyring.asc
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/" \
      > /etc/apt/sources.list.d/jenkins.list

    # Install Terraform repository
    wget -O- https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

   echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list

    # Install Jenkins and Terraform
    sudo apt update
    sudo apt install -y fontconfig openjdk-21-jre
    sudo apt install -y jenkins

    # Enable and start Jenkins
    systemctl enable jenkins
    systemctl start jenkins

    # Verify installations
    terraform --version
    java -version
    systemctl status jenkins --no-pager
  EOF

  tags = {
    Name = "Jenkins-Terraform-Server"
  }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}
