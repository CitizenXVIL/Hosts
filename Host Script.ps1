<#

    Script created by MMotti

#>

Clear-Host

# User defined variables

$host_file    = 'http://someonewhocares.org/hosts/hosts'
$ah_host_file = 'http://getadhell.com/standard-package.txt'
$mm_host_file = 'https://raw.githubusercontent.com/CitizenXVIL/Hosts/master/Wildcards.txt'
$sb_host_file = 'https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts'

$out_file     = "$env:USERPROFILE\desktop\hosts.txt"


Write-Output "--> Fetching $host_file"

# Fetch the original host file for processing

$hosts        = (Invoke-WebRequest -Uri $host_file).Content -split '\n'


Write-Output "--> Fetching $ah_host_file"


# Fetch the AdHell host file

$ahhosts      = (Invoke-WebRequest -Uri $ah_host_file).Content -split '\n'


Write-Output "--> Fetching $mm_host_file"


# Fetch my custom host file

$mmhosts      = (Invoke-WebRequest -Uri $mm_host_file).Content -split '\n'


Write-Output "--> Fetching $sb_host_file"

# Fetch Steven Black's host file

$sbhosts      = (Invoke-WebRequest -Uri $sb_host_file).Content -split '\n'


# Add AdHell and Steven Black's hosts to original hosts

$hosts        = $hosts + $ahhosts + $sbhosts

# Get the total line count

$line_count   = $hosts.Count + $mmhosts.Count


Write-Output "--> Lines Detected: $line_count"


Write-Output '--> Parsing host file'


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

$hosts        = $hosts | Select-String '(?sim)(?=^.{4,253}$)(^((?!-)[a-z0-9-]{1,63}(?<!-)\.)+[a-z]{2,63}$)' -AllMatches

# Remove empty lines
`
$hosts        = $hosts | Select-String '(^\s*$)' -NotMatch

# Extra removals

$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(2o7)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(2mdn)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(ad(s)?)(\.)|^(adserv)(\.)|^(adserver(s)?)(\.)' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(adtech(us)?)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(affiliate(s)?)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(analytic(s)?)(\.)' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(am15)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(banner)(s)?(\.)' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(checkm8)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(fastclick)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(focalink)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(hitbox)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(hyperbanner)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(metric)(s)?(\.)' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(stats)(\.)|^(statistics)(\.)' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(.*)(\.)?(thruport)(\.)(.*)$' -NotMatch
$hosts        = $hosts | Select-String '(?sim)^(track)(\.)|^(tracker)(\.)|^(tracking)(\.)' -NotMatch

# Add custom hosts to the main hosts

$hosts        = $hosts + $mmhosts

# Count total hosts

$host_count   = $hosts.Count


Write-Output "--> Hosts Detected: $host_count"


Write-Output "--> Removing duplicate hosts (this may take a minute)"


<#############################################
       Fastest way to remove matchinfo
#############################################>

$hosts        = $hosts -replace ''

##############################################


# Remove duplicates

$hosts        = $hosts | Sort-Object -Unique

# Count unique hosts

$u_host_cout  = $hosts.Count


Write-Output "--> Hosts added: $u_host_cout"


# Output host file


Write-Output '--> Saving host file'


$hosts     = $hosts -join "`n"

[System.IO.File]::WriteAllText($out_file,$hosts)


Write-Output "--> Host file saved to: $out_file"