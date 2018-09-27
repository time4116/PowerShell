# If you would like to connect to your update server via the c# namespace

$WSUSServer = yourserver
$WSUSPort = 8530 # Or your port

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WSUSServer, $false, $WSUSPort);

# Get all the updates that are driver updates
$drivers = $wsus.GetUpdates() | Where-Object {$_.UpdateClassificationTitle -eq 'Drivers'}

# Delete each driver in the $drivers array. This is very slow!
$drivers|ForEach-Object {$wsus.DeleteUpdate($_.Id.UpdateId.ToString()); Write-Host $_.Title removed}

# Create a bunch of PowerShell jobs to speed up the above process
$maxConcurrentJobs = 16 #Max. number of simultaneously running jobs

foreach ($drive in $drivers) {
    
    $Check = $false #Variable to allow endless looping until the number of running jobs will be less than $maxConcurrentJobs.
    while ($Check -eq $false) {
        if ((Get-Job -State 'Running').Count -lt $maxConcurrentJobs) {
            $jobs = (Get-Job -State 'Running').Count
            # write-host "There are $jobs running"
            $driveid = $drive.Id.UpdateId.ToString()
            Start-Job -scriptblock {
                # I tried storing lines 29 and 30 in a $wsus variable but it would change the object and not actually
                # delete the update when I called the variable via -ArgumentList.
            
                [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
                $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WSUSServer, $false, $Port);
                $wsus.DeleteUpdate($args[1]); Write-Host $args[0].Title removed} -ArgumentList $drive, $driveid         
                $Check = $true #To stop endless looping and proceed to the next object in the list.
        }
    }
}

# Run a report that lists all of the failed updates and the coresponding computer
# You'll need to use PoshWSUS module: https://github.com/proxb/PoshWSUS

Import-Module "Path to where you saved the module"

Connect-PoshWSUSServer $WSUSServer -port $WSUSPort
$clients = Get-PoshWSUSUpdateSummaryPerClient|Where-Object FailedCount|select UpdateTitle,Computer,FailedCount
$results = foreach ($cli in $clients) {(Get-PoshWSUSClient $cli.Computer).GetUpdateInstallationInfoPerUpdate()|Where-Object UpdateInstallationState -Match Failed}
$results|Select-Object UpdateTitle, UpdateKB, ComputerName, TargetGroup, UpdateInstallationState|export-csv C:\temp\FailedUpdateInstall.csv -NoTypeInformation
Disconnect-PoshWSUSServer
