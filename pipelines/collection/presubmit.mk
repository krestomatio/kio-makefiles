.PHONY: sanity
sanity: ansible-lint start-dockerd test-sanity ## Run sanity tests
