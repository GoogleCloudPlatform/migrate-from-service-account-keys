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

from google.auth.transport.requests import AuthorizedSession
import google.auth

cred, project = google.auth.default(
    scopes=['https://www.googleapis.com/auth/cloud-platform'])

'''
auth_req = google.auth.transport.requests.Request()
cred.refresh(auth_req)
'''

def get_policy_analyzer_project(project_id):
    authed_session = AuthorizedSession(cred)
    keyactivity = []

    def process_keyactivity(response):
        if response and 'error' not in response:
            for activity in response['activities']:
                name = activity['fullResourceName'].split('/')
                sa_email = name[6]
                sa_data = {
                    'keys': {
                        'keyId': name[8],
                        'lastUse': None,
                    },
                    'recommenderSubtype': None,
                    'recommenderDescription': None,
                    'recommenderRevokedIamPermissionsCount': None,
                    'recommenderPriority': None,
                    'associatedRecommendation': None,
                }
                sa_data['keys']['lastUse'] = activity['activity'].get(
                    'lastAuthenticatedTime', None)
                recommendations = get_recommendations(project_id, sa_email)
                if recommendations:
                    sa_data.update(recommendations)
                keyactivity.append(sa_data)

    response = authed_session.get(
        f"https://policyanalyzer.googleapis.com/v1/projects/{project_id}/locations/global/activityTypes/serviceAccountKeyLastAuthentication/activities:query").json()
    process_keyactivity(response)
    while 'nextPageToken' in response:
        params = {
            'pageToken': response['nextPageToken']
        }
        response = authed_session.get(
            f"https://policyanalyzer.googleapis.com/v1/projects/{project_id}/locations/global/activityTypes/serviceAccountKeyLastAuthentication/activities:query", params=params).json()
        process_keyactivity(response)
    return keyactivity

def get_recommendations(project_id, sa_email):
    authed_session = AuthorizedSession(cred)
    data = {}
    response = authed_session.get(
        f"https://recommender.googleapis.com/v1/projects/{project_id}/locations/global/recommenders/google.iam.policy.Recommender/recommendations").json()
    if response and 'error' not in response:
        for recommendation in response['recommendations']:
            if(sa_email in recommendation['content']['overview']['member']):
                data = {
                    'recommenderSubtype' : recommendation['recommenderSubtype'],
                    'recommenderDescription' : recommendation['description'],
                    'recommenderRevokedIamPermissionsCount' : recommendation['primaryImpact']['securityProjection']['details']['revokedIamPermissionsCount'],
                    'recommenderPriority' : recommendation['priority'],
                    'associatedRecommendation' : recommendation['name'],
                }
    return data