#!/bin/bash

# Script to trigger a workflow_dispatch event
# and provide a set of explicit input events
# - PACT_CLI_DOCKER_VERSION
#   - latest
#   - any tag
# Requires a Github API token with repo scope stored in the
# environment variable GITHUB_ACCESS_TOKEN_FOR_PF_RELEASES
# Adapated from Beth Skurrie's excellent script at
# https://github.com/pact-foundation/pact-ruby/blob/master/script/trigger-release.sh
# Reference documentation
# https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event

: "${GITHUB_ACCESS_TOKEN_FOR_PF_RELEASES:?Please set environment variable GITHUB_ACCESS_TOKEN_FOR_PF_RELEASES}"

repository_slug=$(git remote get-url $(git remote show) | cut -d':' -f2 | sed 's/\.git//')

PACT_CLI_DOCKER_VERSION=${1:-'latest'}
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
output=$(curl -L -v -X POST https://api.github.com/repos/${repository_slug}/actions/workflows/build.yml/dispatches \
    -H 'Accept: application/vnd.github.v3+json' \
    -H "Authorization: Bearer $GITHUB_ACCESS_TOKEN_FOR_PF_RELEASES" \
    -d "{\"ref\":\"$GIT_BRANCH\",\"inputs\":{\"PACT_CLI_DOCKER_VERSION\":\"$PACT_CLI_DOCKER_VERSION\"}}" 2>&1)

if ! echo "${output}" | grep "HTTP\/2 204" >/dev/null; then
    echo "$output" | sed "s/${GITHUB_ACCESS_TOKEN_FOR_PF_RELEASES}/********/g"
    echo "Failed to trigger release"
    exit 1
else
    echo "workflow_dispatch triggered for $repository_slug using PACT_CLI_DOCKER_VERSION=$PACT_CLI_DOCKER_VERSION "
fi
