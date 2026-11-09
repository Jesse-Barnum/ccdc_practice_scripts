# Create Administrators and add them to the sudo group
useradd -m -G sudo -s /bin/bash phineas
useradd -m -G sudo -s /bin/bash ferb

# Create Standard Users
useradd -m -s /bin/bash isabella
useradd -m -s /bin/bash buford
useradd -m -s /bin/bash candice
useradd -m -s /bin/bash baljeet
useradd -m -s /bin/bash perry

# Set a default starting password for all users so competitors can log in
echo "phineas:platypus" | chpasswd
echo "ferb:platypus" | chpasswd
echo "isabella:platypus" | chpasswd
echo "buford:platypus" | chpasswd
echo "candice:platypus" | chpasswd
echo "baljeet:platypus" | chpasswd
echo "perry:platypus" | chpasswd
