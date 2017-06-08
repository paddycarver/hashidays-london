// global variables
variable "region" {
  default = "europe-west1"
}

variable "aws_zones" {
  type = "list"
}

variable "aws_servers" {
  type = "string"
}

variable "zones" {
  default = ["b", "c", "d"]
}

// nomad server variables
variable "server_machine_type" {
  default = "n1-standard-4"
}

// nomad node variables
variable "node_machine_type" {
  default = "n1-standard-1"
}

// nomad bastion variables
variable "bastion_machine_type" {
  default = "g1-small"
}

output "cidr" {
  value = "${data.google_compute_subnetwork.default.ip_cidr_range}"
}

output "region" {
  value = "${var.region}"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = "${var.region}"
}
