# Makefile — a convenience shipped by the Rust pack. The spine's own entry points are scripts:
#   scripts/gate (the enforcer) · scripts/run <verb> (the project's declared commands) · scripts/handoff
SHELL := /usr/bin/env bash
.PHONY: help gate check fmt clippy test build hooks handoff

help:
	@echo "make gate     - run the doctrine enforcer (scripts/gate)"
	@echo "make check    - fmt --check + clippy (deny warnings) + test   (scripts/run check)"
	@echo "make fmt      - cargo fmt --all"
	@echo "make clippy   - cargo clippy --all-targets --all-features -- -D warnings"
	@echo "make test     - cargo test --workspace --all-features"
	@echo "make build    - cargo build --workspace --all-features"
	@echo "make hooks    - install the git hooks (scripts/bootstrap.sh --contributor)"
	@echo "make handoff  - the session-end check (scripts/handoff)"

gate:
	bash scripts/gate
check:
	bash scripts/run check
fmt:
	bash scripts/run fmt
clippy:
	bash scripts/run lint
test:
	bash scripts/run test
build:
	bash scripts/run build
hooks:
	bash scripts/bootstrap.sh --contributor
handoff:
	bash scripts/handoff
