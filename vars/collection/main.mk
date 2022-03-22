# JX
JOB_NAME ?= sanity

# JX
UPDATEBOT_COMMIT_MESSAGE ?= chore(update): bump collection krestomatio.k8s $(VERSION)
UPDATEBOT_ALL_MODIFY_FILES := $(shell git diff --name-only $${LAST_TAG:-HEAD~1} 2>/dev/null | wc -l)
UPDATEBOT_M4E_MODIFY_FILES := $(shell git diff --name-only $${LAST_TAG:-HEAD~1} roles/v1alpha1/m4e roles/v1alpha1/web/nginx/ roles/v1alpha1/database/postgres 2>/dev/null | wc -l )
UPDATEBOT_NFS_MODIFY_FILES := $(shell git diff --name-only $${LAST_TAG:-HEAD~1} roles/v1alpha1/nfs 2>/dev/null | wc -l )
UPDATEBOT_KEYDB_MODIFY_FILES := $(shell git diff --name-only $${LAST_TAG:-HEAD~1} roles/v1alpha1/database/keydb 2>/dev/null | wc -l )
UPDATEBOT_POSTGRES_MODIFY_FILES := $(shell git diff --name-only $${LAST_TAG:-HEAD~1} roles/v1alpha1/database/postgres 2>/dev/null | wc -l )

ifneq ($(UPDATEBOT_ALL_MODIFY_FILES),0)
ifeq ($(shell test $(UPDATEBOT_M4E_MODIFY_FILES) -eq $(UPDATEBOT_ALL_MODIFY_FILES); echo $$?),0)
UPDATEBOT_CONFIG_FILE ?= updatebot-m4e-only.yaml
else ifeq ($(shell test $(UPDATEBOT_NFS_MODIFY_FILES) -eq $(UPDATEBOT_ALL_MODIFY_FILES); echo $$?),0)
UPDATEBOT_CONFIG_FILE ?= updatebot-nfs-only.yaml
else ifeq ($(shell test $(UPDATEBOT_KEYDB_MODIFY_FILES) -eq $(UPDATEBOT_ALL_MODIFY_FILES); echo $$?),0)
UPDATEBOT_CONFIG_FILE ?= updatebot-keydb-only.yaml
else ifeq ($(shell test $(UPDATEBOT_POSTGRES_MODIFY_FILES) -eq $(UPDATEBOT_ALL_MODIFY_FILES); echo $$?),0)
UPDATEBOT_CONFIG_FILE ?= updatebot-postgres-only.yaml
else
UPDATEBOT_CONFIG_FILE ?= updatebot.yaml
endif
endif
