provider "google" {
  credentials = file("terraform-sa-key.json")
  project     = "storybook-take-1"
  region      = "us-central1"
  zone        = "us-central1-c"
}



# IP ADDRESS
resource "google_compute_address" "ip_address" {
  name = "storybooks-ip-${terraform.workspace}"
}

# NETWORK
data "google_compute_network" "default" {
  name = "default"
}
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-${terraform.workspace}"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["allow-http-${terraform.workspace}"]
}

# OS IMAGE
data "google_compute_image" "cos_image" {
  family  = "cos-101-lts"
  project = "cos-cloud"
}

resource "google_compute_instance" "instance" {
  name         = "${var.app_name}-vm-${terraform.workspace}"
  machine_type = var.gcp_machine_type
  zone         = "us-central1-a"

  tags = google_compute_firewall.allow_http.target_tags #means how we apply our firewall rules to our instance

  boot_disk { #where we specify the image we want to use
    initialize_params {
      image = data.google_compute_image.cos_image.self_link
    }
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  service_account {
    scopes = ["storage-ro"] #in order to read storage read only docker iimage from gcp
  }
}
