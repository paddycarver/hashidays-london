// set up our account information for AWS and GCP

provider "aws" {
  // pulling credentials from shared credentials file
  region = "eu-west-1"
}

provider "google" {
  // pulling credentials from the application default credentials
  project = "paddy-hashidays-london"
  region  = "europe-west2"
}
