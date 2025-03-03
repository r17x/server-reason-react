project_name = server-reason-react

DUNE = opam exec -- dune
opam_file = $(project_name).opam

.PHONY: help
help: ## Print this help message
	@echo "";
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

.PHONY: build
build: ## Build the project, including non installable libraries and executables
	$(DUNE) build @all

.PHONY: build-prod
build-prod: ## Build for production (--profile=prod)
	$(DUNE) build --profile=prod @all

.PHONY: dev
dev: ## Build in watch mode
	$(DUNE) build -w @all

.PHONY: clean
clean: ## Clean artifacts
	$(DUNE) clean

.PHONY: test
test: ## Run the unit tests
	$(DUNE) build @runtest

.PHONY: test-watch
test-watch: ## Run the unit tests in watch mode
	$(DUNE) build @runtest -w

.PHONY: test-promote
test-promote: ## Updates snapshots and promotes it to correct
	$(DUNE) build @runtest --auto-promote

.PHONY: deps
deps: $(opam_file) ## Alias to update the opam file and install the needed deps

.PHONY: format
format: ## Format the codebase with ocamlformat
	$(DUNE) build @fmt --auto-promote

.PHONY: format-check
format-check: ## Checks if format is correct
	$(DUNE) build @fmt

.PHONY: init
setup-githooks: ## Setup githooks
	git config core.hooksPath .githooks

.PHONY: create-switch
create-switch: ## Create opam switch
	opam switch create . 5.1.0 --deps-only --with-test -y

.PHONY: install
install:
	$(DUNE) build @install
	opam install . --deps-only --with-test

.PHONY: pin
pin: ## Pin dependencies
	opam pin add melange.dev "https://github.com/melange-re/melange.git#2ff08be262f113fc8d28b66c272502c6f403399c" -y
	opam pin add reason-react-ppx.dev "https://github.com/reasonml/reason-react.git#7ca984c9a406b01e906fda1898f705f135fad202" -y
	opam pin add reason-react.dev "https://github.com/reasonml/reason-react.git#7ca984c9a406b01e906fda1898f705f135fad202" -y
	opam pin add melange-fetch.dev "git+https://github.com/melange-community/melange-fetch.git#master" -y
	opam pin add melange-webapi.dev "git+https://github.com/melange-community/melange-webapi.git#master" -y

.PHONY: init
init: setup-githooks create-switch install pin ## Create a local dev enviroment

.PHONY: ppx-test
ppx-test: ## Run ppx tests
	$(DUNE) runtest ppx

.PHONY: ppx-test-watch
ppx-test-watch: ## Run ppx tests in watch mode
	$(DUNE) runtest ppx --watch

.PHONY: lib-test
lib-test: ## Run library tests
	$(DUNE) exec test/test.exe

.PHONY: demo
demo: ## Run demo executable
	$(DUNE) exec demo/index.exe

.PHONY: demo-watch
demo-watch: ## Run demo executable
	$(DUNE) exec -w demo/index.exe

.PHONY: subst
subst: ## Run dune substitute
	$(DUNE) subst

.PHONY: documentation
documentation: ## Generate odoc documentation
# Since odoc/dune fails when 2 wrapped libraries have the same name,
# we need to ignore conflicting packages by adding an underscode in front of it
# https://github.com/ocaml/dune/issues/1645
	mv $(CURDIR)/packages/promise $(CURDIR)/packages/_promise
	mv $(CURDIR)/packages/url $(CURDIR)/packages/_url
	$(DUNE) build --root . @doc
# and rollback the rename, so the build continues to work
	mv $(CURDIR)/packages/_promise $(CURDIR)/packages/promise
	mv $(CURDIR)/packages/_url $(CURDIR)/packages/url

# Because if the hack above, we can't have watch mode
## .PHONY: documentation-watch
## documentation-watch: ## Generate odoc documentation
##	$(DUNE) build --root . -w @doc

.PHONY: documentation-serve
documentation-serve: documentation ## Open odoc documentation with default web browser
	open _build/default/_doc/_html/index.html
