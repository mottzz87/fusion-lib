#!/bin/bash

sh_v="1.0.3"

bai='\033[0m'
hui='\e[37m'

gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'


permission_granted="true"

CheckFirstRun_true() {
    if grep -q '^permission_granted="true"' /usr/local/bin/k > /dev/null 2>&1; then
        sed -i 's/^permission_granted="false"/permission_granted="true"/' ./cute.sh
        sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
    fi
}

CheckFirstRun_true


# 收集功能埋点信息的函数，记录当前脚本版本号，使用时间，系统版本，CPU架构，机器所在国家和用户使用的功能名称，绝对不涉及任何敏感信息，请放心！请相信我！
# 为什么要设计这个功能，目的更好的了解用户喜欢使用的功能，进一步优化功能推出更多符合用户需求的功能。
# 全文可搜搜 send_stats 函数调用位置，透明开源，如有顾虑可拒绝使用。

ENABLE_STATS="false"

send_stats() {

    if [ "$ENABLE_STATS" == "false" ]; then
        return
    fi

    country=$(curl -s ipinfo.io/country)
    os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')
    cpu_arch=$(uname -m)
    curl -s -X POST "https://api.kejilion.pro/api/log" \
         -H "Content-Type: application/json" \
         -d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\",\"version\":\"$sh_v\"}" &>/dev/null &
}

cleanup() {
    send_stats "非法退出脚本"
    echo
    exit
}

trap cleanup SIGINT


yinsiyuanquan2() {

if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
    sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ./cute.sh
    sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
fi

}


yinsiyuanquan2
cp -f ./cute.sh /usr/local/bin/k > /dev/null 2>&1



CheckFirstRun_false() {
    if grep -q '^permission_granted="false"' /usr/local/bin/k > /dev/null 2>&1; then
        UserLicenseAgreement
    fi
}

# 提示用户同意条款
UserLicenseAgreement() {
    clear
    echo -e "${gl_kjlan}欢迎使用本脚本工具箱${gl_bai}"
    echo "首次使用脚本，请先阅读并同意用户许可协议。"
    echo "用户许可协议: https://blog.kejilion.pro/user-license-agreement/"
    echo -e "----------------------"
    read -r -p "是否同意以上条款？(y/n): " user_input


    if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
        send_stats "许可同意"
        sed -i 's/^permission_granted="false"/permission_granted="true"/' ./cute.sh
        sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
    else
        send_stats "许可拒绝"
        clear
        exit
    fi
}

CheckFirstRun_false



ip_address() {
ipv4_address=$(curl -s ipv4.ip.sb)
ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}


install() {
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return
    fi

    for package in "$@"; do
        if ! command -v "$package" &>/dev/null; then
            echo -e "${gl_huang}正在安装 $package...${gl_bai}"
            if command -v dnf &>/dev/null; then
                dnf -y update
                dnf install -y epel-release
                dnf install -y "$package"
            elif command -v yum &>/dev/null; then
                yum -y update
                yum install -y epel-release
                yum -y install "$package"
            elif command -v apt &>/dev/null; then
                apt update -y
                apt install -y "$package"
            elif command -v apk &>/dev/null; then
                apk update
                apk add "$package"
            elif command -v pacman &>/dev/null; then
                pacman -Syu --noconfirm
                pacman -S --noconfirm "$package"
            elif command -v zypper &>/dev/null; then
                zypper refresh
                zypper install -y "$package"
            elif command -v opkg &>/dev/null; then
                opkg update
                opkg install "$package"
            else
                echo "未知的包管理器!"
                return
            fi
        else
            echo -e "${gl_lv}$package 已经安装${gl_bai}"
        fi
    done

    return
}


install_dependency() {
      clear
      install wget socat unzip tar
}


