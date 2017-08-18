# Loads the PowerShell snap-in needed for PowerCLI commands
Add-PSSnapin VMware.VimAutomation.Core
$VIServer = 'vCenter Server'

Connect-VIServer -Server $VIServer # This will use account that the script is run from

# Creates a clean and easy to read spreadsheet
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>

# SizeGB is rounded to make it easier on us

$Report = Get-VM | Get-Snapshot | Select VM,Name,Description,@{Label="SizeGB";Expression={"{0:N2}" -f ($_.SizeGB)}},Created
If (-not $Report) # If there are no snapshots you will get a report stating so
{ $Report = New-Object PSObject -Property @{
 VM = "No snapshots found on any VM's controlled by $VIServer"
 Name = ""
 Description = ""
 Size = ""
 Created = ""
 }
}

$NumberOfSnaps = $Report.count # Could the total number of snapshots
$SnapTotal = ($Report|Measure-Object 'SizeGB' -Sum).Sum # Count the total storage consumed by snapshots

$Report = $Report | Select VM,Name,Description,SizeGB,Created | ConvertTo-Html -Head $Header # ` = continue on next line
-PreContent "<p><h2>Current Snapshots: $NumberOfSnaps | Total GB: $SnapTotal</h2></p><br> # -PreContent = What will show up in body of email before the html table.
$Report | Out-File c:\PowerCLI\SnapShotReport.html

$Body = get-content c:\PowerCLI\SnapShotReport.html|out-string # PS 2.0 "get-content" does not have "-raw" flag so "out-string" was used instead
(Send-MailMessage -SmtpServer "Enter Mail Server" -From "Enter Sender Address" -To "Enter Recipient Address" -Subject "vCenter - Current Snapshot Report" `
-Body $Body -BodyAsHtml)
