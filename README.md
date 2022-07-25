# CLS Phase 1 Server setup instruction

 1. Clone repository
 
> cd ~ git clone
> [git@github.com:cls-cdema/cls-deployment.git](mailto:git@github.com:cls-cdema/cls-deployment.git)
> cd cls-deployment 
> sudo chmod +x *.sh

2. Update deployment .env file. Deployment .env file contains configuration for primary domain and contact email of deployment server and database password for database user account to be generated. following are default .env contents.

> repo=git@github.com:cls-cdema/cls-laravel.git
> domain=cls-cdema.org
> contact=e2ecdema@gmail.com
> pass=somedbpassword

3. Run shell script file **1\.setup_server.sh** file.

> ./1.setup_server.sh

This shell script will setup followings:

 - Installing Apahe Web server 
 - Installing PHP and required extensions  
 - Installing Mysql database server 
 - Installing Composer Installing   
  - Apache Certbot 
  - Cloning CLS project repository from github 
  - Setting up the project with the provided domain name in deployment .env file.
  - Creating database and database user. Database name and database password must be the same as defined in deployment .env file.
  - Generating SSH key if not already exists.

 4. Configure the deployment key
Copy the public key from terminal and setup deployment key in cls main repository.

 4. Configure the project
This shell script will configure following settings.
 - Setting up default directories
 - Setting correct directory permission.
 - update composer libraries
 - initial migration of database
 - generating passport authentication keys
 
> ./2.configure_project.sh

5. Configure SSL certificate
This shell script will setup SSL certificate from Lets Encrypt with domain name from .env file. Before running this step, deployment server's IP address must be pointed as A or AA record from domain control panel.

>  ./3._configure_ssl.sh