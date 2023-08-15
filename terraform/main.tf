module "iam" {
  source    = "./iam-role"
  role_name = "lambda-handler"
}

module "aws_cognito_user_pool" {
  source           = "./cognito"
  pool_name        = "apollo-pool"
  pool_client_name = "apollo-client"

  password_policy = {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # user_pool_domain
  domain_name = "apollo-domain-login"

  # clients
  app_clients = [
    {
      name                                 = "apollo-client"
      allowed_oauth_flows                  = ["client_credentials"]
      resource_server                      = "apollo"
      generate_secret                      = true
      allowed_oauth_flows_user_pool_client = true

      explicit_auth_flows = [
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_CUSTOM_AUTH"
      ]
    },
    {
      name                                 = "login"
      allowed_oauth_flows                  = ["code"]
      allowed_oauth_scopes                 = ["email", "openid"]
      callback_urls                        = ["https://oauth.pstmn.io/v1/callback"]
      supported_identity_providers         = ["COGNITO"]
      resource_server                      = ""
      generate_secret                      = false
      allowed_oauth_flows_user_pool_client = true

      explicit_auth_flows = [
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_USER_PASSWORD_AUTH"
      ]
    }
  ]

  # resource_servers
  resource_servers = [
    {
      name       = "apollo"
      identifier = "apollo"
      scopes = [
        {
          scope_name        = "read"
          scope_description = "read"
        },
        {
          scope_name        = "write"
          scope_description = "write"
        }
      ]
    }
  ]

  tags = {
    Service     = "project-x",
    Environment = "Development",
    Name        = "Development projetct cognito"
  }
}

module "api_gateway" {
  source                    = "./api-gateway"
  aws_cognito_user_pool_arn = module.aws_cognito_user_pool.aws_cognito_user_pool_arn
  lambda_role_arn           = module.iam.arn
}

module "lambda_login" {
  source                       = "./lambda/lambda-gateway"
  lambda_name                  = "login"
  lambda_role_arn              = module.iam.arn
  lambda_role_name             = module.iam.name
  lambda_filename              = local.lambda_login_filename
  api_gateway_root_resource_id = module.api_gateway.api_gateway_root_resource_id
  api_gateway_id               = module.api_gateway.id
  api_gateway_execution_arn    = module.api_gateway.api_gateway_execution_arn
  api_gateway_path             = "login"
  api_gateway_environment      = "dev"
  api_http_method              = "POST"
  method_authorization         = "NONE"
}

module "authorize_token" {
  source                       = "./lambda/lambda-gateway"
  lambda_name                  = "authorize-token"
  lambda_role_arn              = module.iam.arn
  lambda_role_name             = module.iam.name
  lambda_filename              = local.lambda_authorize_filename
  api_gateway_root_resource_id = module.api_gateway.api_gateway_root_resource_id
  api_gateway_id               = module.api_gateway.id
  api_gateway_execution_arn    = module.api_gateway.api_gateway_execution_arn
  api_gateway_path             = "verify-token"
  api_gateway_environment      = "dev"
  api_http_method              = "GET"
  method_authorization         = "NONE"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [module.lambda_login.integration, module.authorize_token.integration]
  rest_api_id = module.api_gateway.id
  stage_name  = "dev"
}

locals {
  lambda_login_filename     = "../bin/login/login.zip"
  lambda_authorize_filename = "../bin/authorize/authorize.zip"
}

output "api_gateway_execution_arn" {
  value = module.api_gateway.api_gateway_execution_arn
}

output "api_gateway_id" {
  value = module.api_gateway.id
}

output "api_gateway_integration" {
  value = module.lambda_login.integration
}
