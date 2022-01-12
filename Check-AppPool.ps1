<#
.SYNOPSIS
Cette Cmdlet permet de verifier le fonctionnement des pools d'applications ou seulement d'un pool.
.DESCRIPTION
 Cette Cmdlet permet de verifier le fonctionnement des pools d'applications ou seulement d'un pool.
.SYNTAX
 CheckAppPool.ps1 [-all]
 CheckAppPool.ps1 [-AppPoolName <String>] 
.EXAMPLE
CheckAppPool.ps1 -all
 Check tous les pool d'application
CheckAppPool.ps1 -AppPoolName test
 Check le pool d'application test
.
.INPUTS
[switch]$all,
[string]$AppPoolName
.OUTPUTS

.NOTES
    NAME: CheckAppPool.ps1
    AUTHOR: CaptainPyK
    Company: ECRITEL
#>

[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$False,Position=1)][switch]$all,
    [Parameter(Mandatory=$False,Position=2)][string]$AppPoolName
)

#Code erreur Nagios

$codeOK=0
$codewarning=1
$codecritical=2
$codeunknown=3


#Fonction pour check les AppPool en erreur

function AppPool{
    Param(
    [Parameter(Mandatory=$False)][string]$AppPoolName
    )
    
    
    if ($AppPoolName) {
    
        $result = Get-IISAppPool $AppPoolName | select-object name,state| Where-Object State -eq "Stopped"
        write-output $result
    }
    else {
        $result = Get-IISAppPool| select-object name,state | Where-Object State -eq "Stopped"
        write-output $result
    }

}


#Fonction pour renvoyer les codes en erreur

function nagiosresult{
Param ($AppPoolobj)


    if($AppPoolobj){
    Write-output $codecritical $AppPoolobj
    }
    else {
    Write-output "$codeOK No AppPool Error"
    }
}




if ($all -and $AppPoolName)
{
    Write-Output "Merci de lire la documentation"
}
elseif ($all)
{
   # Check de tous les AppPools
    $answer = AppPool
    nagiosresult -AppPoolobj $answer
}
elseif(($all -eq $False) -and (![string]::IsNullOrEmpty($AppPoolName)) )
{
   # Check d'un AppPool en particulier
    $answer = AppPool -AppPoolName $AppPoolName
    nagiosresult -AppPoolobj $answer
}
elseif(($all -eq $False) -and ([string]::IsNullOrEmpty($AppPoolName)) )
{
    Write-Output "Merci de lire la documentation"
}

