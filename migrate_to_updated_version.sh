#!/bin/bash

# Migration Script for CLS Deployment
# Upgrades existing installations to the updated version with Ubuntu 22.04/24.04 fixes
# Version: 2.0.0

set -e  # Exit on any error

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Migration version
MIGRATION_VERSION="2.0.0"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} CLS Deployment Migration Script v${MIGRATION_VERSION}${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup existing files
backup_existing_files() {
    print_step "Backing up existing configuration files..."

    local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup important files
    local files_to_backup=(
        ".env"
        "1.setup_server.sh"
        "2.configure_project.sh"
        "3.configure_ssl.sh"
        "4.setup_cron_job_backup_maintanance.sh"
    )

    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$backup_dir/"
            print_success "Backed up $file"
        fi
    done

    echo "BACKUP_DIR=$backup_dir" > .migration_info
    print_success "Backup created in: $backup_dir"
}

# Function to create utility directories and files
create_utilities() {
    print_step "Creating utility functions..."

    mkdir -p utils

    # Create SSH utilities
    cat > utils/ssh_utils.sh << 'EOF'
#!/bin/bash

# SSH Utility Functions for CLS Deployment
# Provides consistent SSH key handling across Ubuntu 22.04 and 24.04

get_user_home() {
    if [ "$EUID" -eq 0 ]; then
        echo "/root"
    else
        echo "$HOME"
    fi
}

find_ssh_public_key() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"

    for key_type in id_ed25519 id_ecdsa id_rsa; do
        if [ -f "${ssh_dir}/${key_type}.pub" ]; then
            echo "${ssh_dir}/${key_type}.pub"
            return 0
        fi
    done
    return 1
}

generate_ssh_key() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"
    local comment="${1:-$(whoami)@$(hostname)}"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if ssh-keygen -t ed25519 -f /dev/null -N "" 2>/dev/null; then
        echo "Generating Ed25519 SSH key..."
        ssh-keygen -t ed25519 -C "$comment" -f "${ssh_dir}/id_ed25519" -N ""
        chmod 600 "${ssh_dir}/id_ed25519"
        chmod 644 "${ssh_dir}/id_ed25519.pub"
        echo "${ssh_dir}/id_ed25519.pub"
    else
        echo "Generating RSA SSH key (Ed25519 not supported)..."
        ssh-keygen -t rsa -b 4096 -C "$comment" -f "${ssh_dir}/id_rsa" -N ""
        chmod 600 "${ssh_dir}/id_rsa"
        chmod 644 "${ssh_dir}/id_rsa.pub"
        echo "${ssh_dir}/id_rsa.pub"
    fi
}

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

setup_github_known_hosts() {
    local user_home=$(get_user_home)
    local ssh_dir="${user_home}/.ssh"
    local known_hosts="${ssh_dir}/known_hosts"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if ! grep -q "github.com" "$known_hosts" 2>/dev/null; then
        echo "Adding GitHub to SSH known_hosts..."
        ssh-keyscan github.com >> "$known_hosts" 2>/dev/null
        chmod 644 "$known_hosts"
    else
        echo "GitHub already in SSH known_hosts"
    fi
}

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

export -f get_user_home find_ssh_public_key generate_ssh_key ensure_ssh_key
export -f display_ssh_public_key setup_github_known_hosts test_github_ssh
EOF

    # Create environment utilities
    cat > utils/env_utils.sh << 'EOF'
#!/bin/bash

# Environment Variable Utility Functions

escape_for_sed() {
    local value="$1"
    printf '%s\n' "$value" | sed 's/[[\.*^$()+?{|\\]/\\&/g'
}

replace_env_var() {
    local placeholder="$1"
    local value="$2"
    local file="$3"

    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist"
        return 1
    fi

    cp "$file" "${file}.bak"
    local escaped_value=$(escape_for_sed "$value")

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

update_env_file() {
    local file="$1"
    shift

    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist"
        return 1
    fi

    echo "Updating environment variables in $file..."

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

export -f escape_for_sed replace_env_var update_env_file validate_env_vars
EOF

    # Create system utilities
    cat > utils/system_utils.sh << 'EOF'
#!/bin/bash

# System Utility Functions

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

is_root_user() {
    [ "$EUID" -eq 0 ]
}

has_sudo_privileges() {
    sudo -n true 2>/dev/null
}

get_user_type() {
    if is_root_user; then
        echo "root"
    elif has_sudo_privileges; then
        echo "sudo"
    else
        echo "regular"
    fi
}

ensure_privileges() {
    local user_type=$(get_user_type)

    case $user_type in
        root|sudo)
            echo "Running with appropriate privileges ($user_type)"
            return 0
            ;;
        regular)
            echo "Error: This script requires root privileges or sudo access"
            return 1
            ;;
    esac
}

