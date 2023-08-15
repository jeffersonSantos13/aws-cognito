output "arn_lambda" {
  value = aws_lambda_function.lambda.arn
}

output "name_lambda" {
  value = aws_lambda_function.lambda.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}

output "integration" {
  value = aws_api_gateway_integration.integration
}