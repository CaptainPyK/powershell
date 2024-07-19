$pluginname = "httpd/iis"
$pluginreturn = @{}

function get-srvosversion (){
    $WinEdition=(Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    if ($WinEdition-like "Microsoft Windows Server*"){
        return $true
    }
    else {
        return $false
    }
}

function get-prerequisiteiis (){
    $iisinstalled=Get-WindowsFeature | Where-Object {$_.InstallState -eq 'Installed' -and $_.name -eq 'Web-Server'}
    $iisadmintools= get-module | where-object {$_.name -eq "IISAdministration"}
    if (!$iisinstalled){
        #Write-host "IIS is not installed on this server"
        return $false
    }
    else 
    {    
        if (!$iisadmintools) {
            try {
                Install-PackageProvider -Name Nuget -force
                Set-PSRepository PSGallery -InstallationPolicy Trusted
                Install-Module -Name 'IISAdministration'
                return $true
            }
            catch{
                Write-host "issue to install 'IISAdministration' module"
                return $false
                }
            
        }
        else{
            return $true
        }

    }
}

function get-bind(){
        $hashresult=@{}
        $allbind=@()
        $iissites=Get-IISSite | Select-Object Name,Bindings
        $protocol=@('http','https')
        #We parse the iis site
        foreach ($iissite in $iissites){
            $Bindings = $iissite.Bindings
            #Now we parse the all the bindings in a iis site
            foreach ($Binding in $Bindings){
            if ($protocol -contains $Binding.protocol ){
                #only http and https site, if needed please add protocol in $protocol
                #We only retrieve the vhost
                $bindbrut=$Binding.bindingInformation
                $bind=($bindbrut.split(':'))[2]

                #if vhost is empty, the bind is default
                if($bind -notmatch "\S"){
                    #write-host "DefaultWebSite"
                    $bind = "DefaultWebSite"
                }

                #We add the vhost in list $allbind only if is not already present
                if($allbind -notcontains $bind){
                    $allbind += $bind
                }
            }
            }
            
        }
        $hashresult['vhosts']=$allbind
        return $hashresult
}

if(get-srvosversion){
    #write-host "os ok"
    if (get-prerequisiteiis){
        #write-host "iis ok"
        $allvhosts=get-bind
        $pluginreturn[$pluginname]=$allvhosts
        return $pluginreturn
        #ConvertTo-Json $pluginreturn -depth 10
    }
    else{
        #write-host "iis not installed or problem with powershel module IISAdministration"
        exit
    }
}
else{
    #write-host "os not supported for iis"
    exit
}
