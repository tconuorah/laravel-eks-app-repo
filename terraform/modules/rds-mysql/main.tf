resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "RDS MySQL security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group]
  }

  # Managed EKS node groups may use AWS-managed security groups instead of the
  # custom node security group we create in Terraform, but their traffic still
  # originates from the app subnets.
  dynamic "ingress" {
    for_each = length(var.app_cidr_blocks) > 0 ? [var.app_cidr_blocks] : []

    content {
      description = "MySQL from EKS app subnets"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ingress.value
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db-sg"
  })
}

resource "aws_db_instance" "this" {
  identifier                = "${var.name}-mysql"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = var.db_instance_class
  allocated_storage         = 20
  storage_type              = "gp3"
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = var.db_password
  port                      = 3306
  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.db.id]
  publicly_accessible       = false
  multi_az                  = true
  backup_retention_period   = 7
  deletion_protection       = false
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.name}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm-ss", timestamp())}"
  apply_immediately         = false

  tags = merge(var.tags, {
    Name = "${var.name}-mysql"
  })
}
