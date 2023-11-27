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



# Scheduler Service Account

resource "google_service_account" "scheduler_service_account" {
  account_id   = var.scheduler_sa_name
  display_name = "Service Account for invoking Workflows"
}

resource "google_project_iam_member" "scheduler_iam" {
  project = data.google_project.sa_key_usage.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_service_account.email}"
}


# Access Analyzer Function Service Account

resource "google_service_account" "access_analyzer_service_account" {
  account_id   = var.access_analyzer_sa_name
  display_name = "Service Account for analyzing Key Usage data in BigQuery"
}

#  IAM Recommender Viewer
resource "google_project_iam_member" "access_analyzer_iam" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.dataViewer",
    "roles/bigquery.jobUser",
    "roles/policyanalyzer.activityAnalysisViewer"
  ])
  project = data.google_project.sa_key_usage.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.access_analyzer_service_account.email}"
}


# Workflows Service Account

resource "google_service_account" "workflows_service_account" {
  account_id   = var.workflows_sa_name
  display_name = "Service Account for executing Workflow operations"
}

resource "google_project_iam_member" "workflows_iam" {
  for_each = toset([
    "roles/cloudfunctions.invoker",
    "roles/logging.logWriter",
    "roles/run.invoker",
    "roles/workflows.invoker"
  ])
  project = data.google_project.sa_key_usage.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.workflows_service_account.email}"
}


# CAI Export Function Service Account

resource "google_service_account" "cai_export_service_account" {
  account_id   = "${var.cai_export_sa_name}-${var.org_resource_postfix}"
  display_name = "Service Account for exporting Cloud Asset Inventory data into BigQuery"
}

resource "google_project_iam_member" "cai_export_iam" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/cloudasset.viewer"
  ])
  project = data.google_project.sa_key_usage.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cai_export_service_account.email}"
}

resource "google_organization_iam_custom_role" "custom_cai_export_org_role" {
  role_id = "${var.custom_cai_org_role}_${var.org_resource_postfix}"
  org_id  = var.org_id
  title   = "CAI to BigQuery Export Role"
  permissions = [
    "cloudasset.assets.exportResource",
  ]
  stage = "GA"
  count = var.provision_org_iam ? 1 : 0
}

resource "google_organization_iam_member" "cai_export_organization_binding" {
  for_each = var.provision_org_iam ? {
    "roles/resourcemanager.organizationViewer" : "roles/resourcemanager.organizationViewer",
    "${var.custom_cai_org_role}" : "organizations/${var.org_id}/roles/${var.custom_cai_org_role}_${var.org_resource_postfix}"
  } : {}
  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.cai_export_service_account.email}"
}

resource "google_organization_iam_member" "access_analyzer_organization_binding" {
  for_each = var.provision_org_iam ? {
    "roles/policyanalyzer.activityAnalysisViewer" : "roles/policyanalyzer.activityAnalysisViewer",
    "roles/recommender.iamViewer" : "roles/recommender.iamViewer"
  } : {}
  org_id = var.org_id
  role   = each.value
  member  = "serviceAccount:${google_service_account.access_analyzer_service_account.email}"
}

resource "google_project_service_identity" "cai_sa" {
  provider = google-beta
  project = data.google_project.sa_key_usage.project_id
  service = "cloudasset.googleapis.com"
}

resource "google_project_iam_member" "cloud_asset_service_agent" {
  project = data.google_project.sa_key_usage.project_id
  role    = "roles/cloudasset.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.cai_sa.email}"
}