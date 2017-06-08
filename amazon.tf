module "aws" {
  source = "./aws"

  ami   = "ami-46d7cb20"
  zones = ["${var.aws_zones}"]
}

variable "aws_zones" {
  default = ["a", "b", "c"]
}
