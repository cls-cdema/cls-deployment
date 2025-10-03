#!/bin/bash

# CLS Docker Deployment Script
# Simplified version for nginx proxy deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "${SCRIPT_DIR}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to confirm action
confirm_action() {
    local message="$1"
    read -p "$message (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to detect SSH key files dynamically
detect_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_file=""
    
    if [ ! -d "$ssh_dir" ]; then
        return 1
    fi
    
    # Look for common SSH key patterns
    for pattern in "id_rsa.pub" "id_ed25519.pub" "id_ecdsa.pub" "id_dsa.pub"; do
        if [ -f "$ssh_dir/$pattern" ]; then
            key_file="$ssh_dir/$pattern"
            break
        fi
    done
    
    # If no standard key found, look for any .pub file
    if [ -z "$key_file" ]; then
        key_file=$(find "$ssh_dir" -name "*.pub" -type f | head -n 1)
    fi
    
    if [ -n "$key_file" ] && [ -f "$key_file" ]; then
        echo "$key_file"
        return 0
    else
        return 1
    fi
}

# Function to generate SSH key if none exists
generate_ssh_key() {
    # Check if ~/.ssh directory exists, create if not
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

# Check for existing SSH public keys (id_rsa.pub or *.pub)
pub_keys=$(ls ~/.ssh/*.pub 2>/dev/null)

if [ -n "$pub_keys" ]; then
    echo "Existing SSH public key(s) found:"
    for key in $pub_keys; do
        echo "Content of $key:"
        cat "$key"
        echo ""
    done
else
    echo "No SSH key found, generating new key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
    echo "New SSH public key generated:"
    cat ~/.ssh/id_rsa.pub
fi
}

# Function to check environment file
check_env_file() {
    if [ ! -f ".env" ]; then
        print_error ".env file not found!"
        print_status "Creating .env template file..."
        create_env_template
        print_warning "Please edit .env file with your configuration before running the script again."
        exit 1
    fi
    
    # Source the environment file
    source .env
    
    # Validate required variables
    local required_vars=("domain" "db" "user" "pass" "contact" "repo" "branch" "container_index")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        print_warning "Please check your .env file and ensure all required variables are set."
        exit 1
    fi
}

# Function to create .env template
create_env_template() {
    cat > .env << 'EOF'
# CLS Deployment Configuration
# Please update these values according to your setup

# Domain configuration
domain=your-domain.com
contact=admin@your-domain.com
container_index=1

# Database configuration
db=cls_database
user=cls_user
pass=your_secure_password
db_host=localhost

# Git repository configuration
repo=https://github.com/your-org/your-repo.git
branch=main

# Traccar configuration (optional)
traccar_installer=https://github.com/traccar/traccar/releases/download/v5.8/traccar-linux-5.8.zip
EOF
    chmod 600 .env
}

# Function to setup SSH keys
setup_ssh_keys() {
    print_step "Setting up SSH keys..."
    
    if ! confirm_action "Setup SSH keys?"; then
        print_status "Skipping SSH setup..."
        return 0
    fi
    
    # Add GitHub to known hosts
    #print_status "Adding GitHub to known hosts..."
    #ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true
    
    # Ensure ~/.ssh directory exists with correct permissions
    #mkdir -p ~/.ssh
    #chmod 700 ~/.ssh
    
    # Detect existing SSH key
    #local ssh_key
    #generate_ssh_key
    ./generate-ssh.sh
    print_warning "Please add the SSH key to your repository before cloning project."
    echo "${repo}/settings/keys" | sed 's#git@github\.com:#https://github.com/#' | sed 's/\.git$//'
    # Set correct permissions for the private key
    #chmod 600 "${ssh_key%.pub}" 2>/dev/null || true
    
    print_status "SSH setup completed!"
    #read -p "Press Enter to continue..."

}

# Function to clone Laravel project
clone_project() {
    print_step "Cloning Laravel project..."
    
    local project_dir="${SCRIPT_DIR}/cls"
    
    # Remove existing project directory if it exists
    if [ -d "$project_dir" ]; then
        print_status "Removing existing project directory..."
        rm -rf "$project_dir"
    fi
    
    print_status "Adding GitHub to known hosts..."
    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true
    
    print_status "Cloning repository..."
    git clone -b ${branch} ${repo} "$project_dir"
    
    # Set proper permissions
    chown -R $(whoami):$(whoami) "$project_dir"
    chmod -R 755 "$project_dir"
    
    print_status "Project cloned successfully!"
}

# Function to create Docker environment file
create_docker_env() {
    print_step "Step 3: Creating Docker environment file..."
    
    local project_dir="${SCRIPT_DIR}/cls"
    
    if [ ! -d "$project_dir" ]; then
        print_error "Project directory not found. Please clone the project first."
        return 1
    fi
    
    cd "$project_dir"
    
    # Create .env file from Laravel template
    if [ -f ".env.example" ]; then
        print_status "Creating .env from Laravel template..."
        cp .env.example .env
    else
        print_error "Laravel .env.example not found!"
        return 1
    fi
    
    # Update .env with deployment configuration
    print_status "Updating environment configuration..."

    # Replace CONTAINER_INDEX in .env
    sed -i.bak "s/^CONTAINER_INDEX=.*/CONTAINER_INDEX=${container_index}/g" .env && rm .env.bak

    # Update APP_URL
    sed -i.bak "s/CLS_DOMAIN=.*/CLS_DOMAIN=${domain}/g" .env && rm .env.bak
    sed -i.bak "s/LE_EMAIL=.*/LE_EMAIL=${contact}/g" .env && rm .env.bak

    # Update database configuration
    sed -i.bak "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/g" .env && rm .env.bak

    # Set database host based on container_index
    if [ "$container_index" -eq 1 ]; then
        sed -i.bak "s/DB_HOST=.*/DB_HOST=mysql-db/g" .env && rm .env.bak
    else
        sed -i.bak "s/DB_HOST=.*/DB_HOST=mysql-db${container_index}/g" .env && rm .env.bak
    fi

    sed -i.bak "s/DB_PORT=.*/DB_PORT=3306/g" .env && rm .env.bak
    sed -i.bak "s/DB_DATABASE=.*/DB_DATABASE=${db}/g" .env && rm .env.bak
    sed -i.bak "s/DB_USERNAME=.*/DB_USERNAME=${user}/g" .env && rm .env.bak
    sed -i.bak "s/DB_PASSWORD=.*/DB_PASSWORD=${pass}/g" .env && rm .env.bak

    # Update mail configuration
    sed -i.bak "s/MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS=${contact}/g" .env && rm .env.bak
    sed -i.bak "s/MAIL_FROM_NAME=.*/MAIL_FROM_NAME=\"CLS System\"/g" .env && rm .env.bak

    # Configure cache based on container_index
    if [ "$container_index" -eq 1 ]; then
        # For container_index=1, use Redis
        sed -i.bak "s/CACHE_DRIVER=.*/CACHE_DRIVER=redis/g" .env && rm .env.bak
        sed -i.bak "s/SESSION_DRIVER=.*/SESSION_DRIVER=redis/g" .env && rm .env.bak
        sed -i.bak "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/g" .env && rm .env.bak

        # Update Redis configuration
        sed -i.bak "s/REDIS_HOST=.*/REDIS_HOST=127.0.0.1/g" .env && rm .env.bak
        sed -i.bak "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=/g" .env && rm .env.bak
        sed -i.bak "s/REDIS_PORT=.*/REDIS_PORT=6379/g" .env && rm .env.bak
    else
        # For container_index>1, use file-based cache (no Redis)
        sed -i.bak "s/CACHE_DRIVER=.*/CACHE_DRIVER=file/g" .env && rm .env.bak
        sed -i.bak "s/SESSION_DRIVER=.*/SESSION_DRIVER=file/g" .env && rm .env.bak
        sed -i.bak "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/g" .env && rm .env.bak
    fi

    # Generate docker-compose-ctr-N.yml in composes/ if container_index > 1
    if [ "$container_index" -gt 1 ]; then
        local compose_dir="${SCRIPT_DIR}/cls/composes"
        mkdir -p "$compose_dir"
        local compose_target="$compose_dir/docker-compose-ctr-${container_index}.yml"
        # Remove any old generated file in cls/ root (cleanup)
        if [ -f "${SCRIPT_DIR}/cls/docker-compose-ctr-${container_index}.yml" ]; then
            rm -f "${SCRIPT_DIR}/cls/docker-compose-ctr-${container_index}.yml"
        fi
        if [ -f "${SCRIPT_DIR}/cls/docker-compose-ctr.yml" ]; then
            sed "s/CONTAINER_INDEX/${container_index}/g" "${SCRIPT_DIR}/cls/docker-compose-ctr.yml" > "$compose_target"
            print_status "Created $compose_target with CONTAINER_INDEX=${container_index}"
        else
            print_error "docker-compose-ctr.yml template not found!"
        fi
    fi
    
    print_status "Docker environment configuration completed!"
}

# Function to get docker compose command
get_docker_compose_cmd() {
    #if command_exists docker-compose; then
    #    echo "docker-compose"
   # else
        echo "docker compose"
    #fi
}

# Function to deploy docker services
deploy_docker_services() {
    local project_dir="${SCRIPT_DIR}/cls"
    cd "$project_dir"
    
    local compose_cmd=$(get_docker_compose_cmd)
    
    if [ "$container_index" -eq 1 ]; then
        print_step "Step 4: Starting main CLS Docker services..."
        print_status "Running docker-compose up -d..."
        
        if $compose_cmd up -d; then
            print_status "Main Docker services started successfully!"
            print_status "Application should be available at: http://localhost:8080"
        else
            print_error "Failed to start main Docker services!"
            return 1
        fi
        
        print_step "Step 5: Starting Nginx Proxy Manager..."
        print_status "Running docker-compose -f docker-compose.nginx.yml up -d..."
        
        if $compose_cmd -f docker-compose.nginx.yml up -d; then
            print_status "Nginx Proxy Manager started successfully!"
            print_status "Proxy Manager Web UI available at: http://localhost:81"
            print_status "Default login: admin@example.com / changeme"
        else
            print_error "Failed to start Nginx Proxy Manager!"
            return 1
        fi
    else
        print_step "Step 4/5: Starting CLS Docker services for container instance ${container_index}..."
        local compose_file="${SCRIPT_DIR}/cls/composes/docker-compose-ctr-${container_index}.yml"
        local env_file="${SCRIPT_DIR}/cls/.env"
        if [ -f "$compose_file" ]; then
            print_status "Running docker-compose --env-file $env_file -f $compose_file up -d..."
            if $compose_cmd --env-file "$env_file" --project-directory "$SCRIPT_DIR/cls" -f "$compose_file" up -d; then
                print_status "Docker services for container ${container_index} started successfully!"
                print_status "Application should be available at: http://localhost:808${container_index}"
            else
                print_error "Failed to start Docker services for container ${container_index}!"
                return 1
            fi
        else
            print_error "$compose_file not found! Did you run step 3?"
            return 1
        fi
    fi
    
    # Wait a moment for services to fully start
    sleep 5
    
    # Show service status
    #print_status "Current running services:"
    #$compose_cmd ps
}

# Function to show menu
show_menu() {
    echo ""
    echo "=========================================="
    echo "  CLS Docker Deployment Management"
    echo "=========================================="
    echo ""
    echo "Current Configuration:"
    echo "  Domain: ${domain:-'Not set'}"
    echo "  Database: ${db:-'Not set'}"
    echo "  Repository: ${repo:-'Not set'}"
    echo "  Branch: ${branch:-'Not set'}"
    echo "  Container Index: ${container_index:-'Not set'}"
    echo ""
    echo "Available options:"
    echo "  1) Setup SSH keys"
    echo "  2) Clone Laravel project"
    echo "  3) Create Docker environment"
    echo "  4) Deploy Docker services"
    echo "  5) Setup backup cron job"
    echo "  q) Quit"
    echo ""
}

# Function to setup backup cron job for Docker
step_setup_backup_cron_docker() {
    print_step "Setting up backup cron job..."

    if ! confirm_action "Setup backup cron job?"; then
        print_warning "Skipping backup cron job setup."
        return 0
    fi

    local cron_script_path="${SCRIPT_DIR}/data/db_backup_docker.sh"
    if [ ! -f "$cron_script_path" ]; then
        print_error "Backup script not found at $cron_script_path"
        return 1
    fi

    # Ensure script is executable
    chmod +x "$cron_script_path"

    # Cron job command
    local cron_command="0 2 * * * $cron_script_path"
    local cron_comment="# CLS Docker Backup Job for ${domain}"

    # Add cron job if it doesn't exist
    if ! (crontab -l 2>/dev/null | grep -qF "$cron_comment"); then
        print_status "Adding cron job for database and file backup..."
        (crontab -l 2>/dev/null; echo "$cron_comment"; echo "$cron_command") | crontab -
        print_status "Cron job added successfully."
    else
        print_status "Cron job already exists."
    fi
}

# --- Place this at the very end of the script ---
# Interactive main menu
main() {
    # Check if .env file exists and is valid
    check_env_file

    while true; do
        show_menu
        read -p "Select an option: " choice

        case $choice in
            1) setup_ssh_keys ;;
            2) clone_project ;;
            3) create_docker_env ;;
            4) deploy_docker_services ;;
            5) step_setup_backup_cron_docker ;;
            q|Q)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac

        if [ "$choice" != "q" ] && [ "$choice" != "Q" ]; then
            read -p "Press Enter to continue..."
        fi
    done
}

# Run main function
main "$@"
