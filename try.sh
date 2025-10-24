sudo apt update && sudo apt install clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam # initial DB pull
sudo systemctl enable --now clamav-freshclam clamav-daemon
