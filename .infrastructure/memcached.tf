# ------------------------------------------------------------#
# Memcached Security Group
# ------------------------------------------------------------#
resource "aws_security_group" "memcached" {
  name        = format("%s-%s-aws-security-group", var.environment, var.project)
  description = "Allow inbound traffic on port 11211"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = format("%s-%s-aws-security-group", var.environment, var.project)
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
  name = format("%s-%s-memcached-subnet-group", var.environment, var.project)
  subnet_ids = [
    aws_subnet.private["1c"].id,
    aws_subnet.private["1d"].id,
  ]
}

# ------------------------------------------------------------#
# Memcached cluster
# ------------------------------------------------------------#
resource "aws_elasticache_cluster" "memcached" {
  cluster_id           = format("%s-%s-memcached-cluster", var.environment, var.project)
  engine               = "memcached"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 2
  parameter_group_name = "default.memcached1.6"
  subnet_group_name    = aws_elasticache_subnet_group.memcached.name
  security_group_ids   = [aws_security_group.memcached.id]
}

# ------------------------------------------------------------#
# OutPut
# ------------------------------------------------------------#
output "CACHE_HOST1" {
  value       = "${aws_elasticache_cluster.memcached.cache_nodes.0.address}:11211"
  description = "Cache cluster node 1 endpoint"
}

output "CACHE_HOST2" {
  value       = "${aws_elasticache_cluster.memcached.cache_nodes.1.address}:11211"
  description = "Cache cluster node 2 endpoint"
}
