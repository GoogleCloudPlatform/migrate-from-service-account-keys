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


# Cloud Functions setup

resource "random_integer" "cai_bucket_postfix" {
  min = 1
  max = 50000
  keepers = {
    project_id = data.google_project.sa_key_usage.project_id
    region     = var.region
  }
}

resource "google_storage_bucket" "cai_code_bucket" {
  name     = "code-bucket-${random_integer.cai_bucket_postfix.result}"
  location = var.region
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
}


# CAI Export Function

data "archive_file" "cai_export_zip" {
  type        = "zip"
  output_path = "/tmp/cai-export.zip"
  source_dir  = "${var.path_prefix}src/cai-export/"
}

resource "google_storage_bucket_object" "cai_export_object" {
  name   = "cai-export.${data.archive_file.cai_export_zip.output_sha}.zip"
  bucket = google_storage_bucket.cai_code_bucket.name
  source = data.archive_file.cai_export_zip.output_path
}

resource "google_cloudfunctions2_function" "cai_export_function" {
  name        = "cai_export_function"
  description = "Exports Cloud Asset Inventory data into BigQuery"
  project     = data.google_project.sa_key_usage.project_id
  location    = var.region

  build_config {
    runtime     = "python310"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket_object.cai_export_object.bucket
        object = google_storage_bucket_object.cai_export_object.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 120
    service_account_email = google_service_account.cai_export_service_account.email
    environment_variables = {
      PROJECT_ID       = data.google_project.sa_key_usage.project_id,
      ORG_ID           = var.org_id,
      RESOURCE_DATASET = "${var.cai_dataset_id}_resource",
      TABLE_PREFIX     = "export",
    }
  }
}


# Access Analyzer Function

data "archive_file" "access_analyzer_zip" {
  type        = "zip"
  output_path = "/tmp/access-analyzer.zip"
  source_dir  = "${var.path_prefix}/src/access-analyzer/"
}

resource "google_storage_bucket_object" "access_analyzer_object" {
  name   = "access-analyzer.${data.archive_file.access_analyzer_zip.output_sha}.zip"
  bucket = google_storage_bucket.cai_code_bucket.name
  source = data.archive_file.access_analyzer_zip.output_path
}

resource "google_cloudfunctions2_function" "access_analyzer_function" {
  name        = "access-analyzer"
  description = "Analyzes Key Usage data in BigQuery"
  project     = data.google_project.sa_key_usage.project_id
  location    = var.region

  build_config {
    runtime     = "python310"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket_object.access_analyzer_object.bucket
        object = google_storage_bucket_object.access_analyzer_object.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "1024M"
    timeout_seconds       = 1800
    service_account_email = google_service_account.access_analyzer_service_account.email
    environment_variables = {
      PROJECT_ID       = data.google_project.sa_key_usage.project_id,
      ORG_ID           = var.org_id,
      DEST_TABLE       = "${data.google_project.sa_key_usage.project_id}.${var.key_usage_dataset_id}.key_usage",
      RESOURCE_DATASET = "${var.cai_dataset_id}_resource",
      TABLE_PREFIX     = "export",
    }
  }
}