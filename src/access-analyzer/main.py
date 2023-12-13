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

import os

import analyze
import functions_framework
from flask import jsonify
from google.cloud import bigquery

project_id = os.environ.get("PROJECT_ID")
dataset = os.environ.get("RESOURCE_DATASET")
table_prefix = os.environ.get("TABLE_PREFIX")
destination_table = os.environ.get("DEST_TABLE")


@functions_framework.http
def main(self):
    client = bigquery.Client()
    sa_keys = get_keys(client)
    projects = set()
    key_dict = {}
    access_data = []
    for row in sa_keys:
        key_dict[row["key"]] = {
            "project": row["project_id"],
            "principalName": row["principal_name"],
            "keyId": row["key"],
            "keyCreationTime": str(row["valid_after_time"]),
            "keyLastUse": None,
            "requestTime": str(row["request_time"]),
            "recommenderSubtype": None,
            "recommenderDescription": None,
            "recommenderPriority": None,
            "recommenderRevokedIamPermissionsCount": None,
            "associatedRecommendation": None,
        }
        projects.add(row["project_id"])
    for project in projects:
        analysis_data = analyze.get_policy_analyzer_project(project)
        if analysis_data:
            for data in analysis_data:
                if data["keyId"] in key_dict:
                    key_dict[data["keyId"]].update(data)
    access_data = list(key_dict.values())
    if not access_data:
        print("No new rows to add.")
        return {}

    error = client.insert_rows_json(destination_table, access_data)

    if not error:
        print("New rows have been added.")
    else:
        print(f"Encountered errors while inserting rows: {error}")
    return jsonify(error)


def get_keys(bq_client):
    cai_table_query = bq_client.query(
        f"SELECT\n"
        f'REGEXP_EXTRACT(name, "projects/(.*)/serviceAccounts") AS project_id,\n'
        f'REGEXP_EXTRACT(resource.data.name, "serviceAccounts/(.*)/keys") AS principal_name,\n'
        f'REGEXP_EXTRACT(name, "keys/(.*)") AS key,\n'
        f"resource.data.validAfterTime AS valid_after_time,\n"
        f"requestTime AS request_time\n"
        f"FROM `{project_id}.{dataset}.{table_prefix}_iam_googleapis_com_ServiceAccountKey`\n"
        f"WHERE DATE(requestTime) = (\n"
        f"SELECT CAST(MAX(requestTime) AS DATE) FROM \
            `{project_id}.{dataset}.{table_prefix}_iam_googleapis_com_ServiceAccountKey`\n"
        f")\n"
        f'AND resource.data.keyType like "USER_MANAGED"'
    )
    sa_key_table = cai_table_query.result()
    return sa_key_table
