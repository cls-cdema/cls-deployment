# CLS Phase 1: Fresh Installation (Updated)

## Updates and Improvements

This updated version of CLS deployment scripts has been optimized to work with:

- ✅ **Ubuntu 22.04 LTS** (root and sudo users)
- ✅ **Ubuntu 24.04 LTS** (root and sudo users)  
- ✅ **Ubuntu 20.04 LTS** (backward compatibility)
- ✅ **Modern SSH key formats** (Ed25519, ECDSA, RSA)
- ✅ **Robust environment variable handling**
- ✅ **Improved error handling and validation**

### Key Fixes

1. **SSH Key Generation**: Now supports both legacy (`id_rsa`) and modern (`id_ed25519`) SSH key formats
2. **User Context**: Properly handles both root and sudo user installations
3. **Environment Variables**: Fixed text replacement issues with special characters in passwords
4. **System Compatibility**: Added Ubuntu version detection and appropriate package handling
5. **Error Handling**: Comprehensive validation and rollback mechanisms

## Prerequisites

- Linux server with Ubuntu 20.04 LTS, 22.04 LTS, or 24.04 LTS
- Root access or sudo privileges
- External firewall configured to allow SSH (port 22) and HTTP/HTTPS (ports 80, 443)
- Minimum 5GB free disk space
- Internet connectivity

## Quick Test

Before installation, run the test suite to validate your system:

```bash
chmod +x test_setup.sh
./test_setup.sh
```

## Installation Steps

### 1. Clone and Setup

```bash
cd ~
git clone https://github.com/cls-cdema/cls-deployment
cd cls-deployment
cp .env.example .env
chmod +x *.sh
```

### 2. Configure Environment

Edit the deployment `.env` file with your settings:

```bash
nano .env
```

Required configuration:
```
repo=git@github.com:cls-cdema/cls-laravel.git
branch=develop
domain=your-domain.com
contact=admin@your-domain.com
db=your_database_name
db_host=127.0.0.1
user=your_db_user
pass=your_secure_password
```

### 3. System Setup

Run the server setup script:

```bash
./1.setup_server.sh
```

This script will:
- Perform system compatibility checks
- Install Apache, PHP, MySQL, and required extensions
- Generate or detect SSH keys (supports Ed25519, ECDSA, and RSA)
- Configure PHP settings
- Set up firewall rules
- Display SSH public key for GitHub deployment

### 4. Configure SSH Deploy Key

Copy the displayed SSH public key and add it as a deploy key in your GitHub repository:

1. Go to your repository settings
2. Navigate to "Deploy keys"
3. Click "Add deploy key"
4. Paste the public key and save

To test SSH connectivity:
```bash
source ./utils/ssh_utils.sh && test_github_ssh
```

### 5. Project Configuration

Configure the project:

```bash
./2.configure_project.sh
```

This will:
- Clone the CLS project repository
- Set up directory structure and permissions
- Configure Laravel environment variables
- Run database migrations
- Generate authentication keys

### 6. SSL Certificate

Set up SSL certificate (ensure DNS is configured first):

```bash
./3.configure_ssl.sh
```

### 7. Automated Backups and Maintenance

Set up cron jobs:

```bash
./4.setup_cron_job_backup_maintanance.sh
```

### Complete Installation (One Command)

For automated installation with all steps:

```bash
./1.setup_server.sh complete
```

**Requirements for complete mode:**
- `.env` file configured
- SSH deploy key already set up in GitHub
- Domain DNS pointing to server IP

## Updating Existing Installations

### System Updates

```bash
./1.setup_server.sh update
```

### Project Updates

```bash
./2.configure_project.sh update
```

### Reset Project (Clean Reinstall)

```bash
./2.configure_project.sh reset
```

## Utility Functions

The updated scripts include modular utility functions:

### SSH Utilities (`utils/ssh_utils.sh`)
- Modern SSH key detection and generation
- Cross-platform compatibility (root/sudo)
- GitHub connectivity testing

### Environment Utilities (`utils/env_utils.sh`)
- Safe text replacement with special character handling
- Backup and restore functionality
- Validation checks

### System Utilities (`utils/system_utils.sh`)
- Ubuntu version detection
- Package management abstraction
- System requirements checking

## Troubleshooting

### SSH Key Issues

If SSH key generation or detection fails:

```bash
# Check SSH configuration
source utils/ssh_utils.sh
get_ssh_info

# Manual key generation
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
```

### Environment Variable Issues

If text replacement fails:

```bash
# Test environment functions
source utils/env_utils.sh
validate_env_vars domain db user pass
```

### System Compatibility Issues

Check system requirements:

```bash
source utils/system_utils.sh
check_system_requirements
show_system_info
```

### Permission Issues

For permission-related errors:

```bash
# Check current user type
source utils/system_utils.sh
echo "User type: $(get_user_type)"

# Fix common permission issues
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
```

## Testing

Run comprehensive tests:

```bash
./test_setup.sh
```

This validates:
- Utility function availability
- SSH key detection logic
- Environment variable handling
- System compatibility
- Script syntax
- Configuration files

## Version Compatibility Matrix

| Ubuntu Version | PHP Version | MySQL Version | SSH Key Type | Status |
|----------------|-------------|---------------|--------------|---------|
| 20.04 LTS      | 7.4         | 8.0           | RSA/Ed25519  | ✅ Supported |
| 22.04 LTS      | 8.1         | 8.0           | Ed25519      | ✅ Supported |
| 24.04 LTS      | 8.3         | 8.0           | Ed25519      | ✅ Supported |

## Security Improvements

1. **SSH Key Security**: Prefers Ed25519 over RSA for better security
2. **Password Handling**: Secure handling of passwords with special characters
3. **File Permissions**: Proper permission management for web directories
4. **Firewall Configuration**: Automated UFW setup with minimal required ports

## Performance Optimizations

1. **Non-interactive Installation**: Prevents hanging during package installation
2. **Parallel Operations**: Improved script execution time
3. **Error Recovery**: Automatic rollback on configuration failures
4. **Resource Management**: Optimized PHP memory and execution settings

## Additional Features

### Traccar Server Setup (Optional)

```bash
# Configure traccar settings in .env
./6.setup_traccar_server.sh
```

### Server Update Automation

```bash
./5.setup_cron_job_server_update.sh
```

## Support and Maintenance

- **Backup Location**: `/path/to/cls-deployment/data/backups/`
- **Log Files**: Check Apache logs in `/var/log/apache2/`
- **Cron Jobs**: Managed automatically, check with `crontab -l`

For issues or questions, refer to the test output and utility functions for debugging information.

## Migration from Previous Version

If upgrading from the original deployment scripts:

1. Backup your current `.env` file
2. Pull the updated repository
3. Run the test suite to validate compatibility
4. Update your deployment using the new scripts

The updated scripts are backward compatible and will not break existing installations.