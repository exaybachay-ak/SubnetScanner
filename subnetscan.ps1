<#
	Resolve all hostnames on your subnet
#>

cls
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

$ipinfo = get-wmiobject win32_networkadapterconfiguration | ? {$_.ipenabled}

#Trimming IP info down - only grabbing adapters that have a default gateway
$activeIP = get-wmiobject win32_networkadapterconfiguration | ? {$_.ipenabled} | `
Where-Object {$_.DefaultIPGateway -NotLike ''} 

if ($activeIP.ipsubnet -eq "255.255.255.0"){
  $classCPattern = "\b(?:[0-9]{1,3}\.){2}[0-9]{1,3}\."
  $classCIpAddr = ($activeIP.ipAddress | sls -Pattern $classCPattern).Matches.Value

  $usermessage = $classCIpAddr + "0/24"
  write-output "Scanning entire $usermessage subnet..."
  write-output "========================================="
  write-output " "

  $scanrange = (0..255)
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
              write-host "$scanIp      (Host is listening on SMB - could be a Windows system)"
            }
            else{
              write-host "$scanIp    $hn (Host is listening on SMB - could be a Windows system)"
            }             
        }
        else{
          write-host "$scanIp    (Host is ignoring SMB - probably NOT a Windows system)"
        }
      }
      else{ }
  }
}

write-output " "
