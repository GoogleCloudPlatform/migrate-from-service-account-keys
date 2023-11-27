# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


resource "random_integer" "org_resource_postfix" {
  min = 1
  max = 60000
  keepers = {
    project_id = data.google_project.sa_key_usage.project_id
    region     = var.region
  }
}

module "cai_sa_analyzer" {
  source               = "./modules/cai-sa-analyzer/"
  org_id               = var.org_id
  project_id           = data.google_project.sa_key_usage.project_id
  region               = var.region
  path_prefix          = "../"
  bq_location          = var.bq_location
  cai_dataset_id       = var.cai_dataset_id
  key_usage_dataset_id = var.key_usage_dataset_id
  workflow_schedule    = var.sa_key_schedule
  org_resource_postfix = random_integer.org_resource_postfix.result
  provision_org_iam    = var.provision_org_iam

  depends_on = [
    google_project_service.services
  ]
}

data "google_project" "sa_key_usage" {
  project_id = var.project_id
  depends_on = [
    google_project_service.cloudresourcemanager
  ]
}