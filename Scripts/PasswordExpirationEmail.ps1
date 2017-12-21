<#

Password expiration email script
Make sure to specify $logfile, $htmlpath, $htmlfilename, and have the AD Module installed for PowerShell

This script will perform the following:

		OU’s targeted:
		                OU=test,DC=test,DC=local 
		                OU=test,DC=test,DC=local
		 
		Condition:
		                AD Account is Enabled
		                AD Account does not have PasswordNeverExpires set
		                AD Account password will expire in exactly 21 days
		 
		Action:
		                AD Account will be emailed with communication specified in $htmlfilename var
		 
		What will be Logged:
		                AD Account emailed

		When the script is finished a report with the effected users will be sent to test@test.com
#>

$startdate = get-date
$enddate = get-date 2018-4-19
$logdate = get-date -format d # MM/DD/YYYY

if (($startdate) -le ($enddate))
	{	
	
	Import-module ActiveDirectory
	
	$pwdPolicy = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
    
   	$report = '' # Clear contents of report variable before processing script
	
    	# Make sure to set the following vars below (CONFIRM THESE)
   	$logfile = "C:\temp\PasswordEmail\email_pass_report.log"
    	$htmlpath = "C:\temp\PasswordEmail\" # Be sure to include \ at the end of the path
	$htmlfilename = 'Example.htm'

	$OUs = "OU=test,DC=test,DC=local","OU=test,DC=test,DC=local"
	$List = ForEach ($OU in $OUs){
		Get-ADUser -SearchBase $OU -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False -and pwdLastSet -ne 0} –Properties GivenName,SamAccountName,Mail,msDS-UserPasswordExpiryTimeComputed,PasswordLastSet,LastLogonDate
	                             } # End

	$list|ForEach-Object{
	$Userl = $_.SamAccountName
	$UserFirstName = $_.GivenName
	$mail = $_.Mail
	$pwdLife = (($startdate) - $_.PasswordLastSet).Days
	$pwdExpiration = $pwdPolicy - $pwdLife

            	# Condition: User must still be in the password cycle and password must expire in exactly 21 days.
		if ($pwdExpiration -eq 21 -and $pwdlife -le ($pwdPolicy + 1)){
		$date = ($startdate).AddDays($pwdExpiration)
		$date = $date.DateTime -replace ',\W[2](.*?)*M','' # Strip off year and time using regular expressions
                
                # Remove below comment to check debugging...
		#Write-host "Email sent to $Mail. Expiration in $pwdExpiration days" -ForegroundColor Green
		Add-Content $logfile "$logdate:_______________Email sent to $Mail. Expiration in $pwdExpiration or $(($startdate).AddDays($pwdExpiration))."

		# Add each user to report variable
		$report += "Email sent to $Mail. Expiration in $pwdExpiration days or on $(($startdate).AddDays($pwdExpiration)). `n"

	            # Takes the HTML template and replaces the text on the left with username and date.
                $html = get-content ($htmlpath + $htmlfilename) -raw
			$var = foreach ($i in $html){
			$i -replace "UserFirstName","$UserFirstName"
						    }# End
			$var = foreach ($i in $var){
			$i -replace "123Date","$date"
						}# End
		$var|out-file ($htmlpath + $htmlfilename + '_replaced.htm') -Encoding ascii

                # Send email to user that meets condition
		Send-MailMessage -SmtpServer mail.test.com -From notifications@test.com -To $mail -Subject "Your Password Is Expiring!" -body $var -BodyAsHtml
				                                               
                                                            		} # End 2nd if statement
				            } # End for loop
				
                # Send report with users who were sent an email
                Send-MailMessage -SmtpServer mail.test.com -From notifications@test.com -To "test@test.com" -Subject "Report Date: $logdate - AD User Password Expiration Email (21 Days)." -body $report
	
    } # End 1st if statement

else
    {
    # Send email to user to decomission script
    Send-MailMessage -SmtpServer mail.test.com -From notifications@test.com -To "test@test.com" -Subject "Please Confirm Password Email Script Is Disabled! $pwdPolicy Day Limit Reached." -body "Located on SERVER as a scheduled task"
    }	
