terraform {
  backend "gcs" {
    bucket = "iskprinter-tf-state"
    prefix = "infrastructure"
  }
}
