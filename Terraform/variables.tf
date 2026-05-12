variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment_name" {
  description = "Name of the Container Apps Environment"
  type        = string
  default     = "env-assignment2"
}

variable "container_app_name" {
  description = "Name of the Container App"
  type        = string
  default     = "ca-assignment2"
}

variable "container_image" {
  description = "Container image to deploy (full reference, e.g. acrname.azurecr.io/app:tag). The workflow passes this in via terraform apply."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "container_target_port" {
  description = "Port the container listens on. ASP.NET Core 8 in a container defaults to 8080."
  type        = number
  default     = 8080
}

variable "container_registry_name" {
  description = "Name of the Azure Container Registry. Must be globally unique, 5-50 lowercase alphanumeric chars."
  type        = string
}

variable "github_actions_sp_object_id" {
  description = "Object ID of the GitHub Actions service principal. Used to grant AcrPush so the workflow can push images. Looked up by the workflow via 'az ad sp show'."
  type        = string
}

# --- Assignment 3 additions ---

variable "service_bus_namespace_name" {
  description = "Globally unique Service Bus namespace name"
  type        = string
  default     = "sb-assignment3-carsonl15"
}

variable "service_bus_queue_name" {
  description = "Service Bus queue the web app sends to and the function reads from"
  type        = string
  default     = "messages"
}

variable "function_storage_account_name" {
  description = "Globally unique storage account that holds both the function runtime files and the messages blob container. 3-24 lowercase alphanumeric chars."
  type        = string
  default     = "sa3msgcarsonl15a3"
}

variable "messages_blob_container_name" {
  description = "Blob container the function writes incoming messages to"
  type        = string
  default     = "messages"
}

variable "function_app_name" {
  description = "Globally unique Function App name"
  type        = string
  default     = "func-assignment3-carsonl15"
}

variable "sql_server_name" {
  description = "Globally unique Azure SQL Server name"
  type        = string
  default     = "sql-assignment3-carsonl15"
}

variable "sql_database_name" {
  description = "Azure SQL Database name"
  type        = string
  default     = "sqldb-assignment3"
}

variable "sql_admin_login" {
  description = "SQL administrator login"
  type        = string
  default     = "sqladmin"
}