install_packages() {
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical

    local install_cmd
    if is_root_user; then
        install_cmd="apt install -y"
    else
        install_cmd="sudo -E apt install -y"
    fi

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

export -f get_ubuntu_version is_root_user has_sudo_privileges get_user_type
export -f ensure_privileges install_packages
EOF

    chmod +x utils/*.sh
    print_success "Utility functions created"
}

# Function to update main scripts
update_main_scripts() {
    print_step "Updating main deployment scripts..."

    # Source the old .env to preserve settings
    if [ -f ".env" ]; then
        source .env
    else
        print_error ".env file not found. Please ensure it exists before migration."
        exit 1
    fi

    # Update 1.setup_server.sh with SSH key fixes
    print_step "Updating 1.setup_server.sh..."

    # Create updated setup server script
    cat > 1.setup_server.sh << 'EOL'
#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}
source ${SCRIPT_DIR}/.env

# Load utilities
if [ -f "${SCRIPT_DIR}/utils/ssh_utils.sh" ]; then
    source ${SCRIPT_DIR}/utils/ssh_utils.sh
fi
if [ -f "${SCRIPT_DIR}/utils/system_utils.sh" ]; then
    source ${SCRIPT_DIR}/utils/system_utils.sh
fi

echo "Welcome to CLS Phase 1 Installer 2.0.0 (Updated)"
echo "This version supports Ubuntu 22.04/24.04 with improved SSH key handling"
echo ""
echo "Domain = ${domain}"
echo "Database = ${db}"
echo "Database User = ${user}"
echo "Admin Email = ${contact}"
echo "CLS Project Repository = ${repo}"
echo "Repository Branch = ${branch}"
echo ""

if [ "$1" = "update" ]; then
    echo "Update mode.."
else
    read -p "Do you want to proceed? (yes/no) " yn
    case $yn in
        yes ) echo "Configuration confirmed";;
        no ) echo "Exiting..."; exit;;
        * ) echo "Invalid response"; exit 1;;
    esac
fi

# Ensure proper privileges
if ! ensure_privileges; then
    exit 1
fi

echo "Updating system..."
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

if is_root_user; then
    apt-get -qy update
    apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
    apt-get -qy autoclean
else
    sudo -E apt-get -qy update
    sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
    sudo -E apt-get -qy autoclean
fi

echo "Installing packages..."
install_packages git apache2 mysql-server php libapache2-mod-php php-mysql php-common php-xml php-xmlrpc php-curl php-gd php-imagick php-cli php-dev php-imap php-mbstring php-opcache php-soap php-zip php-intl curl python3-certbot-apache

if [ "$1" != "update" ]; then
    # SSH key setup with modern support
    echo "Setting up SSH configuration..."
    SSHKEY=$(ensure_ssh_key "cls-deployment@$(hostname)")
    setup_github_known_hosts

    # Configure Apache
    if is_root_user; then
        a2dissite 000-default
        a2enmod ssl proxy_http proxy_wstunnel rewrite
    else
        sudo a2dissite 000-default
        sudo a2enmod ssl proxy_http proxy_wstunnel rewrite
    fi

    # Install Composer
    if ! command -v composer >/dev/null 2>&1; then
        echo "Installing Composer..."
        curl -s https://getcomposer.org/installer | php
        if is_root_user; then
            mv composer.phar /usr/bin/composer
        else
            sudo mv composer.phar /usr/bin/composer
        fi
        chmod +x /usr/bin/composer
    fi

    # Configure firewall
    if command -v ufw >/dev/null 2>&1; then
        if is_root_user; then
            ufw --force enable
            ufw allow ssh
            ufw allow 'Apache Full'
            ufw reload
        else
            sudo ufw --force enable
            sudo ufw allow ssh
            sudo ufw allow 'Apache Full'
            sudo ufw reload
        fi
    fi
fi

# PHP configuration
echo "Configuring PHP settings..."
INI_LOC=$(php -i 2>/dev/null | sed -n '/^Loaded Configuration File => /{s:^.*> ::;p;q}')

if [ -n "$INI_LOC" ] && [ -f "$INI_LOC" ]; then
    if is_root_user; then
        cp "$INI_LOC" "${INI_LOC}.backup"
        sed -i 's/^upload_max_filesize.*/upload_max_filesize = 400M/' "$INI_LOC"
        sed -i 's/^post_max_size.*/post_max_size = 200M/' "$INI_LOC"
        sed -i 's/^max_execution_time.*/max_execution_time = 3000/' "$INI_LOC"
        sed -i 's/^max_input_time.*/max_input_time = 5000/' "$INI_LOC"
        sed -i 's/^memory_limit.*/memory_limit = 512M/' "$INI_LOC"
    else
        sudo cp "$INI_LOC" "${INI_LOC}.backup"
        sudo sed -i 's/^upload_max_filesize.*/upload_max_filesize = 400M/' "$INI_LOC"
        sudo sed -i 's/^post_max_size.*/post_max_size = 200M/' "$INI_LOC"
        sudo sed -i 's/^max_execution_time.*/max_execution_time = 3000/' "$INI_LOC"
        sudo sed -i 's/^max_input_time.*/max_input_time = 5000/' "$INI_LOC"
        sudo sed -i 's/^memory_limit.*/memory_limit = 512M/' "$INI_LOC"
    fi
    echo "✓ PHP configuration updated"
fi

if [ "$1" != "update" ]; then
    echo ""
    echo "================================================"
    echo "SSH Deployment Key Setup Required"
    echo "================================================"
    echo "Please add the following SSH key as a deployment key"
    echo "in your repository: ${repo}"
    echo ""
    display_ssh_public_key
    echo ""
    echo "After setup, proceed with: ./2.configure_project.sh"
    echo "================================================"
fi

if [ "$1" = "complete" ]; then
    echo "Complete Mode - running all steps..."
    ${SCRIPT_DIR}/2.configure_project.sh
    ${SCRIPT_DIR}/3.configure_ssl.sh y
    ${SCRIPT_DIR}/4.setup_cron_job_backup_maintanance.sh y
fi
EOL

    chmod +x 1.setup_server.sh
    print_success "Updated 1.setup_server.sh"

    # Update 2.configure_project.sh with improved environment handling
    print_step "Updating 2.configure_project.sh..."

    cat > 2.configure_project.sh << 'EOL'
#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}
source ${SCRIPT_DIR}/.env

# Load utilities
if [ -f "${SCRIPT_DIR}/utils/ssh_utils.sh" ]; then
    source ${SCRIPT_DIR}/utils/ssh_utils.sh
fi
if [ -f "${SCRIPT_DIR}/utils/env_utils.sh" ]; then
    source ${SCRIPT_DIR}/utils/env_utils.sh
fi
if [ -f "${SCRIPT_DIR}/utils/system_utils.sh" ]; then
    source ${SCRIPT_DIR}/utils/system_utils.sh
fi

# Validate required variables
validate_env_vars "domain" "db" "db_host" "user" "pass" "repo" "branch"

echo "Setting up environment variables in ./data/db.sql..."
sed -i "s/__DOMAIN__/${domain}/g" ./data/db.sql
sed -i "s/__DB__/${db}/g" ./data/db.sql
sed -i "s/__USER__/${user}/g" ./data/db.sql
sed -i "s/__PASS__/${pass}/g" ./data/db.sql

echo "Preparing MySQL Database and User..."
if is_root_user; then
    mysql < ./data/db.sql
else
    sudo mysql < ./data/db.sql
fi

# Configure Apache
if is_root_user; then
    a2dissite ${domain} 2>/dev/null || true
    chown -R www-data: /var/www/
else
    sudo a2dissite ${domain} 2>/dev/null || true
    sudo chown -R www-data: /var/www/
fi

if command -v setfacl >/dev/null 2>&1; then
    if is_root_user; then
        setfacl -R -m u:$USER:rwx /var/www
    else
        sudo setfacl -R -m u:$USER:rwx /var/www
    fi
fi

if [ "$1" = "" ]; then
    if is_root_user; then
        cp ./data/000-default.conf /etc/apache2/sites-available/${domain}.conf
    else
        sudo cp ./data/000-default.conf /etc/apache2/sites-available/${domain}.conf
    fi
fi

cd /var/www
setup_github_known_hosts

Directory=/var/www/${domain}
if [ -d "$Directory" ]; then
    echo "Repository found..."
    if [ "$1" = "reset" ]; then
        echo "Project reset mode - cleaning existing site..."
        if is_root_user; then
            rm -rf /var/www/${domain}
        else
            sudo rm -rf /var/www/${domain}
        fi
        git clone -b ${branch} ${repo} ${domain}
        git config --global --add safe.directory /var/www/${domain}
    else
        cd ${domain}
        echo "Updating repository..."
        git stash && git pull origin ${branch}
    fi
else
    echo "Cloning repository..."
    git clone -b ${branch} ${repo} ${domain}
    git config --global --add safe.directory /var/www/${domain}
fi

cd ${domain}

# Backup and update .env
if [ -f "./.env.example" ]; then
    cp ./.env.example ./.env

    echo "Updating Laravel environment variables..."
    # Use improved environment variable replacement
    update_env_file "/var/www/${domain}/.env" \
        "DOMAIN" "${domain}" \
        "DB" "${db}" \
        "DBHOST" "${db_host}" \
        "USER" "${user}" \
        "PASS" "${pass}"
fi

# Update Apache configuration
if [ -f "/etc/apache2/sites-available/${domain}.conf" ]; then
    if is_root_user; then
        sed -i "s|__DOMAIN__|${domain}|g" /etc/apache2/sites-available/${domain}.conf
        sed -i "s|__CONTACT__|${contact}|g" /etc/apache2/sites-available/${domain}.conf
        a2ensite ${domain}
        systemctl reload apache2
    else
        sudo sed -i "s|__DOMAIN__|${domain}|g" /etc/apache2/sites-available/${domain}.conf
        sudo sed -i "s|__CONTACT__|${contact}|g" /etc/apache2/sites-available/${domain}.conf
        sudo a2ensite ${domain}
        sudo systemctl reload apache2
    fi
fi

# Create required directories
echo "Creating required directories..."
directories=(
    "public/upload/import"
    "public/upload/export"
    "public/upload/temp"
    "public/upload/library"
    "public/upload/location"
    "public/upload/srf"
)

for dir in "${directories[@]}"; do
    if [ ! -d "/var/www/${domain}/${dir}" ]; then
        if is_root_user; then
            mkdir -p "/var/www/${domain}/${dir}"
        else
            sudo mkdir -p "/var/www/${domain}/${dir}"
        fi
    fi
done

# Set permissions
echo "Setting directory permissions..."
if is_root_user; then
    chown -R www-data:www-data /var/www/${domain}/
    chmod -R 755 /var/www/${domain}/
    chown -R www-data:www-data /var/www/${domain}/public/upload
    chmod -R 777 /var/www/${domain}/public/upload
    [ -d "/var/www/${domain}/storage" ] && chown -R www-data:www-data /var/www/${domain}/storage
    [ -d "/var/www/${domain}/vendor" ] && chown -R www-data:www-data /var/www/${domain}/vendor
else
    sudo chown -R www-data:www-data /var/www/${domain}/
    sudo chmod -R 755 /var/www/${domain}/
    sudo chown -R www-data:www-data /var/www/${domain}/public/upload
    sudo chmod -R 777 /var/www/${domain}/public/upload
    [ -d "/var/www/${domain}/storage" ] && sudo chown -R www-data:www-data /var/www/${domain}/storage
    [ -d "/var/www/${domain}/vendor" ] && sudo chown -R www-data:www-data /var/www/${domain}/vendor
fi

if command -v setfacl >/dev/null 2>&1; then
    if is_root_user; then
        setfacl -R -m u:$USER:rwx /var/www
    else
        sudo setfacl -R -m u:$USER:rwx /var/www
    fi
fi

echo "Updating Composer packages..."
composer update

echo "Running database migrations..."
if [ "$1" = "reset" ]; then
    if is_root_user; then
        mysql < ${SCRIPT_DIR}/data/db.sql
    else
        sudo mysql < ${SCRIPT_DIR}/data/db.sql
    fi
    php artisan migrate:refresh
    php artisan passport:install --force
    if [ -f "/var/www/${domain}/database/sqls/seed.sql" ]; then
        if is_root_user; then
            mysql ${db} < /var/www/${domain}/database/sqls/seed.sql
        else
            sudo mysql ${db} < /var/www/${domain}/database/sqls/seed.sql
        fi
    fi
else
    php artisan migrate
    if [ "$1" = "" ]; then
        php artisan passport:install
        if [ -f "/var/www/${domain}/database/sqls/seed.sql" ]; then
            if is_root_user; then
                mysql ${db} < /var/www/${domain}/database/sqls/seed.sql
            else
                sudo mysql ${db} < /var/www/${domain}/database/sqls/seed.sql
            fi
        fi
    fi
fi

echo "✓ Project configuration completed successfully"
EOL

    chmod +x 2.configure_project.sh
    print_success "Updated 2.configure_project.sh"
}

