#this script is meant to be run after clamav is installed and while in the "C:\Program Files\ClamAV" directory

#create the correct conf files
copy .\conf_examples\freshclam.conf.sample .\freshclam.conf
copy .\conf_examples\clamd.conf.sample .\clamd.conf

#replace the 'example' portion of the conf files so they operate correctly.
(Get-Content "C:\Program Files\ClamAV\freshclam.conf") -replace '^Example', '#Example' | Set-Content "C:\Program Files\ClamAV\freshclam.conf"
(Get-Content "C:\Program Files\ClamAV\clamd.conf") -replace '^Example', '#Example' | Set-Content "C:\Program Files\ClamAV\clamd.conf"

#update the database
#.\freshclam.exe

# Create a Scheduled Task for ClamAV to scan every 30 minutes
schtasks /create /tn "Clam_30min_scan" /tr "\"C:\Program Files\ClamAV\clamscan.exe\" -r -i --log=\"C:\temp\System_scan.log\" \"C:\System32\"" /sc minute /mo 30 /ru System /rl highest




#if the ./freshclam failed:
#setx CURL_CA_BUNDLE "C:\Program Files\ClamAV\cacert.pem" /m
# Download these three files (you can do this in the browser shown in your screenshots):
# main.cvd
# daily.
# bytecode.cvd
