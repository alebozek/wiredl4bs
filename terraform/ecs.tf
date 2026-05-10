# Cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# EFS para persistencia del laboratorio
resource "aws_efs_file_system" "lab" {
  creation_token = "${var.project_name}-efs"

  encrypted = true

  tags = {
    Name = "${var.project_name}-efs"
  }
}

# Mount target EFS subnet AZ1
resource "aws_efs_mount_target" "private_1" {
  file_system_id  = aws_efs_file_system.lab.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

# Mount target EFS subnet AZ2
resource "aws_efs_mount_target" "private_2" {
  file_system_id  = aws_efs_file_system.lab.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.efs_sg.id]
}

# ECS Task Definition
resource "aws_ecs_task_definition" "lab" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]

  network_mode = "awsvpc"

  cpu    = "1024"
  memory = "2048"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  # Volumen persistente EFS
  volume {
    name = "aide_db"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.lab.id
      root_directory = "/"

      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([
    {
      name  = "wiredl4bs"
      image = "${aws_ecr_repository.wiredl4bs.repository_url}:latest"
      essential = true
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

# Servicio ECS
resource "aws_ecs_service" "lab" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.lab.arn

  desired_count = 1
  launch_type   = "FARGATE"

  enable_execute_command = false

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
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}