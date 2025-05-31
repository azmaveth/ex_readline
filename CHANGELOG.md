# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-05-31

### Added
- **Fallback escape sequence parsing**: Added EscapeParser module for environments without TTY access
- **Robust terminal detection**: Fallback to standard IO when stty/TTY commands fail
- **Debug scripts**: Added diagnostic tools to understand terminal environments

### Fixed
- **Escript mode in restricted environments**: Now works when /dev/tty is unavailable (e.g., mcp_chat CLI)
- **Escape sequences in fallback mode**: Arrow keys now properly parsed even without raw terminal mode
- **Terminal setup always succeeds**: Removed error cases, always falls back to working mode

### Changed
- Terminal.setup_raw_mode() now always returns {:ok, mode} (never errors)
- Improved escape sequence parsing to handle more terminal types

## [0.2.0] - 2025-05-30

### Added
- **Escript terminal handling**: Complete rewrite of terminal handling to support both IEx and escript environments
- **Automatic mode detection**: Library automatically detects whether it's running in IEx or escript mode
- **Direct TTY access**: Escript mode now uses system commands and direct /dev/tty access for proper terminal control
- **Comprehensive test suite**: Added extensive test coverage for both environments including terminal tests, keybinding tests, and integration tests
- **Terminal abstraction layer**: Clean separation between terminal modes with unified API

### Changed
- **BREAKING:** Terminal.setup_raw_mode() now returns {:ok, mode} instead of just the settings
- **BREAKING:** Terminal.read_key() now accepts an optional terminal mode parameter
- **BREAKING:** Keybindings.handle_key() now requires terminal mode as third parameter
- Improved error handling throughout the terminal system
- Enhanced escape sequence detection and handling

### Fixed
- **Arrow keys in escript mode**: No longer show raw escape sequences (^[[A, ^[[B, etc.)
- **Ctrl-P/N navigation in escript mode**: History navigation now works correctly
- **All control sequences**: Proper handling of all keybindings in escript environments
- Terminal capability detection in different runtime environments
- Escape sequence reading in escript mode

### Removed
- Dependency on Erlang's standard IO for escript terminal handling (now uses direct TTY access)

## [0.1.0] - 2025-05-25

### Added
- Initial release of ExReadline
- Simple reader implementation using Erlang's IO system
- Advanced line editor with readline functionality
- Command history with persistence to disk
- Basic Emacs-style keybindings (Ctrl-A/E/B/F/K/U/W)
- Arrow key support for navigation and history (with known issues in escript mode)
- Tab completion with customizable completion function
- Word-based cursor movement (Alt-B, Alt-F)
- Line killing commands (Ctrl-K, Ctrl-U, Ctrl-W)
- Terminal control (clear screen, cursor movement)
- GenServer-based architecture for both implementations
- Configurable history file location and size
- Unified interface through main ExReadline module
- Basic test coverage

### Known Issues
- Arrow keys show escape sequences (^[[A, ^[[B) in escript mode
- Ctrl-P/N navigation shows literal characters in escript mode
- Terminal handling differs between IEx and escript environments