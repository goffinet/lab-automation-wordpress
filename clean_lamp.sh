#! /bin/bash
# clean_lamp.sh
systemctl stop httpd mariadb php-fpm
systemctl stop apache2 mysql
systemctl disable httpd mariadb php-fpm
systemctl disable apache2 mysql
dnf -y remove mariadb mariadb-server httpd php-fpm
yum -y remove httpd mariadb-server php php-common php-mysqlnd php-gd php-imap php-xml php-cli php-opcache php-mbstring php-json firewalld
apt-get -y --purge remove apache2 php libapache2-mod-php mariadb-server php-mysql php-curl php-gd php-intl php-json php-mbstring php-xml php-zip
apt-get -y --purge autoremove
apt-get autoclean
rm -rf /var/lib/mysql/
rm -rf /etc/mysql/
rm -f /etc/my.cnf
rm -f ~/.my.cnf
rm -rf /var/www/html
rm -rf /etc/httpd*
rm -rf /etc/apache2/*
rm -rf /etc/php*
firewall-cmd --zone=public --permanent --remove-service=http
firewall-cmd --zone=public --permanent --remove-service=https
firewall-cmd --reload
