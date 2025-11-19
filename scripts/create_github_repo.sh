#!/usr/bin/env bash
set -euo pipefail

# Script to create a GitHub repository and set MIT license automatically.
# Behavior:
# - Checks for gh CLI and uses it when available (recommended).
# - Falls back to using the GitHub API (requires GITHUB_TOKEN with repo scopes).
# - Ensures a local git repo exists with at least one commit.
# - Adds a remote origin and pushes the main branch.

PACKAGE_DIR=$(pwd)
# Dry-run option (no push, no remote changes when set)
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ] || [ "${DRY_RUN:-}" = "true" ]; then
  DRY_RUN=true
  echo "Running in dry-run mode (no push or remote changes)"
fi
if [ ! -f "$PACKAGE_DIR/pubspec.yaml" ]; then
  echo "No pubspec.yaml found in the current dir. Please run this script from your package root."
  exit 1
fi

PACKAGE_NAME=$(grep '^name:' pubspec.yaml | sed 's/name: //')
DESCRIPTION=$(grep '^description:' pubspec.yaml | sed 's/description: //')
USERNAME=${USERNAME:-SoundSliced}
REPO=${REPO:-$PACKAGE_NAME}
GITHUB_TOKEN=${GITHUB_TOKEN:-}

YEAR=$(date +%Y)

function ensure_git_repo() {
  if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit"
  fi

  # Ensure at least one commit and branch main
  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    git add .
    git commit -m "Initial commit"
  fi
  git branch -M main || true
}

function create_license_if_missing() {
  if [ ! -f LICENSE ] && [ ! -f LICENSE.md ]; then
    echo "Creating MIT LICENSE file..."
    cat > LICENSE <<LICENSE
MIT License

Copyright (c) $YEAR $USERNAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE
    git add LICENSE
    git commit -m "Add MIT license"
  fi
}

ensure_git_repo

# If gh CLI is available, use it (preferred)
if command -v gh >/dev/null 2>&1; then
  echo "Using GitHub CLI (gh) to create or update repository..."
    if gh repo view $USERNAME/$REPO >/dev/null 2>&1; then
    echo "Repository $USERNAME/$REPO already exists on GitHub. Will set remote and push."
    git remote remove origin 2>/dev/null || true
    git remote add origin https://github.com/$USERNAME/$REPO.git 2>/dev/null || true
    if [ "$DRY_RUN" = false ]; then
      git push -u origin main
    else
      echo "DRY RUN: would push to origin main"
    fi
  else
    echo "Creating new repository $USERNAME/$REPO on GitHub with MIT license..."
    # Login if needed (interactive). For CI or automation, ensure GH token is configured.
    if ! gh auth status >/dev/null 2>&1; then
      echo "You are not logged into GitHub CLI. Attempting to login interactively..."
      gh auth login
    fi
    if [ "$DRY_RUN" = false ]; then
      gh repo create $USERNAME/$REPO --public --description "$DESCRIPTION" --license mit || {
        echo "gh repo create failed. Falling back to API if token available..."
      }
    else
      gh repo create $USERNAME/$REPO --public --description "$DESCRIPTION" --license mit || {
        echo "DRY RUN: gh repo create failed or would have failed. Skipping push."
      }
    fi
      fi
else
  echo "GitHub CLI not found. Will try GitHub API with GITHUB_TOKEN fallback."
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "GITHUB_TOKEN is empty; cannot create repository without 'gh' or a GitHub token. Exiting."
    exit 1
  fi

  # Check if the repo exists
  status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$USERNAME/$REPO)
    if [ "$status" = "200" ]; then
    echo "Repository exists. Creating remote and pushing..."
    git remote remove origin 2>/dev/null || true
    git remote add origin https://github.com/$USERNAME/$REPO.git 2>/dev/null || true
    if [ "$DRY_RUN" = false ]; then
      git push -u origin main
    else
      echo "DRY RUN: would push to origin main"
    fi
  elif [ "$status" = "404" ]; then
    echo "Creating repository via GitHub API..."
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
      -d '{"name":"'$REPO'","description":"'$DESCRIPTION'","private":false,"auto_init":true,"license_template":"mit"}' \
      https://api.github.com/user/repos
    git remote remove origin 2>/dev/null || true
    git remote add origin https://github.com/$USERNAME/$REPO.git 2>/dev/null || true
    if [ "$DRY_RUN" = false ]; then
      git push -u origin main
    else
      echo "DRY RUN: would push to origin main"
    fi
  else
    echo "Unexpected response from GitHub API: $status. Exiting."
    exit 1
  fi
fi

# If the license wasn't created by gh or API and missing locally, create it
if [ ! -f LICENSE ] && [ ! -f LICENSE.md ]; then
  create_license_if_missing
  if [ "$DRY_RUN" = false ]; then
    git push
  else
    echo "DRY RUN: created LICENSE locally; would push if not dry-run"
  fi
fi

echo "Repository creation/push complete."
