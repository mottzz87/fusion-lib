#!/bin/bash
sudo -i 
echo "root:wN4@xhA5WxKj5nhO"
sudo chpasswd root 
sudo sed -i 's/^#?PermitRootLogin./PermitRootLogin yes/g' /etc/ssh/sshd_config 
sudo sed -i 's/^#?PasswordAuthentication./PasswordAuthentication yes/g' /etc/ssh/sshd_config 
sudo service ssh restart
