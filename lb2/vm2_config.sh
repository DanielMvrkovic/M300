sudo apt install nfs-common

sudo mkdir -p /mnt/nfs-share

cat >>/etc/fstab<<EOF
192.168.10.20:/data/nfs /mnt/nfs-share  nfs     defaults    0   0
EOF

sudo mount /mnt/nfs-share

sudo mkdir -p /backup
sudo mkdir -p /backup/log_bk
sudo mkdir -p /backup/config_bk

cat >>/etc/crontab<<EOF
*/11 * * * *    root    cp /mnt/nfs-share/configs/apache/apache2.conf /backup/config_bk/apache2.conf.bk
*/11 * * * *    root    cp /mnt/nfs-share/configs/apache/default-ssl.conf /backup/config_bk/default-ssl.conf.bk
*/11 * * * *    root    tar czf /backup/log_bk/apache.log.bk.tgz /mnt/nfs-share/logs/apache/access.log /mnt/nfs-share/logs/apache/error.log /mnt/nfs-share/logs/apache/other_vhosts_access.log
EOF
