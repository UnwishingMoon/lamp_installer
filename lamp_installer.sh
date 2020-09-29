#!/bin/bash
#########################################################
#                                                       #
#   Name: Lamp Installer                                #
#   Author: Diego Castagna (diegocastagna.com)          #
#   Description: This script will install               #
#   and configure LAMP and Certbot                      #
#   on Linux ready for Production                       #
#   License: diegocastagna.com/license                  #
#                                                       #
#########################################################

# Constants
WEBSITE="diegocastagna.com"
SCRIPTNAME="LAMP_INSTALLER"
PREFIX="[$WEBSITE][$SCRIPTNAME]"

# Variables
dbRootPass="${1}"
dbPMAPass="${2}"

# Performing some checks
if [[ $EUID -ne 0 ]]; then
    echo "$PREFIX This script must be run as root or with sudo privileges"
    exit 1
fi
if [ $# -le 1 ]; then
    echo "Usage: ${0} DBRootPassword PHPMyAdminUserPassword"
    exit 1
fi

echo "$PREFIX Starting the script.."
echo "$PREFIX Updating the system package.."
apt update -yq

echo "$PREFIX Upgrading system packages.."
apt upgrade -yq

echo "$PREFIX Filling Debconf selections.."
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $dbRootPass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $dbPMAPass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $dbPMAPass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

echo "$PREFIX Installing Apache, Mysql, PHP, PHPMyadmin"
apt install -yq apache2 mysql-server php libapache2-mod-php php-mysql php-cli php-mbstring phpmyadmin

echo "$PREFIX Setting up Apache.."
a2enmod rewrite headers ssl expires
a2dismod status
a2disconf charset javascript-common other-vhosts-access-log serve-cgi-bin localized-error-pages
rm /etc/apache2/sites-available/*
rm /etc/apache2/sites-enabled/*
echo '<VirtualHost *:80>
    #ServerName host
    #ServerAlias host
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/>
        Options -Indexes +SymLinksIfOwnerMatch -Includes
        AllowOverride All
    </Directory>
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf
echo "$PREFIX Enabling PHP modules.."
phpenmod mbstring

echo "$PREFIX Securing Mysql installation.."
mysql --user=root <<_EOF_
ALTER USER 'root'@'localhost' IDENTIFIED BY '${dbRootPass}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

echo "$PREFIX Restarting Apache and Mysql.."
service apache2 restart
service mysql restart

echo "$PREFIX Removing unused packages.."
apt autoremove -yq

echo "$PREFIX Script finished!"
echo "$PREFIX Thank you for downloading this script from $WEBSITE"