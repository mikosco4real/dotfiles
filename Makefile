# Dotfiles task runner. `make` on its own prints the available targets.
#
# Recipes use hard tabs: macOS ships GNU Make 3.81, which predates
# .RECIPEPREFIX. Keep it that way or it breaks on a stock Mac.

SHELL      := /bin/bash
CHEZMOI    := chezmoi
SOURCE_DIR := $(shell $(CHEZMOI) source-path 2>/dev/null || echo .)
REPO_ROOT  := $(shell git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPTS    := $(wildcard $(REPO_ROOT)/home/.chezmoiscripts/*.tmpl)
ZSH_FRAGS  := $(wildcard $(REPO_ROOT)/home/dot_config/zsh/conf.d/*.zsh)
# Real bash files deployed as-is (executable_ entries are never templates).
SH_FILES   := $(wildcard $(REPO_ROOT)/home/dot_config/tmux/scripts/executable_*.sh) \
              $(wildcard $(REPO_ROOT)/test/*.sh)

.DEFAULT_GOAL := help
.PHONY: help apply diff status update lint fmt fmt-lua test test-shell doctor externals clean

help: ## Show this help
	@echo "Dotfiles — available targets:"
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

apply: ## Apply the source state to $HOME
	$(CHEZMOI) apply --verbose

diff: ## Show what apply would change
	$(CHEZMOI) diff

status: ## Show which managed files have drifted
	$(CHEZMOI) status

update: ## git pull, then apply, then refresh vendored externals
	$(CHEZMOI) git pull -- --autostash --rebase
	$(CHEZMOI) apply --verbose
	$(CHEZMOI) apply --refresh-externals
	@command -v brew >/dev/null 2>&1 && brew bundle install --file="$(REPO_ROOT)/home/dot_config/homebrew/Brewfile" --no-upgrade || true
	@command -v mise >/dev/null 2>&1 && mise install || true

externals: ## Force-refresh vendored plugins and fonts
	$(CHEZMOI) apply --refresh-externals --verbose

lint: ## shellcheck + shfmt on rendered scripts, zsh -n on every fragment
	@fail=0; \
	echo "--- shellcheck (rendered templates) ---"; \
	for f in $(SCRIPTS); do \
	  if ! out=$$($(CHEZMOI) execute-template < "$$f" 2>/tmp/_lint.err); then \
	    printf "  FAIL %s (template did not render: %s)\n" "$$(basename $$f)" "$$(cat /tmp/_lint.err)"; \
	    fail=1; continue; \
	  fi; \
	  [ -z "$$(printf '%s' "$$out" | tr -d '[:space:]')" ] && { printf "  skip %s (OS-gated: renders empty here)\n" "$$(basename $$f)"; continue; }; \
	  printf '%s' "$$out" > /tmp/_lint.sh; \
	  if bash -n /tmp/_lint.sh && shellcheck -S warning /tmp/_lint.sh; then printf "  ok   %s\n" "$$(basename $$f)"; \
	  else printf "  FAIL %s\n" "$$(basename $$f)"; fail=1; fi; \
	done; \
	echo "--- shellcheck + shfmt (plain .sh files) ---"; \
	for f in $(SH_FILES); do \
	  if shellcheck -S warning "$$f" && shfmt -d -i 2 -ci -sr "$$f" >/dev/null; then \
	    printf "  ok   %s\n" "$$(basename $$f)"; \
	  else printf "  FAIL %s\n" "$$(basename $$f)"; fail=1; fi; \
	done; \
	echo "--- zsh -n (shellcheck cannot parse zsh) ---"; \
	for f in $(ZSH_FRAGS) $(REPO_ROOT)/home/dot_zshenv \
	         $(REPO_ROOT)/home/dot_config/zsh/dot_zshrc \
	         $(REPO_ROOT)/home/dot_config/zsh/dot_zshenv \
	         $(REPO_ROOT)/home/dot_config/zsh/dot_zprofile; do \
	  if zsh -n "$$f" 2>/dev/null; then printf "  ok   %s\n" "$$(basename $$f)"; \
	  else printf "  FAIL %s\n" "$$(basename $$f)"; fail=1; fi; \
	done; \
	echo "--- lua (stylua) ---"; \
	if [ -x "$$HOME/.local/share/nvim/mason/bin/stylua" ]; then \
	  if (cd $(REPO_ROOT)/nvim && "$$HOME/.local/share/nvim/mason/bin/stylua" --check . >/dev/null 2>&1); then \
	    echo "  ok   nvim lua"; \
	  else \
	    n=$$(cd $(REPO_ROOT)/nvim && "$$HOME/.local/share/nvim/mason/bin/stylua" --check . 2>&1 | grep -c '^Diff in ' || true); \
	    echo "  FAIL $$n lua file(s) not formatted — run: make fmt-lua"; fail=1; \
	  fi; \
	else echo "  skip stylua not installed (Mason provides it)"; fi; \
	exit $$fail

fmt: ## Format shell scripts in place
	shfmt -w -i 2 -ci -sr $(SH_FILES)

fmt-lua: ## Reformat ALL nvim Lua to nvim/.stylua.toml (large diff — deliberate)
	@[ -x "$$HOME/.local/share/nvim/mason/bin/stylua" ] || { echo "stylua not installed"; exit 1; }
	cd $(REPO_ROOT)/nvim && "$$HOME/.local/share/nvim/mason/bin/stylua" .

test: ## Full bootstrap in a clean ubuntu:24.04 container, run TWICE for idempotency
	$(REPO_ROOT)/test/run.sh

test-shell: ## Drop into a shell in the test container to poke around
	$(REPO_ROOT)/test/run.sh --shell

doctor: ## Check this machine's install is intact
	@echo "--- chezmoi ---"
	@# Drop the "ok" rows and the long list of "info: <password manager> not found"
	@# probes; this setup deliberately uses no password manager.
	@out=$$($(CHEZMOI) doctor 2>&1 | grep -vE '^(ok|info) ' | grep -v '^RESULT'); \
	  [ -z "$$out" ] && echo "  no warnings" || echo "$$out"
	@echo "--- drift ---"
	@out=$$($(CHEZMOI) status); [ -z "$$out" ] && echo "  clean" || echo "$$out"
	@echo "--- files that MUST still be symlinks ---"
	@for f in .config/nvim .config/starship.toml .config/kitty/kitty.conf \
	          .config/tmux/tmux.conf .config/ghostty/config \
	          .config/zed/settings.json .config/zsh/.zshrc .zshenv; do \
	  if [ -L "$$HOME/$$f" ]; then echo "  ok      $$f"; \
	  elif [ -e "$$HOME/$$f" ]; then echo "  DETACHED $$f  (real file — an app may have overwritten the symlink)"; \
	  else echo "  MISSING $$f"; fi; \
	done
	@echo "--- broken symlinks into the repo ---"
	@found=$$(find "$$HOME" -maxdepth 4 -xtype l -lname '*chezmoi*' 2>/dev/null); \
	  [ -z "$$found" ] && echo "  none" || echo "$$found"
	@echo "--- required tools ---"
	@for t in chezmoi zsh nvim tmux starship fzf rg fd zoxide mise git; do \
	  printf "  %-10s %s\n" "$$t" "$$(command -v $$t || echo MISSING)"; \
	done
	@echo "--- nvim >= 0.12 (vim.pack) ---"
	@nvim --version 2>/dev/null | head -1 || echo "  nvim missing"
	@echo "--- tree-sitter CLI (treesitter main branch needs it) ---"
	@command -v tree-sitter >/dev/null 2>&1 && echo "  ok" || echo "  MISSING: brew install tree-sitter-cli"

clean: ## Remove local scratch files
	rm -f /tmp/_lint.sh /tmp/_lint.err
