output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "name" {
  value = module.aws_cognito_user_pool.aws_cognito_user_pool_arn
}