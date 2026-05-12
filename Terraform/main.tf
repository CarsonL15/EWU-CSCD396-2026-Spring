terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = var.environment_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_container_registry" "main" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

# Lets the GitHub Actions service principal push images during the build step.
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_actions_sp_object_id
}

# User-assigned identity attached to the Container App so it can pull from ACR.
# Using user-assigned (rather than system-assigned) avoids a chicken-and-egg
# cycle: the AcrPull role assignment can be created before the Container App.
resource "azurerm_user_assigned_identity" "container_app" {
  name                = "id-${var.container_app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

# Azure RBAC has eventual consistency: a role assignment's API write returns
# success before the permission is actually effective for data-plane calls.
# Without this delay the Container App's first image pull can fail with
# "denied: requested access to the resource is denied".
resource "time_sleep" "wait_for_acr_pull" {
  depends_on      = [azurerm_role_assignment.acr_pull]
  create_duration = "60s"
}

# --- Assignment 3: Service Bus ---

resource "azurerm_servicebus_namespace" "main" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "messages" {
  name         = var.service_bus_queue_name
  namespace_id = azurerm_servicebus_namespace.main.id
}

# Container App's identity sends messages to the queue.
resource "azurerm_role_assignment" "ca_sb_sender" {
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

# Function App's identity reads messages from the queue.
resource "azurerm_role_assignment" "func_sb_receiver" {
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}

# --- Assignment 3: Storage account (function runtime + messages output) ---

resource "azurerm_storage_account" "function" {
  name                     = var.function_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "messages" {
  name                  = var.messages_blob_container_name
  storage_account_name  = azurerm_storage_account.function.name
  container_access_type = "private"
}

# Function App's identity writes received messages as blobs.
resource "azurerm_role_assignment" "func_blob_contributor" {
  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}

# --- Assignment 3: Function App ---

resource "azurerm_application_insights" "main" {
  name                = "ai-${var.function_app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
}

resource "azurerm_service_plan" "function" {
  name                = "asp-${var.function_app_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "main" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  service_plan_id            = azurerm_service_plan.function.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
    application_insights_connection_string = azurerm_application_insights.main.connection_string
    application_insights_key               = azurerm_application_insights.main.instrumentation_key
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"                  = "dotnet-isolated"
    "ServiceBusConnection__fullyQualifiedNamespace" = "${azurerm_servicebus_namespace.main.name}.servicebus.windows.net"
    "SERVICE_BUS_QUEUE"                         = azurerm_servicebus_queue.messages.name
    "BLOB_ACCOUNT_URL"                          = "https://${azurerm_storage_account.function.name}.blob.core.windows.net"
    "BLOB_CONTAINER_NAME"                       = azurerm_storage_container.messages.name
  }

  lifecycle {
    ignore_changes = [
      # Zip-deploy from the workflow sets WEBSITE_RUN_FROM_PACKAGE; don't fight it on subsequent applies.
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# --- Assignment 3: Azure SQL (Extra Credit) ---

resource "random_password" "sql_admin" {
  length      = 24
  special     = true
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
  min_special = 2
  # Some special chars cause issues in connection strings/URLs.
  override_special = "!@#$%^&*()-_=+[]{}"
}

resource "azurerm_mssql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "main" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"
}

# "Allow Azure services and resources to access this server" — the special
# 0.0.0.0/0.0.0.0 entry. Required for the Container App to connect.
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# --- Container App: wire in Service Bus + SQL config ---

resource "azurerm_container_app" "main" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.container_app.id
  }

  secret {
    name  = "sql-connection-string"
    value = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin_login};Password=${random_password.sql_admin.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  template {
    container {
      name   = "webapp"
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "SERVICE_BUS_NAMESPACE"
        value = "${azurerm_servicebus_namespace.main.name}.servicebus.windows.net"
      }
      env {
        name  = "SERVICE_BUS_QUEUE"
        value = azurerm_servicebus_queue.messages.name
      }
      env {
        name        = "SQL_CONNECTION_STRING"
        secret_name = "sql-connection-string"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = var.container_target_port
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  # Image is rolled by the app workflow via `az containerapp update --image`.
  # Without this, every TF apply would revert to whatever container_image var
  # was passed (e.g., a stale tag from the bootstrap step).
  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }

  depends_on = [time_sleep.wait_for_acr_pull]
}
