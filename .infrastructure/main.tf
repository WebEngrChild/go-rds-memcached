provider "aws" {
  region = "ap-northeast-1"
}

# ------------------------------------------------------------#
# VPC
# ------------------------------------------------------------#
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "handson"
  }
}

# ------------------------------------------------------------#
# Subnet Public
# ------------------------------------------------------------#
resource "aws_subnet" "public_1a" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = aws_vpc.main.id

  # Subnetを作成するAZ
  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "handson-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "handson-public-1c"
  }
}

resource "aws_subnet" "public_1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"

  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "handson-public-1d"
  }
}

# ------------------------------------------------------------#
# Subnets Private
# ------------------------------------------------------------#
resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.10.0/24"

  tags = {
    Name = "handson-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.20.0/24"

  tags = {
    Name = "handson-private-1c"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.30.0/24"

  tags = {
    Name = "handson-private-1d"
  }
}

# ------------------------------------------------------------#
# Internet Gateway
# ------------------------------------------------------------#
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson"
  }
}

# ------------------------------------------------------------#
# Elasti IP
# ------------------------------------------------------------#
resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1a"
  }
}

resource "aws_eip" "nat_1c" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1c"
  }
}

resource "aws_eip" "nat_1d" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1d"
  }
}

# ------------------------------------------------------------#
# NAT Gateway
# ------------------------------------------------------------#
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id # NAT Gatewayを配置するSubnetを指定
  allocation_id = aws_eip.nat_1a.id       # 紐付けるElasti IP

  tags = {
    Name = "handson-1a"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id

  tags = {
    Name = "handson-1c"
  }
}

resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = aws_subnet.public_1d.id
  allocation_id = aws_eip.nat_1d.id

  tags = {
    Name = "handson-1d"
  }
}

# ------------------------------------------------------------#
# Route Table Public
# ------------------------------------------------------------#
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-public"
  }
}

# ------------------------------------------------------------#
# Route Public
# ------------------------------------------------------------#
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# ------------------------------------------------------------#
# Association Public
# ------------------------------------------------------------#
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------#
# Route Table Private
# ------------------------------------------------------------#
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1c"
  }
}

resource "aws_route_table" "private_1d" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1d"
  }
}

# ------------------------------------------------------------#
# Route Private
# ------------------------------------------------------------#
resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1c.id
}

resource "aws_route" "private_1d" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1d.id
  nat_gateway_id         = aws_nat_gateway.nat_1d.id
}

# ------------------------------------------------------------#
# Association Private
# ------------------------------------------------------------#
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private_1d.id
}

# ------------------------------------------------------------#
# SecurityGroup ALB
# ------------------------------------------------------------#
resource "aws_security_group" "alb" {
  name        = "handson-alb"
  description = "handson alb"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "handson-alb"
  }
}

# ------------------------------------------------------------#
# SecurityGroup Rule
# ------------------------------------------------------------#
resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# ------------------------------------------------------------#
# ALB
# ------------------------------------------------------------#
resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = "handson"

  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public_1a.id, aws_subnet.public_1c.id, aws_subnet.public_1d.id]
}

