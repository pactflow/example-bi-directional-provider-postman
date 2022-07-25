PACTICIPANT ?= "pactflow-example-bi-directional-provider-postman"
GITHUB_REPO := "pactflow/example-bi-directional-provider-postman"
VERSION?=$(shell npx -y absolute-version)
BRANCH?=$(shell git rev-parse --abbrev-ref HEAD)

## ====================
## Demo Specific Example Variables
## ====================
OAS_PATH=oas/swagger.yml
REPORT_PATH?=$(shell ls newman/*)
REPORT_FILE_CONTENT_TYPE?=text/plain
VERIFIER_TOOL?=postman

## =====================
## Multi-platform detection and support
## =====================
SHELL := /bin/bash
PACT_TOOL?=docker
PACT_CLI_DOCKER_VERSION?=latest
PACT_CLI_VERSION?=latest
PACT_CLI_STANDALONE_VERSION?=1.89.00
PACT_BROKER_COMMAND=pact-broker
PACTFLOW_CLI_COMMAND=pactflow

ifeq '$(findstring ;,$(PATH))' ';'
	detected_OS := Windows
else
	detected_OS := $(shell uname 2>/dev/null || echo Unknown)
	detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
	detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
	detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

ifeq ($(PACT_TOOL),standalone)
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
# Git for Windows (gitbash/mingw64 requires this for volumn mount path in Docker
ifneq ($(filter $(detected_OS),Windows MSYS),) 
	export MSYS_NO_PATHCONV=1
endif
PACT_CLI_DOCKER_RUN_COMMAND?=docker run --rm -v /${PWD}:/${PWD} -w ${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:${PACT_CLI_DOCKER_VERSION}
# Second pact CLI docker command as we dont need volume mounts for some commands
# MSYS_NO_PATHCONV only seems to work for PACTFLOW_CLI_COMMAND
PACT_CLI_DOCKER_RUN_CMD?=docker run --rm -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:${PACT_CLI_DOCKER_VERSION}
# add docker run command path
	PACT_BROKER_COMMAND:=${PACT_CLI_DOCKER_RUN_CMD} ${PACT_BROKER_COMMAND}
	PACTFLOW_CLI_COMMAND:=${PACT_CLI_DOCKER_RUN_COMMAND} ${PACTFLOW_CLI_COMMAND}
endif

## =====================
## Build/test tasks
## =====================

install:
	npm install 

test:
	@echo "\n========== STAGE: test ✅ ==========\n"
	@echo "Running postman collection via Newman CLI runner, to test locally running provider"
	@npm run test
	@echo "converting postman collection into OAS spec"
	@npm run test:convert 

## ====================
## CI tasks
## ====================

all: ci
all_docker: ci_docker
all_standalone: ci_standalone
all_ruby_cli: ci_ruby_cli

# Run the ci target from a developer machine with the environment variables
# set as if it was on Github Actions.
# Use this for quick feedback when playing around with your workflows.
ci:  test_and_publish can_i_deploy $(DEPLOY_TARGET)

ci_ruby_cli:
	PACT_TOOL=ruby_cli make ci
ci_docker:
	PACT_TOOL=docker make ci
ci_standalone:
	PACT_TOOL=standalone make ci

test_and_publish:
	@if make test; then \
		EXIT_CODE=0 make publish_provider_contract; \
	else \
		EXIT_CODE=1 make publish_provider_contract; \
	fi; \

publish_provider_contract:
	@echo "\n========== STAGE: publish-provider-contract (spec + results) ==========\n"
	${PACTFLOW_CLI_COMMAND} publish-provider-contract \
	${OAS_PATH} \
	--provider ${PACTICIPANT} \
	--provider-app-version ${VERSION} \
	--branch ${BRANCH} \
	--content-type application/yaml \
	--verification-exit-code=${EXIT_CODE} \
	--verification-results ${REPORT_PATH} \
	--verification-results-content-type ${REPORT_FILE_CONTENT_TYPE} \
	--verifier ${VERIFIER_TOOL}

## =====================
## Deploy tasks
## =====================

# Only deploy from main/master
ifneq ($(filter $(BRANCH),main master),)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

deploy: deploy_app record_deployment
deploy_target: can_i_deploy $(DEPLOY_TARGET)
no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy:
	@echo "\n========== STAGE: can-i-deploy? 🌉 ==========\n"
	${PACT_BROKER_COMMAND} can-i-deploy \
	--pacticipant ${PACTICIPANT} \
	--version ${VERSION} \
	--to-environment production

deploy_app:
	@echo "\n========== STAGE: deploy 🚀 ==========\n"
	@echo "Deploying to prod"

record_deployment: 
	${PACT_BROKER_COMMAND} \
	record_deployment \
	--pacticipant ${PACTICIPANT} \
	--version ${VERSION} \
	--environment production

## =====================
## Pact CLI install/uninstall tasks
## =====================

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
		./pact/bin/pactflow.bat help;; \
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

uninstall-pact-ruby-standalone:
	rm -rf ./pact

uninstall-pact-ruby-standalone-zip:
	rm pact-${PACT_CLI_STANDALONE_VERSION}-*

install-make-windows:
	curl -L https://sourceforge.net/projects/ezwinports/files/make-4.3-without-guile-w32-bin.zip/download --output make.zip && \
		unzip make.zip -d make && \
		./make/bin/make.exe check_make && \
		cp -r make/* /mingw64 && \
		make check_make && \
		rm -rf make && \
		rm make.zip

uninstall-make-windows:
	rm /mingw64/bin/make.exe && \
	rm /mingw64/include/gnumake.h && \
	rm /mingw64/lib/libgnumake-1.dll.a && \
	rm /mingw64/share/doc/make-4.3/NEWS && \
	rm /mingw64/share/info/make.info && \
	rm /mingw64/share/info/make.info-1 && \
	rm /mingw64/share/info/make.info-2 && \
	rm /mingw64/share/man/cat1/make.1 && \
	rm /mingw64/share/man/man1/make.1

check_make:
	@echo make is working

install_rvm:
	command curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
	command curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
	curl -sSL https://get.rvm.io | bash -s stable --ruby

## ======================
## Misc
## ======================

convert:
	npm run test:convert

.PHONY: start stop test