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

# 3. Unblock "bin" Folder access
Remove-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering/hiddenSegments -Name . -AtElement @{segment='bin'}

# 4. Re-Enable Directory Browsing (Make files listable again)
Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -Value True

# 5. Restore Server Headers (Stop hiding identity)
# Re-enable the "Server" header
Set-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering -Name removeServerHeader -Value False

# Note: Putting "X-Powered-By" back is harder because it's a default, 
# but simply removing the block rule usually suffices. 
# If you explicitly removed it, this command adds it back:
Add-WebConfigurationProperty -Filter /system.webServer/httpProtocol/customHeaders -Name . -Value @{name='X-Powered-By';value='ASP.NET'}

Write-Host "IIS Hardening Reverted. Verify services are running!" -ForegroundColor Green
