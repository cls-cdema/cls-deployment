#!/bin/bash

# Environment Variable Utility Functions for CLS Deployment
# Provides robust text replacement that works across different Ubuntu versions
# Handles special characters in passwords and other values

# Function to safely escape special characters for sed
escape_for_sed() {
    local value="$1"
    # Escape special characters that could break sed
    printf '%s\n' "$value" | sed 's/[[\.*^$()+?{|\\]/\\&/g'
}

# Function to safely replace environment variables in files
replace_env_var() {
    local placeholder="$1"
    local value="$2"
    local file="$3"

    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist"
        return 1
    fi

    # Create backup
    cp "$file" "${file}.bak"

    # Escape the value for sed
    local escaped_value=$(escape_for_sed "$value")

    # Use | as delimiter to avoid conflicts with / in paths/URLs
    if sed -i "s|__${placeholder}__|${escaped_value}|g" "$file"; then
        echo "✓ Replaced __${placeholder}__ with value in $file"
        rm "${file}.bak"
        return 0
    else
        echo "✗ Failed to replace __${placeholder}__ in $file"
        mv "${file}.bak" "$file"
        return 1
    fi
}

# Function to update multiple environment variables in a file
update_env_file() {
    local file="$1"
    shift

    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist"
        return 1
    fi

    echo "Updating environment variables in $file..."

    # Process key=value pairs
    while [ $# -gt 0 ]; do
        local key="$1"
        local value="$2"

        if [ -z "$key" ] || [ -z "$value" ]; then
            echo "Warning: Skipping empty key or value"
            shift 2
            continue
        fi

        replace_env_var "$key" "$value" "$file"
        shift 2
    done
}

# Function to validate environment variables are set
validate_env_vars() {
    local missing_vars=()

    for var in "$@"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables:"
        printf " - %s\n" "${missing_vars[@]}"
        return 1
    fi

    return 0
}

# Function to display environment variables (with password masking)
show_env_vars() {
    echo "Current Environment Configuration:"
    echo "================================="

    for var in "$@"; do
        local value="${!var}"

        # Mask password fields
        if [[ "$var" =~ ^.*[Pp][Aa][Ss][Ss].*$ ]]; then
            echo "$var = ***masked***"
        else
            echo "$var = $value"
        fi
    done
    echo ""
}

# Function to create .env file from template with variable substitution
create_env_from_template() {
    local template_file="$1"
    local output_file="$2"
    shift 2

    if [ ! -f "$template_file" ]; then
        echo "Error: Template file $template_file does not exist"
        return 1
    fi

    # Copy template to output
    cp "$template_file" "$output_file"

    # Update with provided variables
    update_env_file "$output_file" "$@"
}

# Function to backup and restore .env files
backup_env_file() {
    local file="$1"
    local backup_suffix="${2:-$(date +%Y%m%d_%H%M%S)}"

    if [ -f "$file" ]; then
        cp "$file" "${file}.backup_${backup_suffix}"
        echo "✓ Backed up $file to ${file}.backup_${backup_suffix}"
        return 0
    else
        echo "Warning: File $file does not exist, cannot backup"
        return 1
    fi
}

restore_env_file() {
    local file="$1"
    local backup_suffix="$2"

    if [ -f "${file}.backup_${backup_suffix}" ]; then
        cp "${file}.backup_${backup_suffix}" "$file"
        echo "✓ Restored $file from backup_${backup_suffix}"
        return 0
    else
        echo "Error: Backup file ${file}.backup_${backup_suffix} does not exist"
        return 1
    fi
}

# Function to check if all placeholders in a file have been replaced
check_placeholders_replaced() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist"
        return 1
    fi

    local remaining=$(grep -o '__[A-Z_]*__' "$file" | sort -u)

    if [ -n "$remaining" ]; then
        echo "Warning: Unreplaced placeholders found in $file:"
        echo "$remaining"
        return 1
    else
        echo "✓ All placeholders replaced in $file"
        return 0
    fi
}

# Export functions for use in other scripts
export -f escape_for_sed
export -f replace_env_var
export -f update_env_file
export -f validate_env_vars
export -f show_env_vars
export -f create_env_from_template
export -f backup_env_file
export -f restore_env_file
export -f check_placeholders_replaced
