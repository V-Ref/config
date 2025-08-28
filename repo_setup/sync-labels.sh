#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   sync-labels.sh --org V-Ref --repos "vref-fe vref-be vref-docs" --file labels.json [--dry-run true]
ORG=""
REPOS=""
FILE="labels.json"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="$2"; shift 2 ;;
    --repos) REPOS="$2"; shift 2 ;;
    --file) FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null; then echo "gh CLI required"; exit 1; fi
if ! command -v jq >/dev/null; then echo "jq required"; exit 1; fi
if [[ -z "$ORG" || -z "$REPOS" ]]; then
  echo "Missing --org or --repos"; exit 1
fi
if [[ ! -f "$FILE" ]]; then
  echo "labels file not found: $FILE"; exit 1
fi

echo ">>> ORG=$ORG"
echo ">>> REPOS=$REPOS"
echo ">>> FILE=$FILE"
echo ">>> DRY_RUN=$DRY_RUN"

# TSV: name<TAB>color<TAB>description
mapfile -t LABEL_ROWS < <(jq -r '.[] | [.name, .color, (.description // "")] | @tsv' "$FILE")

for REPO in $REPOS; do
  echo "---- Syncing labels for $ORG/$REPO ----"
  mapfile -t EXISTING < <(gh api "repos/$ORG/$REPO/labels" --paginate -q '.[].name' || true)

  for ROW in "${LABEL_ROWS[@]}"; do
    IFS=$'\t' read -r NAME COLOR DESC <<<"$ROW"

    if printf '%s\n' "${EXISTING[@]}" | grep -qx "$NAME"; then
      echo "update: $NAME"
      if [[ "$DRY_RUN" != "true" ]]; then
        gh api -X PATCH "repos/$ORG/$REPO/labels/$NAME" \
          -f new_name="$NAME" -f color="$COLOR" -f description="$DESC" >/dev/null || true
      fi
    else
      echo "create: $NAME"
      if [[ "$DRY_RUN" != "true" ]]; then
        gh api -X POST "repos/$ORG/$REPO/labels" \
          -f name="$NAME" -f color="$COLOR" -f description="$DESC" >/dev/null || true
      fi
    fi
  done

  # (옵션) labels.json에 없는 라벨을 지울지 여부는 정책으로 결정
  # if want prune: list existing - desired → DELETE

done
echo "Done."
