resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/wiredl4bs/vpn"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "vpn_stream" {
  name           = "wiredl4bs-stream"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}

resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name = "wiredl4bs-ca"
  }

  is_ca_certificate     = true
  validity_period_hours = 87600

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_csr" {
  private_key_pem = tls_private_key.server_key.private_key_pem

  subject {
    common_name = "vpn.wiredl4bs.local"
  }

  dns_names = [
    "vpn.wiredl4bs.local"
  ]
}

resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem   = tls_cert_request.server_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "server_auth"
  ]
}

resource "tls_private_key" "client_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_csr" {
  private_key_pem = tls_private_key.client_key.private_key_pem

  subject {
    common_name = "vpn.wiredl4bs.local"
  }
}

resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem   = tls_cert_request.client_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "client_auth"
  ]
}

resource "aws_acm_certificate" "server" {
  private_key      = tls_private_key.server_key.private_key_pem
  certificate_body = tls_locally_signed_cert.server_cert.cert_pem
}

resource "aws_acm_certificate" "client_ca" {
  private_key      = tls_private_key.ca_key.private_key_pem
  certificate_body = tls_self_signed_cert.ca_cert.cert_pem
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description       = "wiredl4bs-client-vpn"
  client_cidr_block = var.vpn_client_cidr

  server_certificate_arn = aws_acm_certificate.server.arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client_ca.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_logs.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_stream.name
  }

  dns_servers  = ["8.8.8.8"]
  split_tunnel = true

  tags = {
    Name = "wiredl4bs-vpn"
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_assoc_1" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.private_1.id
}

resource "aws_ec2_client_vpn_network_association" "vpn_assoc_2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.private_2.id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id

  target_network_cidr = var.vpc_cidr
  authorize_all_groups = true

  description = "Allow VPN access to VPC"
}

resource "aws_ec2_client_vpn_route" "vpn_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = var.vpc_cidr
  target_vpc_subnet_id   = aws_subnet.private_1.id

  depends_on = [
    aws_ec2_client_vpn_network_association.vpn_assoc_1
  ]
}

resource "null_resource" "vpn_export" {
  triggers = {
    vpn_id = aws_ec2_client_vpn_endpoint.vpn.id
  }

  provisioner "local-exec" {
    command = "aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.vpn.id} --output text > ${path.module}/wiredl4bs.ovpn"
  }
}

