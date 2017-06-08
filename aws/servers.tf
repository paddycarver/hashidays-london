resource "aws_launch_configuration" "nomad_server" {
  count                = 3
  name_prefix          = "nomad-server-${element(var.zones, count.index)}-"
  image_id             = "${var.ami}"
  instance_type        = "${var.server_instance_type}"
  security_groups      = ["${aws_security_group.nomad_servers.id}"]
  key_name             = "${aws_key_pair.ssh.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.nomad_server.name}"

  user_data = <<EOF
#!/bin/bash
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

sed -i -e 's/{REGION}/${var.region}/g' /etc/consul.d/server.json
sed -i -e 's/{INSTANCE-TYPE}/${var.server_instance_type}/g' /etc/consul.d/server.json
sed -i -e 's/{CLOUD}/aws/g' /etc/consul.d/server.json
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/consul.d/server.json

sed -i -e 's/{REGION}/${var.region}/g' /etc/nomad.d/server.hcl
sed -i -e 's/{INSTANCE-TYPE}/${var.server_instance_type}/g' /etc/nomad.d/server.hcl
sed -i -e 's/{ZONE}/${var.region}-${element(var.zones, count.index)}/g' /etc/nomad.d/server.hcl
sed -i -e 's/{CLOUD}/aws/g' /etc/nomad.d/server.hcl
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/nomad.d/server.hcl

systemctl enable nomad-server
systemctl enable consul-server
systemctl start consul-server
systemctl start nomad-server
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nomad_servers" {
  count                = 3
  name                 = "nomad-server-${element(var.zones, count.index)}"
  max_size             = 1
  min_size             = 1
  availability_zones   = ["${var.region}${element(var.zones, count.index)}"]
  launch_configuration = "${element(aws_launch_configuration.nomad_server.*.name, count.index)}"
  vpc_zone_identifier  = ["${element(aws_subnet.private.*.id, count.index)}"]
  depends_on           = ["aws_nat_gateway.nat"]

  tag {
    key                 = "role"
    value               = "consul-server"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "nomad_server" {
  name = "nomad-server"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create the policy
resource "aws_iam_policy" "nomad_server" {
  name        = "nomad-server"
  description = "Describe other Consul servers."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the policy
resource "aws_iam_policy_attachment" "nomad_server" {
  name       = "nomad_server"
  roles      = ["${aws_iam_role.nomad_server.name}"]
  policy_arn = "${aws_iam_policy.nomad_server.arn}"
}

# Create the instance profile
resource "aws_iam_instance_profile" "nomad_server" {
  name = "nomad-server"
  role = "${aws_iam_role.nomad_server.name}"
}
