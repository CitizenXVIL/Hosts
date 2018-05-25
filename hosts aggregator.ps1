Clear-Host

# User defined variables

$host_files   = 'http://getadhell.com/standard-package.txt',` #AdHell original list
                'http://someonewhocares.org/hosts/hosts',` #Dan Pollock
                'https://pgl.yoyo.org/as/serverlist.php?showintro=0;hostformat=hosts',` #Peter Lowe
                'https://raw.githubusercontent.com/bjornstar/hosts/master/hosts',` #Bjorn Stormberg
                'https://goo.gl/bGNWyV',` #mmotti manual additions -> merge this into regex and wildcards
                'https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts',` #StevenBlack Unified hosts
                'https://filters.adtidy.org/extension/chromium/filters/15.txt'  #AdGuard Simplified domain names filter
                ###'https://hosts-file.net/ad_servers.txt' hpHosts ad servers; too large###
$wildcards    = 'generated_wildcards.txt'
$regex_file   = 'regex_removals.txt'
$whitelist    = 'whitelist.txt'

$out_file     = "$PSScriptRoot\hosts.txt"

# Emtpy hosts array

$hosts = @()

# For each host file

foreach($host_list in $host_files)
{
    Write-Output "--> Fetching $host_list"

    # Add hosts to the array

    $hosts += (Invoke-WebRequest -Uri $host_list -UseBasicParsing).Content -split '\n'
}

# Fetch mmotti's host file separately

Write-Output "--> Fetching $wildcards"

$mmhosts      = (Get-Content $wildcards) -split '\n'

Write-Output "--> Fetching $whitelist"

$whitelist      = (Get-Content $whitelist) -split '\n'

Write-Output '--> Parsing host files'

# Remove local end-zone

$hosts        = $hosts -replace '127.0.0.1'`
                       -replace '0.0.0.0'
# Remove whitespace

$hosts        = $hosts -replace '\s'

# Remove user comments

$hosts        = $hosts -replace '(#.*)|((\s)+#.*)'

# Remove www prefix

$hosts        = $hosts -replace '^(www)([0-9]{0,3})?(\.)'

# Remove filter syntax
$hosts        = $hosts -replace '\||'`
                       -replace '\^'
# Only select 'valid' URLs

$hosts        = $hosts | Select-String '(?sim)(?=^.{4,253}$)(^((?!-)[a-z0-9-]{1,63}(?<!-)\.)+[a-z]{2,63}$)|^([\*])([A-Z0-9-_.]+)$|^([A-Z0-9-_.]+)([\*])$|^([\*])([A-Z0-9-_.]+)([\*])$' -AllMatches

# Remove empty lines
`
$hosts        = $hosts | Select-String '(^\s*$)' -NotMatch

# Output host count prior to removals

Write-Output "--> Hosts Detected: $($hosts.count)"

# Extra removals for wildcards
# Get regex filters

Write-Output "--> Running regex removals (this may take a minute)"

$regex_str    = (Get-Content $regex_file) -split '\n'

# Loop through each regex and select non-matching items

foreach($regex in $regex_str)
{   
    $hosts    = $hosts | Select-String $regex -NotMatch
}

# Add custom hosts to the main hosts

$hosts        = $hosts += $mmhosts

# Remove whitelisted hosts from main hosts

$hosts = $hosts |Where-Object { $whitelist -notcontains $_ }

# Count total hosts

Write-Output "--> Hosts Detected: $($hosts.count)"

Write-Output "--> Removing duplicate hosts (this may take a minute)...`n"

<#############################################
       Fastest way to remove matchinfo
#############################################>

$hosts        = $hosts -replace ''

##############################################

# Remove duplicates and force lower case

$hosts        = ($hosts).toLower() | Sort-Object -Unique

# Output host count prior to next set of removals removal

Write-Output "--> Hosts Detected: $($hosts.count)"

<##############################################
            Remove redundant domains
###############################################>

#Natively defined reverse function
function reverse($str) { $a = $str.ToCharArray(); [Array]::Reverse($a); -join $a }

#Defined variables for following while loop
$iicount = $($hosts.count)
$icount = $($hosts.count)
$fcount = 0
$removed = 1

Write-Output "Removing redundant domains by wildcard (this will take several minutes)...`n"

#Loop to remove redundant domains by reversing and comparing array elements
While ($removed -ne 0) {

    $icount = $($hosts.count)

    $hosts = $hosts | ForEach-Object { reverse $_ } | Sort-Object |
      ForEach-Object { $prev = $null } {
        if ($null -eq $prev -or $_ -notlike "$prev*" ) { reverse $_ }
        $prev = $_
      } | Sort-Object

    $fcount = $($hosts.count)
    $removed = $icount - $fcount
    Write-Output "Initial Count: $icount, Reduced Count: $fcount, Removed Domains: $removed"
}

$removed = $iicount - $fcount

Write-Output "`nFinished removing redundant domains.`nInitial Count: $iicount, Final Count: $fcount, Total Domains Removed: $removed`n"

Write-Output "Saving to file..."

#Force elements to lowercase and remove duplicates
$hosts = ($hosts).toLower() | Sort-Object -Unique

#New line after each element
$hosts = $hosts -join "`n"

#Output to file.
[System.IO.File]::WriteAllText($out_file,$hosts)

Write-Output "--> Host file saved to: $out_file"

Read-Host 'Press Enter to continue…' | Out-Null