remove() {
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return
    fi

    for package in "$@"; do
        echo -e "${gl_huang}正在卸载 $package...${gl_bai}"
        if command -v dnf &>/dev/null; then
            dnf remove -y "${package}"*
        elif command -v yum &>/dev/null; then
            yum remove -y "${package}"*
        elif command -v apt &>/dev/null; then
            apt purge -y "${package}"*
        elif command -v apk &>/dev/null; then
            apk del "${package}*"
        elif command -v pacman &>/dev/null; then
            pacman -Rns --noconfirm "${package}"
        elif command -v zypper &>/dev/null; then
            zypper remove -y "${package}"
        elif command -v opkg &>/dev/null; then
            opkg remove "${package}"
        else
            echo "未知的包管理器!"
            return
        fi
    done

    return
}


# 通用 systemctl 函数，适用于各种发行版
systemctl() {
    COMMAND="$1"
    SERVICE_NAME="$2"

    if command -v apk &>/dev/null; then
        service "$SERVICE_NAME" "$COMMAND"
    else
        /bin/systemctl "$COMMAND" "$SERVICE_NAME"
    fi
}


# 重启服务
restart() {
    systemctl restart "$1"
    if [ $? -eq 0 ]; then
        echo "$1 服务已重启。"
    else
        echo "错误：重启 $1 服务失败。"
    fi
}

# 启动服务
start() {
    systemctl start "$1"
    if [ $? -eq 0 ]; then
        echo "$1 服务已启动。"
    else
        echo "错误：启动 $1 服务失败。"
    fi
}

# 停止服务
stop() {
    systemctl stop "$1"
    if [ $? -eq 0 ]; then
        echo "$1 服务已停止。"
    else
        echo "错误：停止 $1 服务失败。"
    fi
}

# 查看服务状态
status() {
    systemctl status "$1"
    if [ $? -eq 0 ]; then
        echo "$1 服务状态已显示。"
    else
        echo "错误：无法显示 $1 服务状态。"
    fi
}


enable() {
    SERVICE_NAME="$1"
    if command -v apk &>/dev/null; then
        rc-update add "$SERVICE_NAME" default
    else
       /bin/systemctl enable "$SERVICE_NAME"
    fi

    echo "$SERVICE_NAME 已设置为开机自启。"
}



break_end() {
      echo -e "${gl_lv}操作完成${gl_bai}"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
}

kejilion() {
            cd ~
            kejilion_sh
}

check_crontab_installed() {
    if command -v crontab >/dev/null 2>&1; then
        echo -e "${gl_lv}crontab 已经安装${gl_bai}"
        return
    else
        install_crontab
        return
    fi
}

install_crontab() {

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|kali)
                apt update
                apt install -y cron
                systemctl enable cron
                systemctl start cron
                ;;
            centos|rhel|almalinux|rocky|fedora)
                yum install -y cronie
                systemctl enable crond
                systemctl start crond
                ;;
            alpine)
                apk add --no-cache cronie
                rc-update add crond
                rc-service crond start
                ;;
            arch|manjaro)
                pacman -S --noconfirm cronie
                systemctl enable cronie
                systemctl start cronie
                ;;
            opensuse|suse|opensuse-tumbleweed)
                zypper install -y cron
                systemctl enable cron
                systemctl start cron
                ;;
            openwrt|lede)
                opkg update
                opkg install cron
                /etc/init.d/cron enable
                /etc/init.d/cron start
                ;;
            *)
                echo "不支持的发行版: $ID"
                return
                ;;
        esac
    else
        echo "无法确定操作系统。"
        return
    fi

    echo -e "${gl_lv}crontab 已安装且 cron 服务正在运行。${gl_bai}"
}

iptables_open() {
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F

    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F

}

add_swap() {
    # 获取当前系统中所有的 swap 分区
    swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

    # 遍历并删除所有的 swap 分区
    for partition in $swap_partitions; do
      swapoff "$partition"
      wipefs -a "$partition"  # 清除文件系统标识符
      mkswap -f "$partition"
    done

    # 确保 /swapfile 不再被使用
    swapoff /swapfile

    # 删除旧的 /swapfile
    rm -f /swapfile

    # 创建新的 swap 分区
    dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if [ -f /etc/alpine-release ]; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
        chmod +x /etc/local.d/swap.start
        rc-update add local
    else
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    echo -e "虚拟内存大小已调整为${gl_huang}${new_swap}${gl_bai}MB"
}

