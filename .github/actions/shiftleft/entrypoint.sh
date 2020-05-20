#!/bin/sh

set -e

GITHUB_BRANCH=${GITHUB_REF##*/}
GITHUB_PROJECT=${GITHUB_REPO##*/}
PULL_REQUEST=$(curl "https://api.github.com/repos/$GITHUB_REPO/pulls?state=open" \
  -H "Authorization: Bearer $GITHUB_TOKEN" | jq ".[] | select(.head.sha==\"$GITHUB_SHA\") | .number")
echo "Got pull request $PULL_REQUEST for branch $GITHUB_BRANCH"

go build

# Install ShiftLeft
curl https://cdn.shiftleft.io/download/sl > /usr/local/bin/sl && chmod a+rx /usr/local/bin/sl

curl -s -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "pending", "context": "Code analysis"}'

sl analyze --version-id "$GITHUB_SHA" --tag branch="$GITHUB_BRANCH" --tag app.group="go-app" --app "$GITHUB_PROJECT" --go --cpg --wait --force .

curl -s -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "success", "context": "Code analysis"}'

sleep 5

curl -s -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "pending", "context": "Vulnerability analysis"}'

# VULNS=$(curl -s -XPOST "https://www.shiftleft.io/api/v3/public/org/$SHIFTLEFT_ORG_ID/app/$GITHUB_PROJECT/vulnerabilities/" \
#   -H "Authorization: Bearer $SHIFTLEFT_API_TOKEN" | jq -c -r '[.totalResults,.lowImpactResults,.highImpactResults]')

# TOTAL=$(echo "$VULNS" | jq -c -r '.[0]')
# LOW=$(echo "$VULNS" | jq -c -r '.[1]')
# HIGH=$(echo "$VULNS" | jq -c -r '.[2]')

# COMMENT="## Vulnerability summary\\n\\nTotal: $TOTAL\\nHigh impact: $HIGH\\nLow impact: $LOW"

# curl -s -XPOST "https://api.github.com/repos/$GITHUB_REPO/issues/$PULL_REQUEST/comments" \
#   -H "Authorization: Bearer $GITHUB_TOKEN" \
#   -H "Content-Type: application/json" \
#   -d "{\"body\": \"$COMMENT\"}"

COMMENT_BODY='{"body":""}'
COMMENT_BODY=$(echo "$COMMENT_BODY" | jq '.body += "<img height=20 src=\"https://www.shiftleft.io/static/images/ShiftLeft_logo_white.svg\"/> — Inspect Analysis Findings\n===\n\n"')

NEW_FINDINGS=$(curl -H "Authorization: Bearer $SHIFTLEFT_API_TOKEN" "https://www.shiftleft.io/api/v4/orgs/$SHIFTLEFT_ORG_ID/apps/$GITHUB_PROJECT/scans/compare?source=tag.branch=master&target=tag.branch=$GITHUB_BRANCH" | jq -c -r '.response.new | .? | .[] | "* [ID " + .id + "](https://www.shiftleft.io/findingDetail/" + .app + "/" + .id + "): " + "["+.severity+"] " + .title')

COMMENT_BODY=$(echo "$COMMENT_BODY" | jq ".body += \"### New findings\n\n\"")
COMMENT_BODY=$(echo "$COMMENT_BODY" | jq ".body += \"$NEW_FINDINGS\n\n\"")

curl -s -XPOST "https://api.github.com/repos/$GITHUB_REPO/issues/$PULL_REQUEST/comments" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$COMMENT_BODY"

curl -s -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"state\": \"success\", \"context\": \"Vulnerability analysis\", \"target_url\": \"https://www.shiftleft.io/violationlist/$GITHUB_PROJECT?apps=$GITHUB_PROJECT&isApp=1\"}"

sl check-analysis --app "$GITHUB_PROJECT" --source 'tag.branch=master' --target "tag.branch=$GITHUB_BRANCH"
