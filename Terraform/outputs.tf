output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_registry_login_server" {
  description = "Login server hostname of the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.main.name
}

output "container_app_fqdn" {
  description = "Stable FQDN of the Container App ingress (does not change between revisions)"
  value       = azurerm_container_app.main.ingress[0].fqdn
}

output "container_app_url" {
  description = "Stable URL of the Container App"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.main.name
}

output "function_app_url" {
  description = "Default hostname of the Function App"
  value       = "https://${azurerm_linux_function_app.main.default_hostname}"
}

output "service_bus_namespace" {
  description = "Service Bus namespace fully-qualified hostname"
  value       = "${azurerm_servicebus_namespace.main.name}.servicebus.windows.net"
}

output "service_bus_queue" {
  description = "Service Bus queue name"
  value       = azurerm_servicebus_queue.messages.name
}

output "messages_storage_account_name" {
  description = "Storage account where the function writes received messages"
  value       = azurerm_storage_account.function.name
}

output "messages_blob_container_name" {
  description = "Blob container where the function writes received messages"
  value       = azurerm_storage_container.messages.name
}

output "sql_server_fqdn" {
  description = "Azure SQL Server fully-qualified hostname"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Azure SQL Database name"
  value       = azurerm_mssql_database.main.name
}
