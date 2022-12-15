variable "rootManagementGroup" {
  type = string
  default = "axeleos-enterprise_scale"
}

variable "platformManagementGroup" {
  type = string
  default = "Platform"
}

variable "lzManagementGroup" {
  type = string
  default = "Landing Zones"
}

variable "decomManagementGroup" {
  type = string
  default = "Decommissioned"
}

variable "sandboxManagementGroup" {
  type = string
  default = "Sandbox"
}

variable "idManagementGroup" {
  type = string
  default = "Identity"
}

variable "idManagementGroupSubId" {
  type = list
  default = ["f64fc3ff-2792-4338-aa51-c97d4d388148"]
}

variable "mgmtManagementGroup" {
  type = string
  default = "Management"
}

variable "mgmtManagementGroupSubId" {
  type = list
  default = ["f64fc3ff-2792-4338-aa51-c97d4d388148"]
}

variable "connManagementGroup" {
  type = string
  default = "Connectivity"
}

variable "connManagementGroupSubId" {
  type = list
  default = ["f64fc3ff-2792-4338-aa51-c97d4d388148"]
}

variable "citrixManagementGroup" {
  type = string
  default = "Citrix"
}

variable "managedby" {
  type        = string
  default     = "Terraform"
}