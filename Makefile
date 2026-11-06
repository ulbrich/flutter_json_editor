.PHONY: help next-version release

default: help

help:
	@echo "flutter_json_editor"
	@perl -nle'print $& if m{^[a-zA-Z0-9_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

next-version: ## Show the next release tag of this branch (master: v<x.y.z>, renderer/material: material-v<x.y.z>) and the make command that releases it
	@set -- `scripts/release.sh --next`; \
	printf "%-20s %-30s (last %s, pubspec %s)\n" "$$1" "make release" "`test "$$2" = - && echo none || echo $$2`" "$$3"
	@echo "\nOptionally call it with e.g. \"VERSION=1.2.3 make release\" to override the version"

release: ## Run the tests, bump pubspec.yaml, tag and push the next version (master or renderer/material, all committed; VERSION=1.2.3 overrides)
	VERSION=$(VERSION) scripts/release.sh
