sudo apt-get -y install apache2
sudo apt-get -y install ufw
sudo ufw enable
sudo ufw allow 80/tcp

sudo rm /var/www/index.html

cat >>/var/wwww/index.html<<EOF
<!DOCTYPE html>
<html>
<body>

<h1>My Webserver</h1>
<p>My Webserver</p>

</body>
</html>
EOF