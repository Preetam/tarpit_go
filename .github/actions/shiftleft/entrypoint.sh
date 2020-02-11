#!/bin/sh

GITHUB_BRANCH=${GITHUB_REF##*/}
GITHUB_PROJECT=${GITHUB_REPO##*/}
PULL_REQUEST=$(curl "https://api.github.com/repos/$GITHUB_REPO/pulls?state=open" \
  -H "Authorization: Bearer $GITHUB_TOKEN" | jq ".[] | select(.head.sha==\"$GITHUB_SHA\") | .number")
echo "Got pull request $PULL_REQUEST for branch $GITHUB_BRANCH"

go get ./...
go build

# Install ShiftLeft
curl https://cdn.shiftleft.io/download/sl > /usr/local/bin/sl && chmod a+rx /usr/local/bin/sl

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "pending", "context": "Code analysis"}'

sl analyze --version-id "$GITHUB_SHA" --tag branch="$GITHUB_BRANCH" --app "$GITHUB_PROJECT" --go --cpg --wait --force .

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "success", "context": "Code analysis"}'

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "pending", "context": "Vulnerability analysis"}'

VULNS=$(curl -XPOST "https://www.shiftleft.io/api/v3/public/org/$SHIFTLEFT_ORG_ID/app/$GITHUB_PROJECT/vulnerabilities/" \
  -H "Authorization: Bearer $SHIFTLEFT_API_TOKEN" | jq -c -r '[.totalResults,.lowImpactResults,.highImpactResults]')

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"state\": \"success\", \"context\": \"Vulnerability analysis\", \"target_url\": \"https://www.shiftleft.io/violationlist/$GITHUB_PROJECT?apps=$GITHUB_PROJECT&isApp=1\"}"

TOTAL=$(echo "$VULNS" | jq -c -r '.[0]')
LOW=$(echo "$VULNS" | jq -c -r '.[1]')
HIGH=$(echo "$VULNS" | jq -c -r '.[2]')

COMMENT="## Vulnerability summary\\n\\nTotal: $TOTAL\\nHigh impact: $HIGH\\nLow impact: $LOW"

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/issues/$PULL_REQUEST/comments" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"$COMMENT\"}"

sl check-analysis --app "$GITHUB_PROJECT" --branch "$GITHUB_BRANCH"
