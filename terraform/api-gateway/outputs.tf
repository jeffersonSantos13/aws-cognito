output "id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

output "api_gateway_root_resource_id" {
  value = aws_api_gateway_rest_api.api_gateway.root_resource_id
}

output "api_gateway_execution_arn" {
  value = aws_api_gateway_rest_api.api_gateway.execution_arn
}

/* output "aws_api_gateway_authorizer_id" {
  value = aws_api_gateway_authorizer.client_credentials_authorizer.id
}
 */