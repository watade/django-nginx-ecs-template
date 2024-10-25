variable "db_name" {}
variable "db_user" {}
variable "db_password" {}

resource "aws_db_subnet_group" "django_ecs_db_subnet_group" {
  description = "Created from the RDS Management Console"
  subnet_ids  = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1c.id, aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1c.id]
}

resource "aws_db_instance" "postgres" {
  identifier             = "django-ecs-db"
  engine                 = "postgres"
  engine_version         = "16.1"
  instance_class         = "db.t3.micro"
  storage_type           = "gp2"
  allocated_storage      = 20
  max_allocated_storage  = 1000
  apply_immediately      = false
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  network_type           = "IPV4"
  db_subnet_group_name   = aws_db_subnet_group.django_ecs_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  storage_encrypted            = true
  copy_tags_to_snapshot        = true
  performance_insights_enabled = true
  skip_final_snapshot          = true
}
