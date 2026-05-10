# Repositorio privado ECR
resource "aws_ecr_repository" "wiredl4bs" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = var.project_name
  }
}