PACTICIPANT := "pactflow-example-bi-directional-provider-postman"
GITHUB_REPO := "pactflow/example-bi-directional-provider-postman"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:latest"

# Only deploy from master
ifeq ($(GIT_BRANCH),master)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

all: test

## ====================
## CI tasks
## ====================

ci:
	@if make test; then \
		make publish_success; \
	else \
		make publish_failure; \
	fi; \

create_branch_version:
	@echo "\n========== STAGE: pre-publish contract - create_branch_version ==========\n"
	@echo "\n Creating a branch version to associate with the Provider contract on upload\n"
	PACTICIPANT=${PACTICIPANT} ./scripts/create_branch_version.sh

publish_success: .env create_branch_version
	@echo "\n========== STAGE: publish contract + results (success) ==========\n"
	PACTICIPANT=${PACTICIPANT} npm run test:publish -- true

publish_failure: .env create_branch_version
	@echo "\n========== STAGE: publish contract + results (failure) ==========\n"
	PACTICIPANT=${PACTICIPANT} npm run test:publish -- false

# Run the ci target from a developer machine with the environment variables
# set as if it was on Github Actions.
# Use this for quick feedback when playing around with your workflows.
fake_ci: .env
	GIT_COMMIT=`git rev-parse --short HEAD` \
	GIT_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	make ci; 
	GIT_COMMIT=`git rev-parse --short HEAD` \
	GIT_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	make deploy_target

deploy_target: can_i_deploy $(DEPLOY_TARGET)

## =====================
## Build/test tasks
## =====================

test: .env
	@echo "\n========== STAGE: test ✅ ==========\n"
	@echo "Running postman collection via Newman CLI runner, to test locally running provider"
	@npm run test
	@echo "converting postman collection into OAS spec"
	@npm run test:convert 
	@echo "Running transform, to set additionalProperties to false in converted oas spec"
	@sed 's/^\([[:space:]]*\)\(type: object\)/\1additionalProperties: false\n\1\2/' oas/oas_from_postman_collection.yml > oas/swagger.yml
	@echo "Transformed oas spec available at ./oas/swagger.yml"

## =====================
## Deploy tasks
## =====================

deploy: deploy_app record_deployment

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy: .env
	@echo "\n========== STAGE: can-i-deploy? 🌉 ==========\n"
	@"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --to-environment production

deploy_app:
	@echo "\n========== STAGE: deploy 🚀 ==========\n"
	@echo "Deploying to prod"

record_deployment: .env
	@"${PACT_CLI}" broker record_deployment --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --environment production

## =====================
## Pactflow set up tasks
## =====================

## ======================
## Misc
## ======================

convert:
	npm run test:convert
.env:
	touch .env

.PHONY: start stop test