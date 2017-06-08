// global variables
variable "region" {
  default = "eu-west-1"
}

variable "zones" {
  type = "list"
}

variable "ami" {
  type = "string"
}

// nomad server variables
variable "server_instance_type" {
  default = "t2.xlarge"
}

// nomad node variables
variable "node_instance_type" {
  default = "t2.medium"
}

// nomad bastion variables
variable "bastion_instance_type" {
  default = "t2.micro"
}

output "cidr" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "region" {
  value = "${var.region}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "nomad_servers_sg" {
  value = "${aws_security_group.nomad_servers.id}"
}

output "private_route_tables" {
  value = "${aws_route_table.private.*.id}"
}

output "num_private_route_tables" {
  value = "${length(var.zones)}"
}

output "vpn_gateway" {
  value = "${aws_vpn_gateway.aws.id}"
}