check_swap() {

  swap_total=$(free -m | awk 'NR==3{print $2}')

  # 判断是否需要创建虚拟内存
  if [ "$swap_total" -gt 0 ]; then
      :
  else
      new_swap=1024
      add_swap
  fi

}

output_status() {
    output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
        NR > 2 { rx_total += $2; tx_total += $10 }
        END {
            rx_units = "Bytes";
            tx_units = "Bytes";
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

            if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

            printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
        }' /proc/net/dev)

}

current_timezone() {
    if grep -q 'Alpine' /etc/issue; then
       date +"%Z %z"
    else
       timedatectl | grep "Time zone" | awk '{print $3}'
    fi

}


set_timedate() {
    shiqu="$1"
    if grep -q 'Alpine' /etc/issue; then
        install tzdata
        cp /usr/share/zoneinfo/${shiqu} /etc/localtime
        hwclock --systohc
    else
        timedatectl set-timezone ${shiqu}
    fi
}


wait_for_lock() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "等待dpkg锁释放..."
        sleep 1
    done
}

# 修复dpkg中断问题
fix_dpkg() {
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


bbr_on() {

cat > /etc/sysctl.conf << EOF
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p

}


restart_ssh() {
    restart sshd ssh > /dev/null 2>&1

}


new_ssh_port() {


  # 备份 SSH 配置文件
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

  # 替换 SSH 配置文件中的端口号
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  # 重启 SSH 服务
  restart_ssh

  iptables_open
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH 端口已修改为: $new_port"

  sleep 1

}

add_sshkey() {

# ssh-keygen -t rsa -b 4096 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""
ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys


ip_address
echo -e "私钥信息已生成，务必复制保存，可保存成 ${gl_huang}${ipv4_address}_ssh.key${gl_bai} 文件，用于以后的SSH登录"

echo "--------------------------------"
cat ~/.ssh/sshkey
echo "--------------------------------"

sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
       -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
       -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
       -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
echo -e "${gl_lv}ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${gl_bai}"

}

enable_bbr() {
    if grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${gl_lv}BBR 已经启用${gl_bai}"
    else
        echo -e "\nnet.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        echo -e "${gl_lv}BBR 已成功启用${gl_bai}"
    fi
}

add_sshpasswd() {

echo "设置你的ROOT密码"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT登录设置完毕！${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！" && break_end && kejilion
}

linux_ps() {

    clear
    send_stats "系统信息查询"

    ip_address

    cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

    cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
        <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

    cpu_cores=$(nproc)

    mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

    disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

    ipinfo=$(curl -s ipinfo.io)
    country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
    city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
    isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')


    cpu_arch=$(uname -m)

    hostname=$(hostname)

    kernel_version=$(uname -r)

    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    queue_algorithm=$(sysctl -n net.core.default_qdisc)

    # 尝试使用 lsb_release 获取系统信息
    os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')

    output_status

    current_time=$(date "+%Y-%m-%d %I:%M %p")


    swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dMB/%dMB (%d%%)", used, total, percentage}')

    runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

    timezone=$(current_timezone)


    echo ""
    echo -e "系统信息查询"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}主机名: ${gl_bai}$hostname"
    echo -e "${gl_kjlan}运营商: ${gl_bai}$isp_info"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}系统版本: ${gl_bai}$os_info"
    echo -e "${gl_kjlan}Linux版本: ${gl_bai}$kernel_version"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}CPU架构: ${gl_bai}$cpu_arch"
    echo -e "${gl_kjlan}CPU型号: ${gl_bai}$cpu_info"
    echo -e "${gl_kjlan}CPU核心数: ${gl_bai}$cpu_cores"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}CPU占用: ${gl_bai}$cpu_usage_percent%"
    echo -e "${gl_kjlan}物理内存: ${gl_bai}$mem_info"
    echo -e "${gl_kjlan}虚拟内存: ${gl_bai}$swap_info"
    echo -e "${gl_kjlan}硬盘占用: ${gl_bai}$disk_info"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}$output"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}网络拥堵算法: ${gl_bai}$congestion_algorithm $queue_algorithm"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}公网IPv4地址: ${gl_bai}$ipv4_address"
    echo -e "${gl_kjlan}公网IPv6地址: ${gl_bai}$ipv6_address"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}地理位置: ${gl_bai}$country $city"
    echo -e "${gl_kjlan}系统时区: ${gl_bai}$timezone"
    echo -e "${gl_kjlan}系统时间: ${gl_bai}$current_time"
    echo -e "${gl_kjlan}------------------------"
    echo -e "${gl_kjlan}系统运行时长: ${gl_bai}$runtime"
    echo

}

