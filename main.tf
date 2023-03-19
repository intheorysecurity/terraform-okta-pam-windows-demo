data "aws_ami" "windows_image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "oktapam_project" "windows_project" {
  name = "windows-project"
  create_server_users = true
}

resource "oktapam_server_enrollment_token" "enrollment_token" {
  project_name = oktapam_project.windows_project.name
  description = "ASA enrollment tokne for windows project"
}

resource "oktapam_group" "group_name" {
    name = "windows-team"
}

resource "oktapam_project_group" "project_group_assignment" {
  group_name = oktapam_group.group_name.name
  project_name = oktapam_project.windows_project.name
  server_access = true
  server_admin = true
  create_server_group = false
}

//create new Security group
resource "aws_security_group" "security_group" {
  name = "ASA Windows Security Group"
  ingress {
    from_port   = 4421
    to_port     = 4421
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
    Environment = var.aws_environment_tag
  }
}

//create EC2 instance
resource "aws_instance" "ec2_instance" {
  //ami             = var.aws_instance_ami
  ami             = data.aws_ami.windows_image.id
  instance_type   = var.aws_instance_type
  security_groups = [aws_security_group.security_group.name]
  user_data       = templatefile("./scripts/install-sftd.ps1", { enrollment_token = oktapam_server_enrollment_token.enrollment_token.token })
  tags = {
    Environment = var.aws_environment_tag,
    Name        = "ASA Windows Demo"
  }
}