# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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