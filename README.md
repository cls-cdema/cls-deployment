# CLS Phase 1: Fresh Installation

 1. Clone repository and set permissions for setup script. each setup script can be checked against a text editor before setting permissions.
 
> cd ~ git clone  [https://github.com/cls-cdema/cls-deployment](mailto:https://github.com/cls-cdema/cls-deployment)
> cd cls-deployment 
> cp .env.example .env
> sudo chmod +x *.sh

2. Update deployment .env file. Deployment .env file contains the configuration for the primary domain and contact email of deployment server and database password for database user account to be generated. following are default .env contents.

> repo=https://github.com/cls-cdema/cls-deployment.git
> branch=master
> domain=cls-cdema.org
> contact=e2ecdema@gmail.com
> db=cls_cdema_org
> user=cls
> pass=somedbpassword

3. Run shell script file **1\.setup_server.sh** file. There may be several user confirmations during setup process. If system asks to restart services for outdated kernel/ services, 'select all' must be selected.

> sudo ./1.setup_server.sh

This shell script will initiate the following:
 - Installing Apache Web server 
 - Installing PHP and required extensions  
 - Installing Mysql database server 
 - Installing Composer Installing   
  - Apache Certbot 
  - Creating database and database user. Database name and database password must be the same as defined in deployment .env file.
  - Generating SSH key if not already exists.

 4. Configure the deployment key - Copy the public key from the open terminal window and setup deployment key in cls main repository.

 5. Run the shell script file   **2\.configure_project.sh** to configure the  following:
 - Cloning CLS project repository from github. 
 - Setting up a new project with the provided domain name in deployment .env file. 
 - Setting up the default directories.
 - Setting correct directory permission.
 - Updating composer libraries.
 - Initial migration of database.
 - Initial data seeding.
 - Generating passport authentication keys.

> sudo ./2.configure_project.sh

5. generate an SSL certificate by runing the following shell script which will setup an SSL certificate from Lets Encrypt (https://letsencrypt.org) using the domain name from .env file. Before running this step, deployment server's IP address must be pointed as A or AA record from domain control panel.

>  sudo ./3._configure_ssl.sh

# CLS Phase 1: Updating Servers

1. Run shell script file **1\.setup_server.sh** file with "update" argument. There may be several user confirmations during setup process. If system asks to restart services for outdated kernel/ services, all need to be selected.

> sudo ./1.setup_server.sh update

This shell script will setup the following:
 - Updating Apahe Web server.
 - Updating PHP and required extensions.
 - Updating Mysql database server.

 2. Run the shell script file **2\.configure_project.sh**  with "update" argument. to configure following settings.
 - Pulling last commit of project from github repo.
 - Updating composer libraries.
 - Migrating of database changes.

> sudo ./2.configure_project.sh update

# CLS Phase 1: Resetting project only

 1. Run the shell script file **2\.configure_project.sh**  with "reset" argument. to configure following settings.
 - Removing existing project files.
 - Cloning CLS project repository from github.
 - Setting up the project with the provided domain name in deployment .env file. 
 - Setting up the default directories.
 - Setting correct directory permission.
 - Updating composer libraries.
 - Dropping existing database.
 - Initial migration of database.
 - Initial data seeding.
 - Generating passport authentication keys.

> sudo ./2.configure_project.sh reset


# CLS Phase 1: Cron Jbs for database backup and server update

1. Run 4.setup_cron_jobs.sh file to register cron jobs. Database backup script will run every 6 Hours daily and Server update script will run monthly.
