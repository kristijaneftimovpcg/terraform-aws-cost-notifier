variable "lambda-name" {
  default     = "budget-calculation"
  description = "The lambda function name"
  type        = string
}

variable "lambda-role-name" {
  default     = "lambda-execution-role"
  description = "The lambda function role name"
  type        = string
}

variable "python-runtime" {
  default     = "python3.11"
  description = "The python runtime"
  type        = string
}

variable "cloudwatch-rule-name" {
  default     = "cost-lambda-trigger"
  description = "The cloudwatch rule name"
  type        = string
}

variable "cron-expression" {
  description = "Value of the cron expression"
  type        = string
}

variable "sns-protocol" {
  default     = "email"
  description = "The sns protocol"
  type        = string
}

variable "sns-topic-name" {
  default     = "budget-notifications"
  description = "The sns topic name"
  type        = string
}

variable "sns-endpoint" {
  description = "The sns endpoint"
  type        = list(string)
}

variable "sns-po-endpoint" {
  description = "The sns endpoint for PO"
  type        = string
  default     = ""
}

variable "project-name" {
  description = "The project name"
  type        = string
}

variable "aws-region" {
  description = "The AWS region where resources will be deployed"
  type        = string
}

variable "calculation-type" {
  description = "The lambda calculation type"
  type        = string
}

variable "budget-threshold" {
  default     = 0
  description = "The budget threshold"
  type        = number
}
