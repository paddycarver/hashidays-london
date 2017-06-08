resource "google_compute_instance_template" "nomad_node" {
  count        = 3
  name_prefix  = "nomad-node-${element(var.zones, count.index)}-"
  tags         = ["consul-client"]
  machine_type = "${var.node_machine_type}"

  disk {
    source_image = "family/nomad"
    disk_size_gb = "50"
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata {
    startup-script = <<EOF
#!/bin/bash
sed -i -e 's/{REGION}/${var.region}/g' /etc/consul.d/client.json
sed -i -e 's/{INSTANCE-TYPE}/${var.node_machine_type}/g' /etc/consul.d/client.json
sed -i -e 's/{CLOUD}/gcp/g' /etc/consul.d/client.json

sed -i -e 's/{REGION}/${var.region}/g' /etc/nomad.d/client.hcl
sed -i -e 's/{INSTANCE-TYPE}/${var.node_machine_type}/g' /etc/nomad.d/client.hcl
sed -i -e 's/{ZONE}/${var.region}-${element(var.zones, count.index)}/g' /etc/nomad.d/client.hcl
sed -i -e 's/{CLOUD}/gcp/g' /etc/nomad.d/client.hcl
systemctl enable nomad-client
systemctl enable consul-client
systemctl start consul-client
systemctl start nomad-client
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

resource "google_compute_instance_group_manager" "nomad_nodes" {
  count = 3
  name  = "nomad-nodes-${element(var.zones, count.index)}"

  base_instance_name = "nomad-node-${element(var.zones, count.index)}"
  instance_template  = "${element(google_compute_instance_template.nomad_node.*.self_link, count.index)}"
  zone               = "${var.region}-${element(var.zones, count.index)}"

  target_size = 3
}
