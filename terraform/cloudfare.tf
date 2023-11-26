provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "dns_record" {
  zone_id = var.cloudflare_zone_id
  name    = "storybooks${terraform.workspace == "production" ? "" : "-${terraform.workspace}"}"
  value   = google_compute_address.ip_address.address
  type    = "A"
  proxied = true

}


