# ------------------------------------------------------------#
# Existing ECR
# ------------------------------------------------------------#
data "aws_ecr_repository" "existing" {
  name = "go-dev-repo"
}

# ------------------------------------------------------------#
# Existing SSM Parameter Store
# ------------------------------------------------------------#
data "aws_ssm_parameter" "existing" {
  name = "/env"
}

# ------------------------------------------------------------#
# Latest EC2 AMI
# ------------------------------------------------------------#
data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

