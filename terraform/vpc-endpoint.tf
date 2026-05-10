resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids = [ 
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
  ]

  security_group_ids = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}