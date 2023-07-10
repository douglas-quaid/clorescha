resource "azurerm_resource_group" "res-0" {
  location = "australiasoutheast"
  name     = "DevStuff"
}
resource "azurerm_cdn_endpoint" "res-1" {
  is_compression_enabled = true
  location               = "global"
  name                   = "datcdn"
  optimization_type      = "GeneralWebDelivery"
  origin_host_header     = "datdevstorage.z26.web.core.windows.net"
  profile_name           = "cdn-profile"
  resource_group_name    = "DevStuff"
  delivery_rule {
    name  = "httpRedirect"
    order = 1
    request_scheme_condition {
      match_values = ["HTTP"]
    }
    url_redirect_action {
      protocol      = "Https"
      redirect_type = "Found"
    }
  }
  origin {
    host_name = "datdevstorage.z26.web.core.windows.net"
    name      = "datdevstorage-blob-core-windows-net"
  }
  depends_on = [
    azurerm_cdn_profile.res-10,
  ]
}
resource "azurerm_cdn_endpoint_custom_domain" "res-2" {
  cdn_endpoint_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/DevStuff/providers/Microsoft.Cdn/profiles/cdn-profile/endpoints/datcdn"
  host_name       = "www.rcapz.net"
  name            = "www-rcapz-net"
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
  }
  depends_on = [
    azurerm_cdn_endpoint.res-1,
  ]
}
resource "azurerm_storage_account" "res-4" {
  account_replication_type = "GRS"
  account_tier             = "Standard"
  location                 = "australiasoutheast"
  name                     = "datdevstorage"
  resource_group_name      = "DevStuff"
  static_website {
    error_404_document = "404.html"
    index_document     = "index.html"
  }
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}
resource "azurerm_storage_container" "res-6" {
  name                 = "$web"
  storage_account_name = "datdevstorage"
}
resource "azurerm_cdn_profile" "res-10" {
  location            = "global"
  name                = "cdn-profile"
  resource_group_name = "DevStuff"
  sku                 = "Standard_Microsoft"
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}

resource "azurerm_storage_blob" "webfolder" {
  for_each = fileset(path.module, "upload/*")

  name                   = trimprefix(each.key, "upload/")
  storage_account_name   = azurerm_storage_account.res-4.name
  storage_container_name = azurerm_storage_container.res-6.name
  type                   = "Block"
  content_type           = "text/html"
  source                 = each.key
  content_md5            = filemd5(each.key)
}
