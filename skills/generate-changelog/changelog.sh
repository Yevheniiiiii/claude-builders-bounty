#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-CHANGELOG.md}"

LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"

if [ -n "$LAST_TAG" ]; then
    RANGE="${LAST_TAG}..HEAD"
else
    RANGE="HEAD"
fi

mapfile -t COMMITS < <(
    git log "$RANGE" --no-merges --pretty=format:'%s'
)

declare -a ADDED=()
declare -a FIXED=()
declare -a CHANGED=()
declare -a REMOVED=()

for msg in "${COMMITS[@]}"; do

    case "$msg" in
        feat:*|feat\(*|add:*|new:*)
            ADDED+=("$msg")
            ;;

        fix:*|fix\(*|bug:*|hotfix:*)
            FIXED+=("$msg")
            ;;

        remove:*|removed:*|delete:*|drop:*)
            REMOVED+=("$msg")
            ;;

        *)
            CHANGED+=("$msg")
            ;;
    esac
done

{
    echo "# Changelog"
    echo
    echo "## Unreleased - $(date +%Y-%m-%d)"

    echo
    echo "### Added"
    if [ ${#ADDED[@]} -eq 0 ]; then
        echo "- None"
    else
        printf -- '- %s\n' "${ADDED[@]}"
    fi

    echo
    echo "### Fixed"
    if [ ${#FIXED[@]} -eq 0 ]; then
        echo "- None"
    else
        printf -- '- %s\n' "${FIXED[@]}"
    fi

    echo
    echo "### Changed"
    if [ ${#CHANGED[@]} -eq 0 ]; then
        echo "- None"
    else
        printf -- '- %s\n' "${CHANGED[@]}"
    fi

    echo
    echo "### Removed"
    if [ ${#REMOVED[@]} -eq 0 ]; then
        echo "- None"
    else
        printf -- '- %s\n' "${REMOVED[@]}"
    fi

} > "$OUT"

echo "Generated $OUT"
