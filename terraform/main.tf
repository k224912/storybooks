terraform {
  backend "gcs" {
    bucket = " //storybook-take-1-terraform"
    prefix = "/stage/storybooks"

  }
}
