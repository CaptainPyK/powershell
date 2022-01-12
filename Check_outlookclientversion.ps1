#On se connecte au serveur AD pour pouvoir lancer des requetes sur les comptes AD

$ADServer = "AD_serverName"
$ADConnection = New-PSSession -ComputerName $ADServer
Import-Module -PSsession $ADConnection -Name ActiveDirectory

# on stocke les comptes utilisateurs dans une varaible pour plus tard
$users= get-aduser -filter * -SearchBase "Specified OU BASE" -properties name,legacyExchangeDN,mail

#hashtable pour pouvoir afficher les version de Outlook par la suite

$outlookversion = @{
    '8' = 'Outlook 97-98'
    '9' = 'Outlook 2000'
    '10' = 'Outlook XP/2002'
    '11' = 'Outlook 2003'
    '12' = 'Outlook 2007'
    '14' = 'Outlook 2010'
    '15' = 'Outlook 2013'
    '16' = 'Outlook 2016-2019'

}


# Chemin des logs RPC Client

$logpath = 'C:\Program Files\Microsoft\Exchange Server\V15\Logging\RPC Client Access'

# On récupere la liste les logs des 3à derniers jours dans le répertoires des logs exchange.
$files = Get-ChildItem $logpath |Where-Object {$_.LastWriteTime -ge (Get-Date).AddDays(-30)}



# On inspecte les logs
$logs = $files | ForEach-Object {Get-Content $_.FullName}| Where-Object {$_ -notlike '#*'}
 
# On converti le fichier de logs en objet powershell
$results = $logs |ConvertFrom-Csv -Header date-time,sessionid,seqnumber,clientname,organization-info,clientsoftware,clientsoftwareversion,clientmode,clientip,serverip,protocol,applicationid,operation,rpcstatus,processingtime,operationspecific,failures
 
# On récupere uniquement les lignes outlook est mentionne
$results= $results | Where-Object {$_.'clientsoftware' -eq 'OUTLOOK.EXE'} | select-object clientsoftware,clientsoftwareversion,clientmode,clientname | sort-object -Property client-software-version

#On va pour chaque ligne crꦲ un object powershell qui va avoir pour propriete le nom du client, la version du client outool ainsi que l'utilisation du mode cache
foreach ($result in $results)
{
#Version du client outlook
$outlookversionclient =  $result.clientsoftwareversion
#le mode client utilise par outlook
$outlookcache =  $result.clientmode
#Cette variable correspond au LegacyExchangeDN
$brutnameclient = $result.clientname

#on indique juste par un boolean si le client est en cache ou non
if ( $outlookcache -eq "Cached")
{
$cacheactive = $true
}
else
{
$cacheactive= $false    
}
#on split la varialble de version d'oulook et on recupere la premiere valeur
$outlookversionclient = ($outlookversionclient.split('.'))[0]

# On crꥠun object
$clientoutlook = @{
    ModeCacheactive = $cacheactive
    OutlookEdition = $outlookversion[$outlookversionclient]
    #On affiche le compte afficher a partir de la propriete LegacyExchangeDN
    Username = ($users|Where-Object -Property legacyExchangeDN -eq $brutnameclient  | Select-Object name).name
    Mail = ($users|Where-Object -Property legacyExchangeDN -eq $brutnameclient  | Select-Object mail).mail
}

[PSCustomObject]$clientoutlook

}
Remove-PSSession -Session $ADConnection
