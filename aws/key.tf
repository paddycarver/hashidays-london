resource "aws_key_pair" "ssh" {
  key_name   = "hashidays-london-nomad"
  public_key = "${file(pathexpand("~/.ssh/id_rsa.pub"))}"
}
