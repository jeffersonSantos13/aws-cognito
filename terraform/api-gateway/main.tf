# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "api_gateway"
  description = "My REST API"
}

/* resource "aws_api_gateway_authorizer" "client_credentials_authorizer" {
  name                   = "client_authorizer"
  rest_api_id            = aws_api_gateway_rest_api.api_gateway.id
  identity_source        = "method.request.header.Authorization"
  type                   = "COGNITO_USER_POOLS"
  authorizer_uri         = var.aws_cognito_user_pool_arn
  authorizer_credentials = var.lambda_role_arn
  provider_arns          = [var.aws_cognito_user_pool_arn]
} */