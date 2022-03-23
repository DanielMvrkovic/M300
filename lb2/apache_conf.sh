sudo apt-get -y install apache2
sudo apt-get -y install ufw

sudo ufw enable
sudo ufw allow 443/tcp

rm /var/www/html/index.html



sudo a2ensite default-ssl.conf
sudo a2enmod ssl