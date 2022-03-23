sudo apt-get install -y nfs-kernel-server 
sudo apt-get install -y nfs-common

sudo mkdir -p /data/nfs/configs
sudo mkdir -p /data/nfs/configs/apache
sudo mkdir -p /data/nfs/logs
sudo mkdir -p /data/nfs/logs/apache

chmod -R 777 /data/nfs

cat >>/etc/exports<<EOF
/data/nfs   192.168.10.30(rw,sync,no_root_squash,no_subtree_check)
EOF

sudo exportfs -a

sudo systemctl enable nfs-server

sudo systemctl start nfs-server

sudo ufw allow 2049/tcp