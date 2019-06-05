$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$CompanyName = 'CROPP Cooperative'
$DomainName = 'CROPP'
$HostName = 'MBAM01.dev.cropp.com'
$RecoveryDatabaseName = 'MBAMRecoveryandHardware'
$ComplianceDatabaseName = 'MBAMComplianceStatus'
$ReportReadWriteAccount = "$DomainName\mbamdbarw"
$AppPoolAccount = "$DomainName\mbamapppool"
$AccessAccount = "$DomainName\G_MBAM_DB_RW"
$ReportAccount = "$DomainName\G_MBAM_Compliance_R"
$HelpdeskAccessGroup = "$DomainName\G_MBAM_HelpDesk"
$ReportsReadOnlyAccessGroup = "$DomainName\G_MBAM_Reporting"
$AdvancedHelpdeskAccessGroup = "$DomainName\G_MBAM_AdvHelpDesk"
$ReportUrl = "http://$HostName/ReportServer"
$ConnectionString = "Data Source=$HostName;Integrated Security=True"
$ComplianceAndAuditDBConnectionString = "Data Source=$HostName;Initial Catalog=MBAMComplianceStatus;Integrated Security=True"
$RecoveryDBConnectionString = "Data Source=$HostName;Initial Catalog=MBAMRecoveryandHardware;Integrated Security=True"

$secpasswd = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$ReportReadWriteAccountCred = New-Object System.Management.Automation.PSCredential ($ReportReadWriteAccount, $secpasswd)
$AppPoolAccountCred = New-Object System.Management.Automation.PSCredential ($AppPoolAccount, $secpasswd)
#$AccessAccountCred = New-Object System.Management.Automation.PSCredential ($AccessAccount, $secpasswd)
#$ReportAccountCred = New-Object System.Management.Automation.PSCredential ($ReportAccount, $secpasswd)

# Install MBAM Server
$ArgumentList = "/quiet CEIPENABLED=False OPTIN_FOR_MICROSOFT_UPDATES=False"
Start-Process (Join-Path $scriptDir "MbamServerSetup.exe") -ArgumentList $ArgumentList -Wait

#Load MBAM Powershell Module
Import-Module 'C:\Program Files\Microsoft BitLocker Administration and Monitoring\WindowsPowerShell\Modules\Microsoft.MBAM'

# Enable compliance and audit database
Enable-MbamDatabase -AccessAccount $AccessAccount -ComplianceAndAudit -ConnectionString $ConnectionString -DatabaseName $ComplianceDatabaseName -ReportAccount $ReportAccount

# Enable recovery database
Enable-MbamDatabase -AccessAccount $AccessAccount -ConnectionString $ConnectionString -DatabaseName $RecoveryDatabaseName -Recovery

# Enable report feature
Enable-MbamReport -ComplianceAndAuditDBConnectionString $ComplianceAndAuditDBConnectionString -ComplianceAndAuditDBCredential $ReportReadWriteAccountCred -ReportsReadOnlyAccessGroup $ReportsReadOnlyAccessGroup

# Enable agent service feature
Enable-MbamWebApplication -AgentService -CMIntegrationMode -ComplianceAndAuditDBConnectionString $ComplianceAndAuditDBConnectionString -TpmLockoutAutoReset -WebServiceApplicationPoolCredential $AppPoolAccountCred

# Enable administration web portal feature
Enable-MbamWebApplication -AdministrationPortal -AdvancedHelpdeskAccessGroup $AdvancedHelpdeskAccessGroup -CMIntegrationMode -ComplianceAndAuditDBConnectionString $ComplianceAndAuditDBConnectionString -HelpdeskAccessGroup $HelpdeskAccessGroup -HostName $HostName -InstallationPath 'C:\inetpub' -Port 80 -RecoveryDBConnectionString $RecoveryDBConnectionString -ReportsReadOnlyAccessGroup $ReportsReadOnlyAccessGroup -ReportUrl $ReportUrl -VirtualDirectory 'HelpDesk' -WebServiceApplicationPoolCredential $AppPoolAccountCred

# Enable self service web portal feature
Enable-MbamWebApplication -CompanyName $CompanyName -ComplianceAndAuditDBConnectionString $ComplianceAndAuditDBConnectionString -DisableNoticePage -HelpdeskUrlText 'Contact the IT Helpdesk.' -HostName $HostName -InstallationPath 'C:\inetpub' -Port 80 -RecoveryDBConnectionString $RecoveryDBConnectionString -SelfServicePortal -VirtualDirectory 'SelfService' -WebServiceApplicationPoolCredential $AppPoolAccountCred