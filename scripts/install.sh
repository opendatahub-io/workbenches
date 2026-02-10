#!/bin/bash
# install.sh - Creates symlinks from Kubeflow Notebooks to AI rules files
#
# Usage:
#   ./scripts/install.sh [OPTIONS] /path/to/kubeflow-notebooks
#
# Options:
#   -q, --quiet    Suppress non-error output
#   -h, --help     Show help message
#
# Examples:
#   ./scripts/install.sh ../kubeflow-notebooks
#   ./scripts/install.sh --quiet /path/to/kubeflow-notebooks

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Script-specific variables
# ============================================================================

TOTAL_CREATED=0
TOTAL_SKIPPED=0
TOTAL_ERRORS=0

# ============================================================================
# Functions
# ============================================================================

create_link() {
    local source="$1"
    local target="$2"

    local full_source="$AGENTS_DIR/$source"
    local full_target="$TARGET_ROOT/$target"

    # Check source exists
    if [[ ! -e "$full_source" ]]; then
        print_error "Source not found: $source"
        ((TOTAL_ERRORS++)) || true
        return
    fi

    # Create parent directory if needed
    local target_dir
    target_dir=$(dirname "$full_target")
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    # Handle existing file/link
    if [[ -L "$full_target" ]]; then
        local current_link
        current_link=$(readlink "$full_target")
        if [[ "$current_link" == "$full_source" ]]; then
            print_warning "Already linked: $target"
            ((TOTAL_SKIPPED++)) || true
            return
        else
            rm "$full_target"
        fi
    elif [[ -f "$full_target" ]]; then
        print_warning "Backing up: $target -> $target.backup"
        mv "$full_target" "$full_target.backup"
    fi

    # Create symlink
    ln -s "$full_source" "$full_target"
    print_success "Created: $target"
    ((TOTAL_CREATED++)) || true
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
    show_usage "$0" "Creates symlinks from Kubeflow Notebooks to the agent files in this repository."
fi

# Resolve and validate target path
TARGET_ROOT=$(resolve_target_path "$TARGET_INPUT")
if [[ -z "$TARGET_ROOT" ]]; then
    print_error "Target directory does not exist: $TARGET_INPUT"
    exit 1
fi

validate_kubeflow_dir "$TARGET_ROOT" || exit 1
validate_mappings_file || exit 1

# Run installation
print_message "Installing AI rules..."
print_message "  Source: $REPO_ROOT"
print_message "  Target: $TARGET_ROOT"
print_message ""

print_info "Installing agents..."

process_mappings create_link

# Summary
print_message ""
print_message "Installation complete!"
print_message "  Created: $TOTAL_CREATED"
print_message "  Skipped: $TOTAL_SKIPPED"
print_message "  Errors:  $TOTAL_ERRORS"

if [[ $TOTAL_ERRORS -gt 0 ]]; then
    exit 1
fi

# Remind about .gitignore
print_message ""
print_message "Remember to add to your Kubeflow Notebooks .gitignore:"
generate_gitignore_entries | while read -r entry; do
    print_message "  $entry"
done
