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

"""Modules to work with Google Cloud services locally"""
import os

import functions_framework
from flask import jsonify
from google.cloud import asset_v1


@functions_framework.http
def main():
    """Function to write service account key data from asset inventory to BQ"""
    org_id = os.environ.get("ORG_ID")
    project_id = os.environ.get("PROJECT_ID")
    resource_dataset = os.environ.get("RESOURCE_DATASET")
    table_prefix = os.environ.get("TABLE_PREFIX")

    client = asset_v1.AssetServiceClient()
    output_config = asset_v1.OutputConfig()

    # Parent Config
    parent = f"organizations/{org_id}"

    # BQ Destination Config
    output_config.bigquery_destination.table = table_prefix
    output_config.bigquery_destination.force = True
    output_config.bigquery_destination.separate_tables_per_asset_type = True

    # Partition Spec Config
    partition_spec = asset_v1.PartitionSpec()
    partition_key = asset_v1.PartitionSpec.PartitionKey.REQUEST_TIME
    partition_spec.partition_key = asset_v1.PartitionSpec.PartitionKey.REQUEST_TIME

    output_config.bigquery_destination.partition_spec.partition_key = partition_key

    configs = {
        "resource": {
            "destination": f"projects/{project_id}/datasets/{resource_dataset}",
            "content_type": asset_v1.ContentType.RESOURCE,
            "asset_types": [
                "iam.googleapis.com/ServiceAccount",
                "iam.googleapis.com/ServiceAccountKey",
            ],
            "response": None,
        }
    }

    for config, field in configs.items():
        output_config.bigquery_destination.dataset = field["destination"]
        field["response"] = client.export_assets(
            request={
                "parent": parent,
                "content_type": configs[config]["content_type"],
                "asset_types": configs[config]["asset_types"],
                "output_config": output_config,
            }
        )

    # Resource Export Time >>> IAM Export Time, so we output operationId for Resource
    output = {"operationId": configs["resource"]["response"].operation.name}
    return jsonify(output)
