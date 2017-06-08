resource "google_compute_instance_template" "nomad_server" {
  count        = 3
  name_prefix  = "nomad-server-${element(var.zones, count.index)}-"
  tags         = ["consul-server"]
  machine_type = "${var.server_machine_type}"

  disk {
    source_image = "family/nomad"
    disk_size_gb = "80"
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata {
    startup-script = <<EOF
#!/bin/bash
IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e 's/{REGION}/${var.region}/g' /etc/consul.d/server.json
sed -i -e 's/{INSTANCE-TYPE}/${var.server_machine_type}/g' /etc/consul.d/server.json
sed -i -e 's/{CLOUD}/gcp/g' /etc/consul.d/server.json
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/consul.d/server.json

sed -i -e 's/{REGION}/${var.region}/g' /etc/nomad.d/server.hcl
sed -i -e 's/{INSTANCE-TYPE}/${var.server_machine_type}/g' /etc/nomad.d/server.hcl
sed -i -e 's/{ZONE}/${var.region}-${element(var.zones, count.index)}/g' /etc/nomad.d/server.hcl
sed -i -e 's/{CLOUD}/gcp/g' /etc/nomad.d/server.hcl
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/nomad.d/server.hcl

systemctl enable nomad-server
systemctl enable consul-server
systemctl start consul-server
systemctl start nomad-server
consul join -wan ${var.aws_servers}
nomad server-join ${var.aws_servers}
EOF

    ssh-keys = "nomad:${file(pathexpand("~/.ssh/id_rsa.pub"))}"
  }

  service_account {
    scopes = [
      "compute-ro",
      "storage-ro",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "nomad_servers" {
  count = 3
  name  = "nomad-server-${element(var.zones, count.index)}"

  base_instance_name = "nomad-server-${element(var.zones, count.index)}"
  instance_template  = "${element(google_compute_instance_template.nomad_server.*.self_link, count.index)}"
  zone               = "${var.region}-${element(var.zones, count.index)}"

  target_size = 1
}
