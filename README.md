# Kaitos

## Project Maturity

<!--POKE_INFO_START-->
<div id="poke-info" align="center">
  <h3>
    If Kaitos' latest stable release was a Pokémon,
    <br>
    it would be...
  </h3>
  <img
    id="pokemon-img"
    src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/9.gif"
  />
  <br>
  <span id="pokemon-name"><b>Release #9: v0.0.9 - Blastoise</b></span>
  <br>
  <img
    id="rust-runtime-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=rust&label=Rust"
  />
  <img
    id="go-cli-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=go&label=Go"
  />
  <img
    id="security-checks"
    src="https://github.com/kernelle-soft/kaitos-toolchain/actions/workflows/_security.yaml/badge.svg?branch=main"
    alt="Security Checks"
  />
  <br>
  <span>Base Stats</span>
  <table align="center">
    <tr>
      <th>Lang</th>
      <th>Lines of Code</th>
    </tr>
    <tr>
      <td>Go</td>
      <td>235</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td>27</td>
    </tr>
    <tr>
      <td>Bash</td>
      <td>3401</td>
    </tr>
  </table>
</div>
<!--POKE_INFO_END-->


## Development Setup

### Prerequisites

- Go 1.21+
- Rust (stable)
- Cargo
- [direnv](https://direnv.net/) - automatically loads environment from `.envrc`

### Workspace Setup

Bootstrap the development environment (initializes the [shellshock](https://github.com/kernelle-soft/shellshock) submodule and installs tools):

```bash
git submodule update --init shell/.shock && shell/.shock/workspace_init.sh
```

Check tool status without installing:

```bash
shell/shock workspace --check
```

### Project Structure

```
shell/
  shock                         # CLI dispatcher (derived from .shock/)
  .shock/                       # shellshock submodule
  scripts/
    lib/                        # kaitos-specific shell libraries
    chores/                     # chore scripts (build, sync, lint)
    ci/                         # CI scripts (publish, coverage, test)
    install/                    # installer scripts
shock.lock                      # tool dependencies (read by shock workspace)
manifest.json                   # project metadata
```

### Git Hooks

This project uses [lefthook](https://github.com/evilmartians/lefthook) to manage git hooks for formatting checks.

Install lefthook and set up the hooks:

```bash
go install github.com/evilmartians/lefthook@latest
lefthook install
```

This configures pre-commit hooks that run:
- `gofmt` on Go files
- `rustfmt` on Rust files
