sudo apt-get -y install apache2
sudo apt-get -y install ufw

sudo ufw enable
sudo ufw allow 443/tcp

rm /var/www/html/index.html

sudo touch /data/nfs/logs/apache/access.log
sudo touch /data/nfs/logs/apache/error.log
sudo touch /data/nfs/logs/apache/other_vhosts_access.log

sudo ln -s /var/log/apache2/access.log /data/nfs/logs/apache/access.log
sudo ln -s /var/log/apache2/error.log /data/nfs/logs/apache/error.log
sudo ln -s /var/log/apache2/other_vhosts_access.log /data/nfs/logs/apache/other_vhosts_access.log


sudo a2ensite default-ssl.conf
sudo a2enmod ssl
sudo systemctl restart apache2

cat >>/etc/crontab<<EOF
*/10 * * * *    root    cp /etc/apache2/apache2.conf /data/nfs/configs/apache/apache2.conf
*/10 * * * *    root    cp /etc/apache2/sites-enabled/default-ssl.conf /data/nfs/configs/apache/default-ssl.conf
EOF