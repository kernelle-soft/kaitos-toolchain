# Hack to pass through stuff set up in .envrc
set shell := ["bash", "-c", "source .envrc && eval \"$1\"", "-"]

clean:
  ./scripts/chores/clean.sh

clean-all:
  ./scripts/chores/clean.sh -a

lint:
  cd go && go fmt ./...
  cd crates && cargo fmt --all

test: test-go test-rust

test-go:
  cd go && go test ./...

test-rust:
  cd crates && cargo test --workspace

bump *args:
  ./scripts/chores/bump_git_version.sh {{args}}
  ./scripts/chores/sync_cargo_version.sh
  ./scripts/chores/sync_project_manifest.sh