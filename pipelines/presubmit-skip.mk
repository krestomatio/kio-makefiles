.PHONY: sanity
sanity:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info skipping sanity...)

.PHONY: lint
lint:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info skipping lint...)

.PHONY: build-image
build-image:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info skipping build-image...)

.PHONY: pr-preview
pr-preview:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info skipping pr-preview...)

.PHONY: pr
pr:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info skipping pr...)

.PHONY: k8s
k8s:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info skipping k8s...)
