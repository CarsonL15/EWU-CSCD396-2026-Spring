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
