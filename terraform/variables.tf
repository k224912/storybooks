### GENERAL
variable "app_name" {
  type    = string
  default = "storybooks"
}
### ATLAS
variable "atlas_project_id" {
  type = string
}


variable "mongodbatlas_public_key" {
  type = string
}

variable "mongodbatlas_private_key" {
  type = string
}




variable "atlas_user_password" {
  type = string
}





### GCP
variable "gcp_machine_type" {
  type = string
}

### CLOUDFLARE
variable "cloudflare_api_token" {
  type = string
}

# variable "cloudflare_zone_id" {
#   type = string
# }

variable "cloudflare_domain" {
  type = string
}

### NETLIFY



