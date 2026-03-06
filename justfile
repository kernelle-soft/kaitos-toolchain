
# Hack to pass through stuff set up in .envrc
set shell := ["bash", "-c", "unset __ENVRC_LOADED; . ./.envrc && $1", "-"]
mod test 'just/test.just'
mod sync 'just/sync.just'
mod docs 'site'

clean *args:
  ./shell/scripts/chores/clean.sh {{args}}

lint:
  cd go && go fmt ./...
  cd crates && cargo fmt --all

test-all:
  just test go
  just test rust

bump *args:
  ./shell/shock git-bump {{args}}

publish *args:
  ./shell/shock publish-release {{args}}

build *args:
  ./shell/scripts/chores/build.sh {{args}}

release *args:
  ./shell/scripts/chores/build.sh --release --bundle {{args}}

watch *args:
  watchexec \
    --restart \
    --clear \
    --exts go,rs,toml \
    --watch go \
    --watch crates \
    -i 'crates/target/**' \
    -- just build {{args}}

setup-workspace *args:
  git submodule update --init shell/.shock && shell/.shock/workspace_init.sh {{args}}
