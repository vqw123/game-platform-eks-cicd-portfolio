variable "region" {
  description = "AWS region for the stage"
  type        = string
}

variable "stage" {
  description = "Deployment stage such as dev, qa, or prod"
  type        = string
}

variable "service_role" {
  description = "IAM role ARN used by all CodeBuild projects in the stage"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by all CodeBuild projects in the stage"
  type        = string
}

variable "subnets" {
  description = "Private subnet IDs used by CodeBuild"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs used by CodeBuild"
  type        = list(string)
}

variable "codebuild_projects" {
  description = "Per-service CodeBuild configuration"
  type = map(object({
    environment_variables = list(object({
      name  = string
      value = string
    }))
    location       = string
    buildspec      = string
    source_version = string
    group_name     = string
    stream_name    = string
  }))
}
