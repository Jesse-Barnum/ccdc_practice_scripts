sudo apt update

sudo apt install xfce4 xfce4-goodies -y

sudo apt install xrdp -y

echo "xfce4-session" | tee ~/.xsession

sudo systemctl restart xrdp

sudo iptables -A INPUT -s 192.168.5.176/32 -p tcp --dport 3389 -j ACCEPT

