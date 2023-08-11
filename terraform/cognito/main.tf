resource "aws_cognito_user_pool" "pool" {
  name = var.pool_name
  tags = var.tags
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = var.pool_client_name
  user_pool_id                         = aws_cognito_user_pool.pool.id
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = var.client_allowed_oauth_flows
  generate_secret                      = var.client_generate_secret
  allowed_oauth_scopes                 = aws_cognito_resource_server.resource.scope_identifiers

  /* allowed_oauth_scopes = flatten([
    for server in aws_cognito_resource_server.resource : server.scope_identifiers
  ]) */
}

resource "aws_cognito_resource_server" "resource" {
  name       = var.resource_server_name
  identifier = var.resource_server_identifier

  #scope
  dynamic "scope" {
    for_each = var.resource_scopes
    content {
      scope_name        = lookup(scope.value, "scope_name")
      scope_description = lookup(scope.value, "scope_description")
    }
  }

  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.domain_name
  user_pool_id = aws_cognito_user_pool.pool.id
}
