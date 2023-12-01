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



# CAI Dataset

resource "google_bigquery_dataset" "cai_resource_dataset" {
  dataset_id                 = "${var.cai_dataset_id}_resource"
  location                   = var.bq_location
  delete_contents_on_destroy = true
}

# Key Usage Dataset

locals {
  sa_key_schema = jsonencode([
    { name = "project", type = "STRING" },
    { name = "principalName", type = "STRING" },
    { name = "keys", type = "RECORD", fields = [
      { name = "keyId", type = "STRING" },
      { name = "creationTime", type = "TIMESTAMP" },
      { name = "lastUse", type = "TIMESTAMP" },
    ] },
    { name = "requestTime", type = "TIMESTAMP" },
    { name = "recommenderSubtype", type = "STRING" },
    { name = "recommenderDescription", type = "STRING" },
    { name = "recommenderPriority", type = "STRING" },
    { name = "recommenderRevokedIamPermissionsCount", type = "NUMERIC" },
    { name = "associatedRecommendation", type = "STRING" },
  ])
}

resource "google_bigquery_dataset" "key_usage_dataset" {
  dataset_id                 = var.key_usage_dataset_id
  location                   = var.bq_location
  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "key_usage_table" {
  dataset_id          = google_bigquery_dataset.key_usage_dataset.dataset_id
  table_id            = "key_usage"
  schema              = local.sa_key_schema
  deletion_protection = false

  time_partitioning {
    field         = "requestTime"
    type          = "DAY"
    expiration_ms = null
  }
}