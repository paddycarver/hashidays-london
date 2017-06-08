resource "aws_launch_configuration" "nomad_node" {
  count                = 3
  name_prefix          = "nomad-node-${element(var.zones, count.index)}-"
  image_id             = "${var.ami}"
  instance_type        = "${var.node_instance_type}"
  security_groups      = ["${aws_security_group.nomad_nodes.id}"]
  key_name             = "${aws_key_pair.ssh.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.nomad_node.name}"

  user_data = <<EOF
#!/bin/bash
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

sed -i -e 's/{REGION}/${var.region}/g' /etc/consul.d/client.json
sed -i -e 's/{INSTANCE-TYPE}/${var.node_instance_type}/g' /etc/consul.d/client.json
sed -i -e 's/{CLOUD}/aws/g' /etc/consul.d/client.json
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/consul.d/client.json

sed -i -e 's/{REGION}/${var.region}/g' /etc/nomad.d/client.hcl
sed -i -e 's/{INSTANCE-TYPE}/${var.node_instance_type}/g' /etc/nomad.d/client.hcl
sed -i -e 's/{ZONE}/${var.region}-${element(var.zones, count.index)}/g' /etc/nomad.d/client.hcl
sed -i -e 's/{CLOUD}/aws/g' /etc/nomad.d/client.hcl
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/nomad.d/client.hcl

systemctl enable nomad-client
systemctl enable consul-client
systemctl start consul-client
systemctl start nomad-client
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nomad_nodes" {
  count                = 3
  name                 = "nomad-node-${element(var.zones, count.index)}"
  max_size             = 3
  min_size             = 3
  availability_zones   = ["${var.region}${element(var.zones, count.index)}"]
  launch_configuration = "${element(aws_launch_configuration.nomad_node.*.name, count.index)}"
  vpc_zone_identifier  = ["${element(aws_subnet.private.*.id, count.index)}"]
  depends_on           = ["aws_nat_gateway.nat"]

  tag {
    key                 = "role"
    value               = "consul-client"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "nomad_node" {
  name = "nomad-node"

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
resource "aws_iam_policy" "nomad_node" {
  name        = "nomad-node"
  description = "Describe Consul servers."

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
resource "aws_iam_policy_attachment" "nomad_node" {
  name       = "nomad_node"
  roles      = ["${aws_iam_role.nomad_node.name}"]
  policy_arn = "${aws_iam_policy.nomad_node.arn}"
}

# Create the instance profile
resource "aws_iam_instance_profile" "nomad_node" {
  name = "nomad-node"
  role = "${aws_iam_role.nomad_node.name}"
}
