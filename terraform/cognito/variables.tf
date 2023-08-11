variable "pool_name" {
  default = "handler"
}

variable "pool_client_name" {
  default = "handler"
}

variable "client_allowed_oauth_flows" {
  type = list(any)
  default = []
}

variable "client_generate_secret" {
  default = false
}

variable "resource_server_identifier" {
  default = ""
}

variable "resource_server_name" {
  default = "handler"
}

variable "domain_name" {
  default = "handler"
}

variable "resource_server_scope_name" {
  description = "The scope name"
  type        = string
  default     = null
}

variable "resource_server_scope_description" {
  description = "The scope description"
  type        = string
  default     = null
}

variable "resource_scopes" {
  type = list(any)
  default = []
}

variable "tags" {
  type = map(string)
  default = {
    Service = "project-x",
    Environment = "Development",
    Name = "Development projetct cognito"
  }
}