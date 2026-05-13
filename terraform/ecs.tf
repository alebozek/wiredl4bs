# cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# EFS para persistencia del laboratorio
resource "aws_efs_file_system" "lab" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-efs"
  }
}

# mount target EFS en subnet AZ1
resource "aws_efs_mount_target" "private_1" {
  file_system_id  = aws_efs_file_system.lab.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

# mount target EFS en subnet AZ2
resource "aws_efs_mount_target" "private_2" {
  file_system_id  = aws_efs_file_system.lab.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.efs_sg.id]
}

# definición de la tarea ECS
resource "aws_ecs_task_definition" "lab" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"

  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "aide_db"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.lab.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([
    {
      name                  = "wiredl4bs"
      image                 = "${aws_ecr_repository.wiredl4bs.repository_url}:latest"
      essential             = true
      readonlyRootFilesystem = false

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
        {
          containerPort = 22
          hostPort      = 22
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "aide_db"
          containerPath = "/var/lib/aide"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "wiredl4bs"
        }
      }
    }
  ])

  depends_on = [
    null_resource.docker_build_push,
    aws_ecr_repository.wiredl4bs
  ]
}

# servicio ECS
resource "aws_ecs_service" "lab" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.lab.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # importante para hacer pruebas en caso de encontrar problemas
  enable_execute_command = true

  network_configuration {
    subnets = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]

    security_groups = [
      aws_security_group.ecs_sg.id
    ]

    assign_public_ip = false
  }

  # entradas al load balancer para poder acceder a HTTP y SSH
  load_balancer {
    target_group_arn = aws_lb_target_group.tg_http.arn
    container_name   = "wiredl4bs"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_ssh.arn
    container_name   = "wiredl4bs"
    container_port   = 22
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.ssh
  ]
}

# grupo de logs de CloudWatch para ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}

# Network Load Balancer interno
resource "aws_lb" "internal_nlb" {
  name               = "${var.project_name}-nlb"
  internal           = true
  load_balancer_type = "network"

  subnets = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}

# Target group HTTP
resource "aws_lb_target_group" "tg_http" {
  name        = "${var.project_name}-tg-http"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# Target group SSH
resource "aws_lb_target_group" "tg_ssh" {
  name        = "${var.project_name}-tg-ssh"
  port        = 22
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# Listener HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_http.arn
  }
}

# Listener SSH
resource "aws_lb_listener" "ssh" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_ssh.arn
  }
}