# Function to create test script
create_test_script() {
    print_step "Creating test script..."

    cat > test_migration.sh << 'EOF'
#!/bin/bash

# Test script for migration validation

echo "Testing migration results..."

# Test utilities
echo "Checking utility files..."
for util in utils/ssh_utils.sh utils/env_utils.sh utils/system_utils.sh; do
    if [ -f "$util" ]; then
        echo "✓ $util exists"
        if bash -n "$util"; then
            echo "✓ $util syntax valid"
        else
            echo "✗ $util has syntax errors"
        fi
    else
        echo "✗ $util missing"
    fi
done

# Test SSH key detection
echo "Testing SSH key detection..."
source utils/ssh_utils.sh
if ssh_key=$(find_ssh_public_key); then
    echo "✓ SSH key found: $(basename "$ssh_key")"
else
    echo "! No SSH key found (normal for new systems)"
fi

# Test environment validation
echo "Testing environment configuration..."
if [ -f ".env" ]; then
    source .env
    source utils/env_utils.sh
    if validate_env_vars "domain" "db" "user"; then
        echo "✓ Required environment variables present"
    else
        echo "✗ Missing required environment variables"
    fi
else
    echo "✗ .env file not found"
fi

# Test system compatibility
echo "Testing system compatibility..."
source utils/system_utils.sh
echo "OS: $(get_ubuntu_version)"
echo "User type: $(get_user_type)"

echo "Migration test completed!"
EOF

    chmod +x test_migration.sh
    print_success "Test script created"
}

