# ECR
resource "aws_ecr_repository" "django" {
  name                 = "test-django"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "nginx" {
  name                 = "test-nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECS
resource "aws_service_discovery_http_namespace" "django_ecs_ns" {
  name = "django-ecs-cluster"
  tags = {
    "AmazonECSManaged" = "true"
  }
  tags_all = {
    "AmazonECSManaged" = "true"
  }
}

resource "aws_ecs_cluster" "django_ecs_cluster" {
  name = "django-ecs-cluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.django_ecs_ns.arn
  }
}

resource "aws_ecs_task_definition" "django_ecs_task" {
  family                   = "django-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name         = "django"
      image        = aws_ecr_repository.django.repository_url
      cpu          = 0
      portMappings = []
      essential    = true
      entryPoint = [
        "/bin/sh",
        "-c"
      ]
      command = [
        "python manage.py collectstatic --noinput && gunicorn myapp.wsgi --bind=unix:/var/run/gunicorn/gunicorn.sock"
      ]
      environment = [
        {
          name  = "POSTGRES_USER"
          value = var.db_user
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = var.db_password
        },
        {
          name  = "POSTGRES_PORT"
          value = "5432"
        },
        {
          name  = "NLB_DOMAIN_NAME"
          value = aws_lb.django_ecs_nlb.dns_name
        },
        {
          name  = "POSTGRES_NAME"
          value = var.db_name
        },
        {
          name  = "POSTGRES_HOST"
          value = "django-ecs-db.coowltz0fbko.ap-northeast-1.rds.amazonaws.com"
        },
        {
          name  = "SECRET_KEY"
          value = var.secret_key
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "gunicorn-sock"
          containerPath = "/var/run/gunicorn"
          readOnly      = false
        },
        {
          sourceVolume  = "django-static"
          containerPath = "/usr/src/app/static"
          readOnly      = false
        }
      ]
      volumesFrom            = []
      readonlyRootFilesystem = false
      ulimits                = []
      environmentFiles       = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/django-ecs-task"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
        secretOptions = []
      }
      systemControls = []
    },
    {
      name  = "nginx"
      image = aws_ecr_repository.nginx.repository_url
      cpu   = 0
      portMappings = [
        {
          name          = "nginx-80-tcp"
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      essential        = true
      environment      = []
      environmentFiles = []
      mountPoints = [
        {
          sourceVolume  = "gunicorn-sock"
          containerPath = "/var/run/gunicorn"
          readOnly      = false
        },
        {
          sourceVolume  = "django-static"
          containerPath = "/usr/share/static"
          readOnly      = false
        }
      ]
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/django-ecs-task"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        },
        secretOptions = []
      }
      systemControls = []
    }
  ])

  volume {
    name = "django-static"
  }

  volume {
    name = "gunicorn-sock"
  }
}

resource "aws_ecs_service" "django_ecs_service" {
  name            = "django-ecs-service"
  cluster         = aws_ecs_cluster.django_ecs_cluster.id
  task_definition = aws_ecs_task_definition.django_ecs_task.arn
  desired_count   = 1

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true
  # launch_type                        = "FARGATE"
  platform_version = "1.4.0"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 1
  }

  health_check_grace_period_seconds = 60
  load_balancer {
    target_group_arn = aws_lb_target_group.django_ecs_nlb_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.private_sg.id]
    subnets = [
      aws_subnet.private_subnet_1a.id,
      aws_subnet.private_subnet_1c.id
    ]
  }
}
