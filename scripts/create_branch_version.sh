#!/bin/bash

echo "==> Creating version branch for ${PACTICIPANT}"
curl \
  -X PUT \
  -H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
  -H "Content-Type: application/json" \
  "${PACT_BROKER_BASE_URL}/pacticipants/${PACTICIPANT}/branches/${GIT_BRANCH}/versions/${GIT_COMMIT}" \
  -d '{}
 }'