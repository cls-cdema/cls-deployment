# CLS Phase 1 Server setup instruction (Fresh Installation)

 1. Clone repository and set permission for setup script. each setup script can be checked against a texteditor before setting permissions.
 
> cd ~ git clone  [https://github.com/cls-cdema/cls-deployment](mailto:https://github.com/cls-cdema/cls-deployment)
> cd cls-deployment 
> sudo chmod +x *.sh

2. Update deployment .env file. Deployment .env file contains configuration for primary domain and contact email of deployment server and database password for database user account to be generated. following are default .env contents.

> repo=https://github.com/cls-cdema/cls-deployment.git
> branch=master
> domain=cls-cdema.org
> contact=e2ecdema@gmail.com
> db=cls_cdema_org
> user=cls
> pass=somedbpassword

3. Run shell script file **1\.setup_server.sh** file. There may be several user confirmations during setup process. If system asked to restart services for outdated kernel/ services, it needs to select all.

> sudo ./1.setup_server.sh

This shell script will setup followings:
 - Installing Apahe Web server 
 - Installing PHP and required extensions  
 - Installing Mysql database server 
 - Installing Composer Installing   
  - Apache Certbot 
  - Creating database and database user. Database name and database password must be the same as defined in deployment .env file.
  - Generating SSH key if not already exists.

 4. Configure the deployment key - Copy the public key from terminal and setup deployment key in cls main repository.

 5. Run the shell script file   **2\.configure_project.sh** to configure following settings.
 - Cloning CLS project repository from github 
 - Setting up the project with the provided domain name in deployment .env file. 
 - Setting up the default directories
 - Setting correct directory permission.
 - Updating composer libraries
 - Initial migration of database
 - Initial data seeding
 - Generating passport authentication keys

> sudo ./2.configure_project.sh

5. Configure SSL certificate by runing following shell script which will setup SSL certificate from Lets Encrypt with domain name from .env file. Before running this step, deployment server's IP address must be pointed as A or AA record from domain control panel.

>  sudo ./3._configure_ssl.sh

# CLS Phase 1 Server update instruction

1. Run shell script file **1\.setup_server.sh** file with "update" argument. There may be several user confirmations during setup process. If system asked to restart services for outdated kernel/ services, it needs to select all.

> sudo ./1.setup_server.sh update

This shell script will setup followings:
 - Updating Apahe Web server 
 - Updating PHP and required extensions  
 - Updating Mysql database server 

 2. Run the shell script file **2\.configure_project.sh**  with "update" argument. to configure following settings.
 - Pulling last commit of project from github repo
 - Updating composer libraries
 - Migrating of database changes

> sudo ./2.configure_project.sh update

# CLS Phase 1 Server Resetting project only

 2. Run the shell script file **2\.configure_project.sh**  with "reset" argument. to configure following settings.
 - Removing existing project files.
 - Cloning CLS project repository from github.
 - Setting up the project with the provided domain name in deployment .env file. 
 - Setting up the default directories
 - Setting correct directory permission.
 - Updating composer libraries
 - Initial migration of database
 - Initial data seeding
 - Generating passport authentication keys

> sudo ./2.configure_project.sh reset