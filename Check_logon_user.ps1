$logging = $true
$logFile = "C:\logfolder\hystorylogon_user-"+ [System.DateTime]::Now.ToString("-yyyy_MM_dd_hhmm") + ".log"

 if ( $logging )
{
    # Test Log File Path
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True")
    {
        # Create CSV File and Headers
        New-Item $logfile -ItemType File
        Add-Content $logfile "eventcreated,UserAccount,UserDomain,LogonType,WorkstationName,SourceNetworkAddress"
    }
  }


 enum LogonTypes {
            Interactive = 2
            Network = 3
            Batch = 4
            Service = 5
            Unlock = 7
            NetworkClearText = 8
            NewCredentials = 9
            RemoteInteractive = 10
            CachedInteractive = 11
        }

$filter = @{
    LogName = 'Security'
    ID = 4624
    StartTime = [datetime]::Now.AddHours(-2) 
}
$events=Get-WinEvent -FilterHashTable $filter

foreach ($event in $events) {

        $eventcreated = $event.TimeCreated
        $UserAccount = $event.Properties.Value[5]
        $UserDomain = $event.Properties.Value[6]
        $LogonType = [LogonTypes]($event.Properties.Value[8])
        $WorkstationName = $event.Properties.Value[11]
        $SourceIPAddress = $event.Properties.Value[18]



if (($event.Properties.Value[8] -eq "2") -and ($UserAccount -notlike "UMFD-*") -and  ($UserAccount -notlike "DWM-*"))
{
Write-Host "INTERACTIVE"
Write-Host  $eventcreated,$LogonType,$UserAccount,$UserDomain,$WorkstationName,$SourceIPAddress
Write-Host "---"
Add-Content $logfile "$eventcreated,$LogonType,$UserAccount,$UserDomain,$WorkstationName,$SourceIPAddress"
}
if (($event.Properties.Value[8] -eq "10") -and ($UserAccount -notlike "UMFD-*") -and  ($UserAccount -notlike "DWM-*"))
{
Write-Host "REMOTE INTERACTIVE"
Write-Host  $eventcreated,$LogonType,$UserAccount,$UserDomain,$WorkstationName,$SourceIPAddress
Write-Host "---"
Add-Content $logfile "$eventcreated,$LogonType,$UserAccount,$UserDomain,$WorkstationName,$SourceIPAddress"
}

}
