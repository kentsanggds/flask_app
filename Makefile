.DEFAULT_GOAL := help
SHELL := /bin/bash
DATE = $(shell date +%Y-%m-%dT%H:%M:%S)

APP_NAME ?= re2-test-flask-app

APP_VERSION_FILE = version.py

GIT_COMMIT ?= $(shell git rev-parse HEAD 2> /dev/null || cat commit || echo "")

BUILD_TAG ?= re2-test-flask-app
BUILD_NUMBER ?= manual
BUILD_URL ?= manual
DEPLOY_BUILD_NUMBER ?= ${BUILD_NUMBER}

DOCKER_CONTAINER_PREFIX = ${USER}-${BUILD_TAG}

CF_MANIFEST_FILE ?= manifest.yml

CF_API ?= api.cloud.service.gov.uk
CF_ORG ?= csd-sso
CF_HOME ?= ${HOME}
$(eval export CF_HOME)
CF_SPACE ?= sandbox

DOCKER_IMAGE = kenlt/test
DOCKER_IMAGE_TAG = ${CF_SPACE}
DOCKER_IMAGE_NAME = ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}
DOCKER_TTY ?= $(if ${JENKINS_HOME},,t)

PORT ?= 5100

.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: venv
venv: venv/bin/activate ## Create virtualenv if it does not exist

venv/bin/activate:
	test -d venv || virtualenv venv -p python3
	./venv/bin/pip install pip-accel

.PHONY: dependencies
dependencies: venv ## Install build dependencies
	mkdir -p ${PIP_ACCEL_CACHE}
	PIP_ACCEL_CACHE=${PIP_ACCEL_CACHE} ./venv/bin/pip-accel install --upgrade .

.PHONY: build
build: dependencies ## Build project

.PHONY: _run
_run:
	./run_app.sh

.PHONY: _run_uwsgi
_run_uwsgi:
	./run_uwsgi_app_docker.sh

define run_docker_container
	docker run -i${DOCKER_TTY} --rm \
		--name "${DOCKER_CONTAINER_PREFIX}-${1}" \
		-p ${PORT}:${PORT} \
		-e FLASK_APP=${FLASK_APP} \
		-e FLASK_DEBUG=${FLASK_DEBUG} \
		-e WERKZEUG_DEBUG_PIN=${WERKZEUG_DEBUG_PIN} \
		-e BUILD_NUMBER=${BUILD_NUMBER} \
		-e BUILD_URL=${BUILD_URL} \
		-e APP_NAME=${APP_NAME} \
		-e PORT=${PORT} \
		-e http_proxy="${HTTP_PROXY}" \
		-e HTTP_PROXY="${HTTP_PROXY}" \
		-e https_proxy="${HTTPS_PROXY}" \
		-e HTTPS_PROXY="${HTTPS_PROXY}" \
		-e NO_PROXY="${NO_PROXY}" \
		${DOCKER_IMAGE_NAME} \
		${2}
endef

# ---- DOCKER COMMANDS ---- #

.PHONY: run-with-docker
run-with-docker: prepare-docker-build-image ## Build inside a Docker container
	$(call run_docker_container,build, make _run)

.PHONY: run-uwsgi-with-docker
run-uwsgi-with-docker: prepare-docker-build-image ## Build inside a Docker container
	$(call run_docker_container,build, make _run_uwsgi)

.PHONY: bash-with-docker
bash-with-docker: prepare-docker-build-image ## Build inside a Docker container
	$(call run_docker_container,build, bash)

.PHONY: prepare-docker-build-image
prepare-docker-build-image: ## Build docker image
	docker build -f docker/Dockerfile \
		--build-arg http_proxy="${http_proxy}" \
		--build-arg https_proxy="${https_proxy}" \
		--build-arg NO_PROXY="${NO_PROXY}" \
		--build-arg PORT=${PORT} \
		-t ${DOCKER_IMAGE_NAME} \
		.

.PHONY: clean-docker-containers
clean-docker-containers: ## Clean up any remaining docker containers
	docker rm -f $(shell docker ps -q -f "name=${DOCKER_CONTAINER_PREFIX}") 2> /dev/null || true

.PHONY: upload-to-dockerhub
upload-to-dockerhub: prepare-docker-build-image ## Upload the current version of the docker image to dockerhub
	$(if ${DOCKERHUB_USERNAME},,$(error Must specify DOCKERHUB_USERNAME))
	$(if ${DOCKERHUB_PASSWORD},,$(error Must specify DOCKERHUB_PASSWORD))
	@docker login -u ${DOCKERHUB_USERNAME} -p ${DOCKERHUB_PASSWORD}
	docker push ${DOCKER_IMAGE_NAME}

.PHONY: cf-deploy
cf-deploy: ## Deploys the app to Cloud Foundry
	cf push test-flask-app --docker-image ${DOCKER_IMAGE_NAME}
