Clear Host

#Retrieve list of googlevideo.com subdomains
#This site limits retrievals to 100 times per day per IP address
Write-Host 'Retrieving googlevideo.com subdomain list...'
$subdomains    = (Invoke-WebRequest -Uri https://api.hackertarget.com/hostsearch/?q=googlevideo.com -UseBasicParsing).Content -split '\n'

#Output file location
$out_file      = "$PSScriptRoot\youtube_domains.txt"

Write-Host 'Retrieving previously generated youtube subdomain list...'
$ytdomains_old = Get-Content('D:\Victor\Documents\Android\Host Files\Script\youtube_domains.txt')
$ytdomains_old = $ytdomains_old -split '\n'

#Youtube domain list set up
$ytdomains     = New-Object System.Collections.Generic.List[System.Object]

Write-Host 'Generating new youtube subdomains...'

#Split "fingerprint"
$subdomains = $subdomains | Foreach-Object{
    if (($_ -split '\.')[0] -like 'r*' -and
        ($_ -split '\.')[0] -ne 'redirector')  {
    ($_ -split '\.')[1]
    }
}

#Generate new subdomains in r*---sn- format with above fingerprints.
$subdomains | Foreach-Object{
    $i = 1
    while ($i -ne 21) {
        $ytdomains.Add("r"+$i+"---"+$_+".googlevideo.com")
        $i++
    }
}

$ytdomains     = $ytdomains += $ytdomains_old

$ytdomains     = $ytdomains | Sort-Object -Unique

$ytdomains     = $ytdomains -join "`n"

#Output to file.
[System.IO.File]::WriteAllText($out_file,$ytdomains)

Write-Host "--> Domain count list saved to: $out_file"

