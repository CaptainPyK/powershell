$pluginname = "system/softwares"
$pluginreturn = @{}

$ecritelgenericfeatures= @("AD-Certificate","AD-Domain-Services","ADFS-Federation","ADLDS","ADRMS","DHCP","DNS","Print-Server","VolumeActivation","Web-WebServer","Web-Ftp-Server","WDS","UpdateServices","NET-Framework-Features","NET-Framework-45-Core","NET-Framework-45-ASPNET","Windows-Server-Backup")
$ecritelrdsfeatures= @("RDS-Connection-Broker","RDS-Gateway","RDS-Licensing","RDS-RD-Server","RDS-Web-Access")
$ecritelfilefeatures= @("FS-FileServer","FS-Data-Deduplication","FS-DFS-Namespace","FS-DFS-Replication","FS-Resource-Manager")
$ecritelallfeatures=$ecritelgenericfeatures+$ecritelrdsfeatures+$ecritelfilefeatures


function get-srvosversion (){
    $WinEdition=(Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    if ($WinEdition-like "Microsoft Windows Server*"){
        return $true
    }
    else {
        return $false
    }
}


function get-featureinstalled () {
    $featureinstalled=(Get-WindowsFeature | where-object {$_.installed}| select-object Name,DisplayName)
    return $featureinstalled

}

function get-exchangeinstalled-version () {
    if (Test-Path "$env:exchangeinstallpath\bin\ExSetup.exe") {
        $exchangereturn = @()
        $exchangeserverinfos = @{}
        $msexchversion = $([System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:exchangeinstallpath\bin\ExSetup.exe").FileVersion)
      
        switch -Wildcard ($msexchversion){
        '15.02.*'{$mexchdescription = 'Microsoft Exchange Server 2019'}
        '15.01.*'{$mexchdescription = 'Microsoft Exchange Server 2016'}
        '15.00.*'{$mexchdescription = 'Microsoft Exchange Server 2013'}
        '14.*'{$mexchdescription = 'Microsoft Exchange Server 2010'}
        }


        $exchangeinfos = [ordered]@{
            version = $msexchversion
            description = $mexchdescription
        }
        $exchangeserverinfos.add('Exchange-Server',$exchangeinfos)
        $exchangereturn=$exchangeserverinfos
        return $exchangereturn
    }
    
}

function get-mssqlinstalled-version () {
    $instancesname= @()
    if (Test-Path -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL') {
        $sqlinstanceserverreturn = @()
        $sqlinstanceserverinfos = @{}
        $instances= (Get-Item -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').property  
        foreach ($instance in $instances) {
            $instancesname += Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -name $instance
        } 
        foreach ($instancename in $instancesname) {
            if (test-path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\$instancename\Setup") {
                $instanceinfo=get-itemproperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\$instancename\Setup" | select-object PatchLevel,Edition
                switch -Wildcard ($instanceinfo.PatchLevel){
                '16.*'{$mssqldescrition= "MS SQL Server 2022"}
                '15.*'{$mssqldescrition= "MS SQL Server 2019"}
                '14.*'{$mssqldescrition= "MS SQL Server 2017"}
                '13.*'{$mssqldescrition= "MS SQL Server 2016"}
                '12.*'{$mssqldescrition= "MS SQL Server 2014"}
                '11.*'{$mssqldescrition= "MS SQL Server 2012"}
                '10.50.*'{$mssqldescrition= "MS SQL Server 2008 R2"}
                '10.0.*'{$mssqldescrition= "MS SQL Server 2008"}        
                }
                $sqlinstanceinfo = [Ordered]@{
                version = $instanceinfo.PatchLevel
                description = $mssqldescrition +" "+ $instanceinfo.Edition
                }
                $sqlinstanceserverinfos.add($instancename,$sqlinstanceinfo)        
            }
        }
        $sqlinstanceserverreturn=$sqlinstanceserverinfos
        return $sqlinstanceserverreturn
    }

}

function make-orderfeature ($somewinfeatures) {
    $allfeatures= @()
    $onefeature= @{}
    foreach ($feature in $somewinfeatures) {
        $onefeature= @{}
        $namefeature= $feature.name
        $displaynamefeature= $feature.DisplayName
        
        if($namefeature -in $ecritelallfeatures) {

            $currentfeature = [ordered]@{
                version = ''
                description = $displaynamefeature
            }

            $onefeature.add($namefeature,$currentfeature)
            $allfeatures+=$onefeature
        }



    }
    return $allfeatures

}


if(get-srvosversion){
    $featuresinplace=get-featureinstalled
    $result=make-orderfeature($featuresinplace)
    $result+=get-exchangeinstalled-version
    $result+=get-mssqlinstalled-version

    $pluginreturn[$pluginname]=$result

    return $pluginreturn

}
else{
    #write-host "os not supported for iis"
    exit
}
