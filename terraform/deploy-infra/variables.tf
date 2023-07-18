variable "rg" {
  type = string
  description = "Resource Group name"
}

variable "env" {
  type = string
  description = "Environment"
}

variable "prj" {
  type = string
  description = "Project Name"
}

variable "prjcode" {
  type = string
  description = "Project Code"
}

variable "pwd" {
  type = string
  sensitive = true
  description = "PostgreSQL server password"
}