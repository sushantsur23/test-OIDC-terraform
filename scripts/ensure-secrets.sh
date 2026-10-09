#!/usr/bin/env bash
# Makes sure the AWS Secrets Manager secret exists and contains every
# required key. Missing pieces are filled with default values:
#   - secret does not exist          -> create it with all defaults
#   - secret is scheduled for delete -> restore it, then check keys
#   - secret exists but lacks a key  -> add only the missing keys
#   - secret has every key           -> change nothing
# Existing values are never overwritten, and no value is printed.
#
# Settings (environment variables):
#   SECRET_ID   secret name      (default: sushant-app/prod/ci-test-keys)
#   AWS_REGION  region           (default: us-east-1)
#   DEFAULT_AWS_ACCESS_KEY, DEFAULT_AWS_SECRET_KEY   values used when missing
#
# Requires: aws CLI v2, jq.

set -euo pipefail

SECRET_ID="${SECRET_ID:-sushant-app/prod/ci-test-keys}"
AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION

# Test placeholders only. Never put real credentials in this file.
DEFAULTS=$(jq -n \
  --arg access "${DEFAULT_AWS_ACCESS_KEY:-12345}" \
  --arg secret "${DEFAULT_AWS_SECRET_KEY:-12345}" \
  '{AWS_ACCESS_KEY: $access, AWS_SECRET_KEY: $secret}')

log() { echo "[ensure-secrets] $*"; }

# 1. Does the secret exist?
if ! describe=$(aws secretsmanager describe-secret --secret-id "$SECRET_ID" --output json 2>&1); then
  if grep -q "ResourceNotFoundException" <<<"$describe"; then
    log "Secret '$SECRET_ID' not found. Creating it with default values."
    aws secretsmanager create-secret \
      --name "$SECRET_ID" \
      --description "Test keys read by the terraform-prod GitHub workflow. Not managed by Terraform." \
      --secret-string "$DEFAULTS" \
      --output text --query Name >/dev/null
    log "Created '$SECRET_ID'."
    exit 0
  fi
  log "Could not check secret '$SECRET_ID':"
  echo "$describe" >&2
  exit 1
fi

# 2. Restore it if it was deleted but is still in its recovery window.
if [ "$(jq -r '.DeletedDate // empty' <<<"$describe")" != "" ]; then
  log "Secret '$SECRET_ID' is scheduled for deletion. Restoring it."
  aws secretsmanager restore-secret --secret-id "$SECRET_ID" --output text --query Name >/dev/null
fi

# 3. Read the current value. A secret can exist with no value yet.
current=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" \
  --query SecretString --output text 2>/dev/null || echo "{}")
if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$current"; then
  log "Secret value is not a JSON object. Refusing to overwrite it."
  exit 1
fi

# 4. Add only the keys that are missing or empty.
missing=$(jq -r --argjson d "$DEFAULTS" \
  '. as $cur | [$d | keys[] | select(($cur[.] // "") == "")] | join(" ")' <<<"$current")

if [ -z "$missing" ]; then
  log "Secret '$SECRET_ID' already has every required key. Nothing to do."
  exit 0
fi

log "Adding missing keys with default values: $missing"
merged=$(jq -c --argjson d "$DEFAULTS" \
  '. as $cur | $cur + ($d | with_entries(select(($cur[.key] // "") == "")))' \
  <<<"$current")
aws secretsmanager put-secret-value --secret-id "$SECRET_ID" \
  --secret-string "$merged" --output text --query Name >/dev/null
log "Updated '$SECRET_ID'."
