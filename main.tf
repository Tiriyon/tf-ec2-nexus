provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_instance" "ubuntu" {
  ami           = "ami-0d940f23d527c3ab1"
  instance_type = "t2.medium"

  key_name = aws_key_pair.nexusKey.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  user_data = file("nexus.sh")

  tags = {
    Name = "nexus"
  }
}

resource "aws_key_pair" "nexusKey" {
  key_name   = "nexusKey"
  public_key = file("nexusKey.pub")
}

output "instance_ip" {
  value = aws_instance.ubuntu.public_ip
}

