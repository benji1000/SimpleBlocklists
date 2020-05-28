<#
.SYNOPSIS
	This script downloads an applies hosts blocklists.

.DESCRIPTION
	The script first attempts to elevate to admin, as it is needed to update hosts file.
	It then downloads and merges blocklists defined in the $blockLists array.
	It makes a backup of the hosts file the first time, then adds it to the merged blocklists and saves it to the hosts file.
	It also disables the dnscache service in the registry, as it can slow down the name resolution process.
	Finally, it offers the user to add a scheduled task that will download and apply the blocklists every week.

.NOTES
	The first launch of the script displays message boxes to ask things to the user.
	Once the system is configured and rebooted, the script is *almost* transparent (the Powershell console will briefly pop up).
	Blocklists can be customized by adding or removing URLs in the $blockLists array.
	The user's custom hosts now must be added to the backed up hosts file to be merged with the downloaded blocklists.

.INPUTS
	None

.OUTPUTS
	Hosts file backed up in: C:\Windows\System32\Drivers\etc\hosts.bak
	Hosts file updated: C:\Windows\System32\Drivers\etc\hosts

.EXAMPLE
	./SimpleBlocklists.ps1

.NOTES
	Version:        1.0
	Author:         benji1000
	Creation Date:  May 2020
	Purpose/Change: Initial script development
	
.LINK
	https://github.com/benji1000/SimpleBlocklists
#>

#---------------------------------------------------------[ Parameters ]---------------------------------------------------------

$blockLists = @(
	"http://winhelp2002.mvps.org/hosts.txt",
	"https://adaway.org/hosts.txt",
	"https://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext&useip=0.0.0.0",
	"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
)

$ipToRedirectTo = '0.0.0.0'

#------------------------------------------------[ Attempt to elevate to admin ]-------------------------------------------------

$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$admin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($admin -eq $false) {
	Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -exec bypass -windowstyle hidden -file "{0}"' -f ($myinvocation.MyCommand.Definition))
	exit
}

#-----------------------------------------------[ Download and merge blocklists ]------------------------------------------------

# Download every blocklist defined
$blockedDomains = foreach ($list in $blockLists) {
	Invoke-WebRequest $list | Select-Object -ExpandProperty Content
}

# Copy original hosts file to a backup when this script is run for the first time
$backupFile = $env:SystemRoot+"\System32\Drivers\etc\hosts.bak"
if (!(Test-Path $backupFile)) {
	Copy-Item $env:SystemRoot\System32\Drivers\etc\hosts -Destination $backupFile
}

# Redirect the hosts to the IP we want
$newHosts = $blockedDomains -replace "127\.0\.0\.1",$ipToRedirectTo

# Remove lines that erroneously attributes localhost to 0.0.0.0
$newHosts = $newHosts -replace '0\.0\.0\.0\s+localhost.localdomain',''
$newHosts = $newHosts -replace '0\.0\.0\.0\s+localhost',''
$newHosts = $newHosts -replace '0\.0\.0\.0\s+local',''

# Remove commented lines and empty lines
$newHosts = $newHosts | Where {$_.Trim() -notmatch "^$" -and $_ -notmatch '^#.*$'}
$newHosts = $newHosts -replace '\s?#.*',''
$newHosts = $newHosts -replace '(?m)^\s*?\n'

# Remove duplicates
$newHosts = $newHosts | Sort | Get-Unique

# Add default localhost to the top of the file
$newHosts = "127.0.0.1 localhost`n::1 localhost`n" + $newHosts

# Append the backed up hosts file to the bottom of the file
$oldHosts = Get-Content -Path $backupFile | Out-String
$newHosts = $newHosts + $oldHosts

# Save the new file
$newHosts | Out-File $env:SystemRoot\System32\Drivers\etc\hosts

#--------------------------------------------[ Taking care of the dnscache service ]---------------------------------------------

# Disable the dnscache service startup in the registry as it can't be killed by the user
# Therefore it will need a reboot to take effect
Set-Itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\services\Dnscache' -Name 'Start' -value '4'

# Display a window if the dnscache service is still running to remind the user to reboot
if ((Get-Service dnscache).Status -eq 'Running') {
	$wshell = New-Object -ComObject Wscript.Shell
	$wshell.Popup("However, you need to restart your computer.", 0, "The blocklist was applied!", 64)
}

#--------------------------------------------------[ Scheduled task creation ]---------------------------------------------------

if ((Get-ScheduledTask | Where-Object {$_.TaskName -like "Apply Blocklists" }).State -ne 'Ready') {
	$wshell = New-Object -ComObject Wscript.Shell
	$answer = $wshell.Popup("Do you want to add a weekly scheduled task?", 0, "Update blocklist regularly?", 36)
	if ($answer -eq '6') {
		& schtasks /create /tn "$env:UserName\Apply Blocklists" /sc WEEKLY /mo 1 /ST (Get-Date).ToString("HH:00") /f /ru $env:UserName /rl HIGHEST /tr 'powershell.exe -noprofile -windowstyle hidden -exec bypass C:\SimpleBlocklists.ps1'
	}
}