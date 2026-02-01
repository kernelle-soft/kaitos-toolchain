![Rust Branch Coverage](https://codecov.io/gh/kernelle-soft/kaitos-toolchain/branch/main/graph/badge.svg?flag=rust)
![Go Branch Coverage](https://codecov.io/gh/kernelle-soft/kaitos-toolchain/branch/main/graph/badge.svg?flag=go)

# Kaitos Toolchain

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
