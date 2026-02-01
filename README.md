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
    src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/2.gif"
  />
  <br>
  <span id="pokemon-name"><b>Release #2: v0.0.2 - Ivysaur</b></span>
  <br>
  <img
    id="rust-runtime-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=rust&label=Runtime"
  />
  <img
    id="go-cli-coverage"
    src="https://img.shields.io/codecov/c/github/kernelle-soft/kaitos-toolchain?flag=go&label=CLI"
  />
  <br>
  <span>Base Stats</span>
  <table>
    <tr>
      <th>Lang</th>
      <th>Lines of Code</th>
      <th>Unit Test Coverage</th>
      <th>Coverage Type</th>
    </tr>
    <tr>
      <td>Go</td>
      <td>293</td>
      <td>11%</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td>31
      <td>11%</td>
      <td>Branch</td>
    </tr>
    <tr>
      <td>Bash</td>
      <td>2827</td>
      <td>0%</td>
      <td>Line</td>
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

### Manual Formatting

If you need to fix formatting manually:

```bash
# Go
gofmt -w go/

# Rust
cargo fmt --manifest-path crates/Cargo.toml --all
```
