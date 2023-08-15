
# Create the Lambda function
resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = var.lambda_role_arn
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  # Replace with your Lambda function code
  filename         = var.lambda_filename
  source_code_hash = filebase64sha256(var.lambda_filename)
}

resource "aws_iam_policy_attachment" "lambda_execution" {
  name       = "lambda-execution-policy"
  roles      = [var.lambda_role_name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create a resource in the API Gateway
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root_resource_id
  path_part   = var.api_gateway_path
}

# Create a method for the resource
resource "aws_api_gateway_method" "method" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = var.api_http_method
  authorization = "NONE"
  authorizer_id = ""
}

# Create an integration between the API Gateway and Lambda function
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "example"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*"
}

resource "aws_api_gateway_method_response" "integration_response" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method

  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin"  = false,
  }

  response_models = {
    "application/json" = "Empty"
  }
}

