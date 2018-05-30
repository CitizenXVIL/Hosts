Clear-Host

# Get Start Time
$startDTM = (Get-Date)

# User defined variables

$hosts = Get-Content('hosts.txt')

$countlist = New-Object System.Collections.Generic.List[System.Object]

Write-Output 'Determining parent domains for list...'

$hosts | ForEach-Object {

    if ($_.split("\.")[-2] -ne "com" -and
        $_.split("\.")[-2] -ne "co" -and
        $_.split("\.")[-2] -ne "in" -and
        $_.split("\.")[-2] -ne "gov" -and
        $_.split("\.")[-2] -ne "net" -and
        $_.split("\.")[-2] -ne "edu" -and
        $_.split("\.")[-2] -ne "go") {
            $split = $_.split("\.")[-2,-1] -join "."
            }
            else
            {
            $split = $_.split("\.")[-3,-2,-1] -join "."
    }

$countlist.Add($split)
}

Write-Output 'Counting number of occurences of each parent domain (this will take several minutes)...'

$countlist = $countlist | group | where-object { $_.count -gt 5 } | Sort Count -Descending | ft Name,Count

Write-Output $countlist

#Output to file.

$countlist | Export-CSV $PSScriptRoot\domain_count.txt -NoTypeInformation

Write-Output "--> Domain count list saved to: $PSScriptRoot"


# Get End Time
$endDTM = (Get-Date)

# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"
