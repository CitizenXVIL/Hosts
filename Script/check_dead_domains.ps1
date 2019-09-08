Clear-Host
# Get Start Time
$startDTM = (Get-Date)

# Get hosts file
$hosts = Get-Content ("$PSScriptRoot\hosts.txt")

#Output file location
$alive_file     = "$PSScriptRoot\hosts_alive.txt"

$dead_file = "$PSScriptRoot\nxdomains.txt"

##################################################################################

#Checking for unresponsive, inactive or dead domains
Write-Output "`n`n`n`n`nChecking health of each domain. This will take several minutes"

#Create empty array for NX hosts
$nx_hosts     = @()

# NXDOMAIN native error code
$nx_err_code  = 9003

# Iterator starting point
$i            = 1
$nx           = 1

# For each host
foreach($nx_check in $hosts)
{
    # Output the current progress
    Write-Progress -Activity "Querying Hosts" -status "Query $i of $($hosts.Count)" -percentComplete ($i / $hosts.count*100)
    
    # Try to resolve a DNS name
    try
    {
        Resolve-DnsName $nx_check -Type A -Server 1.1.1.1 -DnsOnly -QuickTimeout -ErrorAction Stop | Out-Null
    }
    # On error
    catch
    {
        # Store error code
        $err_code = $Error[0].Exception.NativeErrorCode

        # If error code matches NXDOMAIN error code
        if($err_code -eq $nx_err_code)
        {
            # Let the user know
            Write-Output "--> NXDOMAIN (#$nx): $nx_check"
            
            # Add to array
            $nx_hosts += $nx_check

            # Iterate
            $nx++
        }
    }
    
    # Iterate
    $i++
}

##################################################################################

#Output to file
Write-Output "`nSaving hosts file with dead domains removed as hosts_alive.txt. `n"

#Remove dead 
$hosts       = $hosts | Where-Object { $nx_hosts -notcontains $_ }

#New line after each element
$hosts       = $hosts -join "`n" 

[System.IO.File]::WriteAllText($alive_file,$hosts)

##################################################################################

# Output the file
Write-Output "Updating dead domain file with new domains.`n--> File saved as nxdomains.txt`n"

# Join array on a new line
$nx_hosts = $nx_hosts -join "`n"

[System.IO.File]::WriteAllText($dead_file,$nx_hosts)

##################################################################################

# Get End Time
$endDTM = (Get-Date)

# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

#Read-Host 'Press Enter to continue…' | Out-Null
