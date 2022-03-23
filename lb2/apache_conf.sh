sudo apt-get -y install apache2
sudo apt-get -y install ufw
sudo ufw enable
sudo ufw allow 80/tcp

rm /var/www/html/index.html
