import-module activedirectory
write-host "Login de l'utilisateur a tester "
$myuser = read-host
 
Get-ADUser -Identity $myuser -Properties name| ft Name
write-host "Le mot de passe expirera le :"
 [datetime]::FromFileTime((Get-ADUser -Identity $myuser -Properties "msDS-UserPasswordExpiryTimeComputed")."msDS-UserPasswordExpiryTimeComputed")
