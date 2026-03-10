module "codebuild_projects" {
  for_each = var.codebuild_projects
  source   = "./modules/codebuild"

  vpc_id             = var.vpc_id
  subnets            = var.subnets
  security_group_ids = var.security_group_ids
  service_role       = var.service_role

  project_config = merge(
    each.value,
    {
      name        = "${split("-", each.key)[0]}-${var.stage}-${join("-", slice(split("-", each.key), 1, length(split("-", each.key))))}"
      description = "${split("-", each.key)[0]}-${var.stage}-${join("-", slice(split("-", each.key), 1, length(split("-", each.key))))}"
    }
  )
}
