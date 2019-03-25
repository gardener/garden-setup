variable "CLIENT_ID" {
  description = "Azure Client ID"
  type        = "string"
}

variable "CLIENT_SECRET" {
  description = "Azure Client Secret"
  type        = "string"
}

variable "TENANT_ID" {
  description = "Azure Tenant ID"
  type        = "string"
}

variable "SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
  type        = "string"
}

variable "REGION" {
  description = "Region of the ABS bucket"
  type = "string"
}

variable "BUCKETNAME" {
  description = "Name of the bucket"
  type = "string"
}

variable "RESOURCE_GROUP" {
  description = "Azure Resource Group"
  type = "string"
}

variable "STORAGE_ACCOUNT_NAME" {
  description = "Name of the storeage account"
}