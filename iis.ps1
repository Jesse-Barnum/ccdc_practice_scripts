# Disable CGI (Common vector for shell execution)
Disable-WindowsOptionalFeature -Online -FeatureName IIS-CGI -NoRestart

# Disable FTP Server (If you don't need it, KILL IT. It's a backdoor magnet.)
Disable-WindowsOptionalFeature -Online -FeatureName IIS-FTPServer -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName IIS-FTPSvc -NoRestart

# Disable Directory Browsing (Prevents attackers from seeing your file structure)
Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -Value False

# Block .exe, .bat, .cmd, and .ps1 access via web
Add-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -Value @{fileExtension='.exe';allowed='False'}
Add-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -Value @{fileExtension='.bat';allowed='False'}
Add-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -Value @{fileExtension='.cmd';allowed='False'}
Add-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/fileExtensions -Name . -Value @{fileExtension='.ps1';allowed='False'}

# Enable Logging and include all fields
Set-WebConfigurationProperty -Filter /system.webServer/httpLogging -Name dontLog -Value False

