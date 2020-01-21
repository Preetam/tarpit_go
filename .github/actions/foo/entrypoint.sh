#!/bin/sh

GITHUB_BRANCH=${GITHUB_REF##*/}
GITHUB_PROJECT=${GITHUB_REPO##*/}
PULL_REQUEST=$(curl "https://api.github.com/repos/$GITHUB_REPO/pulls?state=open" \
  -H "Authorization: Bearer $GITHUB_TOKEN" | jq ".[] | select(.head.sha==\"$GITHUB_SHA\") | .number")
echo "Got pull request $PULL_REQUEST for branch $GITHUB_BRANCH"

# Install ShiftLeft
curl https://cdn.shiftleft.io/download/sl > /usr/local/bin/sl && chmod a+rx /usr/local/bin/sl

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "pending", "context": "Code analysis"}'

sl analyze --tag branch="$GITHUB_BRANCH" --app "$GITHUB_PROJECT" --go --cpg --wait

curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/statuses/$GITHUB_SHA" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "failure", "context": "Code analysis"}'

curl "https://api.github.com/repos/$GITHUB_REPO/pulls?base=$GITHUB_BRANCH&state=open" \
  -H "Authorization: Bearer $GITHUB_TOKEN" | jq '.[0].number'

#curl -XPOST "https://api.github.com/repos/$GITHUB_REPO/issues/$PULL_REQUEST/comments" \
#  -H "Authorization: Bearer $GITHUB_TOKEN" \
#  -H "Content-Type: application/json" \
#  -d '{"body": "Test comment"}'