linux_test() {

    while true; do
      clear
      # send_stats "测试脚本合集"
      echo -e "▶ 测试脚本合集"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}IP及解锁状态检测"
      echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT 解锁状态检测"
      echo -e "${gl_kjlan}2.   ${gl_bai}Region 流媒体解锁测试"
      echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu 流媒体解锁检测"
      echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP质量体检脚本 ${gl_huang}★${gl_bai}"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}网络线路测速"
      echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 三网回程延迟路由测试"
      echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 三网回程线路测试"
      echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 三网测速"
      echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 快速回程测试脚本"
      echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 指定IP回程测试脚本"
      echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 三网线路测试"
      echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多功能测速脚本"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}硬件性能测试"
      echo -e "${gl_kjlan}21.  ${gl_bai}yabs 性能测试"
      echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU性能测试脚本"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}综合性测试"
      echo -e "${gl_kjlan}31.  ${gl_bai}bench 性能测试"
      echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 融合怪测评 ${gl_huang}★${gl_bai}"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
      echo -e "${gl_kjlan}------------------------${gl_bai}"
      read -p "请输入你的选择: " sub_choice

      case $sub_choice in
          1)
              clear
              send_stats "ChatGPT解锁状态检测"
              bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
              ;;
          2)
              clear
              send_stats "Region流媒体解锁测试"
              bash <(curl -L -s check.unlock.media)
              ;;
          3)
              clear
              send_stats "yeahwu流媒体解锁检测"
              install wget
              wget -qO- https://github.com/yeahwu/check/raw/main/check.sh | bash
              ;;
          4)
              clear
              send_stats "xykt_IP质量体检脚本"
              bash <(curl -Ls IP.Check.Place)
              ;;
          11)
              clear
              send_stats "besttrace三网回程延迟路由测试"
              install wget
              wget -qO- git.io/besttrace | bash
              ;;
          12)
              clear
              send_stats "mtr_trace三网回程线路测试"
              curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
              ;;
          13)
              clear
              send_stats "Superspeed三网测速"
              bash <(curl -Lso- https://git.io/superspeed_uxh)
              ;;
          14)
              clear
              send_stats "nxtrace快速回程测试脚本"
              curl nxtrace.org/nt |bash
              nexttrace --fast-trace --tcp
              ;;
          15)
              clear
              send_stats "nxtrace指定IP回程测试脚本"
              echo "可参考的IP列表"
              echo "------------------------"
              echo "北京电信: 219.141.136.12"
              echo "北京联通: 202.106.50.1"
              echo "北京移动: 221.179.155.161"
              echo "上海电信: 202.96.209.133"
              echo "上海联通: 210.22.97.1"
              echo "上海移动: 211.136.112.200"
              echo "广州电信: 58.60.188.222"
              echo "广州联通: 210.21.196.6"
              echo "广州移动: 120.196.165.24"
              echo "成都电信: 61.139.2.69"
              echo "成都联通: 119.6.6.6"
              echo "成都移动: 211.137.96.205"
              echo "湖南电信: 36.111.200.100"
              echo "湖南联通: 42.48.16.100"
              echo "湖南移动: 39.134.254.6"
              echo "------------------------"

              read -p "输入一个指定IP: " testip
              curl nxtrace.org/nt |bash
              nexttrace $testip
              ;;

          16)
              clear
              send_stats "ludashi2020三网线路测试"
              curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
              ;;

          17)
              clear
              send_stats "i-abc多功能测速脚本"
              bash <(curl -sL bash.icu/speedtest)
              ;;


          21)
              clear
              send_stats "yabs性能测试"
              check_swap
              curl -sL yabs.sh | bash -s -- -i -5
              ;;
          22)
              clear
              send_stats "icu/gb5 CPU性能测试脚本"
              check_swap
              bash <(curl -sL bash.icu/gb5)
              ;;

          31)
              clear
              send_stats "bench性能测试"
              curl -Lso- bench.sh | bash
              ;;
          32)
              send_stats "spiritysdx融合怪测评"
              clear
              curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
              ;;

          0)
              kejilion

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done


}



