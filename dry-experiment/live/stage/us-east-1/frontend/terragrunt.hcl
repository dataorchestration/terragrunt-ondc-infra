include "root" {
  path = find_in_parent_folders("common.hcl")
}

include "env" {
  path   = "${dirname(find_in_parent_folders("common.hcl"))}/_env/frontend.hcl"
  expose = true
}

terraform {
  source = include.env.locals.source_base_url
}

inputs = {
  docker_image_version = "v12"
  replicas             = 1
}
