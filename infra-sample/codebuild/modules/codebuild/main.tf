resource "aws_codebuild_project" "project" {
  name           = var.project_config.name
  description    = var.project_config.description
  source_version = var.project_config.source_version

  service_role           = var.service_role
  concurrent_build_limit = 1
  badge_enabled          = true

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    dynamic "environment_variable" {
      for_each = var.project_config.environment_variables

      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }

  source {
    type            = "GITHUB"
    location        = var.project_config.location
    git_clone_depth = 1
    buildspec       = var.project_config.buildspec

    git_submodules_config {
      fetch_submodules = false
    }
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.subnets
    security_group_ids = var.security_group_ids
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.project_config.group_name
      stream_name = var.project_config.stream_name
    }
  }
}

resource "aws_codebuild_webhook" "project" {
  project_name = aws_codebuild_project.project.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/${var.project_config.source_version}"
    }
  }
}
