resource "aws_cognito_user_pool" "pool" {
  name = var.pool_name
  tags = var.tags

  # password_policy
  password_policy {
    minimum_length                   = lookup(var.password_policy, "minimum_length", null) == null ? var.password_policy_minimum_length : lookup(var.password_policy, "minimum_length")
    require_lowercase                = lookup(var.password_policy, "require_lowercase", null) == null ? var.password_policy_require_lowercase : lookup(var.password_policy, "require_lowercase")
    require_numbers                  = lookup(var.password_policy, "require_numbers", null) == null ? var.password_policy_require_numbers : lookup(var.password_policy, "require_numbers")
    require_symbols                  = lookup(var.password_policy, "require_symbols", null) == null ? var.password_policy_require_symbols : lookup(var.password_policy, "require_symbols")
    require_uppercase                = lookup(var.password_policy, "require_uppercase", null) == null ? var.password_policy_require_uppercase : lookup(var.password_policy, "require_uppercase")
    temporary_password_validity_days = lookup(var.password_policy, "temporary_password_validity_days", null) == null ? var.password_policy_temporary_password_validity_days : lookup(var.password_policy, "temporary_password_validity_days")
  }

  # schema
  dynamic "schema" {
    for_each = var.schemas == null ? [] : var.schemas
    content {
      attribute_data_type      = lookup(schema.value, "attribute_data_type")
      developer_only_attribute = lookup(schema.value, "developer_only_attribute")
      mutable                  = lookup(schema.value, "mutable")
      name                     = lookup(schema.value, "name")
      required                 = lookup(schema.value, "required")
    }
  }

  # schema (String)
  dynamic "schema" {
    for_each = var.string_schemas == null ? [] : var.string_schemas
    content {
      attribute_data_type      = "String"
      developer_only_attribute = lookup(schema.value, "developer_only_attribute")
      mutable                  = lookup(schema.value, "mutable")
      name                     = lookup(schema.value, "name")

      # string_attribute_constraints
      dynamic "string_attribute_constraints" {
        for_each = length(keys(lookup(schema.value, "string_attribute_constraints", {}))) == 0 ? [] : [lookup(schema.value, "string_attribute_constraints", {})]
        content {
          min_length = lookup(string_attribute_constraints.value, "min_length", null)
          max_length = lookup(string_attribute_constraints.value, "max_length", null)
        }
      }
    }
  }

  # schema (Number)
  dynamic "schema" {
    for_each = var.number_schemas == null ? [] : var.number_schemas
    content {
      attribute_data_type      = "Number"
      developer_only_attribute = lookup(schema.value, "developer_only_attribute")
      mutable                  = lookup(schema.value, "mutable")
      name                     = lookup(schema.value, "name")

      # number_attribute_constraints
      dynamic "number_attribute_constraints" {
        for_each = length(keys(lookup(schema.value, "number_attribute_constraints", {}))) == 0 ? [] : [lookup(schema.value, "number_attribute_constraints", {})]
        content {
          min_value = lookup(number_attribute_constraints.value, "min_value", null)
          max_value = lookup(number_attribute_constraints.value, "max_value", null)
        }
      }
    }
  }
}

resource "aws_cognito_user_pool_client" "clients" {
  for_each = { for client in local.clients : client.name => client }

  name                                 = each.value.name
  user_pool_id                         = aws_cognito_user_pool.pool.id
  generate_secret                      = each.value.generate_secret
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  access_token_validity                = each.value.access_token_validity
  refresh_token_validity               = each.value.refresh_token_validity
  id_token_validity                    = each.value.id_token_validity
  callback_urls                        = each.value.callback_urls
  supported_identity_providers         = each.value.supported_identity_providers
  explicit_auth_flows                  = each.value.explicit_auth_flows

  allowed_oauth_scopes = each.value.resource_server != "" ? flatten([
    for server in aws_cognito_resource_server.resource :
    server.name == each.value.resource_server ? server.scope_identifiers : []
  ]) : each.value.allowed_oauth_scopes
}

resource "aws_cognito_resource_server" "resource" {
  for_each = { for server in var.resource_servers : server.name => server }

  name       = each.value.name
  identifier = each.value.identifier

  #scope
  dynamic "scope" {
    for_each = each.value.scopes
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

locals {
  clients_default = [
    {
      allowed_oauth_flows                  = var.client_allowed_oauth_flows
      allowed_oauth_flows_user_pool_client = var.client_allowed_oauth_flows_user_pool_client
      allowed_oauth_scopes                 = var.client_allowed_oauth_scopes
      callback_urls                        = var.client_callback_urls
      explicit_auth_flows                  = var.client_explicit_auth_flows
      generate_secret                      = var.client_generate_secret
      name                                 = var.client_name
      access_token_validity                = var.client_access_token_validity
      id_token_validity                    = var.client_id_token_validity
      refresh_token_validity               = var.client_refresh_token_validity
      supported_identity_providers         = var.client_supported_identity_providers
      resource_server                      = var.resource_server
    }
  ]

  clients_parsed = [for e in var.app_clients : {
    allowed_oauth_flows                  = lookup(e, "allowed_oauth_flows", null)
    allowed_oauth_flows_user_pool_client = lookup(e, "allowed_oauth_flows_user_pool_client", null)
    allowed_oauth_scopes                 = lookup(e, "allowed_oauth_scopes", null)
    callback_urls                        = lookup(e, "callback_urls", null)
    explicit_auth_flows                  = lookup(e, "explicit_auth_flows", null)
    generate_secret                      = lookup(e, "generate_secret", null)
    name                                 = lookup(e, "name", null)
    access_token_validity                = lookup(e, "access_token_validity", null)
    id_token_validity                    = lookup(e, "id_token_validity", null)
    refresh_token_validity               = lookup(e, "refresh_token_validity", null)
    supported_identity_providers         = lookup(e, "supported_identity_providers", null)
    resource_server                      = lookup(e, "resource_server", null)
    }
  ]

  clients = length(var.app_clients) == 0 && (var.client_name == null || var.client_name == "") ? [] : (length(var.app_clients) > 0 ? local.clients_parsed : local.clients_default)
}