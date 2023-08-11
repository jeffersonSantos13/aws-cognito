provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_cognito_user_pool" "dev-account" {
  name                     = "dev-account-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length = 8
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Account Confirmation"
    email_message        = "Your confirmation code is {####}"
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "dev-account-client" {
  name         = "dev-app-client"
  user_pool_id = aws_cognito_user_pool.dev-account.id

  # (Optional) Whether the client is allowed to follow the OAuth protocol when interacting with Cognito user pools.
  allowed_oauth_flows_user_pool_client = true

  #  (Optional) List of allowed OAuth flows (code, implicit, client_credentials).
  allowed_oauth_flows = ["code"]

  # Add token validity settings
  access_token_validity  = 3  # 1 hour (in seconds)
  refresh_token_validity = 30 # 30 days (in seconds)
  id_token_validity      = 1  # 1 hour (in seconds)

  allowed_oauth_scopes         = ["email", "openid"]
  callback_urls                = ["http://localhost:8000/callback.html"]
  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "apollo-domain-login-test"
  user_pool_id = aws_cognito_user_pool.dev-account.id
}

resource "aws_api_gateway_rest_api" "sit" {
  name = "sit-api"
}

resource "aws_api_gateway_resource" "sit_resource" {
  rest_api_id = aws_api_gateway_rest_api.sit.id
  parent_id   = aws_api_gateway_rest_api.sit.root_resource_id
  path_part   = "login"
}

resource "aws_api_gateway_method" "sit_method" {
  rest_api_id   = aws_api_gateway_rest_api.sit.id
  resource_id   = aws_api_gateway_resource.sit_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sit_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.sit.id
  resource_id             = aws_api_gateway_resource.sit_resource.id
  http_method             = aws_api_gateway_method.sit_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cognito_login.invoke_arn
}

resource "aws_api_gateway_method_response" "gateway_response" {
  rest_api_id = aws_api_gateway_rest_api.sit.id
  resource_id = aws_api_gateway_resource.sit_resource.id
  http_method = aws_api_gateway_method.sit_method.http_method

  status_code = "200"
}

/* resource "aws_api_gateway_integration_response" "jwt_response" {
  rest_api_id = aws_api_gateway_rest_api.sit.id
  resource_id = aws_api_gateway_resource.sit_resource.id
  http_method = aws_api_gateway_method.sit_method.http_method
  status_code = aws_api_gateway_method_response.gateway_response.status_code

  response_templates = {
    "application/json" = ""
  }
} */

resource "aws_lambda_function" "cognito_login" {
  filename         = "./bin/login.zip"
  function_name    = "handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main"
  source_code_hash = filebase64sha256("./bin/login.zip")
  runtime          = "go1.x"
  environment {
    variables = {
      APP_CLIENT_ID = var.app_client_id,
      USER_POOL_ID  = var.user_pool_id
    }
  }
}

resource "aws_iam_policy_attachment" "lambda_execution" {
  name       = "lambda-execution-policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "example"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sit.execution_arn}/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.sit_api_integration]
  rest_api_id = aws_api_gateway_rest_api.sit.id
  stage_name  = "dev"
}

output "user_pool_id" {
  value = aws_cognito_user_pool.dev-account.id
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.dev-account-client.id
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "cognito_domain_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.us-east-1.amazoncognito.com"
}