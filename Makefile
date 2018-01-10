DOCKERFILE := Dockerfile.template
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR_PATH := $(dir $(MKFILE_PATH))
CONFIG_PATH := ${ROOT_DIR_PATH}config.json
DOCKER_BAKERY_PATH := ${ROOT_DIR_PATH}docker-bakery-binaries/darwin_amd64/docker-bakery

.DEFAULT_GOAL: usage

# tell Makefile not to search files with such names and run tasks unconditionally 
.PHONY: usage debug build-patch build-patch-all build-minor build-minor-all build-major build-major-all push-patch push-patch-all push-minor push-minor-all push-major push-major-all

usage:
	@echo "Use one of following commands:"
	@echo "\tmake build-patch"
	@echo "\tmake build-minor"
	@echo "\tmake build-major"
	@echo "\tmake build-patch-all"
	@echo "\tmake build-minor-all"
	@echo "\tmake build-major-all"
	@echo "\tmake push-patch"
	@echo "\tmake push-minor"
	@echo "\tmake push-major"
	@echo "\tmake push-patch-all"
	@echo "\tmake push-minor-all"
	@echo "\tmake push-major-all"

debug:
	@echo "Using following configuration:"
	@echo "\tMKFILE_PATH: ${MKFILE_PATH}"
	@echo "\tROOT_DIR_PATH: ${ROOT_DIR_PATH}"
	@echo "\tCONFIG_PATH: ${CONFIG_PATH}"
	@echo "\tDOCKER_BAKERY_PATH: ${DOCKER_BAKERY_PATH}"

build-patch:
	${DOCKER_BAKERY_PATH} build -s patch -c ${CONFIG_PATH} -d ${DOCKERFILE} --skip-dependants

build-patch-all:
	${DOCKER_BAKERY_PATH} build -s patch -c ${CONFIG_PATH} -d ${DOCKERFILE}

build-minor:
	${DOCKER_BAKERY_PATH} build -s minor -c ${CONFIG_PATH} -d ${DOCKERFILE} --skip-dependants

build-minor-all:
	${DOCKER_BAKERY_PATH} build -s minor -c ${CONFIG_PATH} -d ${DOCKERFILE}

build-major:
	${DOCKER_BAKERY_PATH} build -s major -c ${CONFIG_PATH} -d ${DOCKERFILE} --skip-dependants

build-major-all:
	${DOCKER_BAKERY_PATH} build -s major -c ${CONFIG_PATH} -d ${DOCKERFILE}

push-patch:
	${DOCKER_BAKERY_PATH} push -s patch -c ${CONFIG_PATH} -d ${DOCKERFILE} --skip-dependants

push-patch-all:
	${DOCKER_BAKERY_PATH} push -s patch -c ${CONFIG_PATH} -d ${DOCKERFILE}

push-minor:
	${DOCKER_BAKERY_PATH} push -s minor -c ${CONFIG_PATH} -d ${DOCKERFILE} --skip-dependants

push-minor-all:
	${DOCKER_BAKERY_PATH} push -s minor -c ${CONFIG_PATH} -d ${DOCKERFILE}

push-major:
	${DOCKER_BAKERY_PATH} push -s major -c ${CONFIG_PATH} -d ${DOCKERFILE} --skip-dependants

push-major-all:
	${DOCKER_BAKERY_PATH} push -s major -c ${CONFIG_PATH} -d ${DOCKERFILE}
