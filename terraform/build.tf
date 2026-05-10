# Obtiene información de la cuenta AWS actual
data "aws_caller_identity" "current" {}

# Construcción y publicación automática de la imagen Docker
#
# IMPORTANTE:
# Terraform se ejecuta desde:
#
# wiredl4bs/terraform
#
# mientras que el Dockerfile está en:
#
# wiredl4bs/Dockerfile
#
# Por eso usamos:
#
# -f ../Dockerfile
#
# y el contexto ".."
#
resource "null_resource" "docker_build_push" {

  # Fuerza rebuild cuando cambia el Dockerfile
  triggers = {
    dockerfile_hash = filemd5("../Dockerfile")
  }

  provisioner "local-exec" {

    command = <<EOT

# Login seguro contra ECR
aws ecr get-login-password --region ${var.aws_region} \
| sudo docker login \
    --username AWS \
    --password-stdin ${aws_ecr_repository.wiredl4bs.repository_url}

# Build de la imagen usando el Dockerfile raíz
sudo docker build \
  -f ../Dockerfile \
  -t ${var.project_name}:latest \
  ..

# Etiquetado para ECR
sudo docker tag \
  ${var.project_name}:latest \
  ${aws_ecr_repository.wiredl4bs.repository_url}:latest

# Push al repositorio privado
sudo docker push \
  ${aws_ecr_repository.wiredl4bs.repository_url}:latest

EOT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    aws_ecr_repository.wiredl4bs
  ]
}