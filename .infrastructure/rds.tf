# ------------------------------------------------------------#
# RDS parameter group
# ------------------------------------------------------------#
resource "aws_db_parameter_group" "main" {
  name   = var.project
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = {
    Name = format("%s-%s-aws-db-parameter-group", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# RDS option group
# ------------------------------------------------------------#
resource "aws_db_option_group" "main" {
  name                     = var.project
  option_group_description = var.project
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = {
    Name = format("%s-%s-aws-db-option-group", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# RDS subnet group
# ------------------------------------------------------------#
resource "aws_db_subnet_group" "main" {
  name = var.project
  subnet_ids = [
    aws_subnet.private["1c"].id,
    aws_subnet.private["1d"].id,
  ]

  tags = {
    Name = format("%s-%s-aws-db-subnet-group", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# RDS Security Group
# ------------------------------------------------------------#
resource "aws_security_group" "rds" {
  name        = format("%s-%s-aws-security-group-rds", var.environment, var.project)
  description = "Allow inbound traffic on port 3306"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-aws-security-group", var.environment, var.project)
  }
}

resource "aws_security_group_rule" "allow_ecs_mysql" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "allow_ec2_mysql" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssm.id
}

# ------------------------------------------------------------#
# RDS Instance
# ------------------------------------------------------------#
resource "random_string" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "main" {
  engine         = "mysql"
  engine_version = "8.0"

  identifier = var.project

  username = "admin"
  password = random_string.db_password.result

  skip_final_snapshot = true

  instance_class = "db.t3.medium"

  storage_type      = "gp2"
  allocated_storage = 20
  storage_encrypted = false

  multi_az               = false
  availability_zone      = "ap-northeast-1d"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 3306

  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = aws_db_option_group.main.name

  apply_immediately = true

  performance_insights_enabled = true

  tags = {
    Name = format("%s-%s-aws-db-instance", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# Bastion EC2
# ------------------------------------------------------------#
resource "aws_security_group" "ssm" {
  name        = format("%s-%s-aws-security-group-ssm", var.environment, var.project)
  description = "Security Group for SSM EC2 Instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-aws-security-group-ssm", var.environment, var.project)
  }
}

resource "aws_security_group_rule" "ssm_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssm.id
}

resource "aws_security_group_rule" "ssm_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks
  security_group_id = aws_security_group.ssm.id
}

resource "aws_security_group_rule" "ssm_ingress_mysql" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks
  security_group_id = aws_security_group.ssm.id
}

resource "aws_iam_role" "rds_access" {
  name = format("%s-%s-aws_iam_role-rds_access", var.environment, var.project)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_access" {
  name = "RDSPolicy"
  role = aws_iam_role.rds_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:*",
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed_policy_attach" {
  role       = aws_iam_role.rds_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "rds_access" {
  name = "RDSAccessProfile"
  role = aws_iam_role.rds_access.name
}

resource "aws_instance" "ssm" {
  ami                         = data.aws_ssm_parameter.ami.value
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.rds_access.name
  subnet_id                   = aws_subnet.public["1d"].id
  vpc_security_group_ids      = [aws_security_group.ssm.id]
  associate_public_ip_address = true
  key_name                    = "access_db"
  user_data                   = <<-EOF
            #!/bin/bash
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            EOF

  tags = {
    Name = format("%s-%s-aws-ssm-ec2-instance", var.environment, var.project)
  }
}

# ------------------------------------------------------------#
# OutPut
# ------------------------------------------------------------#
output "DB_USER" {
  value       = "admin"
  description = "Database username"
}

output "DB_PASS" {
  value       = random_string.db_password.result
  description = "Database password"
}

output "DB_HOST" {
  value       = aws_db_instance.main.address
  description = "Database endpoint"
}

output "DB_NAME" {
  value       = "golang"
  description = "Database name"
}

output "DB_PORT" {
  value       = aws_db_instance.main.port
  description = "Database port"
}

output "bastion_ec2_id" {
  value       = aws_instance.ssm.id
  description = "bastion ec2 id"
}