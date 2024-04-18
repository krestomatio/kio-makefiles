# Release
GIT_ADD_FILES ?= Makefile package.json docs/

# BUILD
IMG_BUILD_ULIMIT ?= "nofile=1024:65535"
