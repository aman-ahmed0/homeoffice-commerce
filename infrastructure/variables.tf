variable "subscription_id" {
  description = "Azure subscription used for this showcase project."
  type        = string
}

variable "location" {
  description = "Azure region for the project resources."
  type        = string
  default     = "centralindia"
}

variable "admin_ipv4_cidr" {
  description = "Public IPv4 address allowed to administer AKS, with /32."
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.admin_ipv4_cidr)) &&
      endswith(var.admin_ipv4_cidr, "/32")
    )
    error_message = "Provide a valid single IPv4 address with /32."
  }
}