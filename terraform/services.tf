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

resource "google_project_service" "cloudresourcemanager" {
  project            = var.project_id
  disable_on_destroy = false
  service            = "cloudresourcemanager.googleapis.com"

}

resource "google_project_service" "services" {
  project            = data.google_project.sa_key_usage.project_id
  disable_on_destroy = false
  for_each = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "iam.googleapis.com",
    "policyanalyzer.googleapis.com",
    "recommender.googleapis.com",
    "run.googleapis.com",
    "workflows.googleapis.com",
  ])
  service    = each.value
  depends_on = [google_project_service.cloudresourcemanager]

}

