# Copyright 2021 Ignacio Asin (iasinDev)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

on: 
  workflow_dispatch:

name: Destroy GCP resources
env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT }}
  SERVICE: ${{ secrets.SERVICE_NAME }}
  REGION: ${{ secrets.GCP_REGION }}
  ZONE: ${{ secrets.GCP_ZONE }}

jobs:

  destroy-terraform-resources:  

    runs-on: ubuntu-latest

    steps:

    - name: Enable GitHub Actions
      uses: actions/checkout@v3.3.0

    - id: auth
      uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}

    - name: Set up Cloud SDK
      uses: google-github-actions/setup-gcloud@v1
      with:
        project_id: ${{ env.PROJECT_ID }}

    - name: Getting tag of the built image
      run: |-
        image_tag=$(gcloud container images list-tags gcr.io/${{ env.PROJECT_ID }}/${{ env.SERVICE }} --limit=1 --sort-by=~TIMESTAMP --format='get(tags)')
        IFS=';' read -ra image_tag_ARRAY <<< "$image_tag"
        image_tag=${image_tag_ARRAY[0]}
        echo "image_tag: $image_tag"     
        echo "image_tag=$image_tag" >> $GITHUB_ENV
    # Install the latest version of Terraform CLI and configure the Terraform CLI configuration file with a Terraform Cloud user API token
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2.0.3

    # Initialize a new or existing Terraform working directory by creating initial files, loading any remote state, downloading modules, etc.
    - name: Terraform Init
      run: terraform init
      env:
        GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
        TF_VAR_project_id: ${{ env.PROJECT_ID }}
        TF_VAR_region: ${{ env.REGION }}
        TF_VAR_zone: ${{ secrets.GCP_ZONE }}

    # Destroy the resources
    - name: Terraform Destroy      
      run: terraform destroy -lock=false -auto-approve
      env:
        GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
        TF_VAR_project_id: ${{ env.PROJECT_ID }}
        TF_VAR_region: ${{ env.REGION }}
        TF_VAR_zone: ${{ env.ZONE }}
        TF_VAR_service: ${{ env.SERVICE }}
        TF_VAR_image_tag: ${{ env.image_tag }}
        