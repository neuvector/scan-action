.PHONY: test lint

lint:
	hadolint Dockerfile

test:
	bats test

docs:
	npm run docs