# ------------------------------------------------------------#
# ALB　Listener
# ------------------------------------------------------------#
resource "aws_lb_listener" "main" {
  # HTTPでのアクセスを受け付ける
  port     = 80
  protocol = "HTTP"

  # ALBのarnを指定します。
  load_balancer_arn = aws_lb.main.arn

  # "ok" という固定レスポンスを設定する
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
  family = "handson"

  # データプレーンの選択
  requires_compatibilities = ["FARGATE"]

  # ECSタスクが使用可能なリソースの上限
  # タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  cpu    = "256"
  memory = "512"

  # ECSタスクのネットワークドライバ
  # Fargateを使用する場合は"awsvpc"決め打ち
  network_mode = "awsvpc"

  # 起動するコンテナの定義
  container_definitions = <<EOL
[
  {
    "name": "go",
    "image": "543494928176.dkr.ecr.ap-northeast-1.amazonaws.com/go-dev-repo:latest",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "secrets": [
      {
        "name": "ENV_FILE",
        "valueFrom": "arn:aws:ssm:ap-northeast-1:543494928176:parameter/env"
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

  # IAMロールのARNを指定
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn
}

# ------------------------------------------------------------#
# ECS Cluster
# ------------------------------------------------------------#
resource "aws_ecs_cluster" "main" {
  name = "handson"
}

# ------------------------------------------------------------#
# ELB Target Group
# ------------------------------------------------------------#
resource "aws_lb_target_group" "main" {
  name = "handson"

  # ターゲットグループを作成するVPC
  vpc_id = aws_vpc.main.id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  # コンテナへの死活監視設定
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
  # ルールを追加するリスナー
  listener_arn = aws_lb_listener.main.arn

  # 受け取ったトラフィックをターゲットグループへ受け渡す
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  # ターゲットグループへ受け渡すトラフィックの条件
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
  name        = "handson-ecs"
  description = "handson ecs"

  # セキュリティグループを配置するVPC
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-ecs"
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

  # TCPでの80ポートへのアクセスを許可する
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"

  # 同一VPC内からのアクセスのみ許可
  cidr_blocks = ["10.0.0.0/16"]
}

# ------------------------------------------------------------#
# ECS Service
# ------------------------------------------------------------#
resource "aws_ecs_service" "main" {
  name = "handson"

  # 依存関係の記述
  depends_on = [aws_lb_listener_rule.main]

  # 当該ECSサービスを配置するECSクラスターの指定
  cluster = aws_ecs_cluster.main.name

  # データプレーンとしてFargateを使用する
  launch_type = "FARGATE"

  # ECSタスクの起動数を定義
  desired_count = 1

  # 起動するECSタスクのタスク定義
  task_definition = aws_ecs_task_definition.main.arn

  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    # タスクの起動を許可するサブネット
    subnets = [aws_subnet.private_1a.id, aws_subnet.private_1c.id, aws_subnet.private_1d.id]
    # タスクに紐付けるセキュリティグループ
    security_groups = [aws_security_group.ecs.id]
  }

  # ECSタスクの起動後に紐付けるELBターゲットグループ
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
  name = "ecs_task_execution_role"

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
  name        = "ecs_task_execution_policy"
  path        = "/"
  description = "ECS task execution policy"

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
  name = "task_role"

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
  name        = "ssm_parameter_store_policy"
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
# RDS parameter group
# ------------------------------------------------------------#
resource "aws_db_parameter_group" "handson" {
  name   = "mysql-parameter-group"
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
    Name = "aws_db_parameter_group"
  }
}

# ------------------------------------------------------------#
# RDS option group
# ------------------------------------------------------------#
resource "aws_db_option_group" "handson" {
  name                     = "handson"
  option_group_description = "handson option group"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = {
    Name = "aws_db_option_group"
  }
}

# ------------------------------------------------------------#
# RDS subnet group
# ------------------------------------------------------------#
resource "aws_db_subnet_group" "handson" {
  name = "handson"
  subnet_ids = [
    aws_subnet.private_1c.id,
    aws_subnet.private_1d.id
  ]

  tags = {
    Name = "aws_db_subnet_group"
  }
}

# ------------------------------------------------------------#
# RDS Security Group
# ------------------------------------------------------------#
resource "aws_security_group" "rds" {
  name        = "rds_security_group"
  description = "Allow inbound traffic on port 3306"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "aws_security_group"
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

resource "aws_db_instance" "handson" {
  engine         = "mysql"
  engine_version = "8.0"

  identifier = "handson"

  username = "admin"
  password = random_string.db_password.result

  skip_final_snapshot = true

  instance_class = "db.t2.micro"

  storage_type      = "gp2"
  allocated_storage = 20
  storage_encrypted = false

  multi_az               = false
  availability_zone      = "ap-northeast-1d"
  db_subnet_group_name   = aws_db_subnet_group.handson.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 3306

  parameter_group_name = aws_db_parameter_group.handson.name
  option_group_name    = aws_db_option_group.handson.name

  apply_immediately = true

  tags = {
    Name = "aws_db_instance"
  }
}

# ------------------------------------------------------------#
# Memcached Security Group
# ------------------------------------------------------------#
resource "aws_security_group" "memcached" {
  name        = "memcached_security_group"
  description = "Allow inbound traffic on port 11211"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "aws_security_group"
  }
}

resource "aws_security_group_rule" "memcached" {
  security_group_id        = aws_security_group.memcached.id
  type                     = "ingress"
  from_port                = 11211
  to_port                  = 11211
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# ------------------------------------------------------------#
# Memcached subnet group
# ------------------------------------------------------------#
resource "aws_elasticache_subnet_group" "memcached" {
  name = "memcached-subnet-group"
  subnet_ids = [
    aws_subnet.private_1c.id,
    aws_subnet.private_1d.id
  ]
}

# ------------------------------------------------------------#
# Memcached cluster
# ------------------------------------------------------------#
resource "aws_elasticache_cluster" "memcached" {
  cluster_id           = "memcached-cluster-202307"
  engine               = "memcached"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 2
  parameter_group_name = "default.memcached1.6"
  subnet_group_name    = aws_elasticache_subnet_group.memcached.name
  security_group_ids   = [aws_security_group.memcached.id]
}

# ------------------------------------------------------------#
# Bastion EC2 
# ------------------------------------------------------------#
resource "aws_security_group" "ssm" {
  name        = "ssm_security_group"
  description = "Security Group for SSM EC2 Instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "aws_security_group_ssm"
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
  cidr_blocks       = ["106.72.179.162/32"]
  security_group_id = aws_security_group.ssm.id
}

resource "aws_security_group_rule" "ssm_ingress_mysql" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["106.72.179.162/32"]
  security_group_id = aws_security_group.ssm.id
}

resource "aws_iam_role" "rds_access" {
  name = "RDSAccessRole"

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
  ami                         = "ami-0947c48ae0aaf6781"
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.rds_access.name
  subnet_id                   = aws_subnet.public_1d.id
  vpc_security_group_ids      = [aws_security_group.ssm.id]
  associate_public_ip_address = true
  key_name                    = "access_db"
  user_data                   = <<-EOF
            #!/bin/bash
            sudo systemctl enable amazon-ssm-agent
            sudo systemctl start amazon-ssm-agent
            EOF

  tags = {
    Name = "SSM EC2 Instance"
  }
}