#!/bin/bash

echo "==> Creating version tag for ${PACTICIPANT}"
curl \
  -X PUT \
  -H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
  -H "Content-Type: application/json" \
  "${PACT_BROKER_BASE_URL}/pacticipants/${PACTICIPANT}/versions/${GIT_COMMIT}/tags/${GIT_BRANCH}" \
  -d '{}
 }'