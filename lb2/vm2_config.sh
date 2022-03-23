sudo apt install nfs-common

sudo mkdir -p /mnt/nfs-share

cat >>/etc/fstab<<EOF
192.168.10.20:/data/nfs /mnt/nfs-share  nfs     defaults    0   0
EOF

sudo mount /mnt/nfs-share

sudo mdkir -p /backup
sudo mkdir -p /backup/log_bp
sudo mkdir -p /backup/config_bp

