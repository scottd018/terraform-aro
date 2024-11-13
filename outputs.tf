output "console_url" {
  value = azurerm_redhat_openshift_cluster.cluster.console_url
}

output "api_server_ip" {
  value = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].ip_address
}

output "ingress_ip" {
  value = azurerm_redhat_openshift_cluster.cluster.ingress_profile[0].ip_address
}

locals {
  subscription_var_deprecation_message = var.subscription_id != null && var.subscription_id != "" ? "subscription_id is deprecated and pulled from your azure cli config" : null
}

output "deprecated_subscription_id_var" {
  value = local.subscription_var_deprecation_message
}
