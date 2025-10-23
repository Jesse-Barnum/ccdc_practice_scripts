sudo apt install iptables 

iptables –A INPUT -I lo –j ACCEPT 

sudo iptables –P INPUT DROP 

iptables –A INPUT –m conntrack –ctstate ESTABLISHED,RELATED –j ACCEPT 

iptables –A INPUT –p tcp –dport 80 –m conntrack –ctstate NEW –j ACCEPT 

iptables –A INPUT –p tcp –dport 443 –m conntrack –ctstate NEW –j ACCEPT 

iptables –A INPUT –p tcp –dport 22 –m conntrack –ctstate NEW –j ACCEPT 

iptables –N LOG_AND_DROP 

 

sudo apt-get install iptables-persistent 

 

sudo netfilter-persistent save 

 

sudo iptables –L –n –v –line-numbers 
