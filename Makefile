PACTICIPANT ?= "pactflow-example-bi-directional-provider-postman"
GITHUB_REPO := "pactflow/example-bi-directional-provider-postman"
COMMIT?=$(shell git rev-parse --short HEAD)
BRANCH?=$(shell git rev-parse --abbrev-ref HEAD)

## ====================
## Demo Specific Example Variables
## ====================
CI_COMMAND?=publish_provider_contract
OAS_PATH=oas/swagger.yml
REPORT_PATH?=$(shell ls newman/*)
REPORT_FILE_CONTENT_TYPE?=text/plain
VERIFIER_TOOL?=postman

## =====================
## Build/test tasks
## =====================

install: npm install 

test: .env
	@echo "\n========== STAGE: test ✅ ==========\n"
	@echo "Running postman collection via Newman CLI runner, to test locally running provider"
	@npm run test
	@echo "converting postman collection into OAS spec"
	@npm run test:convert 

## =====================
## Pact CLI install/uninstall tasks
## =====================
PACT_TOOL?=docker
PACT_CLI_DOCKER_VERSION?=0.50.0.28
PACT_CLI_VERSION?=latest
PACT_CLI_STANDALONE_VERSION?=1.89.00-rc1
PACT_CLI_DOCKER_RUN_COMMAND?=docker run --rm -v /${PWD}:/${PWD} -w ${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:${PACT_CLI_DOCKER_VERSION}
PACT_BROKER_COMMAND=pact-broker
PACTFLOW_CLI_COMMAND=pactflow

install-pact-ruby-cli:
	case "${PACT_CLI_VERSION}" in \
	latest) gem install pact_broker-client;; \
	"") gem install pact_broker-client;; \
		*) gem install pact_broker-client -v ${PACT_CLI_VERSION} ;; \
	esac

uninstall-pact-ruby-cli:
	gem uninstall -aIx pact_broker-client

install-pact-ruby-standalone:
	case "${detected_OS}" in \
	Windows|MSYS) curl -LO https://github.com/pact-foundation/pact-ruby-standalone/releases/download/v${PACT_CLI_STANDALONE_VERSION}/pact-${PACT_CLI_STANDALONE_VERSION}-win32.zip && \
		unzip pact-${PACT_CLI_STANDALONE_VERSION}-win32.zip && \
		./pact/bin/pact-mock-service.bat --help && \
		./pact/bin/pact-provider-verifier.bat --help && \
		./pact/bin/pactflow help;; \
	Darwin) curl -LO https://github.com/pact-foundation/pact-ruby-standalone/releases/download/v${PACT_CLI_STANDALONE_VERSION}/pact-${PACT_CLI_STANDALONE_VERSION}-osx.tar.gz && \
		tar xzf pact-${PACT_CLI_STANDALONE_VERSION}-osx.tar.gz && \
		./pact/bin/pact-mock-service --help && \
		./pact/bin/pact-provider-verifier --help && \
		./pact/bin/pactflow help;; \
	Linux) curl -LO https://github.com/pact-foundation/pact-ruby-standalone/releases/download/v${PACT_CLI_STANDALONE_VERSION}/pact-${PACT_CLI_STANDALONE_VERSION}-linux-x86_64.tar.gz && \
		tar xzf pact-${PACT_CLI_STANDALONE_VERSION}-linux-x86_64.tar.gz && \
		./pact/bin/pact-mock-service --help && \
		./pact/bin/pact-provider-verifier --help && \
		./pact/bin/pactflow help;; \
	esac

## ====================
## CI tasks
## ====================

all: ci
all_docker: ci_docker
all_ruby_standalone: ci_ruby_standalone
all_ruby_cli: ci_ruby_cli

# Run the ci target from a developer machine with the environment variables
# set as if it was on Github Actions.
# Use this for quick feedback when playing around with your workflows.
ci: .env test_and_publish can_i_deploy $(DEPLOY_TARGET)

ci_ruby_cli:
	PACT_TOOL=ruby_cli make ci
ci_docker:
	PACT_TOOL=docker make ci
ci_ruby_standalone:
	PACT_TOOL=ruby_standalone make ci

test_and_publish:
	@if make test; then \
		EXIT_CODE=0 make ${CI_COMMAND}; \
	else \
		EXIT_CODE=1 make ${CI_COMMAND}; \
	fi; \

publish_provider_contract: .env
	@echo "\n========== STAGE: publish provider contract (spec + results) ==========\n"
	${PACTFLOW_CLI_COMMAND} publish-provider-contract \
      ${OAS_PATH} \
      --provider ${PACTICIPANT} \
      --provider-app-version ${COMMIT} \
      --branch ${BRANCH} \
      --content-type application/yaml \
      --verification-exit-code=${EXIT_CODE} \
      --verification-results ${REPORT_PATH} \
      --verification-results-content-type ${REPORT_FILE_CONTENT_TYPE}\
      --verifier ${VERIFIER_TOOL}

## =====================
## Deploy tasks
## =====================

# Only deploy from master
ifeq ($(BRANCH),master)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

deploy_target: can_i_deploy $(DEPLOY_TARGET)

deploy: deploy_app record_deployment
no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy: .env
	@echo "\n========== STAGE: can-i-deploy? 🌉 ==========\n"
	${PACT_BROKER_COMMAND} can-i-deploy \
	--pacticipant ${PACTICIPANT} \
	--version ${COMMIT} \
	--to-environment production

deploy_app:
	@echo "\n========== STAGE: deploy 🚀 ==========\n"
	@echo "Deploying to prod"

record_deployment: .env
	${PACT_BROKER_COMMAND} \
	record_deployment \
	--pacticipant ${PACTICIPANT} \
	--version ${COMMIT} \
	--environment production

## ====================
## Multi-platform detection and support
## ====================
SHELL := /bin/bash

ifeq '$(findstring ;,$(PATH))' ';'
	detected_OS := Windows
else
	detected_OS := $(shell uname 2>/dev/null || echo Unknown)
	detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
	detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
	detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

ifeq ($(PACT_TOOL),ruby_standalone)
# add path to standalone, and add bat if windows
	ifneq ($(filter $(detected_OS),Windows MSYS),)
		PACT_BROKER_COMMAND:="./pact/bin/${PACT_BROKER_COMMAND}.bat"
		PACTFLOW_CLI_COMMAND:="./pact/bin/${PACTFLOW_CLI_COMMAND}.bat"
	else
		PACT_BROKER_COMMAND:="./pact/bin/${PACT_BROKER_COMMAND}"
		PACTFLOW_CLI_COMMAND:="./pact/bin/${PACTFLOW_CLI_COMMAND}"
	endif
endif

ifeq ($(PACT_TOOL),docker)
# add docker run command path
	PACT_BROKER_COMMAND:=${PACT_CLI_DOCKER_RUN_COMMAND} ${PACT_BROKER_COMMAND}
	PACTFLOW_CLI_COMMAND:=${PACT_CLI_DOCKER_RUN_COMMAND} ${PACTFLOW_CLI_COMMAND}
endif

## ======================
## Misc
## ======================

convert:
	npm run test:convert
.env:
	touch .env

.PHONY: start stop test