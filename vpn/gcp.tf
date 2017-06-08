resource "google_compute_vpn_gateway" "gcp" {
  name    = "gcp-vpn"
  network = "default"
  region  = "${var.gcp_region}"
}

resource "google_compute_address" "vpn_static_ip" {
  name   = "vpn-static-ip"
  region = "${var.gcp_region}"
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  region      = "${var.gcp_region}"
  ip_protocol = "ESP"
  ip_address  = "${google_compute_address.vpn_static_ip.address}"
  target      = "${google_compute_vpn_gateway.gcp.self_link}"
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  region      = "${var.gcp_region}"
  ip_protocol = "UDP"
  port_range  = "500-500"
  ip_address  = "${google_compute_address.vpn_static_ip.address}"
  target      = "${google_compute_vpn_gateway.gcp.self_link}"
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  region      = "${var.gcp_region}"
  ip_protocol = "UDP"
  port_range  = "4500-4500"
  ip_address  = "${google_compute_address.vpn_static_ip.address}"
  target      = "${google_compute_vpn_gateway.gcp.self_link}"
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name          = "gcp-tunnel-1"
  ike_version   = "1"
  region        = "${var.gcp_region}"
  peer_ip       = "${aws_vpn_connection.main.tunnel1_address}"
  shared_secret = "${aws_vpn_connection.main.tunnel1_preshared_key}"

  target_vpn_gateway = "${google_compute_vpn_gateway.gcp.self_link}"

  depends_on = [
    "google_compute_forwarding_rule.fr_esp",
    "google_compute_forwarding_rule.fr_udp500",
    "google_compute_forwarding_rule.fr_udp4500",
  ]
}

resource "google_compute_route" "gcp_route1" {
  name       = "gcp-route1"
  network    = "default"
  dest_range = "${var.aws_cidr}"
  priority   = 1000

  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.tunnel1.self_link}"
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name          = "gcp-tunnel-2"
  ike_version   = "1"
  region        = "${var.gcp_region}"
  peer_ip       = "${aws_vpn_connection.main.tunnel2_address}"
  shared_secret = "${aws_vpn_connection.main.tunnel2_preshared_key}"

  target_vpn_gateway = "${google_compute_vpn_gateway.gcp.self_link}"

  depends_on = [
    "google_compute_forwarding_rule.fr_esp",
    "google_compute_forwarding_rule.fr_udp500",
    "google_compute_forwarding_rule.fr_udp4500",
  ]
}

resource "google_compute_route" "gcp_route2" {
  name       = "gcp-route2"
  network    = "default"
  dest_range = "${var.aws_cidr}"
  priority   = 1000

  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.tunnel2.self_link}"
}

resource "google_compute_firewall" "aws" {
  name          = "aws"
  network       = "default"
  source_ranges = ["${var.aws_cidr}"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}
