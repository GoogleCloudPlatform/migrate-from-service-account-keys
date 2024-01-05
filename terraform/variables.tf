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


# Shared variables

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}
variable "project_id" {
  description = "GCP project ID"
  type        = string
}
variable "region" {
  description = "Region to deploy resources within"
  type        = string
  default     = "us-central1"
}


# Scheduler

variable "sa_key_schedule" {
  description = "Cron schedule to import and analyze Service Account Key usage to BigQuery"
  type        = string
  default     = "0 5 * * *"
}

variable "code_path_prefix" {
  description = <<EOT
Path prefix to the folder where src/cai-export and src/access-analyzer are located.
Leave empty if the code can be found in its default location. Use "." for a relative path.
EOT
  type        = string
  default     = ""
}


# BigQuery

variable "cai_dataset_id" {
  description = "The Dataset ID for Cloud Asset Inventory (CAI) export data"
  type        = string
  default     = "cai_export"
}
variable "key_usage_dataset_id" {
  description = "The Dataset ID for Service Account key usage data"
  type        = string
  default     = "sa_key_usage"
}
variable "bq_location" {
  description = "The region or multi-region used for storing BigQuery data"
  type        = string
  default     = "US"
}


# IAM
variable "provision_org_iam" {
  description = "Boolean flag that determines if the principal running terraform has the role Organization Admin (meaning they can grant IAM roles at the organization node).  If `false`, a user with privileged access must manually provision grant IAM roles at the organization node."
  type        = bool
  default     = true
}
