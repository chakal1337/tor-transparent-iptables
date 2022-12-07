#!/bin/bash
[ $( id -u) != "0" ] && echo "This script needs root privileges!" && exit;
if [[ $# < 1 ]]; then
 echo "$0 <on/off>";
 exit;
fi
if [[ $1 == "on" ]]; then
 echo -e "VirtualAddrNetwork 10.192.0.0/10\nAutomapHostsOnResolve 1\nTransPort 9040\nDNSPort 5353" > /etc/tor/torrc;
 echo "Starting TOR...";
 killall tor &>/dev/null;
 tor &>/tmp/.torout &
 grep -q 'Done' <(tail -f /tmp/.torout);
 echo "Setting firewall rules...";
 NON_TOR="192.168.1.0/24 192.168.0.0/24";
 iptables -F;
 iptables -t nat -F;
 tor_uid=$(cat /etc/passwd | grep tor | cut -d ":" -f 3);
 iptables -t nat -A OUTPUT -m owner --uid-owner 0 -j RETURN;
 iptables -t nat -A OUTPUT -m owner --uid-owner $tor_uid -j RETURN;
 iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353;
 for NET in $NON_TOR 127.0.0.0/9 127.128.0.0/10; do
  iptables -t nat -A OUTPUT -d $NET -j RETURN;
 done
 iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040;
 iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT;
 for NET in $NON_TOR 127.0.0.0/8; do
  iptables -A OUTPUT -d $NET -j ACCEPT;
 done
 iptables -A OUTPUT -m owner --uid-owner 0 -j ACCEPT;
 iptables -A OUTPUT -m owner --uid-owner $tor_uid -j ACCEPT;
else
 echo "Deleting firewall rules...";
 iptables -F;
 iptables -t nat -F;
 echo "Killing tor...";
 killall tor &>/dev/null;
fi
