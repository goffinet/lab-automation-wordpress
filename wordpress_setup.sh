#!/bin/bash
# wordpress_setup.sh
ip_address=$(curl -s https://ipinfo.io/ip)
site_title="Demo Wordpress"
site_url="www.${ip_address}.nip.io"
application_path="/var/www/html"
admin_email="test@test.com"
admin_user="admin"
admin_password=$(openssl rand -base64 12)
dbuser="wpuser"
dbroot_password=$(openssl rand -base64 12)
dbuser_password=$(openssl rand -base64 12)

software_installation() {
if [ $(grep -q 'Fedora release 27' /etc/fedora-release; echo $?) == 0 ] ; then
dnf -y install httpd mariadb-server php php-common php-mysqlnd php-gd php-imap php-xml php-cli php-opcache php-mbstring php-json
sed -i 's/^listen.acl_users/;listen.acl_users/g' /etc/php-fpm.d/www.conf
elif [ -f /etc/centos-release ] ; then
curl -L https://rpms.remirepo.net/enterprise/remi-release-7.rpm -o remi-release-7.rpm
rpm -Uvh remi-release-7.rpm
yum-config-manager --enable remi-php72
yum -y install httpd mariadb-server php php-common php-mysqlnd php-gd php-imap php-xml php-cli php-opcache php-mbstring php-json firewalld
echo "PHP Version: $(php -v)"
elif [ -f /etc/lsb-release ] ; then
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
apt-get update
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical \
apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
apt -y install apache2 php libapache2-mod-php mariadb-server php-mysql php-curl php-gd php-intl php-json php-mbstring php-xml php-zip firewalld
else
break
fi
}

vhost_creation() {
port="80"
error_log="${log_path}/${site_url}-error_log"
access_log="${log_path}/${site_url}-access_log common"
#Résolution de nom locale
echo "127.0.0.1 ${site_url}" >> /etc/hosts
#Création du dossier et des pages Web
mkdir -p ${application_path}
#Création du dossier et des fichiers pour les logs
mkdir -p ${log_path}
touch ${error_log}
touch ${access_log}
#Configuration du vhost
cat << EOF > ${vhost_path}/${site_url}.conf
<VirtualHost *:${port}>
ServerAdmin webmaster@${site_url}
DocumentRoot ${application_path}
ServerName ${site_url}
ErrorLog ${error_log}
CustomLog ${access_log}
</VirtualHost>
EOF
}

vhosts_installation() {
if [ -f /etc/redhat-release ] ; then
log_path="/var/log/httpd"
vhost_path="/etc/httpd/conf.d"
vhost_creation
#Restauration de la policy Selinux sur le dossier créé
restorecon -Rv ${application_path}
elif [ -f /etc/lsb-release ] ; then
log_path="/var/log/apache2"
vhost_path="/etc/apache2/sites-available"
vhost_creation
a2dissite 000-default ; a2ensite ${site_url}.conf
fi
}


enable_start_services() {
if [ -f /etc/fedora-release ] ; then
systemctl enable httpd mariadb php-fpm firewalld
systemctl start httpd mariadb php-fpm firewalld
chown apache:apache /run/php-fpm/www.sock
elif [ -f /etc/centos-release ] ; then
systemctl enable httpd mariadb firewalld
systemctl start httpd mariadb firewalld
elif [ -f /etc/lsb-release ] ; then
systemctl enable apache2 mysql firewalld
systemctl start apache2 mysql
systemctl start firewalld
systemctl reload apache2 mysql firewalld
rm -rf /var/www/html/index.html
else
break
fi
}

open_firewall() {
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload
}

https_activation() {
# Three times if DNS failure
certbot --apache --register-unsafely-without-email --agree-tos -d "${site_url}" -n || \
certbot --apache --register-unsafely-without-email --agree-tos -d "${site_url}" -n || \
certbot --apache --register-unsafely-without-email --agree-tos -d "${site_url}" -n
#(crontab -l 2>/dev/null; echo "0 0,12 * * * python -c "import random; import time; time.sleep(random.random() * 3600)" && certbot renew") | crontab -
}

https_installation() {
if [ -f /etc/fedora-release ] ; then
dnf -y install certbot-apache
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.old
https_activation
systemctl reload httpd
chown apache:apache /run/php-fpm/www.sock
elif [ -f /etc/centos-release ] ; then
yum -y install python2-certbot-apache
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.old
https_activation
systemctl reload httpd
elif [ -f /etc/lsb-release ] ; then
apt-get update
apt-get -y install software-properties-common
add-apt-repository ppa:certbot/certbot -y
apt-get -y update
apt-get -y install python-certbot-apache
https_activation
systemctl reload apache2
else
break
fi
}

mysql_secure() {
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${dbroot_password}') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"
}

wordpress_database_creation() {
mysql -e "CREATE USER ${dbuser}@localhost IDENTIFIED BY '${dbuser_password}'"
mysql -e "CREATE DATABASE wp_database"
mysql -e "GRANT ALL ON wp_database.* TO ${dbuser}@localhost"
mysql -e "FLUSH PRIVILEGES"
}

store_passwords() {
echo "DBROOT_PASSWORD=\"${dbroot_password}\"" > ~/.pw_wordpress
echo "DBUSER_PASSWORD=\"${dbuser_password}\"" >> ~/.pw_wordpress
echo "ADMIN_PASSWORD=\"${admin_password}\"" >> ~/.pw_wordpress
chmod 600 ~/.pw_wordpress
}

test_stack() {
# Test Apache
if [ $(curl -s -I 127.0.0.1 | grep -q 'Server: Apache' ; echo $?) == '0' ] ; then
echo "Apache is working" ; else
echo "Apache is NOT working" ; fi
# Test PHP
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
if [ $(curl -s -G http://127.0.0.1/info.php | grep -q 'phpinfo' ; echo $?) == '0' ] ; then
echo "PHP is working" ; else
echo "PHP is NOT working" ; fi
rm -f /var/www/html/info.php
}

wpcli_installation() {
# Installation de wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar ; mv wp-cli.phar /usr/local/bin/wp

# Check if wp-cli is working
if [ $(/usr/local/bin/wp --info > /dev/null ; echo $?) == '0' ] ; then
echo "wp-cli is working" ; else
echo "wp-cli is NOT working" ; fi
}

wordpress_installation() {
# Download Wordpress
/usr/local/bin/wp core download --path=${application_path} --locale=fr_FR --allow-root

# Create wp-config.php
/usr/local/bin/wp config create --dbname=wp_database \
--dbuser=${dbuser} \
--dbpass=${dbuser_password} \
--path=${application_path} \
--allow-root

# Installation
/usr/local/bin/wp core install --url=${site_url} \
--title="${site_title}" \
--admin_user=${admin_user} \
--admin_password=${admin_password} \
--admin_email=${admin_email} \
--path=${application_path} \
--allow-root

# Update plugins to their latest version
/usr/local/bin/wp plugin update --all --path=${application_path} --allow-root
}

print_end_message() {
# Acces to your application
echo "Go to http://${site_url} or https://${site_url} to access to your application"
}


software_installation
vhosts_installation
enable_start_services
open_firewall
https_installation
wordpress_database_creation
mysql_secure
store_passwords
test_stack
wpcli_installation
wordpress_installation
print_end_message
