Sudo apt install iptables 

Iptables –A INPUT -I lo –j ACCEPT 

Sudo iptables –P INPUT DROP 

Iptables –A INPUT –m conntrack –ctstate ESTABLISHED,RELATED –j ACCEPT 

Iptables –A INPUT –p tcp –dport 80 –m conntrack –ctstate NEW –j ACCEPT 

Iptables –A INPUT –p tcp –dport 443 –m conntrack –ctstate NEW –j ACCEPT 

Iptables –A INPUT –p tcp –dport 22 –m conntrack –ctstate NEW –j ACCEPT 

Iptables –N LOG_AND_DROP 

 

//to save current rules 

Sudo apt-get install iptables-persistent 

 

//to save changes 

Sudo netfilter-persistent save 

 

//to see iptables rules 

Sudo iptables –L –n –v –line-numbers 
