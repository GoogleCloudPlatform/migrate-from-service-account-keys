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




# Shared Variables

variable "org_id" {
  description = "The GCP Organization ID"
  type        = string
}
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}
variable "region" {
  description = "Default Region to deploy resources"
  type        = string
}
variable "org_resource_postfix" {
  description = "Postfix number to avoid conflicts within an Organization"
  type        = number
  default     = 0
}

data "google_project" "sa_key_usage" {
  project_id = var.project_id
}


# BigQuery

variable "bq_location" {
  description = "The region or multi-region used for storing BigQuery data"
  type        = string
}
variable "cai_dataset_id" {
  description = "The Dataset ID for CAI data"
  type        = string
}
variable "key_usage_dataset_id" {
  description = "The Dataset ID for SA key usage data"
  type        = string
}


# IAM

variable "provision_org_iam" {
  description = "Boolean flag that determines if Organization IAM resources can be provisioned with Terraform.  If False, user must manually provision the necessary role (custom_cai_export_org_role) and binding (cai_export_organization_binding) on the Organization."
  type        = bool
}
variable "scheduler_sa_name" {
  description = "The service account name for invoking Workflows"
  type        = string
  default     = "scheduler-sa"
}
variable "access_analyzer_sa_name" {
  description = "The service account name for analyzing Key Usage data in BigQuery"
  type        = string
  default     = "access-analyzer"
}
variable "workflows_sa_name" {
  description = "The service account name for executing Workflow operations"
  type        = string
  default     = "workflows-sa"
}
variable "cai_export_sa_name" {
  description = "The service account name for exporting Cloud Asset Inventory data into BigQuery"
  type        = string
  default     = "cai-export-sa"
}
variable "custom_cai_org_role" {
  description = "The name of the custom CAI Organization Role"
  type        = string
  default     = "caiExportRole"
}


# Cloud Functions

variable "path_prefix" {
  description = <<EOT
Path prefix to the folder where src/cai-export and src/access-analyzer are located.
Leave empty if the code can be found in its default location. Use "." for a relative path.
EOT
  type        = string
  default     = ""
}


# Workflows

variable "workflow_schedule" {
  description = "Cron schedule to run the CAI SA workflow"
  type        = string
}
