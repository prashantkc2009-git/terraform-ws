resource "aws_customer_gateway" "on_prem" {
  bgp_asn    = var.on_prem_bgp_asn
  ip_address = var.on_prem_ip_address
  type       = "ipsec.1"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cgw"
    Environment = var.environment
  }
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-vgw"
    Environment = var.environment
  }
}

resource "aws_vpn_connection" "on_prem_vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.on_prem.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpn"
    Environment = var.environment
  }
}

resource "aws_instance" "legacy_mainframe_connector" {
  count = var.enable_bare_metal ? 1 : 0

  ami           = var.bare_metal_ami
  instance_type = var.bare_metal_instance_type
  subnet_id     = var.subnet_id
  tenancy       = "dedicated"

  tags = {
    Name        = "${var.project_name}-${var.environment}-legacy-connector"
    Environment = var.environment
  }
}
