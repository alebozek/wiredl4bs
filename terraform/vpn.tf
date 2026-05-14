# logs de conexión VPN
resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/wiredl4bs/vpn"
  retention_in_days = 7
}
# stream de logs a CloudWatch
resource "aws_cloudwatch_log_stream" "vpn_stream" {
  name           = "wiredl4bs-stream"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}

# clave CA
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
# certificado autofirmado para la ca
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem       = tls_private_key.ca_key.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600

  subject {
    common_name = "wiredl4bs-ca"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

# certificado de la VPN
resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_csr" {
  private_key_pem = tls_private_key.server_key.private_key_pem

  subject {
    common_name = "vpn.wiredl4bs.local"
  }

  dns_names = ["vpn.wiredl4bs.local"]
}

# certificado local autofirmado
resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem      = tls_cert_request.server_csr.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# certificado de cliente
resource "tls_private_key" "client_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_csr" {
  private_key_pem = tls_private_key.client_key.private_key_pem

  subject {
    common_name = "estudiante.wiredl4bs.local"
  }
}

resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem      = tls_cert_request.client_csr.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# importamos los certificado en ACM
resource "aws_acm_certificate" "server" {
  private_key       = tls_private_key.server_key.private_key_pem
  certificate_body  = tls_locally_signed_cert.server_cert.cert_pem
  certificate_chain = tls_self_signed_cert.ca_cert.cert_pem
}

resource "aws_acm_certificate" "client_ca" {
  private_key      = tls_private_key.ca_key.private_key_pem
  certificate_body = tls_self_signed_cert.ca_cert.cert_pem
}

# endpoint de la VPN
resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "wiredl4bs-client-vpn"
  client_cidr_block      = var.vpn_client_cidr
  server_certificate_arn = aws_acm_certificate.server.arn
  split_tunnel           = true
  dns_servers            = [cidrhost(var.vpc_cidr, 2)]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client_ca.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_logs.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_stream.name
  }

  tags = {
    Name = "wiredl4bs-vpn"
  }
}


# la asociamos a una subred
resource "aws_ec2_client_vpn_network_association" "vpn_assoc_1" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.private_1.id
}

# autorizamos a las IPs seleccionadas a conectarse a la VPN
resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
  description            = "Acceso de estudiantes a la VPC del laboratorio"
}

# creamos un archivo de conexion
resource "local_sensitive_file" "ovpn" {
  filename = "${path.module}/wiredl4bs.ovpn"
  content = templatefile("${path.module}/templates/client.ovpn.tpl", {
    endpoint    = aws_ec2_client_vpn_endpoint.vpn.dns_name
    ca_cert     = tls_self_signed_cert.ca_cert.cert_pem
    client_cert = tls_locally_signed_cert.client_cert.cert_pem
    client_key  = tls_private_key.client_key.private_key_pem
    vpc_network = cidrhost(var.vpc_cidr, 0)
    vpc_netmask = cidrnetmask(var.vpc_cidr)
  })

  depends_on = [
    aws_ec2_client_vpn_network_association.vpn_assoc_1,
    aws_ec2_client_vpn_authorization_rule.vpn_auth,
  ]
}
# agregamos las rutas
resource "aws_ec2_client_vpn_route" "vpn_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = var.vpc_cidr
  target_vpc_subnet_id   = aws_subnet.private_1.id
}
# agregamos otra asociacion
resource "aws_ec2_client_vpn_network_association" "vpn_assoc_2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.private_2.id
}

output "container-url" {
  depends_on = [ aws_lb.internal_nlb ]
  value = "Direccion del contenedor: ${aws_lb.internal_nlb.dns_name}"
}

output "vpn-file" {
  depends_on = [ local_sensitive_file.ovpn ]
  value = "Usa el archivo ${local_sensitive_file.ovpn.filename} para conectarte a la VPN y poder acceder al laboratorio"
}