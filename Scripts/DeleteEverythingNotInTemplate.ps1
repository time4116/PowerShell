$logfile = "C:\TEMP\logfile.log"
Remove-Item $logfile -force -ErrorAction Ignore

# Capture the FOLDER_template directory and exclude those folders or files (from being deleted) from the FOLDER directory
$template = (Get-ChildItem C:\FOLDER_template -Recurse -Force).Fullname

# For comparisson with the logfile (Just for testing)
$template|out-file "C:\TEMP\snapshot.log"

# Replace the path for each item in the array to match FOLDER
$excluded = foreach ($i in $template)
    { 
        $i -replace "FOLDER_template","FOLDER"
    }

# Get list of files to be deleted on (FOLDER)
$list = Get-ChildItem C:\FOLDER -Recurse| Where {$name = $_.Fullname; ($excluded | Where {$name -like $_}).count -eq 0}

# Delete all files not explicitly specified in the $excluded variable (FOLDER_template)	
foreach ($i in $list)
    {
    $path = $i.Fullname

    try {
        if (test-path $path){
            
            Remove-Item $i.fullname -Force -Recurse -ErrorAction stop -ErrorVariable x
            Add-Content $logfile "Performing the operation Remove File on target: $path"
        }
       }
    catch {
        # Log all errors except if file does not exist (because of if statement (test-path $path))
        Add-Content $logfile "___________________Could not delete the following file $path because of the following error: `
            `
        $x  `
        "
       }
      } 
