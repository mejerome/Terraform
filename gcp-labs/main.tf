terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {

  credentials = file("/mnt/c/Projects/Learn-TF-b34ebe4479c6.json")

  project = "learn-tf-303113"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "home_network" {
  name                    = "home-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "home_subnet" {
  name          = "home-subnet"
  region        = "us-central1"
  network       = google_compute_network.home_network.id
  ip_cidr_range = "10.130.0.0/20"
}

resource "google_compute_firewall" "allow_rdp" {
  name        = "allow-rdp"
  network     = google_compute_network.home_network.id
  target_tags = ["bastion"]
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
}

resource "google_compute_instance" "win-instance" {
  name         = "windows-svr"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2004-core"
    }
  }
  tags = ["bastion"]

  network_interface {
    subnetwork = google_compute_subnetwork.home_subnet.id
  }

}

