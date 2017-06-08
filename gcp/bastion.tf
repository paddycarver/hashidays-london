resource "google_compute_instance_template" "nomad_bastion" {
  name_prefix  = "nomad-bastion-"
  machine_type = "${var.bastion_machine_type}"

  disk {
    source_image = "family/nomad"
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata {
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

resource "google_compute_instance_group_manager" "nomad_bastion" {
  name               = "nomad-bastion"
  base_instance_name = "nomad-bastion"
  instance_template  = "${google_compute_instance_template.nomad_bastion.self_link}"
  zone               = "${var.region}-${var.zones[0]}"
  target_size        = 1
}
