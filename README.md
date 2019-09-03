# Automate SQL Server AlwaysOn configuration
PowerShell Scripts install SQL Server on both nodes and configure WSFC with AlwaysOn feature. Tested and verified with SQL Server, however, work with later versions as well (some minor changes might be required). I was used the scripts with VMM templates, so args used in some places. Provide just your values.
- Domain.cr : custom resouce with PS script that adds machine to the domain
- SQLInstall.cr : custom resource with PS scripts to install and configure SQL Server
- SQLInstall2.cr : custom resource with PS scripts to install and configure a second SQL Server node
- Result: 2 SQL Servers running in the AlwaysOn-enabled cluster