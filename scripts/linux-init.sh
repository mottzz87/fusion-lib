#!/bin/bash

# 获取终端颜色
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
nc='\033[0m' # No Color

# 函数：检测命令执行结果
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${green}$1 执行成功...${nc}"
        return 0
    else
        echo -e "${red}出现错误: $1$!{nc}"
        exit 1
    fi
}

# 更新系统和清理软件包
update_system() {
    echo -e "${yellow}更新系统和清理...${nc}"
    apt update -y && apt full-upgrade -y && apt autoclean -y && apt autoremove -y
    check_result "更新系统和清理"
}

# 安装软件包
install_packages() {
    echo -e "${yellow}安装常用软件包...${nc}"
    apt install curl wget zsh git nano vim htop btop neofetch nload iftop tree file sudo -y &
	wait
	curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
	echo -e "${yellow}安装 speedtest-cli...${nc}"
	apt install speedtest -y &
	wait
    check_result "安装常用软件包"
}

# 重置iptalbes
reset_iptables(){
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -F
  check_result "重置iptables规则"
}

# 修改 SSH 配置文件
modify_ssh_config(){
  apt purge netfilter-persistent -y
  # 设置新的 root 密码
  echo "root:wN4@xhA5WxKj5nhO" | chpasswd

  # 修改 PasswordAuthentication 和 PermitRootLogin 为 yes
  sed -i 's/^\(PasswordAuthentication\).*/\1 yes/' /etc/ssh/sshd_config
  sed -i 's/^\(PermitRootLogin\).*/\1 yes/' /etc/ssh/sshd_config
}

# 修改时区为上海
change_timezone() {
    echo  -e "${yellow}修改时区为上海...${nc}"
    timedatectl set-timezone Asia/Shanghai
    check_result "修改时区为上海"
}

# 重启 SSH 服务
restart_ssh_service() {
    echo -e "${yellow}重启 SSH 服务使修改生效...${nc}"
    systemctl restart ssh
    check_result "重启 SSH 服务"
}


# 执行自动化操作
main() {
    update_system
    install_packages
    reset_iptables

    modify_ssh_config
    restart_ssh_service
    change_timezone
    echo -e "${green}初始化完毕!${nc}"
}

sudo -i
# 执行主函数
main