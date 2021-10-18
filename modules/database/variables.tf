variable "cicd_bot_name" {
  type = string
}

variable "cicd_namespace" {
  type = string
}

variable "project" {
  type = string
}

variable "mongodb_replicas" {
  type = number
}

variable "neo4j_persistent_volume_size" {
  type = string
}

variable "neo4j_replicas" {
  type = number
}

variable "neo4j_version" {
  type = string
}

variable "region" {
  type = string
}
