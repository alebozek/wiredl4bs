# Obtiene información de la cuenta AWS actual
data "aws_caller_identity" "current" {}

# Construcción y publicación automática de la imagen Docker al ECR
resource "null_resource" "docker_build_push" {

  # Fuerza rebuild cuando cambia el Dockerfile
  triggers = {
    dockerfile_hash = filemd5("../Dockerfile")
  }

  provisioner "local-exec" {

    command = <<EOT

# loggeamos en el ECR
aws ecr get-login-password --region ${var.aws_region} \
| sudo docker login \
    --username AWS \
    --password-stdin ${aws_ecr_repository.wiredl4bs.repository_url}

# construimos la imagen
sudo docker build \
  -f ../Dockerfile \
  -t ${var.project_name}:latest \
  ..

# etiquetamos la imagen
sudo docker tag \
  ${var.project_name}:latest \
  ${aws_ecr_repository.wiredl4bs.repository_url}:latest

# pusheamos la imagen al ECR
sudo docker push \
  ${aws_ecr_repository.wiredl4bs.repository_url}:latest

EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_ecr_repository.wiredl4bs
  ]
}