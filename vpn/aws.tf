resource "aws_customer_gateway" "customer_gateway" {
  bgp_asn    = 60000
  ip_address = "${google_compute_address.vpn_static_ip.address}"
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${var.aws_vpn_gateway}"
  customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
  type                = "ipsec.1"
  static_routes_only  = true
}

resource "aws_vpn_connection_route" "gcp" {
  destination_cidr_block = "${var.gcp_cidr}"
  vpn_connection_id      = "${aws_vpn_connection.main.id}"
}

resource "aws_route" "gcp" {
  count                  = "${var.num_aws_route_tables}"
  route_table_id         = "${element(var.aws_route_tables, count.index)}"
  gateway_id             = "${var.aws_vpn_gateway}"
  destination_cidr_block = "${var.gcp_cidr}"
}

resource "aws_security_group_rule" "google_ingress_nomad_tcp" {
  type        = "ingress"
  from_port   = 4646
  to_port     = 4648
  protocol    = "tcp"
  cidr_blocks = ["${var.gcp_cidr}"]

  security_group_id = "${var.aws_sg}"
}

resource "aws_security_group_rule" "google_ingress_nomad_udp" {
  type        = "ingress"
  from_port   = 4648
  to_port     = 4648
  protocol    = "udp"
  cidr_blocks = ["${var.gcp_cidr}"]

  security_group_id = "${var.aws_sg}"
}

resource "aws_security_group_rule" "google_ingress_consul_tcp" {
  type        = "ingress"
  from_port   = 8302
  to_port     = 8302
  protocol    = "tcp"
  cidr_blocks = ["${var.gcp_cidr}"]

  security_group_id = "${var.aws_sg}"
}

resource "aws_security_group_rule" "google_ingress_consul_udp" {
  type        = "ingress"
  from_port   = 8302
  to_port     = 8302
  protocol    = "udp"
  cidr_blocks = ["${var.gcp_cidr}"]

  security_group_id = "${var.aws_sg}"
}

resource "aws_security_group_rule" "google_egress_tcp" {
  type        = "egress"
  from_port   = 8302
  to_port     = 8302
  protocol    = "tcp"
  cidr_blocks = ["${var.gcp_cidr}"]

  security_group_id = "${var.aws_sg}"
}

resource "aws_security_group_rule" "google_egress_udp" {
  type        = "egress"
  from_port   = 8302
  to_port     = 8302
  protocol    = "udp"
  cidr_blocks = ["${var.gcp_cidr}"]

  security_group_id = "${var.aws_sg}"
}
