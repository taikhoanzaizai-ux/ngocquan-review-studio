#!/usr/bin/env bash
set -euo pipefail

SOURCE_REPO="https://github.com/tinhot24h/dungclaude-edit-tiktok.git"
SOURCE_BRANCH="main"
DEST_BRANCH="main"

cd "$(git rev-parse --show-toplevel)"

echo "==> Importing full source from: $SOURCE_REPO"

# Make sure origin points to this repository and we are on main.
git checkout "$DEST_BRANCH"

# Preserve Ngoc Quan Codespaces helpers so the imported app can still be developed here.
TMP_KEEP="$(mktemp -d)"
trap 'rm -rf "$TMP_KEEP"' EXIT

for p in .devcontainer RUN_CODESPACE.sh IMPORT_UPSTREAM.sh; do
  if [ -e "$p" ]; then
    mkdir -p "$TMP_KEEP/$(dirname "$p")"
    cp -a "$p" "$TMP_KEEP/$p"
  fi
done

# Fetch upstream without merging histories.
if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "$SOURCE_REPO"
else
  git remote add upstream "$SOURCE_REPO"
fi

git fetch --depth=1 upstream "$SOURCE_BRANCH"
UPSTREAM_SHA="$(git rev-parse FETCH_HEAD)"
echo "==> Upstream commit: $UPSTREAM_SHA"

# Remove the current tracked project files, then check out the full upstream tree.
# .git itself is never touched.
git ls-files -z | xargs -0 -r git rm -f --ignore-unmatch

git checkout FETCH_HEAD -- .

# Restore development helpers that are specific to this repository.
for p in .devcontainer RUN_CODESPACE.sh IMPORT_UPSTREAM.sh; do
  if [ -e "$TMP_KEEP/$p" ]; then
    rm -rf "$p"
    mkdir -p "$(dirname "$p")"
    cp -a "$TMP_KEEP/$p" "$p"
  fi
done

cat > UPSTREAM_SOURCE.md <<EOF
# Upstream source provenance

This repository contains source imported from:

- Upstream repository: https://github.com/tinhot24h/dungclaude-edit-tiktok
- Imported commit: $UPSTREAM_SHA
- Imported branch: $SOURCE_BRANCH

The upstream repository did not expose a root LICENSE file at the time of import. This provenance file is intentionally retained. Third-party license files bundled with assets/fonts must also be retained.
EOF

# Prevent the imported updater from accidentally assuming this repository is the upstream owner.
# We do not rewrite application code here; later customization can be done explicitly.

git add -A

if git diff --cached --quiet; then
  echo "==> Nothing changed. Source is already imported."
  exit 0
fi

git config user.name "taikhoanzaizai-ux"
git config user.email "taikhoanzaizai-ux@users.noreply.github.com"
git commit -m "Import full upstream Review Studio source"
git push origin "$DEST_BRANCH"

echo
echo "============================================================"
echo "DONE: full upstream source is now committed to your repo."
echo "Upstream commit: $UPSTREAM_SHA"
echo "============================================================"
