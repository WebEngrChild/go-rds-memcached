variable "project" {
  type    = string
  default = "go-api"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cidr_blocks" {
  description = "List of CIDR blocks"
  type        = list(string)
  default     = ["106.72.179.162/32"]
}