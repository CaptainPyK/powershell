$pluginname = "system/local_accounts"
$pluginreturn = @{}

$windowsgroup =@()

function get-languageaccountlocal (){


    if (Get-LocalGroup | where-object {$_.name -eq 'Administrateurs'}){
        $group=@("Administrateurs","Utilisateurs du Bureau à distance","Opérateurs de configuration réseau","Opérateurs de chiffrement","Opérateurs d’impression","Opérateurs de sauvegarde")
        return $group
    }
    else {
        $group=@("Administrators","Remote Desktop Users","Network Configuration Operators","Cryptographic Operators","Print Operators","Backup Operators")
        return $group
    }
}

function get-languageaccountad (){

     if (Get-ADGroup -Filter * | where-object {$_.Name -eq 'Administrateurs'}){
        $group=@("Administrateurs","Utilisateurs du Bureau à distance","Opérateurs de configuration réseau","Opérateurs de chiffrement","Opérateurs de serveur","Opérateurs d’impression","Opérateurs de sauvegarde")
        return $group
    }
    else {
        $group=@("Administrators","Remote Desktop Users","Network Configuration Operators","Cryptographic Operators","Server Operators","Print Operators","Backup Operators")
        return $group
    }

}


function get-localAccounts () {

    if (!(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        #This Computer is NOT in a DOMAIN
        $windowsgroup=get-languageaccountlocal
        $accounts =@()
        #$accounts=$windowsgroup | Get-LocalGroupMember | select-object name,ObjectClass,PrincipalSource,SID
        #foreach to avoid multiple same accounts.
        foreach ($group in $windowsgroup){
            $acc=$group| Get-LocalGroupMember | select-object name,ObjectClass,PrincipalSource,SID
            if ($accounts.name -notcontains $acc.name) {
                $accounts += $acc
            }
        }
        return $accounts
    }
    
    if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        $Domainrole=(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

        #This Computer is IN a DOMAIN
        if ($Domainrole -eq '2')
        {
            #This Computer is a Domain Controller
            $windowsgroup=get-languageaccountad
            $acc= @()
            #$acc=$windowsgroup | Get-ADGroupMember | select-object name,ObjectClass,PrincipalSource,SID
            #foreach to avoid multiple same accounts.
            foreach ($group in $windowsgroup){
                $accprov=$group| Get-ADGroupMember | select-object name,ObjectClass,PrincipalSource,SID
                if ($acc.name -notcontains $accprov.name) {
                    $acc += $accprov
                }
            }


            $accounts = @()
            foreach ($ac in $acc){

                $objacc = [ordered]@{
                    name= $ac.name
                    ObjectClass= $ac.ObjectClass
                    PrincipalSource= "Active Directory"
                    SID=$ac.SID
                }
                $accounts += $objacc
            }
            return $accounts
        }
        else {
            #This Computer is a server or workstation
            $windowsgroup=get-languageaccountlocal
            #$accounts=$windowsgroup | Get-LocalGroupMember | select-object name,ObjectClass,PrincipalSource,SID
            $accounts =@()
            #foreach to avoid multiple same accounts.
            foreach ($group in $windowsgroup){
                $acc=$group| Get-LocalGroupMember | select-object name,ObjectClass,PrincipalSource,SID
                if ($accounts.name -notcontains $acc.name) {
                    $accounts += $acc
                }
            }

            return $accounts
        }
    }
}

function organizeaccounts($objectsaccounts){
    
    $userlist= @()
    foreach($a in $objectsaccounts) {
        $userdict=@{}
        $SID=[string]($a.SID)
        if(($a.name).split("\").count -gt 1){
            #Local acount "NETBIOSSRVNAME\user"
            $name=[string]($a.name).split("\")[1]
        }
        else{
            #AD Account is without \
            $name=[string]($a.name)
        }
        
        $PrincipalSource=[string]$a.PrincipalSource
        $type=[string]$a.ObjectClass

        $account = [ordered]@{
            gid =''
            uid = '' #($SID.replace('-','')).Substring($SID.IndexOf('S')+1) #ou .Substring(1) :)
            home = ''
            name = $name
            gecos = $type+ " - "+$PrincipalSource
            shell = ''
        }
        $userdict.add($name,$account)
        $userlist += $userdict
    }
    return $userlist
}

$windows=get-localAccounts
$result=organizeaccounts $windows

$pluginreturn[$pluginname]=$result

return $pluginreturn






