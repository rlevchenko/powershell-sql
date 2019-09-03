# Automate SQL Server AlwaysOn configuration
PowerShell scripts to install SQL Server on both nodes and configure WSFC with AlwaysOn feature. Tested and verified with SQL Server 2012, however, works with later versions as well (some minor changes might be required). The scripts were used as a part of VMM templates, so args are used in some places. Provide just your values instead.
- Domain.cr : custom resource with PS script that adds machine to the domain
- SQLInstall.cr : custom resource with PS scripts to install and configure SQL Server
- SQLInstall2.cr : custom resource with PS scripts to install and configure a second SQL Server node
- Result: 2 SQL Servers running in the AlwaysOn-enabled cluster
