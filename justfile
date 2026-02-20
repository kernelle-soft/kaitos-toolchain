
# Hack to pass through stuff set up in .envrc
set shell := ["bash", "-c", "unset __ENVRC_LOADED; . ./.envrc && $1", "-"]
mod test 'just/test.just'
mod sync 'just/sync.just'
mod docs 'site'

clean *args:
  ./scripts/chores/clean.sh {{args}}

lint:
  cd go && go fmt ./...
  cd crates && cargo fmt --all

test-all:
  just test go
  just test rust

bump *args:
  ./scripts/chores/bump_git_version.sh {{args}}

publish *args:
  ./scripts/ci/publish_release.sh {{args}}

build *args:
  ./scripts/chores/build.sh {{args}}

release *args:
  ./scripts/chores/build.sh --release --bundle {{args}}
