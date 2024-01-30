#!/bin/bash

sudo setenforce 0
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config
sudo yum install php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip} -y
sudo yum install httpd -y unzip wget
sudo amazon-linux-extras install php8.2 -y
php -v
sudo sed -i 's/AllowOverride none/AllowOverride all/g' /etc/httpd/conf/httpd.conf
wget https://wordpress.org/latest.zip
sudo unzip latest.zip 
sudo mv wordpress/* /var/www/html/
sudo chown -R apache:apache /var/www/html/
sudo yum update -y
wget https://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo yum install mysql-community-release-el7-5.noarch.rpm -y
sudo yum install mysql-server -y
sudo systemctl start mysqld
sudo systemctl enable mysqld
mysql -uroot <<MYSQL_SCRIPT
CREATE USER 'wp_user'@localhost IDENTIFIED BY 'admin@123';
CREATE DATABASE wp;
GRANT ALL PRIVILEGES ON wp.* TO 'wp_user'@'localhost';
MYSQL_SCRIPT
sudo systemctl restart httpd

