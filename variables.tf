
variable "deployment_role" {
    type = string
    default = ""
}

variable "external_id" {
  type = string
  default = ""
}

variable "deploy_resources" {
    type = bool
    default = false
}

variable "region" {
    type = string
    default = "us-east-1"
}