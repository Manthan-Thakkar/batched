#!/bin/bash
# Variables: set your GitHub username/organization, repository name, and provide a personal access token with repo permissions via the TOKEN environment variable.
OWNER="LabelTraxx"
REPO="AmtechAPB"
# TOKEN must be set in the environment, e.g.: export TOKEN="ghp_..."

if [ -z "$TOKEN" ]; then
  echo "Error: TOKEN environment variable is not set. Please export a GitHub Personal Access Token with repo permissions."
  exit 1
fi
page=1
while true; do
  # List artifacts for the current page (up to 100 per page)
  response=$(curl -s -H "Authorization: Bearer $TOKEN" \
                   -H "Accept: application/vnd.github+json" \
                   "https://api.github.com/repos/$OWNER/$REPO/actions/artifacts?per_page=100&page=$page")
  # Extract artifact IDs
  artifact_ids=$(echo "$response" | jq '.artifacts[].id')
  
  # If no artifacts are found, exit the loop.
  if [ -z "$artifact_ids" ]; then
    echo "No more artifacts found."
    break
  fi
  
  # Delete each artifact
  for id in $artifact_ids; do
    echo "Deleting artifact ID: $id"
    curl -s -X DELETE -H "Authorization: Bearer $TOKEN" \
         -H "Accept: application/vnd.github+json" \
         "https://api.github.com/repos/$OWNER/$REPO/actions/artifacts/$id"
  done
  
  # If fewer than 100 artifacts were returned, this was the last page.
  count=$(echo "$response" | jq '.artifacts | length')
  if [ "$count" -lt 100 ]; then
    break
  fi
  page=$((page+1))
done
