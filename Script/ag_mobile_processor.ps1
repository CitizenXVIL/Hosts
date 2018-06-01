Clear-Host

# User defined variables

Write-Output 'Fetching AdGuard Mobile ads filter...'
$hosts = (Invoke-WebRequest -Uri https://filters.adtidy.org/extension/chromium/filters/11.txt -UseBasicParsing).Content -split '\n'

#Output file location
$out_file     = "$PSScriptRoot\mobile domains.txt"

# Output host count prior to removals

Write-Output "--> Total hosts count: $($hosts.count)"

Write-Output 'Parsing host files...'
Write-Output '--> Removing non-domain entries, whitelist entries, comments etc.'

# Remove filter list syntax
$hosts        = $hosts | Select-String '^(.*)(##)+(.*)$' -NotMatch   |
                         Select-String '^(.*)(#\$#)+(.*)$' -NotMatch |
                         Select-String '^(.*)(#@#)+(.*)$' -NotMatch  |
                         Select-String '^(.*)(#%#)+(.*)$' -NotMatch  |
                         Select-String '^@@(.*)$' -NotMatch          |
                         Select-String '^!(.*)$' -NotMatch

$hosts        = $hosts -replace '\||'`
                       -replace '\^'

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

# Count total hosts

Write-Output "--> New hosts count: $($hosts.count)"

Write-Output "Removing duplicate hosts (this may take a minute)"

<#############################################
       Fastest way to remove matchinfo
#############################################>

$hosts        = $hosts -replace ''

##############################################

# Remove duplicates and force lower case

$hosts        = ($hosts).toLower() | Sort-Object -Unique

# Count unique hosts

Write-Output "--> New hosts count: $($hosts.count)"

<##############################################
            Remove redundant domains
###############################################>

# Natively defined reverse function
# Note: Does not work properly with Unicode combining characters
#       and surrogate pairs.
function reverse($str) { $a = $str.ToCharArray(); [Array]::Reverse($a); -join $a }

Write-Output "Removing redundant domains by wildcard..."

$hosts = $hosts | ForEach-Object { reverse $_ } | Sort-Object |
  ForEach-Object { $prev = $null } {
    if ($null -eq $prev -or $_ -notlike "$prev*" ) { 
      reverse $_
      $prev = $_
    }
  } | Sort-Object -Unique

#Final hosts count
Write-Output "--> Finished removing redundant hosts"
Write-Output "--> Final hosts count: $($hosts.count)"

# Add blank line

$hosts += "`n"

# Output host file

Write-Output '--> Saving host file'

$hosts     = $hosts -join "`n"

[System.IO.File]::WriteAllText($out_file,$hosts)

Write-Output "--> Host file saved to: $out_file"
