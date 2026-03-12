
output "MyIp" {
  value       = data.http.myip.response_body
  description = "value of my IP address"
}

output "WellKnownAppIDs" {
  value       = data.azuread_application_published_app_ids.well_known.result
  description = "The well known application IDs from Azure AD"
}