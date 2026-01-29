# Kaitos Toolchain

## Development Setup

### Prerequisites

- Go 1.21+
- Rust (stable)
- Cargo

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
