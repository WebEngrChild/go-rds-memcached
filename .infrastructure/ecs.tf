# ------------------------------------------------------------#
# ALB
# ------------------------------------------------------------#
resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = var.project

  security_groups = [aws_security_group.alb.id]
  subnets         = values(aws_subnet.public)[*].id
}

# ------------------------------------------------------------#
# ALB　Listener
# ------------------------------------------------------------#
resource "aws_lb_listener" "main" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.main.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

# ------------------------------------------------------------#
# Task Definition
# ------------------------------------------------------------#
resource "aws_ecs_task_definition" "main" {
  family                   = var.project
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  container_definitions    = <<EOL
[
  {
    "name": "go",
    "image": "${data.aws_ecr_repository.existing.repository_url}:latest",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "secrets": [
      {
        "name": "ENV_FILE",
        "valueFrom": "${data.aws_ssm_parameter.existing.arn}"
      }
    ],
    "command": ["/bin/sh", "-c", "printenv ENV_FILE > .env && ./main"],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group" : "${aws_cloudwatch_log_group.ecs_logs.name}",
        "awslogs-region": "ap-northeast-1",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:8080/ || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 10
    }
  }
]
EOL

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn
}

# ------------------------------------------------------------#
# ECS Cluster
# ------------------------------------------------------------#
resource "aws_ecs_cluster" "main" {
  name = var.project
}

# ------------------------------------------------------------#
# ELB Target Group
# ------------------------------------------------------------#
resource "aws_lb_target_group" "main" {
  name        = var.project
  vpc_id      = aws_vpc.main.id
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port     = 8080
    path     = "/"
    protocol = "HTTP"
  }
}

# ------------------------------------------------------------#
# ALB Listener Rule
# ------------------------------------------------------------#
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# ------------------------------------------------------------#
# ECS SecurityGroup
# ------------------------------------------------------------#
resource "aws_security_group" "ecs" {
  name        = format("%s-ecs", var.project)
  description = format("%s-ecs", var.project)
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = format("%s-ecs", var.project)
  }
}

# ------------------------------------------------------------#
# ECS Security Group Egress rule
# ------------------------------------------------------------#
resource "aws_security_group_rule" "ecs_egress" {
  security_group_id = aws_security_group.ecs.id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# ------------------------------------------------------------#
# ECS Security Group Ingress rule
# ------------------------------------------------------------#
resource "aws_security_group_rule" "ecs_ingress" {
  security_group_id = aws_security_group.ecs.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
}

# ------------------------------------------------------------#
# ECS Service
# ------------------------------------------------------------#
resource "aws_ecs_service" "main" {
  name            = var.project
  depends_on      = [aws_lb_listener_rule.main]
  cluster         = aws_ecs_cluster.main.name
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.main.arn

  network_configuration {
    subnets         = values(aws_subnet.private)[*].id
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "go"
    container_port   = 8080
  }
}

# ------------------------------------------------------------#
# Task Execution Role
# ------------------------------------------------------------#
resource "aws_iam_role" "ecs_task_execution_role" {
  name = format("%s-%s-ecs_task_execution_role", var.environment, var.project)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# ------------------------------------------------------------#
# Association Private
# ------------------------------------------------------------#
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = format("%s-%s-ecs_task_execution_policy", var.environment, var.project)
  path        = "/"
  description = format("%s-ecs-task-execution-policy", var.project)

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:StartTask",
        "ecs:StopTask",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:GetParameters"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# ------------------------------------------------------------#
# Task Policy Attachment
# ------------------------------------------------------------#
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

# ------------------------------------------------------------#
# Task Role
# ------------------------------------------------------------#
resource "aws_iam_role" "task_role" {
  name = var.project

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# ------------------------------------------------------------#
# SSM parameter store policy
# ------------------------------------------------------------#
resource "aws_iam_policy" "ssm_parameter_store_policy" {
  name        = var.project
  description = "Allow access to SSM Parameter Store"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:GetParameters",
      "Resource": "*"
    }
  ]
}
EOF
}

# ------------------------------------------------------------#
# SSM parameter store policy attachment
# ------------------------------------------------------------#
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.ssm_parameter_store_policy.arn
}

# ------------------------------------------------------------#
# CloudWatch Logs Group
# ------------------------------------------------------------#
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/handson"
  retention_in_days = 14
}

# ------------------------------------------------------------#
# OutPut
# ------------------------------------------------------------#
output "alb_dns" {
  value       = aws_lb.main.dns_name
  description = "DNS name"
}