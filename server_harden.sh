#!/usr/bin/env bash
#####################################################
# Source various web sources:
# https://www.linuxbabe.com/ubuntu/enable-google-tcp-bbr-ubuntu
# https://www.cyberciti.biz/faq/linux-tcp-tuning/
# Created by cryptopool.builders for crypto use...
#
# Network tuning for YiiMP. Executed on the remote servers and sourced on
# the DB server (server_harden_db.sh), so it must not call exit.
#####################################################

source /etc/functions.sh
source /etc/multipool.conf

echo -e " Boosting server performance for YiiMP...$COL_RESET"
# Boost Network Performance by Enabling TCP BBR (available in every
# supported kernel) and tune the network stack.
sudo tee /etc/sysctl.d/90-multipool-network.conf > /dev/null <<'SYSCTL'
# Created by the YiiMP multi server installer.
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 5000
SYSCTL
sudo modprobe tcp_bbr 2> /dev/null || true
sudo sysctl -q -p /etc/sysctl.d/90-multipool-network.conf || true
echo -e "$GREEN Done...$COL_RESET"
