locals {
  environment = replace(var.environment, "_", "-")
}

variable "connect_users" {
  description = "Usernames to be added to the connect agent"
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

