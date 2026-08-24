#!/bin/bash
# common.sh - Shared functions and variables for AI rules scripts
#
# This file is sourced by install.sh, check.sh, and uninstall.sh.
# Do not run this file directly.

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly."
    exit 1
fi

# ============================================================================
# Path Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================================
# Output Configuration
# ============================================================================

# Colors for output (disabled if not a terminal or --quiet is set)
if [[ -t 1 ]] && [[ "${QUIET:-}" != "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# ============================================================================
# Print Functions
# ============================================================================

print_success() {
    [[ "${QUIET:-}" == "true" ]] && return
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    [[ "${QUIET:-}" == "true" ]] && return
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    # Always print errors, even in quiet mode
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    [[ "${QUIET:-}" == "true" ]] && return
    echo -e "${BLUE}→${NC} $1"
}

print_message() {
    [[ "${QUIET:-}" == "true" ]] && return
    echo "$1"
}

# ============================================================================
# Argument Parsing Helpers
# ============================================================================

# Initialize quiet mode (default off)
QUIET="${QUIET:-false}"

# Parse common arguments (--quiet, --help)
# Sets global QUIET variable and PARSED_ARGS array
# Must NOT be called in a subshell (no $(...))
parse_common_args() {
    QUIET="false"
    PARSED_ARGS=()

    for arg in "$@"; do
        case "$arg" in
            -q|--quiet)
                QUIET="true"
                ;;
            *)
                PARSED_ARGS+=("$arg")
                ;;
        esac
    done
}

# Show usage and exit
show_usage() {
    local script_name="$1"
    local description="$2"

    echo "Usage: $script_name [OPTIONS] /path/to/kubeflow-notebooks"
    echo ""
    echo "$description"
    echo ""
    echo "Options:"
    echo "  -q, --quiet    Suppress non-error output"
    echo "  -h, --help     Show this help message"
    exit 0
}

# ============================================================================
# Validation Functions
# ============================================================================

# Resolve path to absolute and validate it exists
resolve_target_path() {
    local target="$1"

    if [[ -z "$target" ]]; then
        return 1
    fi

    # Resolve to absolute path
    if [[ "$target" == /* ]]; then
        echo "$target"
    else
        echo "$(cd "$target" 2>/dev/null && pwd)" || echo ""
    fi
}

# Validate target is a Kubeflow Notebooks directory
validate_kubeflow_dir() {
    local target="$1"

    if [[ ! -d "$target" ]]; then
        print_error "Target directory does not exist: $target"
        return 1
    fi

    if [[ ! -d "$target/workspaces" ]]; then
        print_error "Invalid Kubeflow Notebooks directory (missing workspaces/): $target"
        return 1
    fi

    return 0
}

# ============================================================================
# Resource Type Discovery
# ============================================================================

# Discover all resource types (top-level directories with a mappings.conf).
# Populates the RESOURCE_TYPES array.
discover_resource_types() {
    RESOURCE_TYPES=()
    for dir in "$REPO_ROOT"/*/; do
        [[ -f "$dir/mappings.conf" ]] || continue
        RESOURCE_TYPES+=("$(basename "$dir")")
    done

    if [[ ${#RESOURCE_TYPES[@]} -eq 0 ]]; then
        print_error "No resource types found (no directories with mappings.conf)"
        return 1
    fi
    return 0
}

# ============================================================================
# Mappings File Functions
# ============================================================================

# Process each mapping in a config file.
# Usage: process_mappings <source_dir> <mappings_file> <callback>
# The callback receives: source target
#   source is relative to source_dir
#   target is relative to TARGET_ROOT
process_mappings() {
    local source_dir="$1"
    local mappings_file="$2"
    local callback="$3"

    if [[ ! -f "$mappings_file" ]]; then
        print_error "Mappings file not found: $mappings_file"
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Parse source and target (whitespace separated)
        local source target
        read -r source target <<< "$line"

        if [[ -n "$source" ]] && [[ -n "$target" ]]; then
            "$callback" "$source_dir" "$source" "$target"
        fi
    done < "$mappings_file"
}

# Process all mappings for a single resource type.
# Usage: process_resource_type <resource_type> <callback>
# The callback receives: source_dir source target
process_resource_type() {
    local resource_type="$1"
    local callback="$2"
    local source_dir="$REPO_ROOT/$resource_type"
    local mappings_file="$source_dir/mappings.conf"

    process_mappings "$source_dir" "$mappings_file" "$callback"
}

# Generate .gitignore entries from all discovered mappings files
generate_gitignore_entries() {
    local entries=()

    for resource_type in "${RESOURCE_TYPES[@]}"; do
        local mappings_file="$REPO_ROOT/$resource_type/mappings.conf"
        [[ -f "$mappings_file" ]] || continue

        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue

            local source target
            read -r source target <<< "$line"

            if [[ -n "$target" ]]; then
                entries+=("$target")
            fi
        done < "$mappings_file"
    done

    # Print unique entries
    printf '%s\n' "${entries[@]}" | sort -u
}
