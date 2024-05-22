TRANSFER_DIR := $(shell if [ -d "$(HOME)/NextcloudPrivate/Transfer" ]; then echo "$(HOME)/NextcloudPrivate/Transfer"; else echo "$(HOME)/Nextcloud/Transfer"; fi)

git-apply-patch:
	git apply ~/Nextcloud/Transfer/qownnotes-scripts.patch


git-create-patch:
	@echo "TRANSFER_DIR: ${TRANSFER_DIR}"; \
	git diff --no-ext-diff --staged --binary > ${TRANSFER_DIR}/qownnotes-scripts.patch; \
	ls -l1t ${TRANSFER_DIR} | head -2
