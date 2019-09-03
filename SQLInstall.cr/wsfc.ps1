$netbios = (Get-ADDomain -Identity (gwmi WIN32_ComputerSystem).Domain).NetBIOSName    
$witness = '\\' + $netbios + '\sqlcl'
New-Cluster -Name SQLFCI -Node $env:computername -StaticAddress "ip here" -NoStorage
Set-ClusterQuorum -NodeAndFileShareMajority $witness