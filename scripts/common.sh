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
AGENTS_DIR="$REPO_ROOT/agents"
MAPPINGS_FILE="$AGENTS_DIR/mappings.conf"

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

# Validate mappings file exists
validate_mappings_file() {
    if [[ ! -f "$MAPPINGS_FILE" ]]; then
        print_error "Mappings file not found: $MAPPINGS_FILE"
        return 1
    fi
    return 0
}

# ============================================================================
# Mappings File Functions
# ============================================================================

# Process each mapping in the config file
# Usage: process_mappings callback_function
# The callback receives: source target
process_mappings() {
    local callback="$1"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Parse source and target (whitespace separated)
        local source target
        read -r source target <<< "$line"
        
        if [[ -n "$source" ]] && [[ -n "$target" ]]; then
            "$callback" "$source" "$target"
        fi
    done < "$MAPPINGS_FILE"
}

# Generate .gitignore entries from mappings
generate_gitignore_entries() {
    local entries=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        local source target
        read -r source target <<< "$line"
        
        if [[ -n "$target" ]]; then
            entries+=("$target")
        fi
    done < "$MAPPINGS_FILE"
    
    # Print unique entries
    printf '%s\n' "${entries[@]}" | sort -u
}
