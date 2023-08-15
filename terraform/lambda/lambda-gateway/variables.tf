variable "lambda_name" {
  description = "Unique name for your Lambda Function."
  default     = "lambda"
}

variable "lambda_handler" {
  description = "Function entrypoint in your code."
  default     = "main"
}

# Runtime disponiveis em: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
variable "lambda_runtime" {
  description = "Identifier of the function's runtime. See Runtimes for valid values."
  default     = "go1.x"
}

variable "lambda_role_arn" {
  description = "Amazon Resource Name (ARN) of the function's execution role. The role provides the function's identity and access to AWS services and resources."
  default     = null
}

variable "lambda_memory_size" {
  description = "mount of memory in MB your Lambda Function can use at runtime."
  default     = 128
}

variable "lambda_timeout" {
  description = "mount of time your Lambda Function has to run in seconds."
  default     = 600
}

variable "lambda_filename" {
  description = "Path to the function's deployment package within the local filesystem"
  default     = null
}

variable "lambda_role_name" {
  description = "name role with lambda permission"
  default     = null
}

variable "api_gateway_path" {
  description = "path to endpoint api gateway for trigger lambda"
  default     = null
}

variable "api_gateway_id" {
  description = "api gateway id"
  default     = null
}

variable "api_gateway_root_resource_id" {
  description = "api_gateway_root_resource_id"
  default     = null
}

variable "api_gateway_environment" {
  description = "environment where the gateway will be"
  default     = null
}

variable "api_http_method" {
  description = "method http for trigger lambda"
  default = "ANY"
}

variable "api_gateway_execution_arn" {
  default = null
}

variable "authorizer_id" {
  default = null
}

variable "method_authorization" {
  default = "NONE"
}
