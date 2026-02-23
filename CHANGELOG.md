# Changelog

## [Unreleased]

### Changed

- Wrapped 15 lines exceeding 300 characters across 4 markdown files (no content changes)
- Tightened CI line-length check from 500 to 300 characters
- Tightened yamllint from `relaxed` preset to targeted config
  (enables structural checks, disables noisy `truthy` and `document-start` rules)
- Expanded CI line-length check to cover `.json`, `.jsonc`, and `.env` files
- Added before/after hardening example to README (nginx)
- Added Trust & Limits section to README
- Added value proposition hook to README
- Updated Contributing section in README to reference CONTRIBUTING.md
- Added `strong` to allowed HTML elements in markdownlint config

### Added

- CONTRIBUTING.md — contributor guide with local validation instructions
- SECURITY.md — security policy for a documentation repository
- CHANGELOG.md
- Issue templates (bug report, feature request)
- Pull request template
