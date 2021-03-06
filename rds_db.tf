//https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

// creating private subnet for rds instance
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "rds-security-group" {
  name = "terraform-rds-sg"

  description = "RDS (terraform-managed)"
  vpc_id      = aws_default_vpc.default.id

//  # Only MySQL in
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_group.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds-football" {
  allocated_storage    = 10
  engine               = "mariadb"
  engine_version       = "10.5.12"
  instance_class       = "db.t2.micro"
  name                 = "football_betting"
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds-security-group.id]

  tags = {
    Name = "terraform-rds-football"
  }
}

// write RDS URL to a file in ansible directory so ansible can apply env vars
resource "local_file" "tf_ansible_vars" {
  content = <<-DOC
  # File generated by Terraform

  tf_rds_url: ${aws_db_instance.rds-football.address}
  DOC
  filename = "./ansible/tf_ansible_vars.yaml"
}

output "rds_URL" {
  value = aws_db_instance.rds-football.address
}