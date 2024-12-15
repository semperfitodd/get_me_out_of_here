locals {
  environment = replace(var.environment, "_", "-")
}

variable "connect_users" {
  description = "Username to be added to the connect agent"
  type        = map(any)

  default = {}
}

variable "did_country_code" {
  description = "Country code for the phone number"
  type        = string

  default = "US"
}

variable "did_prefix" {
  description = "Area code preferred number comes from"
  type        = string

  default = null
}

variable "domain" {
  description = "Base domain for the website"
  type        = string

  default = null
}

variable "environment" {
  description = "Environment name"
  type        = string

  default = null
}

variable "phone_numbers" {
  description = "The count of phone numbers to provision"
  type        = map(any)

  default = {}
}

variable "region" {
  description = "AWS region"
  type        = string

  default = null
}

variable "tags" {
  description = "Universal tags"
  type        = map(string)

  default = {}
}

