#!/usr/bin/env bash
set -e

# Spottr — GitHub create + push script
# Run this directly in Terminal. Your token never leaves your machine.

read -s -p "Paste your GitHub token (input hidden): " TOKEN
echo ""

# Verify token & get username
USERNAME=$(curl -sf https://api.github.com/user \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])")

if [ -z "$USERNAME" ]; then
  echo "Token invalid or revoked. Generate a fresh one and try again."
  exit 1
fi

echo "Authenticated as: $USERNAME"

# Create repo
HTTP=$(curl -s -o /tmp/gh_create.json -w "%{http_code}" \
  -X POST https://api.github.com/user/repos \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d '{"name":"spottr-prototype","description":"Spottr — mobile onboarding prototype","private":false}')

if [ "$HTTP" = "201" ]; then
  echo "Repo created: https://github.com/$USERNAME/spottr-prototype"
elif [ "$HTTP" = "422" ]; then
  echo "Repo already exists, continuing..."
else
  echo "Repo creation failed (HTTP $HTTP)"; cat /tmp/gh_create.json; exit 1
fi

# Init git + commit if needed
git init
git add index.html
git diff --cached --quiet && echo "Nothing to commit" || git commit -m "Initial prototype: Spottr onboarding app"

# Set remote and push
git remote remove origin 2>/dev/null || true
git remote add origin "https://$USERNAME:$TOKEN@github.com/$USERNAME/spottr-prototype.git"
git branch -M main
git push -u origin main

echo ""
echo "Done! Repo live at: https://github.com/$USERNAME/spottr-prototype"
echo ""
echo "Next: run 'npx vercel' in this directory to get a live URL."
