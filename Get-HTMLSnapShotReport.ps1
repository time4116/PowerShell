<#
.Synopsis
   Short function to gather VMware snapshots metrics and send an email report.

.DESCRIPTION
   Coming soon!

.EXAMPLE
    Get-HTMLSnapShotReport -VIServer vcenter.yourdomain.local -SmtpServer blah@yourdomain.com -to blah@yourdomain.com -from blahblah@yourdomain.com
#>

function Get-HTMLSnapShotReport {
[CmdletBinding()]
param (

[Parameter(Mandatory=$true)]
[string[]]$VIServer = 'Your vCenter Server', 

[Parameter(Mandatory=$true)]
[string]$SmtpServer = 'YourSMTPServer@yourdomain.com',

[Parameter(Mandatory=$true)]
[Alias('From')]
[string]$Sender = 'SnapShotReport@yourdomain.com',

[Parameter(Mandatory=$true)]
[Alias('To')]
[string]$Recipient = 'user@yourdomain.com'
)

    PROCESS {


Add-PSSnapin VMware.VimAutomation.Core

Connect-VIServer -Server $VIServer # Will use account that the script is run from

# Fancy Spreadsheet
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
"@


$Report = Get-VM | Get-Snapshot | Select VM,Name,Description,@{Label="SizeGB";Expression={"{0:N2}" -f ($_.SizeGB)}},Created
    If (-not $Report){
                     $Report = New-Object PSObject -Property @{
                            VM = "No snapshots found on any VM's controlled by $VIServer"
                            Name = ""
                            Description = ""
                            Size = ""
                            Created = ""
                              
                                  }
                               }

$NumberOfSnaps = $Report.count
$SnapTotal = ($Report|Measure-Object 'SizeGB' -Sum).Sum

$Report = $Report | Select VM,Name,Description,SizeGB,Created | ConvertTo-Html -Head $Header -PreContent "<p><h2>Current Snapshots: $NumberOfSnaps | Total GB: $SnapTotal</h2></p><br>"

$Body = get-content c:\PowerCLI\SnapShotReport.html|out-string # PS 2.0 "get-content" does not have "-raw" flag so "out-string" was used instead
(Send-MailMessage -SmtpServer $SmtpServer -From $Sender -To $Recipient -Subject "vCenter - Current Snapshot Report" -Body $Body -BodyAsHtml)
        
        }
}
