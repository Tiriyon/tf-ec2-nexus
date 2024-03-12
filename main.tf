provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "allow_ssh"
  }
}

resource "aws_instance" "ubuntu" {
  ami           = "ami-0a0aadde3561fdc1e"
  instance_type = "t2.micro"

  key_name = aws_key_pair.nexusKey.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

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
