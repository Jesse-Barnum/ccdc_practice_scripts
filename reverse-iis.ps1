# 1. Re-Install FTP and CGI (In case scoring needs them)
# Warning: This might require a restart, but we suppress it.
Enable-WindowsOptionalFeature -Online -FeatureName IIS-FTPServer -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-FTPSvc -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI -NoRestart

# 2. Unblock File Extensions (Allow .exe, .bat, etc. again)
# We remove the "False" entry we added.
Remove-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -AtElement @{fileExtension='.exe'}
Remove-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -AtElement @{fileExtension='.bat'}
Remove-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -AtElement @{fileExtension='.cmd'}
Remove-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -AtElement @{fileExtension='.ps1'}

Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -Value True
