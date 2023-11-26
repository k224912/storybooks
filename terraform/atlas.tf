provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.12.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.38"
    }
  }
}

#cluster
resource "mongodbatlas_cluster" "mongo_cluster" {
  project_id   = var.atlas_project_id
  name         = "${var.app_name}-${terraform.workspace}"
  cluster_type = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "CENTRAL_US"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
  cloud_backup                 = true
  auto_scaling_disk_gb_enabled = false
  mongo_db_major_version       = "6.0"

  # Provider Settings "block"
  provider_name               = "GCP"
  provider_instance_size_name = "M10"
}

#database user
resource "mongodbatlas_database_user" "mongodbatlas_database_user" {
  username           = "storybooks-user-${terraform.workspace}" #so i canhave separate users for each workspace
  password           = var.atlas_user_password
  project_id         = var.atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "storybooks"
  }
}

#ip whitelist 
#allows our machine to communicte with cluster
resource "mongodbatlas_project_ip_access_list" "test" {
  project_id = var.atlas_project_id
  ip_address = google_compute_address.ip_address.address
  comment    = "ip address for tf acc testing"
}


