Clear-Host

# Get Start Time
$startDTM = (Get-Date)


# User defined variables

$host_files   = 'http://getadhell.com/standard-package.txt',` #AdHell original list
                'http://someonewhocares.org/hosts/hosts',` #Dan Pollock
                'https://pgl.yoyo.org/as/serverlist.php?showintro=0;hostformat=hosts',` #Peter Lowe
                'https://raw.githubusercontent.com/bjornstar/hosts/master/hosts',` #Bjorn Stormberg
                'https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts',` #Steven Black's ad-hoc list
                #'https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts',` #Steven Black's Unified hosts + fakenews + gambling + porn + social
                'http://www.malwaredomainlist.com/hostslist/hosts.txt',` #Malware Domain List
                'https://raw.githubusercontent.com/ZeroDot1/CoinBlockerLists/master/hosts_browser',` #CoinBlocker
                'https://filters.adtidy.org/extension/chromium/filters/15.txt',`  #AdGuard Simplified domain names filter
                'https://filters.adtidy.org/extension/chromium/filters/11.txt'  #AdGuard Mobile ads filter
                #'https://hosts-file.net/ad_servers.txt' #hpHosts ad servers; too large
$manualadds   = 'manual_additions.txt'
$regex_file   = 'regex_removals.txt'
$whitelist    = 'whitelist.txt'

#Output file location
$out_file     = "$PSScriptRoot\hosts.txt"

# Emtpy hosts array

$hosts = @()

# Fetch host files

Write-Output 'Fetching host files...'
foreach($host_list in $host_files)
{
    Write-Output "--> $host_list"

    # Add hosts to the array

    $hosts += (Invoke-WebRequest -Uri $host_list -UseBasicParsing).Content -split '\n'
}

# Fetch mmotti's host and white list files separately

Write-Output "Fetching auxiliary files..."

Write-Output "--> $manualadds"

$manual       = (Get-Content $manualadds) -split '\n'

Write-Output "--> $whitelist"

$whitelist    = (Get-Content $whitelist) -split '\n'

Write-Output "`nParsing host files..."

# Remove filter syntax
$hosts        = $hosts | Select-String '^(.*)(##)+(.*)$' -NotMatch   |
                         Select-String '^(.*)(#\$#)+(.*)$' -NotMatch |
                         Select-String '^(.*)(#@#)+(.*)$' -NotMatch  |
                         Select-String '^(.*)(#%#)+(.*)$' -NotMatch  |
                         Select-String '^@@(.*)$' -NotMatch          |
                         Select-String '^!(.*)$' -NotMatch
$hosts        = $hosts -replace '\||'`
                       -replace '\^'

# Remove local end-zone

$hosts        = $hosts -replace '127.0.0.1'`
                       -replace '0.0.0.0'
# Remove whitespace

$hosts        = $hosts -replace '\s'

# Remove user comments

$hosts        = $hosts -replace '(#.*)|((\s)+#.*)'

# Remove www prefix

$hosts        = $hosts -replace '^(www)([0-9]{0,3})?(\.)'

# Only select 'valid' URLs

$hosts        = $hosts | Select-String '(?sim)(?=^.{4,253}$)(^((?!-)[a-z0-9-]{1,63}(?<!-)\.)+[a-z]{2,63}$)|^([\*])([A-Z0-9-_.]+)$|^([A-Z0-9-_.]+)([\*])$|^([\*])([A-Z0-9-_.]+)([\*])$' -AllMatches

# Remove empty lines
`
$hosts        = $hosts | Select-String '(^\s*$)' -NotMatch

# Output host count prior to removals

Write-Output "---> Total hosts count: $($hosts.count)"

# Extra removals for wildcards
# Get regex filters

Write-Output "`nRunning regex removals (this will take several minutes)..."

$regex_str    = (Get-Content $regex_file) -split '\n'

# Loop through each regex and select non-matching items

foreach($regex in $regex_str)
{   
    $hosts    = $hosts | Select-String $regex -NotMatch
}

# Add custom hosts to the main hosts

$hosts        = $hosts += $manual

# Remove whitelisted hosts from main hosts

$hosts        = $hosts |Where-Object { $whitelist -notcontains $_ }

# Count total hosts

Write-Output "---> Finished running regex removal"
Write-Output "---> New hosts count: $($hosts.count)"

Write-Output "`nRemoving duplicate hosts..."

<#############################################
       Fastest way to remove matchinfo
#############################################>

$hosts        = $hosts -replace ''

# Remove duplicates and force lower case

$hosts        = ($hosts).toLower() | Sort-Object -Unique

Write-Output "---> Finished removing duplicate hosts"
Write-Output "---> New hosts count: $($hosts.count)"
$icount = $($hosts.count)

<##############################################
            Remove redundant domains
###############################################>

# Natively defined reverse function
# Note: Does not work properly with Unicode combining characters
#       and surrogate pairs.
function reverse($str) { $a = $str.ToCharArray(); [Array]::Reverse($a); -join $a }


Write-Output "`nRemoving redundant domains by wildcard..."

$hosts = $hosts | ForEach-Object { reverse $_ } | Sort-Object |
  ForEach-Object { $prev = $null } {
    if ($null -eq $prev -or $_ -notlike "$prev*" ) { 
      reverse $_
      $prev = $_
    }
  } | Sort-Object -Unique

#Final hosts count
Write-Output "---> Finished removing redundant hosts"
Write-Output "---> Final hosts count: $($hosts.count)"

Write-Output "`nSaving to file..."

#New line after each element
$hosts       = $hosts -join "`n"

#Output to file.
[System.IO.File]::WriteAllText($out_file,$hosts)

Write-Output "--> Host file saved to: $out_file"

# Get End Time
$endDTM = (Get-Date)

# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

#Read-Host 'Press Enter to continue…' | Out-Null
