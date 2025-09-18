#!/bin/bash

# System Utility Functions for CLS Deployment
# Provides system compatibility checks and version-specific handling
# Works across Ubuntu 20.04, 22.04, and 24.04 LTS versions

# Function to get Ubuntu version information
get_ubuntu_version() {
    if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_RELEASE"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -rs
    else
        echo "unknown"
    fi
}

# Function to get Ubuntu codename
get_ubuntu_codename() {
    if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_CODENAME"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -cs
    else
        echo "unknown"
    fi
}

# Function to check if running on supported Ubuntu version
is_supported_ubuntu() {
    local version=$(get_ubuntu_version)
    case $version in
        20.04|22.04|24.04)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to get PHP version based on Ubuntu version
get_recommended_php_version() {
    local ubuntu_version=$(get_ubuntu_version)
    case $ubuntu_version in
        20.04)
            echo "7.4"
            ;;
        22.04)
            echo "8.1"
            ;;
        24.04)
            echo "8.3"
            ;;
        *)
            echo "default"
            ;;
    esac
}

# Function to get MySQL version based on Ubuntu version
get_recommended_mysql_version() {
    local ubuntu_version=$(get_ubuntu_version)
    case $ubuntu_version in
        20.04)
            echo "8.0"
            ;;
        22.04)
            echo "8.0"
            ;;
        24.04)
            echo "8.0"
            ;;
        *)
            echo "default"
            ;;
    esac
}

# Function to check if user is root
is_root_user() {
    [ "$EUID" -eq 0 ]
}

# Function to check if user has sudo privileges
has_sudo_privileges() {
    sudo -n true 2>/dev/null
}

# Function to get current user type (root, sudo, or regular)
get_user_type() {
    if is_root_user; then
        echo "root"
    elif has_sudo_privileges; then
        echo "sudo"
    else
        echo "regular"
    fi
}

# Function to ensure script is run with appropriate privileges
ensure_privileges() {
    local user_type=$(get_user_type)

    case $user_type in
        root)
            echo "Running as root user"
            return 0
            ;;
        sudo)
            echo "Running with sudo privileges"
            return 0
            ;;
        regular)
            echo "Error: This script requires root privileges or sudo access"
            echo "Please run with: sudo $0"
            return 1
            ;;
    esac
}

# Function to get package manager command based on system
get_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt-get"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    else
        echo "unknown"
    fi
}

# Function to update package lists with proper error handling
update_package_lists() {
    local pm=$(get_package_manager)

    echo "Updating package lists..."

    if [ "$pm" != "unknown" ]; then
        # Set environment variables for non-interactive installation
        export DEBIAN_FRONTEND=noninteractive
        export DEBIAN_PRIORITY=critical

        if is_root_user; then
            $pm update -y
        else
            sudo -E $pm update -y
        fi

        return $?
    else
        echo "Error: No supported package manager found"
        return 1
    fi
}

# Function to install packages with version-specific handling
install_packages() {
    local pm=$(get_package_manager)
    local ubuntu_version=$(get_ubuntu_version)

    if [ "$pm" = "unknown" ]; then
        echo "Error: No supported package manager found"
        return 1
    fi

    echo "Installing packages for Ubuntu $ubuntu_version..."

    # Set environment variables for non-interactive installation
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical

    local install_cmd
    if is_root_user; then
        install_cmd="$pm install -y"
    else
        install_cmd="sudo -E $pm install -y"
    fi

    # Install packages
    for package in "$@"; do
        echo "Installing $package..."
        if $install_cmd "$package"; then
            echo "✓ Successfully installed $package"
        else
            echo "✗ Failed to install $package"
            return 1
        fi
    done

    return 0
}

# Function to upgrade system packages safely
upgrade_system() {
    local pm=$(get_package_manager)

    if [ "$pm" = "unknown" ]; then
        echo "Error: No supported package manager found"
        return 1
    fi

    echo "Upgrading system packages..."

    # Set environment variables for non-interactive installation
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical

    local upgrade_cmd
    if is_root_user; then
        upgrade_cmd="$pm"
    else
        upgrade_cmd="sudo -E $pm"
    fi

    # Update and upgrade
    $upgrade_cmd update -qy
    $upgrade_cmd -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
    $upgrade_cmd -qy autoclean

    return $?
}

# Function to check system requirements
check_system_requirements() {
    echo "System Requirements Check:"
    echo "=========================="

    # Check Ubuntu version
    local version=$(get_ubuntu_version)
    local codename=$(get_ubuntu_codename)
    echo "OS Version: Ubuntu $version ($codename)"

    if is_supported_ubuntu; then
        echo "✓ Supported Ubuntu version"
    else
        echo "✗ Unsupported Ubuntu version"
        echo "  Supported versions: 20.04, 22.04, 24.04"
        return 1
    fi

    # Check user privileges
    local user_type=$(get_user_type)
    echo "User Type: $user_type"

    if [ "$user_type" = "regular" ]; then
        echo "✗ Insufficient privileges"
        return 1
    else
        echo "✓ Sufficient privileges"
    fi

    # Check available disk space (minimum 5GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local min_space=$((5 * 1024 * 1024)) # 5GB in KB

    echo "Available Space: $(($available_space / 1024 / 1024))GB"

    if [ "$available_space" -lt "$min_space" ]; then
        echo "✗ Insufficient disk space (minimum 5GB required)"
        return 1
    else
        echo "✓ Sufficient disk space"
    fi

    # Check internet connectivity
    echo -n "Internet Connectivity: "
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "✓ Available"
    else
        echo "✗ Not available"
        return 1
    fi

    echo ""
    echo "✓ All system requirements met"
    return 0
}

# Function to display system information
show_system_info() {
    echo "System Information:"
    echo "==================="
    echo "OS: $(lsb_release -d | cut -f2-)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "User: $(whoami) ($(get_user_type))"
    echo "Home: $(get_user_home)"
    echo "Shell: $SHELL"
    echo "Package Manager: $(get_package_manager)"
    echo "Recommended PHP: $(get_recommended_php_version)"
    echo "Recommended MySQL: $(get_recommended_mysql_version)"
    echo ""
}

# Function to setup firewall rules
setup_firewall() {
    local ports=("$@")

    if ! command -v ufw >/dev/null 2>&1; then
        echo "Installing UFW firewall..."
        install_packages ufw
    fi

    echo "Configuring firewall..."

    local ufw_cmd
    if is_root_user; then
        ufw_cmd="ufw"
    else
        ufw_cmd="sudo ufw"
    fi

    # Enable UFW
    $ufw_cmd --force enable

    # Allow SSH
    $ufw_cmd allow ssh

    # Allow specified ports
    for port in "${ports[@]}"; do
        echo "Allowing port $port..."
        $ufw_cmd allow "$port"
    done

    # Reload firewall
    $ufw_cmd reload

    echo "✓ Firewall configured"
}

# Export functions for use in other scripts
export -f get_ubuntu_version
export -f get_ubuntu_codename
export -f is_supported_ubuntu
export -f get_recommended_php_version
export -f get_recommended_mysql_version
export -f is_root_user
export -f has_sudo_privileges
export -f get_user_type
export -f ensure_privileges
export -f get_package_manager
export -f update_package_lists
export -f install_packages
export -f upgrade_system
export -f check_system_requirements
export -f show_system_info
export -f setup_firewall
