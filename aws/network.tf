resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "hashidays-london-nomad"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "hashidays-london-nomad"
  }
}

resource "aws_subnet" "private" {
  count             = "${length(var.zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.0.${count.index + 1 + aws_subnet.public.count}.0/24"
  availability_zone = "${var.region}${element(var.zones, count.index)}"

  tags {
    Name = "hashidays-london-nomad-private"
  }
}

resource "aws_subnet" "public" {
  count                   = "${length(var.zones)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = "${var.region}${element(var.zones, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "hashidays-london-nomad-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route" "public" {
  route_table_id         = "${aws_route_table.public.id}"
  gateway_id             = "${aws_internet_gateway.gateway.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_eip" "eip" {
  count = "${length(var.zones)}"
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count         = "${length(var.zones)}"
  allocation_id = "${element(aws_eip.eip.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  count            = "${length(var.zones)}"
  vpc_id           = "${aws_vpc.vpc.id}"
  propagating_vgws = ["${aws_vpn_gateway.aws.id}"]
}

resource "aws_route" "private" {
  count                  = "${length(var.zones)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_vpn_gateway" "aws" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route_table_association" "private_subnet" {
  count          = "${length(var.zones)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "public_subnet" {
  count          = "${length(var.zones)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "bastion" {
  name        = "nomad-bastion"
  description = "nomad bastion"

  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion_ping" {
  type              = "ingress"
  from_port         = "8"
  to_port           = "8"
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group" "nomad_servers" {
  name        = "nomad-servers"
  description = "nomad servers"

  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group_rule" "nomad_server_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "nomad_server_tcp_ports_in" {
  type      = "ingress"
  from_port = 4646
  to_port   = 4648
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "nomad_server_udp_ports_in" {
  type      = "ingress"
  from_port = 4648
  to_port   = 4648
  protocol  = "udp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_tcp_ports_in" {
  type      = "ingress"
  from_port = 8300
  to_port   = 8302
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_udp_ports_in" {
  type      = "ingress"
  from_port = 8301
  to_port   = 8302
  protocol  = "udp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_http_api_in" {
  type      = "ingress"
  from_port = 8500
  to_port   = 8500
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_dns_tcp_in" {
  type      = "ingress"
  from_port = 8600
  to_port   = 8600
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_dns_udp_in" {
  type      = "ingress"
  from_port = 8600
  to_port   = 8600
  protocol  = "udp"
  self      = true

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_tcp_ports_nodes" {
  type                     = "ingress"
  from_port                = 8300
  to_port                  = 8301
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.nomad_nodes.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_udp_ports_nodes" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "udp"
  source_security_group_id = "${aws_security_group.nomad_nodes.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_http_api_nodes" {
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.nomad_nodes.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_dns_tcp_nodes" {
  type                     = "ingress"
  from_port                = 8600
  to_port                  = 8600
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.nomad_nodes.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "consul_server_dns_udp_nodes" {
  type                     = "ingress"
  from_port                = 8600
  to_port                  = 8600
  protocol                 = "udp"
  source_security_group_id = "${aws_security_group.nomad_nodes.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "nomad_server_bastion" {
  type                     = "ingress"
  from_port                = 4646
  to_port                  = 4647
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.nomad_nodes.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "nomad_server_nodes" {
  type                     = "ingress"
  from_port                = 4646
  to_port                  = 4646
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group_rule" "nomad_server_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"

  security_group_id = "${aws_security_group.nomad_servers.id}"
}

resource "aws_security_group" "nomad_nodes" {
  name        = "nomad-nodes"
  description = "nomad nodes"

  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group_rule" "nomad_nodes_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nomad_nodes.id}"
}

resource "aws_security_group_rule" "nomad_node_tcp_ports_server" {
  type                     = "ingress"
  from_port                = 4647
  to_port                  = 4647
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.nomad_servers.id}"

  security_group_id = "${aws_security_group.nomad_nodes.id}"
}

resource "aws_security_group_rule" "nomad_node_gossip_tcp_ports_server" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.nomad_servers.id}"

  security_group_id = "${aws_security_group.nomad_nodes.id}"
}

resource "aws_security_group_rule" "nomad_node_gossip_udp_ports_server" {
  type                     = "ingress"
  from_port                = 8301
  to_port                  = 8301
  protocol                 = "udp"
  source_security_group_id = "${aws_security_group.nomad_servers.id}"

  security_group_id = "${aws_security_group.nomad_nodes.id}"
}

resource "aws_security_group_rule" "nomad_node_gossip_tcp_ports_self" {
  type      = "ingress"
  from_port = 8301
  to_port   = 8301
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.nomad_nodes.id}"
}

resource "aws_security_group_rule" "nomad_node_gossip_udp_ports_self" {
  type      = "ingress"
  from_port = 8301
  to_port   = 8301
  protocol  = "udp"
  self      = true

  security_group_id = "${aws_security_group.nomad_nodes.id}"
}

resource "aws_security_group_rule" "nomad_node_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"

  security_group_id = "${aws_security_group.nomad_nodes.id}"
}
