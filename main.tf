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

module "cognito" {
  source                     = "./terraform/cognito"
  pool_name                  = "apollo-pool"
  pool_client_name           = "apollo-client"
  client_allowed_oauth_flows = ["client_credentials"]
  client_generate_secret     = true

  domain_name = "apollo-domain-login"

  resource_server_identifier = "http://api.apollo.resource-server.com"
  resource_server_name       = "apollo-resource-server"
  resource_scopes = [
    {
      scope_name        = "read"
      scope_description = "read"
    },
    {
      scope_name        = "write"
      scope_description = "write"
    }
  ]

  tags = {
    Service     = "project-x",
    Environment = "Development",
    Name        = "Development projetct cognito"
  }
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

resource "aws_lambda_function" "cognito_login" {
  filename         = "./bin/login.zip"
  function_name    = "handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main"
  source_code_hash = filebase64sha256("./bin/login.zip")
  runtime          = "go1.x"
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

output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "name" {
  value = module.cognito.aws_cognito_user_pool_arn
}