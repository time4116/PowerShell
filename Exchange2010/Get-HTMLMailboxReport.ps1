<#
.Synopsis
   Short function to gather VMware snapshots metrics and send an email report.
.DESCRIPTION
   Coming soon!
.EXAMPLE
    Get-HTMLSnapShotReport -VIServer vcenter.yourdomain.local -SmtpServer blah@yourdomain.com -to blah@yourdomain.com -from blahblah@yourdomain.com
#>

function Get-HTMLMailboxReport {
[CmdletBinding()]
param (

[Parameter(Mandatory=$true)]
[string[]]$Path = 'C:\temp', 

[Parameter(Mandatory=$true)]
[string]$SmtpServer = 'YourSMTPServer@yourdomain.com',

[Parameter(Mandatory=$true)]
[Alias('From')]
[string]$Sender = 'MailboxReport@yourdomain.com',

[Parameter(Mandatory=$true)]
[Alias('To')]
[string]$Recipient = 'user@yourdomain.com'
)

    PROCESS {

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010

Get-MailboxDatabase -server $ExchangeServer | Get-MailboxStatistics `
| Where {($_.TotalItemSize -gt 20GB -and $_.DisplayName -notlike 'Personal*') -or `
($_.TotalItemSize -gt 40GB -and $_.DisplayName -like 'Personal*')} `
| Sort TotalItemSize, -Descending|Export-Csv $Path\HTMLReport.csv -NoTypeInformation

$List = Import-csv $Path\HTMLReport.csv

# Fancy Spreadsheet
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #B0C4DE;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
"@

$List = ($List|select `
@{label=”User”;expression={$_.DisplayName}}, `
@{label=”SizeGB”;expression={($_.TotalItemSize)}})

$NumberOfMailBoxes = $List.count

$List = $List| Select User,SizeGB|sort SizeGB -Descending |ConvertTo-Html -Head $Header -PreContent "<p><h2>$NumberOfMailBoxes Mailboxes over threshold!</h2></p><br>"


$Body = $list|out-string # PS 2.0 "get-content" does not have "-raw" flag so "out-string" was used instead
(Send-MailMessage -SmtpServer $SmtpServer -From $Sender -To $Recipient -Subject "ExchangeServer Mailbox Over 20GB; Archive Over 40GB" -Body $Body -BodyAsHtml)
}
}
