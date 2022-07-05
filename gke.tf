# VPC
resource "google_compute_network" "vpc_network" {
  name                    = "btc4043-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet1(asia-northeast1)
resource "google_compute_subnetwork" "an1_private1" {
  name          = "btc4043-an1-private1"
  ip_cidr_range = "192.168.1.0/24"
  region        = "asia-northeast1"
  network       = google_compute_network.vpc_network.id
}

# Service account for GKE Cluster node
resource "google_service_account" "sc_gke1" {
  account_id   = "btc4043-sc-gck1"
  display_name = "Service Account for GkE1"
}

# GKE cluster(Standard)
resource "google_container_cluster" "gke1" {
  name     = "btc4043-gke1-cluster"
  location = "asia-northeast1"

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "STABLE"
  }

  min_master_version = "1.21.10-gke.2000"

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.10.0.0/16"
    services_ipv4_cidr_block = "10.20.0.0/16"
  }
  
  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.an1_private1.self_link

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = "192.168.100.0/28"

    master_global_access_config {
    enabled = false
    }
  }

  master_authorized_networks_config {
  }

  logging_config {
    enable_components = [
        "SYSTEM_COMPONENTS",
        "WORKLOADS"
    ]
  }

  monitoring_config {
    enable_components = [
        "SYSTEM_COMPONENTS",
    ]
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  workload_identity_config {
    workload_pool = "btc4043.svc.id.goog"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2022-04-29T17:00:00Z"
      end_time   = "2022-04-29T21:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=FR,SA,SU"
    }
  }

}

# GKE nodepool
resource "google_container_node_pool" "gke1_nodes" {
  name       = "btc4043-node-pool"
  location   = "asia-northeast1"
  cluster    = google_container_cluster.gke1.name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }

  upgrade_settings {
    max_surge       = 1   
    max_unavailable = 0
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "e2-medium"

    service_account = google_service_account.sc_gke1.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
