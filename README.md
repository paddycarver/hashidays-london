# Going Multi-Cloud with Terraform and Nomad

This is the code used for my Going Multi-Cloud with Terraform and Nomad talk, originally given at [HashiDays London](https://hashidays.com/london.html).

This code contains:

1. A [Packer](https://packer.io) config for building an image capable of running both [Consul](https://consul.io) and [Nomad](https://nomadproject.io).
2. A [Terraform](https://terraform.io) config to stand up an AWS cluster using the image, a GCP cluster using the image, and a VPN connecting the two of them.

## Authentication

The easiest way to authenticate for this is to use the Application Default Credentials for Google, which can be populated using `gcloud auth application-default login`, and to use the AWS shared credentials file, which can be set using `aws configure`.

## Building the Packer Image

To build the Packer Image, change to the `nomad-image` directory and run `packer build image.json`.

## Standing Up the Cluster

To stand up the cluster, run `terraform apply` from the root of the repository.