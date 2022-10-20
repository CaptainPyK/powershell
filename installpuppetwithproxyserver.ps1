#this script install puppet on AWS environment
#logfile are on Cloudwatch
#It need a puppet proxy server

class Logger {
	#----------------------------------------------
	[string] hidden  $cwlGroup
	[string] hidden  $cwlStream
	[string] hidden  $sequenceToken
	#----------------------------------------------
	# Log Initialization
	#----------------------------------------------
	Logger([string] $Action) {
		$this.cwlGroup = "/puppet-deployment/"
		$this.cwlStream	= "{0}/{1}/{2}" -f $env:COMPUTERNAME, $Action,
		(Get-Date -UFormat "%Y-%m-%d_%H.%M.%S")
		$this.sequenceToken = ""
		#------------------------------------------
		if ( !(Get-CWLLogGroup -LogGroupNamePrefix $this.cwlGroup) ) {
			New-CWLLogGroup -LogGroupName $this.cwlGroup
			Write-CWLRetentionPolicy -LogGroupName $this.cwlGroup -RetentionInDays 1
		}
		if ( !(Get-CWLLogStream -LogGroupName $this.cwlGroup -LogStreamNamePrefix $this.cwlStream) ) {
			New-CWLLogStream -LogGroupName $this.cwlGroup -LogStreamName $this.cwlStream
		}
	}
	#----------------------------------------
	[void] WriteLine([string] $msg) {
		$logEntry = New-Object -TypeName "Amazon.CloudWatchLogs.Model.InputLogEvent"
		#-----------------------------------------------------------
		$logEntry.Message = $msg
		$logEntry.Timestamp = (Get-Date).ToUniversalTime()
		if ("" -eq $this.sequenceToken) {
			# First write into empty log...
			$this.sequenceToken = Write-CWLLogEvent -LogGroupName $this.cwlGroup `
				-LogStreamName $this.cwlStream `
				-LogEvent $logEntry
		}
		else {
			# Subsequent write into the log...
			$this.sequenceToken = Write-CWLLogEvent -LogGroupName $this.cwlGroup `
				-LogStreamName $this.cwlStream `
				-SequenceToken $this.sequenceToken `
				-LogEvent $logEntry
		}
	}
}


[Logger]$log = [Logger]::new("puppet")
$log.WriteLine("------------------------------")
$log.WriteLine("Log Installation Puppet Started")

#your puppet env
$Environment = "PYK"
$pathpuppetconf = "C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf"
$puppetmaster = "your puppet master"
$proxyaddress= "your puppet proxy server"
$proxyport= "8888"


    try {
    $log.WriteLine("Log Puppet Started")
    $source = "https://downloads.puppetlabs.com/windows/puppet6/puppet-agent-x64-latest.msi"
    $InstallFileName = $source.split("/")[-1]
    $destination = "c:\windows\temp\" + $InstallFileName
                
    $CheckPuppetAgent = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object{$_.DisplayName -match "Puppet Agent"} | Measure-Object | Select-Object count
                
    if ($CheckPuppetAgent.count -gt 0) {
   Write-Host "Puppet Agent is already installed." -ForegroundColor Green
   $log.WriteLine("Puppet Agent is already installed.")
   [string]$PuppetAgentState = "OK, Puppet Agent already Installed"
    }
   else {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($source, $destination)
                    
        Start-Process -File msiexec -ArgumentList "/qn /norestart /i $destination PUPPET_MASTER_SERVER=$puppetmaster PUPPET_AGENT_ENVIRONMENT=$Environment"  -Wait -Verb RunAs -ErrorAction Stop
                    
        $CheckPuppetAgent = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object{$_.DisplayName -match "Puppet Agent"} | Measure-Object | Select-Object count
        if ($CheckPuppetAgent.count) {
        Write-Host "Puppet Agent has been installed." -ForegroundColor Green
        $log.WriteLine("Puppet Agent has been installed.")
        [string]$PuppetAgentState = "OK"
        Remove-Item $destination -ErrorAction Stop

        

        }
            else {
            Write-Host "Error: Puppet Agent installation failed" -ForegroundColor Red
            $log.WriteLine("Error: Puppet Agent installation failed")
            [string]$PuppetAgentState = "Error"
            }
        $proxypuppetaddress=Get-Content $pathpuppetconf | select-string -Pattern "http_proxy_host"
        $proxypuppetport=Get-Content $pathpuppetconf| select-string -Pattern "http_proxy_port"
        if (!$proxypuppetaddress)
        {
        add-content -path $pathpuppetconf -Value "http_proxy_host = $proxyaddress"
        $log.WriteLine("Puppet Proxy host is configured")
        }
        if(!$proxypuppetport){
        add-content -path $pathpuppetconf -Value "http_proxy_port = $proxyport"
        $log.WriteLine("Puppet Proxy port is configured")
        }
        
        
    }
    }
            catch {
            Write-Host "Error: " $_.Exception.Message -ForegroundColor Red
            $log.WriteLine("Error: $_.Exception.Message")
            [string]$PuppetAgentState = "Error"
    }