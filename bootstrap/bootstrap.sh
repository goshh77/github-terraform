#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# ONE-TIME bootstrap. Run this once, as a project Owner, in Cloud Shell or locally.
#
# It creates what GitHub Actions needs before it can run Terraform itself:
#   1. Enables the APIs Terraform and keyless auth depend on
#   2. GCS bucket for Terraform remote state (versioned, private)
#   3. "github-terraform-ci" service account that Terraform runs as
#   4. Workload Identity Federation pool + OIDC provider for GitHub
#      (no JSON keys anywhere; only goshh77/github-terraform can use it)
#   5. Prints (and optionally sets) the GitHub repository variables
#
# Safe to re-run: every step skips what already exists.
# ------------------------------------------------------------------------------
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-newprj-harsha}"
REGION="${REGION:-asia-south1}"
GITHUB_REPO="${GITHUB_REPO:-goshh77/github-terraform}"
STATE_BUCKET="${STATE_BUCKET:-${PROJECT_ID}-tfstate}"
SA_NAME="${SA_NAME:-github-terraform-ci}"
POOL_ID="${POOL_ID:-github-pool}"
PROVIDER_ID="${PROVIDER_ID:-github-provider}"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Roles for the CI service account (what Terraform is allowed to manage).
CI_ROLES=(
  roles/compute.admin
  roles/iam.serviceAccountAdmin
  roles/iam.serviceAccountUser
  roles/resourcemanager.projectIamAdmin
  roles/cloudsql.admin
  roles/servicenetworking.networksAdmin
  roles/secretmanager.admin
  roles/storage.admin
  roles/serviceusage.serviceUsageAdmin
  roles/iap.admin
)

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

log "Using project ${PROJECT_ID} / repo ${GITHUB_REPO}"
gcloud config set project "${PROJECT_ID}" >/dev/null
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"

log "Enabling bootstrap APIs"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com

log "Terraform state bucket gs://${STATE_BUCKET}"
if ! gcloud storage buckets describe "gs://${STATE_BUCKET}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${STATE_BUCKET}" \
    --location="${REGION}" \
    --uniform-bucket-level-access \
    --public-access-prevention
fi
gcloud storage buckets update "gs://${STATE_BUCKET}" --versioning >/dev/null

log "CI service account ${SA_EMAIL}"
if ! gcloud iam service-accounts describe "${SA_EMAIL}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${SA_NAME}" \
    --display-name="GitHub Actions Terraform (${GITHUB_REPO})"
  sleep 10 # let IAM propagate before binding roles
fi

log "Granting project roles to the CI service account"
for role in "${CI_ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${role}" \
    --condition=None >/dev/null
  echo "  + ${role}"
done

gcloud storage buckets add-iam-policy-binding "gs://${STATE_BUCKET}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectAdmin" >/dev/null

log "Workload Identity pool ${POOL_ID}"
if ! gcloud iam workload-identity-pools describe "${POOL_ID}" --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "${POOL_ID}" \
    --location=global \
    --display-name="GitHub Actions"
fi

log "OIDC provider ${PROVIDER_ID} (restricted to ${GITHUB_REPO})"
if ! gcloud iam workload-identity-pools providers describe "${PROVIDER_ID}" \
  --location=global --workload-identity-pool="${POOL_ID}" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
    --location=global \
    --workload-identity-pool="${POOL_ID}" \
    --display-name="GitHub OIDC" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'"
fi

log "Allowing ${GITHUB_REPO} to impersonate ${SA_EMAIL}"
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_REPO}" \
  >/dev/null

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"

log "Done. Add these as GitHub repository VARIABLES (Settings > Secrets and variables > Actions > Variables):"
cat <<EOF

  GCP_PROJECT_ID   = ${PROJECT_ID}
  GCP_WIF_PROVIDER = ${WIF_PROVIDER}
  GCP_SA_EMAIL     = ${SA_EMAIL}
  TF_STATE_BUCKET  = ${STATE_BUCKET}

EOF

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  read -r -p "gh CLI is logged in. Set these variables on ${GITHUB_REPO} now? [y/N] " ans
  if [[ "${ans}" =~ ^[Yy]$ ]]; then
    gh variable set GCP_PROJECT_ID   --repo "${GITHUB_REPO}" --body "${PROJECT_ID}"
    gh variable set GCP_WIF_PROVIDER --repo "${GITHUB_REPO}" --body "${WIF_PROVIDER}"
    gh variable set GCP_SA_EMAIL     --repo "${GITHUB_REPO}" --body "${SA_EMAIL}"
    gh variable set TF_STATE_BUCKET  --repo "${GITHUB_REPO}" --body "${STATE_BUCKET}"
    echo "Variables set."
  fi
fi

echo
echo "Next: create the 'dev' environment with Required reviewers (see README step 3)."
