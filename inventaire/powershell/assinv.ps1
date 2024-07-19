
$currentpath=Split-Path -Path $MyInvocation.MyCommand.Path

$assinv = @{}
$general = @{}

$unixtimebrut=(New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds

[Int64]$unixtime=[System.Math]::Round($unixtimebrut)

$general['last_run']=$unixtime
$assinv = @{'general'=$general}


$Scripts=Get-ChildItem -path "$currentpath\plugins" -Recurse -Filter *.ps1

foreach($s in $Scripts){

    $scriptresult= Invoke-Expression -Command $s.FullName

    if($scriptresult){
        $assinv['plugins'] += $scriptresult
    }
}
#convertto-yaml -data $assinv
ConvertTo-Json $assinv -Depth 5
