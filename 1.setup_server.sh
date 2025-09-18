#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}
source ${SCRIPT_DIR}/.env
source ${SCRIPT_DIR}/utils/ssh_utils.sh
source ${SCRIPT_DIR}/utils/env_utils.sh
source ${SCRIPT_DIR}/utils/system_utils.sh

# Perform system checks
echo "Performing system compatibility checks..."
if ! check_system_requirements; then
    echo "System requirements not met. Exiting."
    exit 1
fi

show_system_info

echo "Welcome to CLS Phase 1 Installer 1.0.0."
echo "This will install server and setup CLS Phase 1 Project based on following environment settings from ./env file."
echo ""
echo "Domain = ${domain}"
echo "Database = ${db}"
echo "Database User = ${user}"
echo "Admin Email = ${contact}"
echo "CLS Project Repository = ${repo}"
echo "Repository Branch = ${branch}"
echo ""
if [ "$1" = "update" ]
 then
 echo "Update mode.."
 else
read -p "Do you want to proceed? (yes/no) " yn
case $yn in
	yes ) echo env confirmed;;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
esac
fi

echo "Updating system.."
upgrade_system

echo "Installing Apache Web Server.."
install_packages git apache2
echo "Configuring firewall for web server..."
setup_firewall "Apache Full"

echo "Installing MySQL Database Server..."
install_packages mysql-server
#sudo apt install php libapache2-mod-php php7.4-mysql php7.4-common php7.4-mysql php-xml php7.4-xmlrpc php7.4-curl php-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl php-xml -y

echo "Installing PHP and Extensions..."
install_packages php libapache2-mod-php php-mysql php-common php-xml php-xmlrpc php-curl php-gd php-imagick php-cli php-dev php-imap php-mbstring php-opcache php-soap php-zip php-intl
if [ "$1" = "update" ]
 then
 echo "Configuration setting skipped for update mode"
 else
ssh-keyscan github.com >>~/.ssh/known_hosts

sudo a2dissite 000-default
echo "Enabling Apache Modules..."
if is_root_user; then
    a2enmod ssl proxy_http proxy_wstunnel rewrite
else
    sudo a2enmod ssl proxy_http proxy_wstunnel rewrite
fi

echo "Installing curl and Composer V2..."
install_packages curl python3-certbot-apache

# Install Composer
echo "Installing Composer..."
if command -v composer >/dev/null 2>&1; then
    echo "Composer already installed"
else
    curl -s https://getcomposer.org/installer | php
    if is_root_user; then
        mv composer.phar /usr/bin/composer
    else
        sudo mv composer.phar /usr/bin/composer
    fi
    chmod +x /usr/bin/composer
fi

echo "Setting up SSH configuration..."
SSHKEY=$(ensure_ssh_key "cls-deployment@$(hostname)")
setup_github_known_hosts

echo "SSH key setup completed successfully!"
get_ssh_info
#if [ -f "$SSHKEY" ]; then
#   echo "Please contact admin to enable following ssh deployment key at repository ${repo}."
#   echo "After setting up deployment key, you can proceed to next setp 2.configure_project."
#   cat $SSHKEY
#else
#  echo ""
#fi
echo ""
#echo 'Please proceed to next step to configure the project'
fi

echo 'Setting Default PHP INI settings..'
INI_LOC=$(php -i 2>/dev/null | sed -n '/^Loaded Configuration File => /{s:^.*> ::;p;q}')

if [ -n "$INI_LOC" ] && [ -f "$INI_LOC" ]; then
    echo "Found PHP INI at: $INI_LOC"

    # Backup original
    if is_root_user; then
        cp "$INI_LOC" "${INI_LOC}.backup"
    else
        sudo cp "$INI_LOC" "${INI_LOC}.backup"
    fi

    # Set PHP configuration values
    declare -A php_settings=(
        ["upload_max_filesize"]="400M"
        ["post_max_size"]="200M"
        ["max_execution_time"]="3000"
        ["max_input_time"]="5000"
        ["memory_limit"]="512M"
    )

    for key in "${!php_settings[@]}"; do
        value="${php_settings[$key]}"
        echo "Setting $key = $value"

        if is_root_user; then
            sed -i "s/^\($key\s*=\).*/\1 $value/" "$INI_LOC"
        else
            sudo sed -i "s/^\($key\s*=\).*/\1 $value/" "$INI_LOC"
        fi
    done

    echo "✓ PHP configuration updated"
else
    echo "Warning: Could not find PHP INI file"
fi

echo ""
echo "========================================================"
echo "IMPORTANT: SSH Deployment Key Setup Required"
echo "========================================================"
echo "Please contact your administrator to add the following SSH key"
echo "as a deployment key in the repository: ${repo}"
echo ""
display_ssh_public_key
echo ""
echo "After the deployment key is configured, you can proceed to:"
echo "  ./2.configure_project.sh"
echo ""
echo "To test SSH access to GitHub, run:"
echo "  source ./utils/ssh_utils.sh && test_github_ssh"
echo "========================================================"

if [ "$1" = "complete" ]
 then
 echo "Complete Mode.."
 ${SCRIPT_DIR}/2.configure_project.sh
 ${SCRIPT_DIR}/3.configure_ssl.sh y
 ${SCRIPT_DIR}/4.setup_cron_job_backup_maintanance.sh y
fi
