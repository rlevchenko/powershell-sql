<#
.Description
       Script for SQL Server Installation + SQL Management Studio. 
       All SQL Services accounts are being created during the script deploying.
       All features from SQL Server 2012 SP1 Image.
       Report Services is in Native Mode.
       Second disk , 100 Gb thin is only for SQL data
       AD Group "SQLADM" as group for SQL Administrators
       Required firewall ports are also being created at the end of this script
.NOTES
       Name: SQL Server+SQL MS Installation
       Author : Roman Levchenko
       WebSite: www.rlevchenko.com
       Prerequisites: all installed + you need to provide args (domain password + password for SQL Services)

#>

Start-Transcript -Path c:\output.txt
#Variables
$dpass = $args[0]
$spass = $args[1]
$dsecpass = convertto-securestring $dpass -asplaintext -force
$svcsecpass = convertto-securestring $spass -asplaintext -force
$netbios = (Get-ADDomain -Identity (gwmi WIN32_ComputerSystem).Domain).NetBIOSName
$credential = New-Object System.Management.Automation.PsCredential -ArgumentList "$netbios\Administrator", $dsecpass

#################
#Disk Operations#
#################

$disk = get-disk | ? { $_.Size -eq "107374182400" -and $_.ProvisioningType -eq "Thin" }
Initialize-Disk $disk.Number
New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter S
Get-Partition -DiskNumber $disk.Number | Format-Volume -FileSystem NTFS -Force -Confirm:$false -ErrorAction SilentlyContinue

##################
#SQL Installation#
##################

New-ADUser -Name SQLSVC -Credential $credential -AccountPassword $svcsecpass -PasswordNeverExpires $true -Enabled $true
New-ADUser -Name SQLAGSVC -Credential $credential -AccountPassword $svcsecpass -PasswordNeverExpires $true -Enabled $true
New-ADUser -Name SQLRSSVC -Credential $credential -AccountPassword $svcsecpass -PasswordNeverExpires $true -Enabled $true
New-ADGroup -Credential $credential -Name SQLADM -Description "SQL ADMINISTRATORS" -GroupScope Global -GroupCategory Security
Add-ADGroupMember -Identity SQLADM -Members "Domain Admins" -Credential $credential
cmd /c """C:\Program Files\Microsoft SQL Server\110\Setup Bootstrap\SQLServer2012\Setup.exe""" /ACTION=""CompleteImage"" /Q /PID=""key here"" /INSTANCENAME=""MSSQLSERVER"" /INSTANCEID=""MSSQLSERVER"" /AGTSVCACCOUNT=""$netbios\SQLAGSVC"" /AGTSVCPASSWORD=""$spass"" /AGTSVCSTARTUPTYPE=""Automatic"" /SQLSVCSTARTUPTYPE=""Automatic"" /SQLCOLLATION=""Latin1_General_CI_AS"" /SQLSVCACCOUNT=""$netbios\SQLSVC"" /SQLSVCPASSWORD=""$spass"" /SQLSYSADMINACCOUNTS=""$netbios\SQLADM"" /SQLBACKUPDIR=""S:\SQLBackup"" /SQLUSERDBDIR=""S:\Databases"" /SQLUSERDBLOGDIR=""S:\SQLLogs"" /SQLTEMPDBDIR=""S:\SQLTempDB"" /ADDCURRENTUSERASSQLADMIN=""False"" /TCPENABLED=""1"" /NPENABLED=""0"" /BROWSERSVCSTARTUPTYPE=""Automatic"" /RSSVCAccount=""$netbios\SQLRSSVC"" /RSSVCPASSWORD=""$spass"" /IACCEPTSQLSERVERLICENSETERMS /INSTALLSQLDATADIR=""S:\SQLServer2012Data"" | Out-Null
###############################################
#Enabling SQL Server Ports in Windows Firewall#
###############################################

#SQL Basic Ports
New-NetFirewallRule -DisplayName “SQL Server” -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName “SQL Admin Connection” -Direction Inbound –Protocol TCP –LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName “SQL Database Management” -Direction Inbound –Protocol UDP –LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName “SQL Service Broker” -Direction Inbound –Protocol TCP –LocalPort 4022 -Action allow
New-NetFirewallRule -DisplayName “SQL Debugger/RPC” -Direction Inbound –Protocol TCP –LocalPort 135 -Action allow
#SQL Analysis Ports
New-NetFirewallRule -DisplayName “SQL Analysis Services” -Direction Inbound –Protocol TCP –LocalPort 2383 -Action allow
New-NetFirewallRule -DisplayName “SQL Browser” -Direction Inbound –Protocol TCP –LocalPort 2382 -Action allow
#Open HTTP/SSL
New-NetFirewallRule -DisplayName “HTTP” -Direction Inbound –Protocol TCP –LocalPort 80 -Action allow
New-NetFirewallRule -DisplayName “SSL” -Direction Inbound –Protocol TCP –LocalPort 443 -Action allow
New-NetFirewallRule -DisplayName “SQL Server Browse Button Service” -Direction Inbound –Protocol UDP –LocalPort 1433 -Action allow
#Pors required by Skype/Lync
Get-NetFirewallRule -DisplayName *"remote service management"* | Enable-NetFirewallRule -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayName *"windows management"* | Enable-NetFirewallRule -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayName *"windows remote management"* | Enable-NetFirewallRule -ErrorAction SilentlyContinue
#Availability Groups
New-NetFirewallRule -DisplayName “SQL AG 5022 TCP” -Direction Inbound –Protocol TCP –LocalPort 5022 -Action allow
New-NetFirewallRule -DisplayName “SQL AG 5022 UDP” -Direction Inbound –Protocol UDP –LocalPort 5022 -Action allow

#####################################
#SQL Management Studio Installation#
#####################################
cmd /c """C:\SQLMS\Setup.exe""" /ACTION=""Install"" /Q /INSTANCEID=""MSSQLSERVER"" /INSTANCENAME=""MSSQLSERVER"" /FEATURES=""SSMS, ADV_SSMS"" /IACCEPTSQLSERVERLICENSETERMS"" | Out-Null
Remove-Item -Path C:\SQLMS -Recurse -Force

#AlwaysOn
Enable-SqlAlwaysOn -ServerInstance $env:computername -Force