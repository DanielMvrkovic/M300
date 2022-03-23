sudo apt update
sudo apt install nfs-common

sudo mkdir -p /mnt/nfs-share

cat >>/etc/fstab<<EOF
192.168.10.20:/data/nfs /mnt/nfs-share  nfs     defaults    0   0
EOF

sudo mount /mnt/nfs-share
