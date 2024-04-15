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




# Scheduler to invoke Workflow

resource "google_cloud_scheduler_job" "cai_sa_key_workflow_scheduler" {
  name             = "cai-sa-key-analysis-schedule"
  description      = "Scheduled export and analysis of CAI keys"
  schedule         = var.workflow_schedule
  time_zone        = "America/New_York"
  attempt_deadline = "320s"
  region           = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.cai_sa_workflow.id}/executions"
    body        = base64encode("{}")
    oauth_token {
      service_account_email = google_service_account.scheduler_service_account.email
    }
  }
}


# Workflow to orchestrate CAI Export and SA Key analysis

resource "google_workflows_workflow" "cai_sa_workflow" {
  name            = "cai-sa-key-analysis-workflow"
  region          = var.region
  description     = "Workflow to export CAI to a partitioned table and analyze SA keys"
  service_account = google_service_account.workflows_service_account.email
  depends_on = [
    google_project_iam_member.workflows_iam
  ]
  source_contents = <<-EOF
     main:
        steps:
        - exportCAI:
            call: http.get
            args:
                url: ${google_cloudfunctions2_function.cai_export_function.service_config[0].uri}
                headers:
                    User-Agent: "cloud-solutions/migrate-from-service-account-keys-v1"
                auth:
                    type: OIDC
                    audience: ${google_cloudfunctions2_function.cai_export_function.service_config[0].uri}
            result: operationId
        - logOperationId:
            call: sys.log
            args:
                text: $${operationId.body}
                severity: INFO
        - checkCAIOperation:
            call: http.get
            args:
                url: $${"https://cloudasset.googleapis.com/v1/" + operationId.body.operationId}
                headers:
                    User-Agent: "cloud-solutions/migrate-from-service-account-keys-v1"
                auth:
                    type: OAuth2
            result: jobStatus
            next: checkIfDone
        - logOperationStatus:
            call: sys.log
            args:
                text: $${jobStatus}
                severity: INFO
        - checkIfDone:
            switch:
                - condition: $${default(map.get(jobStatus.body, "done"), False)}
                  next: processKeys
        - wait:
            call: sys.sleep
            args:
                seconds: 5
            next: checkCAIOperation
        - processKeys:
            call: http.get
            args:
                url: ${google_cloudfunctions2_function.access_analyzer_function.service_config[0].uri}
                headers:
                    User-Agent: "cloud-solutions/migrate-from-service-account-keys-v1"
                auth:
                    type: OIDC
                    audience: ${google_cloudfunctions2_function.access_analyzer_function.service_config[0].uri}
            result: operationId
    EOF
}