linux_Settings() {

    while true; do
      clear
      # send_stats "系统工具"
      echo -e "▶ 系统工具"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}1.   ${gl_bai}ROOT密码登录模式                   ${gl_kjlan}2.   ${gl_bai}ROOT私钥登录模式"
      echo -e "${gl_kjlan}3.   ${gl_bai}修改登录密码                       ${gl_kjlan}4.   ${gl_bai}修改SSH连接端口"
      echo -e "${gl_kjlan}5.   ${gl_bai}开放所有端口                       ${gl_kjlan}6.   ${gl_bai}查看端口占用状态"
      echo -e "${gl_kjlan}7.   ${gl_bai}系统时区调整                       ${gl_kjlan}8.   ${gl_bai}本机host解析"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}9.   ${gl_bai}限流自动关机                       ${gl_kjlan}10.  ${gl_bai}TG-bot系统监控预警"
      echo -e "${gl_kjlan}11.  ${gl_bai}开启BBR加速                        ${gl_kjlan}99.  ${gl_bai}卸载脚本"
      echo -e "${gl_kjlan}------------------------"
      echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
      echo -e "${gl_kjlan}------------------------${gl_bai}"
      read -p "请输入你的选择: " sub_choice

      case $sub_choice in
          1)
              root_use
              send_stats "root密码模式"
              add_sshpasswd
              ;;
          2)
              root_use
              send_stats "私钥登录"
              echo "ROOT私钥登录模式"
              echo "视频介绍: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
              echo "------------------------------------------------"
              echo "将会生成密钥对，更安全的方式SSH登录"
              read -p "确定继续吗？(Y/N): " choice

              case "$choice" in
                [Yy])
                  clear
                  send_stats "私钥登录使用"
                  add_sshkey
                  ;;
                [Nn])
                  echo "已取消"
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac

              ;;
          3)
            clear
            send_stats "设置你的登录密码"
            echo "设置你的登录密码"
            passwd
            ;; 

          4)
            root_use
            send_stats "修改SSH端口"

            while true; do
                clear
                sed -i 's/#Port/Port/' /etc/ssh/sshd_config

                # 读取当前的 SSH 端口号
                current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

                # 打印当前的 SSH 端口号
                echo -e "当前的 SSH 端口号是:  ${gl_huang}$current_port ${gl_bai}"

                echo "------------------------"
                echo "端口号范围1到65535之间的数字。（输入0退出）"

                # 提示用户输入新的 SSH 端口号
                read -p "请输入新的 SSH 端口号: " new_port

                # 判断端口号是否在有效范围内
                if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
                    if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
                        send_stats "SSH端口已修改"
                        new_ssh_port
                    elif [[ $new_port -eq 0 ]]; then
                        send_stats "退出SSH端口修改"
                        break
                    else
                        echo "端口号无效，请输入1到65535之间的数字。"
                        send_stats "输入无效SSH端口"
                        break_end
                    fi
                else
                    echo "输入无效，请输入数字。"
                    send_stats "输入无效SSH端口"
                    break_end
                fi
            done


              ;;

          5)
              root_use
              send_stats "开放端口"
              iptables_open
              remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
              echo "端口已全部开放"

              ;;
          6)
            clear
            ss -tulnape
            ;;
          7)
            root_use
            send_stats "换时区"
            while true; do
                clear
                echo "系统时间信息"

                # 获取当前系统时区
                timezone=$(current_timezone)

                # 获取当前系统时间
                current_time=$(date +"%Y-%m-%d %H:%M:%S")

                # 显示时区和时间
                echo "当前系统时区：$timezone"
                echo "当前系统时间：$current_time"

                echo ""
                echo "时区切换"
                echo "------------------------"                
                echo "亚洲"
                echo "1.  中国上海时间             2.  中国香港时间"
                echo "3.  日本东京时间             4.  韩国首尔时间"
                echo "5.  新加坡时间               6.  印度加尔各答时间"
                echo "7.  阿联酋迪拜时间           8.  澳大利亚悉尼时间"
                echo "------------------------"
                echo "欧洲"
                echo "11. 英国伦敦时间             12. 法国巴黎时间"
                echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
                echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
                echo "------------------------"
                echo "美洲"
                echo "21. 美国西部时间             22. 美国东部时间"
                echo "23. 加拿大时间               24. 墨西哥时间"
                echo "25. 巴西时间                 26. 阿根廷时间"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p "请输入你的选择: " sub_choice


                case $sub_choice in
                    1) set_timedate Asia/Shanghai ;;
                    2) set_timedate Asia/Hong_Kong ;;
                    3) set_timedate Asia/Tokyo ;;
                    4) set_timedate Asia/Seoul ;;
                    5) set_timedate Asia/Singapore ;;
                    6) set_timedate Asia/Kolkata ;;
                    7) set_timedate Asia/Dubai ;;
                    8) set_timedate Australia/Sydney ;;
                    11) set_timedate Europe/London ;;
                    12) set_timedate Europe/Paris ;;
                    13) set_timedate Europe/Berlin ;;
                    14) set_timedate Europe/Moscow ;;
                    15) set_timedate Europe/Amsterdam ;;
                    16) set_timedate Europe/Madrid ;;
                    21) set_timedate America/Los_Angeles ;;
                    22) set_timedate America/New_York ;;
                    23) set_timedate America/Vancouver ;;
                    24) set_timedate America/Mexico_City ;;
                    25) set_timedate America/Sao_Paulo ;;
                    26) set_timedate America/Argentina/Buenos_Aires ;;
                    0) break ;; # 跳出循环，退出菜单
                    *) break ;; # 跳出循环，退出菜单
                esac
            done
              ;;

          

          8)
              root_use
              send_stats "本地host解析"
              while true; do
                  clear
                  echo "本机host解析列表"
                  echo "如果你在这里添加解析匹配，将不再使用动态解析了"
                  cat /etc/hosts
                  echo ""
                  echo "操作"
                  echo "------------------------"
                  echo "1. 添加新的解析              2. 删除解析地址"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p "请输入你的选择: " host_dns

                  case $host_dns in
                      1)
                          read -p "请输入新的解析记录 格式: 110.25.5.33 kejilion.pro : " addhost
                          echo "$addhost" >> /etc/hosts
                          send_stats "本地host解析新增"

                          ;;
                      2)
                          read -p "请输入需要删除的解析内容关键字: " delhost
                          sed -i "/$delhost/d" /etc/hosts
                          send_stats "本地host解析删除"
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;
          9)
            root_use
            send_stats "限流关机功能"
            while true; do
                clear
                echo "限流关机功能"
                echo "视频介绍: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
                echo "------------------------------------------------"
                echo "当前流量使用情况，重启服务器流量计算会清零！"
                output_status
                echo "$output"

                # 检查是否存在 Limiting_Shut_down.sh 文件
                if [ -f ~/Limiting_Shut_down.sh ]; then
                    # 获取 threshold_gb 的值
                    rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
                    tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
                    echo -e "${gl_lv}当前设置的进站限流阈值为: ${gl_huang}${rx_threshold_gb}${gl_lv}GB${gl_bai}"
                    echo -e "${gl_lv}当前设置的出站限流阈值为: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
                else
                    echo -e "${hui}当前未启用限流关机功能${gl_bai}"
                fi

                echo
                echo "------------------------------------------------"
                echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！"
                read -p "1. 开启限流关机功能    2. 停用限流关机功能    0. 退出  : " Limiting

                case "$Limiting" in
                  1)
                    # 输入新的虚拟内存大小
                    echo "如果实际服务器就100G流量，可设置阈值为95G，提前关机，以免出现流量误差或溢出."
                    read -p "请输入进站流量阈值（单位为GB）: " rx_threshold_gb
                    read -p "请输入出站流量阈值（单位为GB）: " tx_threshold_gb
                    read -p "请输入流量重置日期（默认每月1日重置）: " cz_day
                    cz_day=${cz_day:-1}

                    cd ~
                    curl -Ss -o ~/Limiting_Shut_down.sh https://raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
                    chmod +x ~/Limiting_Shut_down.sh
                    sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
                    sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
                    check_crontab_installed
                    crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
                    (crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
                    crontab -l | grep -v 'reboot' | crontab -
                    (crontab -l ; echo "0 1 $cz_day * * reboot") | crontab - > /dev/null 2>&1
                    echo "限流关机已设置"
                    send_stats "限流关机已设置"
                    ;;
                  2)
                    check_crontab_installed
                    crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
                    crontab -l | grep -v 'reboot' | crontab -
                    rm ~/Limiting_Shut_down.sh
                    echo "已关闭限流关机功能"
                    ;;
                  *)
                    break
                    ;;
                esac
            done
              ;;


          
          10)
              root_use
              send_stats "电报预警"
              echo "TG-bot监控预警功能"
              echo "视频介绍: https://youtu.be/vLL-eb3Z_TY"
              echo "------------------------------------------------"
              echo "您需要配置tg机器人API和接收预警的用户ID，即可实现本机CPU，内存，硬盘，流量，SSH登录的实时监控预警"
              echo "到达阈值后会向用户发预警消息"
              echo -e "${hui}-关于流量，重启服务器将重新计算-${gl_bai}"
              read -p "确定继续吗？(Y/N): " choice

              case "$choice" in
                [Yy])
                  send_stats "电报预警启用"
                  cd ~
                  install nano tmux bc jq
                  check_crontab_installed
                  if [ -f ~/TG-check-notify.sh ]; then
                      chmod +x ~/TG-check-notify.sh
                      nano ~/TG-check-notify.sh
                  else
                      curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh
                      chmod +x ~/TG-check-notify.sh
                      nano ~/TG-check-notify.sh
                  fi
                  tmux kill-session -t TG-check-notify > /dev/null 2>&1
                  tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
                  crontab -l | grep -v '~/TG-check-notify.sh' | crontab - > /dev/null 2>&1
                  (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab - > /dev/null 2>&1

                  curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh > /dev/null 2>&1
                  sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh > /dev/null 2>&1
                  sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
                  chmod +x ~/TG-SSH-check-notify.sh

                  # 添加到 ~/.profile 文件中
                  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
                      echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
                      if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
                         echo 'source ~/.profile' >> ~/.bashrc
                      fi
                  fi

                  source ~/.profile

                  clear
                  echo "TG-bot预警系统已启动"
                  echo -e "${hui}你还可以将root目录中的TG-check-notify.sh预警文件放到其他机器上直接使用！${gl_bai}"
                  ;;
                [Nn])
                  echo "已取消"
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;

          
          
          11)
                root_use
                send_stats "开启BBR加速"
                enable_bbr
                break_end
                ;;
          
          99)
              clear
              send_stats "卸载脚本"
              echo "卸载脚本"
              echo "------------------------------------------------"
              echo "将彻底卸载脚本吗，不影响你其他功能"
              read -p "确定继续吗？(Y/N): " choice

              case "$choice" in
                [Yy])
                  clear
                  rm -f /usr/local/bin/k
                  rm ./cute.sh
                  echo "脚本已卸载，再见！"
                  break_end
                  clear
                  exit
                  ;;
                [Nn])
                  echo "已取消"
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;

          0)
              kejilion

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done

}

