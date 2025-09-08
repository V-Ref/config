#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./repo_setup/sync-labels.sh                # upsert only
#   ./repo_setup/sync-labels.sh --prune        # upsert + delete unknown labels
#   ./repo_setup/sync-labels.sh --dry-run      # show plan only
#   ./repo_setup/sync-labels.sh --prune --dry-run

LABELS_FILE="repo_setup/labels.json"
DRY_RUN=false
PRUNE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --prune)   PRUNE=true ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

# Resolve owner/repo from git remote
REMOTE_URL="$(git config --get remote.origin.url || true)"
if [[ -z "${REMOTE_URL}" ]]; then
  echo "No git remote 'origin' found" >&2; exit 1
fi

# Support both HTTPS and SSH remote formats
if [[ "${REMOTE_URL}" =~ github.com[:/](.+)/(.+)\.git$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
else
  echo "Unsupported remote URL: ${REMOTE_URL}" >&2; exit 1
fi

if [[ ! -f "${LABELS_FILE}" ]]; then
  echo "Labels file not found: ${LABELS_FILE}" >&2; exit 1
fi

# Ensure gh auth or GH_TOKEN available
if ! gh auth status >/dev/null 2>&1; then
  if [[ -z "${GH_TOKEN:-}" ]]; then
    echo "gh not logged in and GH_TOKEN not set" >&2
    echo "Run: gh auth login   or   export GH_TOKEN=..." >&2
    exit 1
  fi
fi

echo "Target repo: ${OWNER}/${REPO}"
echo "Labels file: ${LABELS_FILE}"
echo "Options    : prune=${PRUNE}, dry-run=${DRY_RUN}"
echo

# Load desired labels
DESIRED_JSON="$(cat "${LABELS_FILE}")"
DESIRED_NAMES="$(echo "${DESIRED_JSON}" | jq -r '.[].name')"

# Fetch current labels
CURRENT_JSON="$(gh api "repos/${OWNER}/${REPO}/labels?per_page=100")"
CURRENT_NAMES="$(echo "${CURRENT_JSON}" | jq -r '.[].name')"

# Upsert
echo "== Upsert labels =="
echo "${DESIRED_JSON}" | jq -c '.[]' | while read -r item; do
  name="$(echo "${item}" | jq -r '.name')"
  color="$(echo "${item}" | jq -r '.color')"
  desc="$(echo "${item}" | jq -r '.description // ""')"

  if echo "${CURRENT_NAMES}" | grep -qx "${name}"; then
    echo "Update: ${name}"
    if [[ "${DRY_RUN}" == "false" ]]; then
      gh api -X PATCH "repos/${OWNER}/${REPO}/labels/${name}" \
        -f "new_name=${name}" -f "color=${color}" -f "description=${desc}" >/dev/null
    fi
  else
    echo "Create: ${name}"
    if [[ "${DRY_RUN}" == "false" ]]; then
      gh api -X POST "repos/${OWNER}/${REPO}/labels" \
        -f "name=${name}" -f "color=${color}" -f "description=${desc}" >/dev/null
    fi
  fi
done
echo

# Prune
if [[ "${PRUNE}" == "true" ]]; then
  echo "== Prune labels not in labels.json =="
  # Build a grep pattern of desired names
  TMP_PATTERN="$(echo "${DESIRED_NAMES}" | awk '{print "^"$0"$"}' | paste -sd'|' -)"
  echo "${CURRENT_NAMES}" | while read -r existing; do
    [[ -z "${existing}" ]] && continue
    if ! echo "${existing}" | grep -Eq "${TMP_PATTERN}"; then
      # Skip GitHub default labels if you want to keep them; otherwise delete
      # DEFAULTS=("good first issue" "help wanted")
      # for d in "${DEFAULTS[@]}"; do [[ "${existing}" == "$d" ]] && continue 2; done
      echo "Delete: ${existing}"
      if [[ "${DRY_RUN}" == "false" ]]; then
        gh api -X DELETE "repos/${OWNER}/${REPO}/labels/${existing}" >/dev/null || true
      fi
    fi
  done
  echo
fi

echo "Done."
