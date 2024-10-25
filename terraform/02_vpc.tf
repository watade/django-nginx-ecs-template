# variable "region" {}

# VPC
resource "aws_vpc" "django_ecs_vpc" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "django-ecs-vpc"
  }
}

# サブネット (パブリック×2, プライベート×2)
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.django_ecs_vpc.id
  cidr_block              = "172.16.0.0/20"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "django-ecs-public-subnet-1a"
  }
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id                  = aws_vpc.django_ecs_vpc.id
  cidr_block              = "172.16.16.0/20"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "django-ecs-public-subnet-1c"
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.django_ecs_vpc.id
  cidr_block        = "172.16.32.0/20"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "django-ecs-private-subnet-1a"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.django_ecs_vpc.id
  cidr_block        = "172.16.48.0/20"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "django-ecs-private-subnet-1c"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "django_ecs_gw" {
  vpc_id = aws_vpc.django_ecs_vpc.id

  tags = {
    Name = "django-ecs-internet-gateway"
  }
}

# セキュリティグループ
resource "aws_security_group" "public_sg" {
  name        = "django-ecs-public-sg"
  vpc_id      = aws_vpc.django_ecs_vpc.id
  description = "allow access to public resources"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_public" {
  security_group_id = aws_security_group.public_sg.id
  ip_protocol       = "tcp"
  to_port           = 80
  from_port         = 80
  cidr_ipv4         = "126.78.131.63/32"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_public" {
  security_group_id = aws_security_group.public_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "private_sg" {
  name        = "django-ecs-sg"
  vpc_id      = aws_vpc.django_ecs_vpc.id
  description = "security group for django-ecs"
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_private" {
  security_group_id = aws_security_group.private_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_private" {
  security_group_id = aws_security_group.private_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "rds_sg" {
  name        = "django-ecs-rds-sg"
  vpc_id      = aws_vpc.django_ecs_vpc.id
  description = "Created by RDS management console"
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgres" {
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  to_port                      = 5432
  from_port                    = 5432
  referenced_security_group_id = aws_security_group.private_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_rds" {
  security_group_id = aws_security_group.rds_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ルートテーブル
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.django_ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.django_ecs_gw.id
  }

  tags = {
    Name = "django-ecs-public-rtb"
  }
}

resource "aws_route_table" "private_rtb_1a" {
  vpc_id = aws_vpc.django_ecs_vpc.id

  tags = {
    Name = "django-ecs-private-1a-rtb"
  }
}

resource "aws_route_table" "private_rtb_1c" {
  vpc_id = aws_vpc.django_ecs_vpc.id

  tags = {
    Name = "django-ecs-private-1c-rtb"
  }
}

# VPCエンドポイント
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.django_ecs_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.private_sg.id
  ]

  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name = "django-ecs-ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.django_ecs_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.private_sg.id
  ]

  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name = "django-ecs-ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.django_ecs_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rtb_1a.id,
    aws_route_table.private_rtb_1c.id
  ]

  tags = {
    Name = "django-ecs-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.django_ecs_vpc.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.private_sg.id
  ]

  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name = "django-ecs-logs-endpoint"
  }
}
