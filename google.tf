module "gcp" {
  source = "./gcp"

  aws_zones   = ["a", "b", "c"]
  aws_servers = "${join(" ", data.aws_instance.aws_servers.*.private_ip)}"
}

data "aws_instance" "aws_servers" {
  depends_on = ["module.aws"]
  count      = "${length(var.aws_zones)}"

  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = ["nomad-server-${element(var.aws_zones, count.index)}"]
  }
}
