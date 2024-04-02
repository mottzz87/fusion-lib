#!/bin/bash

sudo -i
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
apt-get purge netfilter-persistent -y

# 设置新的 root 密码
echo "root:wN4@xhA5WxKj5nhO" | chpasswd

# 修改 PasswordAuthentication 和 PermitRootLogin 为 yes
sed -i 's/^\(PasswordAuthentication\).*/\1 yes/' /etc/ssh/sshd_config
sed -i 's/^\(PermitRootLogin\).*/\1 yes/' /etc/ssh/sshd_config

# 重启 SSH 服务
systemctl restart sshd
