provider "azurerm" {
  client_id       = var.CLIENT_ID
  client_secret   = var.CLIENT_SECRET
  tenant_id       = var.TENANT_ID
  subscription_id = var.SUBSCRIPTION_ID
  version         = "=2.48"
  features          {}
}

//=====================================================================
//= ABS bucket
//=====================================================================

resource "azurerm_resource_group" "rg" {
  name     = var.RESOURCE_GROUP
  location = var.REGION
}

resource "azurerm_storage_account" "storageAccount" {
  name                     = var.STORAGE_ACCOUNT_NAME
  location                 = var.REGION
  resource_group_name      = azurerm_resource_group.rg.name
  account_kind             = "BlobStorage"
  access_tier              = "Hot"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "container" {
  name                  = var.BUCKETNAME
  storage_account_name  = azurerm_storage_account.storageAccount.name
  container_access_type = "private"
}

//=====================================================================
//= Output variables
//=====================================================================

output "bucketName" {
  value = azurerm_storage_container.container.name
}

output "storageAccountName" {
  value = azurerm_storage_account.storageAccount.name
}

output "storageAccessKey" {
  sensitive = true
  value     = azurerm_storage_account.storageAccount.primary_access_key
}

