# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-27

### Added
- Initial release of ExReadline
- Simple reader implementation using Erlang's IO system
- Advanced line editor with full readline functionality
- Command history with persistence to disk
- Emacs-style keybindings
- Arrow key support for navigation and history
- Tab completion with customizable completion function
- Word-based cursor movement (Alt-B, Alt-F)
- Line killing commands (Ctrl-K, Ctrl-U, Ctrl-W)
- Terminal control (clear screen, cursor movement)
- GenServer-based history management
- Configurable history file location and size
- Unified interface through main ExReadline module
- Comprehensive documentation and examples

### Features
- Two implementations: simple and advanced
- No external dependencies
- Pure Elixir implementation
- ANSI terminal support
- Configurable and extensible design