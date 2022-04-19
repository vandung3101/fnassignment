#!/bin/bash
wget https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz
tar xvzf ansible-tower-setup-latest.tar.gz
cd ansible-tower-setup-3.8.5-3
cat << EOF > inventory
[tower]
localhost ansible_connection=local

[automationhub]

[database]

[all:vars]
admin_password='Password'

pg_host=''
pg_port=''

pg_database='awx'
pg_username='awx'
pg_password='Azure@123'
pg_sslmode='prefer'  # set to 'verify-full' for client-side enforced SSL

# Automation Hub Configuration
#

automationhub_admin_password=''

automationhub_pg_host=''
automationhub_pg_port=''

automationhub_pg_database='automationhub'
automationhub_pg_username='automationhub'
automationhub_pg_password=''
automationhub_pg_sslmode='prefer'

# By default if the automation hub core and plugin packages
# are installed (i.e. pulp), they won't get upgraded when running the installer
# even if newer packages are available. One needs to run the ./setup.sh
# script with the following set to True.
#
# automationhub_upgrade = False

# By default, the Ansible package will not be upgraded
# to the latest version, even if one exists in the bundled
# installer or another repository. Set upgrade_ansible_with_hub
# to True if you want Ansible to be upgraded
#
# upgrade_ansible_with_hub = False

# By default when one uploads collections to Automation Hub
# an admin needs to approve it before it is made available
# to the users. If one wants to disble the content approval
# flow, the following setting should be set to False.
#
# automationhub_require_content_approval = True

# At import time collections can go through a series of checks.
# Behaviour is driven by galaxy-importer.cfg configuration.
# Example are ansible-doc, ansible-lint, flake8, ...
#
# The following parameter allow one to drive this configuration.
# This variable is expected to be a dictionnary.
#
# automationhub_importer_settings = None

# The default install will deploy a TLS enabled Automation Hub.
# If for some reason this is not the behavior wanted one can
# disable TLS enabled deployment.
#
# automationhub_disable_https = False

# The default install will deploy a TLS enabled Automation Hub.
# Unless specified otherwise the HSTS web-security policy mechanism
# will be enabled. This setting allows one to disable it if need be.
#
# automationhub_disable_hsts = False

# The default install will generate self-signed certificates for the Automation
# Hub service. If you are providing valid certificate via automationhub_ssl_cert
# and automationhub_ssl_key, one should toggle that value to True.
#
# automationhub_ssl_validate_certs = False

# Isolated Tower nodes automatically generate an RSA key for authentication;
# To disable this behavior, set this value to false
# isolated_key_generation=true


# SSL-related variables

# If set, this will install a custom CA certificate to the system trust store.
# custom_ca_cert=/path/to/ca.crt

# Certificate and key to install in nginx for the web UI and API
# web_server_ssl_cert=/path/to/tower.cert
# web_server_ssl_key=/path/to/tower.key

# Certificate and key to install in Automation Hub node
# automationhub_ssl_cert=/path/to/automationhub.cert
# automationhub_ssl_key=/path/to/automationhub.key

# Server-side SSL settings for PostgreSQL (when we are installing it).
# postgres_use_ssl=False
# postgres_ssl_cert=/path/to/pgsql.crt
# postgres_ssl_key=/path/to/pgsql.key
EOF
sudo chmod +x setup.sh
sudo ./setup.sh -e nginx_disable_https=true
sudo echo "SESSION_COOKIE_SECURE = False" >> /etc/tower/settings.py
sudo echo "CSRF_COOKIE_SECURE = False" >> /etc/tower/settings.py
sudo sed -i 's/rewrite/# rewrite/' /etc/nginx/nginx.conf
sudo systemctl reload nginx
sudo ansible-tower-service restart