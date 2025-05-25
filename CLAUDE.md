# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Version Management

### When to Bump Versions
- **Patch version (0.x.Y)**: Bug fixes, documentation updates, minor improvements
- **Minor version (0.X.0)**: New features, non-breaking API changes
- **Major version (X.0.0)**: Breaking API changes (after 1.0.0 release)

### Version Update Checklist
1. Update version in `mix.exs`
2. Update CHANGELOG.md with:
   - Version number and date
   - Added/Changed/Fixed/Removed sections
   - **BREAKING:** prefix for any breaking changes
3. Commit with message: `chore: bump version to X.Y.Z`

### CHANGELOG Format
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality
- **BREAKING:** API changes that break compatibility

### Fixed
- Bug fixes

### Removed
- Removed features
- **BREAKING:** Removed APIs
```

## Development Commands

```bash
# Get dependencies
mix deps.get

# Compile the project
mix compile

# Run tests
mix test

# Run a specific test file
mix test test/path/to/test_file.exs

# Run tests matching a pattern
mix test --only tag:value

# Format code
mix format

# Check code formatting
mix format --check-formatted

# Run static analysis with Credo
mix credo

# Run type checking with Dialyzer
mix dialyzer

# Generate documentation
mix docs

# Interactive shell with project loaded
iex -S mix
```

## Architecture Overview

ExReadline implements a readline library for Elixir with two swappable modes:

### Core Design Pattern

The library uses a **dual-implementation architecture** with runtime mode selection:

1. **SimpleReader** (`lib/ex_readline/simple_reader.ex`): Uses Erlang's built-in IO system for basic line editing
2. **LineEditor** (`lib/ex_readline/line_editor.ex`): Full readline implementation with advanced editing features

Both implementations:
- Implement the `ExReadline.Behaviour` behaviour
- Use GenServer for state management
- Share the `History` module for persistent history
- Are accessed through the `ExReadline` facade module

### Key Architectural Elements

**Mode Selection Logic**: The `ExReadline` module dynamically detects which implementation is running by checking `Process.whereis(:ex_readline)`. This allows runtime switching between modes.

**Terminal Handling**: The `LineEditor` implementation manages raw terminal mode through coordinated setup/teardown in the `Terminal` module. This is critical for proper handling of escape sequences and special keys.

**State Management**: Line editing state is separated from server state via `LineEditor.State`, enabling clean separation of concerns between UI state and process management.

**Keybinding System**: The `Keybindings` module maps terminal input sequences to editing commands, working in conjunction with `Terminal` for input capture and `State` for applying edits.

### Known Issues

From TASKS.md:
- Arrow keys and Ctrl-P/Ctrl-N show raw escape sequences in escript mode
- Terminal handling differs between IEx and escript environments
- These issues likely stem from differences in how IEx and escripts handle terminal I/O