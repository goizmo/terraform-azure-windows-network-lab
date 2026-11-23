variable "region" {
  description = "Región de Azure para el grupo de recursos y los recursos regionales."
  type        = string
  default     = "germanywestcentral"
  nullable    = false
}

variable "vm_size" {
  description = "SKU de cómputo de la VM. Comprueba disponibilidad y cuota para tu suscripción."
  type        = string
  default     = "Standard_D2als_v6"
  nullable    = false
}

variable "vm_zone" {
  description = "Zona de disponibilidad de la VM y su IP pública. null solicita un despliegue regional."
  type        = string
  default     = null

  validation {
    condition     = var.vm_zone == null ? true : contains(["1", "2", "3"], var.vm_zone)
    error_message = "Usa null para un despliegue regional o una de las zonas \"1\", \"2\" o \"3\"."
  }
}

variable "rdp_source_cidr" {
  description = "IPv4 pública de salida del cliente RDP en formato /32."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(cidrnetmask(var.rdp_source_cidr)) &&
      endswith(var.rdp_source_cidr, "/32") &&
      var.rdp_source_cidr != "0.0.0.0/32"
    )
    error_message = "Indica una única IPv4 en formato /32. No uses 0.0.0.0/0 ni comodines."
  }
}

variable "vm_admin_password" {
  description = "Contraseña del administrador local de Windows. Introdúcela mediante TF_VAR_vm_admin_password."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition = (
      length(var.vm_admin_password) >= 12 &&
      length(var.vm_admin_password) <= 123 &&
      length([
        for pattern in ["[a-z]", "[A-Z]", "[0-9]", "[^a-zA-Z0-9[:space:]]"] : pattern
        if can(regex(pattern, var.vm_admin_password))
      ]) >= 3
    )
    error_message = "Usa de 12 a 123 caracteres y al menos tres de estos grupos: minúsculas, mayúsculas, números y símbolos."
  }
}
