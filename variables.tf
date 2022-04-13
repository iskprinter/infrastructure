variable "project" {
  type    = string
  default = "cameronhudson8"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "min_node_8gb_count" {
  default = 1
  type    = number
}

variable "max_node_8gb_count" {
  default = 3
  type    = number
}
