#!/bin/sh

echo "Started"

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "pending", "context": "Security checks", "target_url": "https://example.com"}'

sleep 10

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "failure", "context": "Security checks", "target_url": "https://example.com"}'
echo "Ended"

PULL_REQUEST=$(curl "https://api.github.com/repos/$GITHUB_REPO/pulls?base=$GITHUB_BRANCH&state=open" \
  -H "Authorization: Bearer $GITHUB_TOKEN" | jq '.[0].number')

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/issues/$PULL_REQUEST/comments" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": "Test comment"}'

echo "Ended"