# Function to preserve .env settings
preserve_env_settings() {
    print_step "Preserving environment settings..."

    if [ -f ".env" ]; then
        # Validate current .env has required variables
        source .env

        local required_vars=("domain" "db" "user" "pass" "repo" "branch")
        local missing_vars=()

        for var in "${required_vars[@]}"; do
            if [ -z "${!var}" ]; then
                missing_vars+=("$var")
            fi
        done

        if [ ${#missing_vars[@]} -gt 0 ]; then
            print_warning "Missing required variables in .env: ${missing_vars[*]}"
            print_warning "Please update your .env file before continuing"
            return 1
        fi

        print_success "Environment configuration validated"
    else
        print_error ".env file not found"
        if [ -f ".env.example" ]; then
            print_warning "Copying .env.example to .env - please configure it"
            cp .env.example .env
        else
            print_error "No .env.example file found either"
            return 1
        fi
    fi
}

# Function to update permissions
fix_permissions() {
    print_step "Fixing file permissions..."

    chmod +x *.sh 2>/dev/null || true
    chmod +x utils/*.sh 2>/dev/null || true

    print_success "Permissions updated"
}

# Main migration process
main() {
    print_header

    echo "This script will migrate your existing CLS deployment to support:"
    echo "• Ubuntu 22.04 and 24.04 LTS"
    echo "• Modern SSH key formats (Ed25519)"
    echo "• Improved environment variable handling"
    echo "• Better error handling and validation"
    echo ""

    read -p "Do you want to proceed with the migration? (yes/no): " confirm
    case $confirm in
        yes|y|Y|Yes|YES)
            echo "Proceeding with migration..."
            ;;
        *)
            echo "Migration cancelled."
            exit 0
            ;;
    esac

    # Check if already migrated
    if [ -f ".migration_info" ]; then
        print_warning "Migration info found. Previous migration may have been performed."
        read -p "Continue anyway? (yes/no): " force_confirm
        case $force_confirm in
            yes|y|Y|Yes|YES) ;;
            *) echo "Migration cancelled."; exit 0 ;;
        esac
    fi

    # Perform migration steps
    backup_existing_files || { print_error "Backup failed"; exit 1; }
    preserve_env_settings || { print_error "Environment validation failed"; exit 1; }
    create_utilities || { print_error "Utility creation failed"; exit 1; }
    update_main_scripts || { print_error "Script update failed"; exit 1; }
    create_test_script || { print_error "Test script creation failed"; exit 1; }
    fix_permissions || { print_error "Permission fix failed"; exit 1; }

    print_success "Migration completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Test the migration: ./test_migration.sh"
    echo "2. Update your system: ./1.setup_server.sh update"
    echo "3. Update your project: ./2.configure_project.sh update"
    echo ""
    echo "Your original files are backed up in: $(cat .migration_info | cut -d= -f2)"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
