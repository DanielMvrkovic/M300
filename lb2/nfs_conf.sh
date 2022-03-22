sudo apt-get -y install ntfs-utils

sudo mkdir -p /data/nfs/storage
sudo mkdir -p /data/nfs/configs
sudo mkdir -p /data/nfs/logs
sudo mkdir -p /data/nfs/documents

chmod -R 777 /data/nfs

cat >>/etc/exports<<EOF
/data/nfs   localhost   rw,sync,no_root_squash,no_subtree_check
EOF

sudo exportfs -a

sudo systemctl enable nfs-server

sudo systemctl start nfs-server

sudo ufw allow 2049/tcp