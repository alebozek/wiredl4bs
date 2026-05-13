# security group del contenedor
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-private-sg"
  description = "Trafico hacia las tareas ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde la VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "SSH desde la VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-private-sg"
  }
}

# security group para acceder a EFS
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Permite acceder al EFS desde las tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS desde ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-sg"
  }
}

# security group para los VPCE
resource "aws_security_group" "vpce_sg" {
  name        = "${var.project_name}-vpce-sg"
  description = "Permite a las tareas ECS alcanzar los endpoints de interfaz"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS desde las tareas ECS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  ingress {
    description = "HTTPS desde clientes VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpn_client_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpce-sg"
  }
}