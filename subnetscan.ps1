<#
	Resolve all hostnames on your subnet
#>

$ErrorActionPreference = "SilentlyContinue"

function fastping{
  [CmdletBinding()]
  param(
  [String]$computername = $scanIp,
  [int]$delay = 100
  )

  $ping = new-object System.Net.NetworkInformation.Ping  # see http://msdn.microsoft.com/en-us/library/system.net.networkinformation.ipstatus%28v=vs.110%29.aspx
  try {
    if ($ping.send($computername,$delay).status -ne "Success") {
      return $false;
    }
    else {
      return $true;
    }
  } catch {
    return $false;
  }
}

$activeIP = get-wmiobject win32_networkadapterconfiguration | ? {$_.ipenabled}

$ipInfo = $activeIP.ipAddress[0]
$subInfo = $activeIP.ipsubnet[0]

if ($subInfo -eq "255.255.255.0"){
    $classCPattern = "\b(?:[0-9]{1,3}\.){2}[0-9]{1,3}\."
    $classCIpAddr = ($ipInfo | sls -Pattern $classCPattern).Matches.Value
    $scanrange = (200..255)
    foreach ($ipaddr in $scanrange){
        $scanIp = $classCIpAddr + $ipaddr
        $pingStatus = fastping
        if ($pingStatus -eq "True"){
        	$hn = Resolve-DnsName $scanIp
        	$hn = $hn.namehost
        	$tcpClient = New-Object System.Net.Sockets.TCPClient

            $tcpClient.Connect("$scanIp",445) > $null
            $SMBCheck = $tcpClient.Connected
            if ($SMBCheck -eq "True"){
              	if(!$hn){
              		write-host "$scanIp    (probably a Windows system)"
              	}
              	else{
              		write-host "$scanIp    $hn (probably a Windows system)"
              	}            	
            }
            else{
            	write-host "$scanIp    (probably NOT a Windows system)"
            }
        }
        else{ }
    }
}
