#!/bin/bash
# uninstall.sh - Removes symlinks created by install.sh
#
# Usage:
#   ./scripts/uninstall.sh [OPTIONS] /path/to/kubeflow-notebooks
#
# Options:
#   -q, --quiet    Suppress non-error output
#   -h, --help     Show help message

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Script-specific variables
# ============================================================================

TOTAL_REMOVED=0
TOTAL_RESTORED=0
TOTAL_SKIPPED=0

# ============================================================================
# Functions
# ============================================================================

remove_link() {
    local source_dir="$1"  # Not used, but received from process_mappings
    local source="$2"      # Not used, but received from process_mappings
    local target="$3"
    local full_target="$TARGET_ROOT/$target"

    if [[ -L "$full_target" ]]; then
        rm "$full_target"
        print_success "Removed: $target"
        ((TOTAL_REMOVED++)) || true

        if [[ -f "$full_target.backup" ]]; then
            mv "$full_target.backup" "$full_target"
            print_success "Restored backup: $target"
            ((TOTAL_RESTORED++)) || true
        fi
    elif [[ -f "$full_target" ]]; then
        print_warning "Not a symlink, skipping: $target"
        ((TOTAL_SKIPPED++)) || true
    else
        # File doesn't exist, nothing to do
        ((TOTAL_SKIPPED++)) || true
    fi
}

# ============================================================================
# Main
# ============================================================================

# Parse arguments
parse_common_args "$@"
set -- "${PARSED_ARGS[@]}"

TARGET_INPUT="$1"

# Show help
if [[ -z "$TARGET_INPUT" ]] || [[ "$TARGET_INPUT" == "-h" ]] || [[ "$TARGET_INPUT" == "--help" ]]; then
    show_usage "$0" "Removes AI rules symlinks."
fi

# Resolve and validate target path
TARGET_ROOT=$(resolve_target_path "$TARGET_INPUT")
if [[ -z "$TARGET_ROOT" ]]; then
    print_error "Target directory does not exist: $TARGET_INPUT"
    exit 1
fi

if [[ ! -d "$TARGET_ROOT" ]]; then
    print_error "Target directory does not exist: $TARGET_INPUT"
    exit 1
fi

discover_resource_types || exit 1

# Run uninstallation
print_message "Uninstalling AI rules from: $TARGET_ROOT"
print_message ""

for resource_type in "${RESOURCE_TYPES[@]}"; do
    print_info "Removing ${resource_type}..."
    process_resource_type "$resource_type" remove_link
    print_message ""
done

# Summary
print_message "Uninstall complete!"
print_message "  Removed:  $TOTAL_REMOVED"
print_message "  Restored: $TOTAL_RESTORED"
print_message "  Skipped:  $TOTAL_SKIPPED"
