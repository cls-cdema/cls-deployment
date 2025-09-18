#!/bin/bash

# SSH Utility Functions for CLS Deployment
# Provides consistent SSH key handling across Ubuntu 22.04 and 24.04
# Works with both root and sudo user accounts

# Function to get the appropriate home directory
get_user_home() {
    if [ "$EUID" -eq 0 ]; then
        echo "/root"
    else
        echo "$HOME"
    fi
}

# Function to find existing SSH public key
# Returns the path to the first available public key
find_ssh_public_key() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"

    # Check for different key types in order of preference (newest to oldest)
    for key_type in id_ed25519 id_ecdsa id_rsa; do
        if [ -f "${ssh_dir}/${key_type}.pub" ]; then
            echo "${ssh_dir}/${key_type}.pub"
            return 0
        fi
    done
    return 1
}

# Function to find existing SSH private key
# Returns the path to the first available private key
find_ssh_private_key() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"

    # Check for different key types in order of preference (newest to oldest)
    for key_type in id_ed25519 id_ecdsa id_rsa; do
        if [ -f "${ssh_dir}/${key_type}" ]; then
            echo "${ssh_dir}/${key_type}"
            return 0
        fi
    done
    return 1
}

# Function to generate SSH key with appropriate defaults
generate_ssh_key() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"
    local comment="${1:-$(whoami)@$(hostname)}"

    # Ensure .ssh directory exists with correct permissions
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Generate key based on SSH version capabilities
    if ssh-keygen -t ed25519 -f /dev/null -N "" 2>/dev/null; then
        # Ed25519 is supported (modern SSH)
        echo "Generating Ed25519 SSH key..."
        ssh-keygen -t ed25519 -C "$comment" -f "${ssh_dir}/id_ed25519" -N ""
        chmod 600 "${ssh_dir}/id_ed25519"
        chmod 644 "${ssh_dir}/id_ed25519.pub"
        echo "${ssh_dir}/id_ed25519.pub"
    else
        # Fallback to RSA for older systems
        echo "Generating RSA SSH key (Ed25519 not supported)..."
        ssh-keygen -t rsa -b 4096 -C "$comment" -f "${ssh_dir}/id_rsa" -N ""
        chmod 600 "${ssh_dir}/id_rsa"
        chmod 644 "${ssh_dir}/id_rsa.pub"
        echo "${ssh_dir}/id_rsa.pub"
    fi
}

# Function to ensure SSH key exists, generate if needed
ensure_ssh_key() {
    local comment="${1:-$(whoami)@$(hostname)}"
    local pub_key

    pub_key=$(find_ssh_public_key)
    if [ $? -eq 0 ]; then
        echo "SSH public key found: $pub_key"
        echo "$pub_key"
        return 0
    else
        echo "No SSH key found. Generating new SSH key..."
        generate_ssh_key "$comment"
        return $?
    fi
}

# Function to display SSH public key
display_ssh_public_key() {
    local pub_key=$(find_ssh_public_key)

    if [ $? -eq 0 ] && [ -f "$pub_key" ]; then
        echo "SSH Public Key ($(basename "$pub_key")):"
        echo "================================================="
        cat "$pub_key"
        echo "================================================="
        return 0
    else
        echo "Error: No SSH public key found!"
        return 1
    fi
}

# Function to setup SSH known_hosts for GitHub
setup_github_known_hosts() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"
    local known_hosts="${ssh_dir}/known_hosts"

    # Ensure .ssh directory exists
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Add GitHub to known_hosts if not already present
    if ! grep -q "github.com" "$known_hosts" 2>/dev/null; then
        echo "Adding GitHub to SSH known_hosts..."
        ssh-keyscan github.com >> "$known_hosts" 2>/dev/null
        chmod 644 "$known_hosts"
    else
        echo "GitHub already in SSH known_hosts"
    fi
}

# Function to test SSH connection to GitHub
test_github_ssh() {
    echo "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✓ SSH connection to GitHub successful"
        return 0
    else
        echo "✗ SSH connection to GitHub failed"
        echo "Please ensure your SSH public key is added as a deploy key to the repository"
        return 1
    fi
}

# Function to get SSH connection info
get_ssh_info() {
    echo "SSH Configuration Information:"
    echo "============================="
    echo "User: $(whoami)"
    echo "Home: $(get_user_home)"
    echo "SSH Dir: $(get_user_home)/.ssh"
    echo ""

    local pub_key=$(find_ssh_public_key)
    if [ $? -eq 0 ]; then
        echo "Public Key: $pub_key"
        echo "Key Type: $(ssh-keygen -l -f "$pub_key" 2>/dev/null | awk '{print $4}' | tr -d '()')"
    else
        echo "Public Key: Not found"
    fi

    local priv_key=$(find_ssh_private_key)
    if [ $? -eq 0 ]; then
        echo "Private Key: $priv_key"
    else
        echo "Private Key: Not found"
    fi
}

# Export functions for use in other scripts
export -f get_user_home
export -f find_ssh_public_key
export -f find_ssh_private_key
export -f generate_ssh_key
export -f ensure_ssh_key
export -f display_ssh_public_key
export -f setup_github_known_hosts
export -f test_github_ssh
export -f get_ssh_info