# 函数：设置防火墙
setup_firewall() {
    OS=$(awk -F= '/^ID=/ {print $2}' /etc/os-release | tr -d '"')
    opened_ports=()
    
    # 为不同系统定义端口格式
    if [[ "$OS" =~ ^(debian|ubuntu)$ ]]; then
        ports=(22 80 443 21 3306 8080 "6500:6550")  # UFW 使用冒号
    else
        ports=(22 80 443 21 3306 8080 "6500-6550")  # firewalld 使用连字符
    fi

    case "$OS" in
        centos|rhel|fedora)
            # ... 其他代码保持不变 ...
            ;;
        
        debian|ubuntu)
            # 检查并安装 ufw
            if ! command -v ufw &>/dev/null; then
                echo "正在安装 UFW..."
                install ufw
            fi

            # 启动 ufw
            if ! ufw status | grep -q "Status: active"; then
                echo "y" | ufw enable
            fi
            
            # 开放端口
            for port in "${ports[@]}"; do
                if [[ "$port" == *":"* ]]; then
                    # 处理端口范围
                    if ! ufw status | grep -q "$port/tcp"; then
                        ufw allow "$port"/tcp
                        opened_ports+=("$port")
                    fi
                else
                    # 处理单个端口
                    if ! ufw status | grep -q "^$port/tcp"; then
                        ufw allow "$port"/tcp
                        opened_ports+=("$port")
                    fi
                fi
            done
            ;;
        
        # ... 其他代码保持不变 ...
    esac

    # 输出结果
    if [ ${#opened_ports[@]} -gt 0 ]; then
        echo "已开放端口: ${opened_ports[*]}/tcp"
    else
        echo "所有端口已经开放，无需重复操作"
    fi
}

install_script() {
    # 复制脚本到 /usr/local/bin/k
    sudo cp "$0" /usr/local/bin/k
    
    # 确保脚本有执行权限
    sudo chmod +x /usr/local/bin/k
    
    # 添加别名到 .bashrc 文件
    echo "alias k='/usr/local/bin/k'" >> ~/.bashrc
    
    # 立即生效别名
    source ~/.bashrc
    
    echo "脚本已安装，现在可以使用 'k' 命令来运行脚本。"
}

kejilion_sh() {
setup_firewall
install_script
while true; do
clear

echo -e "适配Ubuntu/Debian/CentOS/Alpine/Kali/Arch/RedHat/Fedora/Alma/Rocky系统"
echo -e "-输入${gl_huang}k${gl_kjlan}可快速启动此脚本-${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1. ${gl_bai}ROOT密码登录"
echo -e "${gl_kjlan}2. ${gl_bai}系统信息查询"
echo -e "${gl_kjlan}3. ${gl_bai}测试脚本合集 ▶ "
echo -e "${gl_kjlan}4. ${gl_bai}系统工具 ▶ "
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}退出脚本"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -p "请输入你的选择: " choice

case $choice in
  1)
    root_use
    send_stats "root密码模式"
    add_sshpasswd
    ;;
  2)
    linux_ps
    ;;

  3)
    linux_test
    ;;

  4)
    linux_Settings
    ;;

  0)
    clear
    exit
    ;;

  *)
    echo "无效的输入!"
    ;;
esac
    break_end
done

}


if [ "$#" -eq 0 ]; then
    # 如果没有参数，运行交互式逻辑
    kejilion_sh
fi
