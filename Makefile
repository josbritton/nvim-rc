.SILENT:
.DEFAULT_GOAL := install

GIT_DIR := $(shell git rev-parse --git-dir)
TEMP_FILE := $(shell mktemp)

.PHONY: clean
clean: truncate-logs
	(. .venv/bin/activate && pre-commit uninstall) || true
	rm -rf .venv/
	rm -rf ~/.local/share/nvim/lazy
	rm -rf ~/.local/share/nvim/site
	rm -rf ~/.local/share/nvim/tree-sitter-*
	rm -rf ~/.local/share/mason
	rm -rf ~/.local/state/nvim/lazy/*
	rm -rf ~/.local/state/nvim/lazydata/*
	rm -rf ~/.local/state/nvim/site/*
	rm -rf ~/.local/state/blink

.PHONY: lint
lint:
	stylua --verify --check .
	markdownlint "**/*.md" --ignore LICENSE.md

.PHONY: format
format:
	stylua --verify .
	markdownlint --fix "**/*.md" --ignore LICENSE.md

.PHONY: install
install: $(GIT_DIR)/hooks/pre-commit
	nvim --headless "+Lazy! restore" +qa

.venv/lock: requirements.txt
	python3 -m venv .venv/

	. .venv/bin/activate && \
	python3 -m pip install -U -r requirements.txt

	touch .venv/lock

$(GIT_DIR)/hooks/pre-commit: .pre-commit-config.yaml .venv/lock
	. .venv/bin/activate && \
	pre-commit install --hook-type pre-commit && \
	touch $(GIT_DIR)/hooks/pre-commit

.gitignore:
	touch .gitignore

.PHONY: truncate-logs
truncate-logs:
	[ -e ~/.local/state/nvim/lsp.log ] || touch ~/.local/state/nvim/lsp.log
	tail -c 1M ~/.local/state/nvim/lsp.log > $(TEMP_FILE)
	cp $(TEMP_FILE) ~/.local/state/nvim/lsp.log
	rm -f $(TEMP_FILE)
