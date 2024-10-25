# ネットワークロードバランサー
resource "aws_lb" "django_ecs_nlb" {
  name               = "django-ecs-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1c.id]
  security_groups    = [aws_security_group.public_sg.id]

  enable_deletion_protection = false
}

# ターゲットグループ
resource "aws_lb_target_group" "django_ecs_nlb_tg" {
  name        = "django-ecs-nlb-target-group"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.django_ecs_vpc.id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 10
  }
}
