# Configure the GCP provider
provider "google" {
  version = "~> 2.11.0"

  credentials = file(var.gcp_credentials_file_path)

  # Should be able to parse project from credentials file but cannot.
  # Cannot convert string to map and cannot interpolate within variables.
  project = var.gcp_project_id

  region = var.gcp_region
}

