# Script to leverage client-side targeting in WSUS
# Creates a GPO for every OU specified in the CSV.
# Links the GPO to the OU in the CSV.

$data = Import-CSV C:\TEMP\WSUS_GPO.CSV

foreach ($line in $data) {
    $target_group = $line.WSUSGroup
    $gp_name = 'WSUS - ' + $line.OUName
    $ou_name = $line.DistinguishedName

    write-host "Creating new GPO: $gp_name"
        Copy-GPO -SourceName 'WSUS - Master Group' -TargetName $gp_name #-WhatIf
    write-host "Updating target group for: $target_group"
        Set-GPRegistryValue -name $gp_name -Key hklm\Software\Policies\Microsoft\Windows\WindowsUpdate -ValueName 'TargetGroup' -Value $target_group -Type String #-WhatIf
    write-host "Enabling group policy on the following location: $ou_name"
        new-GPLink -Name $gp_name -Target $ou_name -LinkEnabled Yes #-WhatIf
}