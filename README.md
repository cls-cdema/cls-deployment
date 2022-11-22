# CLS Phase 1: Fresh Installation

  **Prerequisite** 
  

 - To install CLS, Linux server must be setup with distro Ubuntu 20.04 LTS or 22.04 LTS.
 - External firewall must be configure to allow access SSH port 22 and Web server port 80 and 443.



1. Clone repository and set permissions for setup script. each setup script can be checked against a text editor before setting permissions.

> cd ~ 

> git clone [https://github.com/cls-cdema/cls-deployment](mailto:https://github.com/cls-cdema/cls-deployment)

> cd cls-deployment

> cp .env.example .env

> sudo chmod +x *.sh

  

2. Update deployment .env file. Deployment .env file contains the configuration for the primary domain and contact email of deployment server and database password for database user account to be generated. following are default .env contents.

  

> repo=https://github.com/cls-cdema/cls-deployment.git

> branch=master

> domain=cls-cdema.org

> contact=[USEREMAIL@MAILPROVIDER.TLD]

> db=cls_cdema_org

> db_host=127.0.0.1

> user=cls

> pass=somedbpassword


3. Run shell script file **1\.setup_server.sh** file. There may be several user confirmations during setup process. If system asks to restart services for outdated kernel/ services, 'select all' must be selected.

  

>  ./1.setup_server.sh

  

This shell script will initiate the following:

- Installing Apache Web server

- Installing PHP and required extensions

- Installing Mysql database server

- Installing Composer

- Installing Apache Certbot

- Creating database and database user. Database name and database password must be the same as defined in deployment .env file.

- Generating SSH key if not already exists.

  

4. Configure the deployment key - Copy the public key from the open terminal window and setup deployment key in cls main repository.

  

5. Run the shell script file **2\.configure_project.sh** to configure the following:

- Cloning CLS project repository from github.

- Setting up a new project with the provided domain name in deployment .env file.

- Setting up the default directories.

- Setting correct directory permission.

- Updating composer libraries.

- Initial migration of database.

- Initial data seeding.

- Generating passport authentication keys.

  

>  ./2.configure_project.sh

  

5. generate an SSL certificate by runing the following shell script which will setup an SSL certificate from Lets Encrypt (https://letsencrypt.org) using the domain name from .env file. Before running this step, deployment server's IP address must be pointed as A or AA record from domain control panel.

  

>  ./3._configure_ssl.sh

  

# CLS Phase 1: Updating Servers

  

1. Run shell script file **1\.setup_server.sh** file with "update" argument. There may be several user confirmations during setup process. If system asks to restart services for outdated kernel/ services, all need to be selected.

  

>  ./1.setup_server.sh update

  

This shell script will setup the following:

- Updating Apahe Web server.

- Updating PHP and required extensions.

- Updating Mysql database server.

  

2. Run the shell script file **2\.configure_project.sh** with "update" argument. to configure following settings.

- Pulling last commit of project from github repo.

- Updating composer libraries.

- Migrating of database changes.

  

>  ./2.configure_project.sh update

  

# CLS Phase 1: Resetting project only

  

1. Run the shell script file **2\.configure_project.sh** with "reset" argument. to configure following settings.

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

  

>  ./2.configure_project.sh reset

 

# CLS Phase 1: Cron Jobs for database backup and maintanance
 
1. Run 4.setup_cron_job_backup_maintanance.sh file to register cron job to run database backup script  every 6 Hours daily and to run maintanance script weekly.


# CLS Phase 1: Cron Jobs for server update
 
1. Run 5.setup_cron_job_server_update.sh file to register cron job to run maintanance script yearly.

# CLS Phase 1: Complete All in One install 
1. Run shell script file **1\.setup_server.sh** file with "complete" argument. There may be several user confirmations during setup process. If system asks to restart services for outdated kernel/ services, all need to be selected.
2. This will install 4 step sequencially
 
		1.setup_server.sh
		2.configure_project.sh
		3._configure_ssl.sh
		4.setup_cron_job_backup_maintanance.sh
		
	
4. It is very import to be ready to  have following main points to run in complete mode
	1. .env is ready
	2.  SSH key is arelay imported as deployed key
	3. domain is correctly configured to point to server ip.
  

>  ./1.setup_server.sh complete

  
