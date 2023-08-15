variable "aws_cognito_user_pool_arn" {
  default = null
}

variable "lambda_role_arn" {
  description = "Amazon Resource Name (ARN) of the function's execution role. The role provides the function's identity and access to AWS services and resources."
  default     = null
}