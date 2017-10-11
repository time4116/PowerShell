# Short Script that searches a specified OU for all active accounts that do not have PasswordNeverExpires set to $True
# and user must change password at next login is not set, displays when the user account will expire and users that are out of the
# defined password policy and optionally send an email. Requires AD Module.

$OU = "OU=test,DC=test,DC=local"
$pwdPolicy = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
$list = Get-ADUser -SearchBase $OU -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False -and pwdLastSet -ne 0} `
–Properties SamAccountName,Mail,msDS-UserPasswordExpiryTimeComputed,PasswordLastSet,LastLogonDate

$list|ForEach-Object{
$Userl = $_.SamAccountName
$mail = $_.Mail

$pwdLife = ((Get-Date) - $_.PasswordLastSet).Days
$pwdExpiration = $pwdPolicy - $pwdLife

    if ($pwdLife -le ($pwdPolicy + 1)){     # Calculate the remaning days left in the password policy before expiration
        write-host "$Userl password will expire in $pwdExpiration days"
        
        if ($pwdExpiration -le 21){         # If the password will expire in 3 weeks or less, send email.
            write-host "Email sent to $Mail" -ForegroundColor Green
            #Send-MailMessage -SmtpServer test@test.com -From adtest@test.com -To $_.Mail -Subject "Password Report" -Body "This is a test"
                }
            }
    else{
        Write-Host "$Userl Password out of cycle. $pwdLife" -ForegroundColor red
                }
            }
