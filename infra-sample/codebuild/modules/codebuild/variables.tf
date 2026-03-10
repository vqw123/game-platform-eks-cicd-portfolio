variable "service_role" {
  description = "IAM role ARN used by the CodeBuild project"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the CodeBuild project"
  type        = string
}

variable "subnets" {
  description = "Subnet IDs used by the CodeBuild project"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs used by the CodeBuild project"
  type        = list(string)
}

variable "project_config" {
  description = "Configuration for a single CodeBuild project"
  type = object({
    name        = string
    description = string
    environment_variables = list(object({
      name  = string
      value = string
    }))
    location       = string
    buildspec      = string
    source_version = string
    group_name     = string
    stream_name    = string
  })
}
