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