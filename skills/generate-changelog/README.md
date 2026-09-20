# Structured CHANGELOG generator

Generates a categorized `CHANGELOG.md` from Git history.

## Setup

1. Make it executable: `chmod +x skills/generate-changelog/changelog.sh`
2. Run from a Git repository root: `bash skills/generate-changelog/changelog.sh`
3. Review the generated `CHANGELOG.md` before release.

The script uses commits since the latest Git tag. If no tag exists,
the available repository history is used.

Categories:

- Added
- Fixed
- Changed
- Removed
