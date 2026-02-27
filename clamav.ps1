#this script is meant to be run after clamav is installed and while in the "C:\Program Files\ClamAV" directory

#create the correct conf files
copy .\conf_examples\freshclam.conf.sample .\freshclam.conf
copy .\conf_examples\clamd.conf.sample .\clamd.conf

#replace the 'example' portion of the conf files so they operate correctly.
(Get-Content "C:\Program Files\ClamAV\freshclam.conf") -replace '^Example', '#Example' | Set-Content "C:\Program Files\ClamAV\freshclam.conf"
(Get-Content "C:\Program Files\ClamAV\clamd.conf") -replace '^Example', '#Example' | Set-Content "C:\Program Files\ClamAV\clamd.conf"
