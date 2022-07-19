.PHONY: sanity
sanity: start-dockerd ansible-lint test-sanity ## Run sanity tests
