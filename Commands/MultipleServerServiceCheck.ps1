
#Machines to be monitored 
$Computers = @('PC1','PC2','PC3','PC4')
$Path = 'C:\temp\Blah Service Monitor' 

#Create an array of all services running 
$GetService = foreach ($comp in $Computers) {get-service -ComputerName $Comp| where {$_.Name -like "Blah*"}}

#Find any Blah service that is stopped
foreach ($comp in $computer){
foreach ($Service in $GetService) 
{ 
            $S_Name = $Service.Name
            $Machine = $Service.MachineName
            #check if a service is hung 
            if ($Service.status -eq "StopPending") 
            { 
            #email to notify if a service is down 
            Send-Mailmessage -to blah@domain.com -Subject "$S_Name is hung on $Machine" -from blahmonitor@domain.com-Body "The $S_Name service was found hung and has been re-started" -SmtpServer blahsmtp@domain.com
            $servicePID = (gwmi win32_Service | where { $_.Name -eq $S_Name}).ProcessID 
            Stop-Process $ServicePID 
            Start-Service -Name $S_Name -PassThru | Format-List >> "$Path\Results_Service_Hung.txt"
            $GetService | Format-List Name,Status >> "$Path\Service_Hung.txt"
            }
            elseif ($Service.status -ne "Running") 
            { 
            #email to notify if a service is down 
            Send-Mailmessage -to blah@domain.com -Subject "$S_Name is stopped on $Machine" -from blahmonitor@domain.com-Body "The $S_Name service was found stopped and has been re-started" -SmtpServer blahsmtp@domain.com
            #automatically restart the service. 
            Start-Service -Name $S_Name -PassThru | Format-List >> "$Path\Results_Service_Stopped.txt"
            net start "$S_Name" >> "$Path\NetLog_Stopped.txt"
            $GetService | Format-List Name,Status >> "$Path\Service_Stopped.txt"
            } 
        } 
     }
   
#Return execution policy to RemoteSigned
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
