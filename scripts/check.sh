#!/bin/bash
# check.sh - Verifies symlinks are correctly installed
#
# Usage:
#   ./scripts/check.sh [OPTIONS] /path/to/kubeflow-notebooks
#
# Options:
#   -q, --quiet    Suppress non-error output (exit code indicates status)
#   -h, --help     Show help message
#
# Returns exit code 0 if all links are valid, 1 otherwise.

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Script-specific variables
# ============================================================================

TOTAL_VALID=0
TOTAL_INVALID=0
TOTAL_MISSING=0

# ============================================================================
# Functions
# ============================================================================

check_link() {
    local source="$1"
    local target="$2"

    local full_source="$AGENTS_DIR/$source"
    local full_target="$TARGET_ROOT/$target"

    if [[ ! -e "$full_target" ]] && [[ ! -L "$full_target" ]]; then
        print_error "Missing: $target"
        ((TOTAL_MISSING++)) || true
        return
    fi

    if [[ ! -L "$full_target" ]]; then
        print_warning "Not a symlink: $target"
        ((TOTAL_INVALID++)) || true
        return
    fi

    local current_link
    current_link=$(readlink "$full_target")
    if [[ "$current_link" == "$full_source" ]]; then
        print_success "Valid: $target"
        ((TOTAL_VALID++)) || true
    else
        print_error "Wrong target: $target"
        print_message "         Expected: $full_source"
        print_message "         Actual:   $current_link"
        ((TOTAL_INVALID++)) || true
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
    show_usage "$0" "Checks if agent symlinks are correctly installed."
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

validate_mappings_file || exit 1

# Run check
print_message "Checking AI rules in: $TARGET_ROOT"
print_message ""

print_info "Checking agents..."

process_mappings check_link

# Summary
print_message ""
print_message "Check complete!"
print_message "  Valid:   $TOTAL_VALID"
print_message "  Invalid: $TOTAL_INVALID"
print_message "  Missing: $TOTAL_MISSING"

if [[ $TOTAL_INVALID -gt 0 ]] || [[ $TOTAL_MISSING -gt 0 ]]; then
    print_message ""
    print_message "Run ./scripts/install.sh to fix issues."
    exit 1
fi

print_message ""
print_success "All symlinks are correctly installed!"
