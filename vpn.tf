module "vpn" {
  source = "./vpn"

  aws_cidr             = "${module.aws.cidr}"
  gcp_cidr             = "${module.gcp.cidr}"
  aws_region           = "${module.aws.region}"
  gcp_region           = "${module.gcp.region}"
  shared_secret        = "${random_id.shared_secret.hex}"
  aws_vpc              = "${module.aws.vpc_id}"
  aws_sg               = "${module.aws.nomad_servers_sg}"
  aws_route_tables     = "${module.aws.private_route_tables}"
  num_aws_route_tables = "${module.aws.num_private_route_tables}"
  aws_vpn_gateway      = "${module.aws.vpn_gateway}"
}

resource "random_id" "shared_secret" {
  byte_length = 12
}
