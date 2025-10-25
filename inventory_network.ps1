#Added a set date and weekAgo for the assignment
$now = Get-Date "2024-10-14"
$weekAgo = $now.AddDays(-7)

#Start of raport
Write-Host "===================="
Write-Host "NETWORK_CONFIGS RAPPORT"
Write-Host "====================`n"

#Start of list of config-files section
Write-Host "Lista över alla konfigurationsfiler (.conf .rules .log)"
Write-Host "--------------------"

#Search through the files to only include chosen file types
$allConfigs = Get-ChildItem -Path "network_configs" -Recurse -Include *.conf, *.rules, *.log

#Loop through the collected files and print out the file name,
#size rounded to 2 decimals in kilobytes and when it was last edited
foreach ($file in $allConfigs) {
    Write-Host "$($file.Name) - $([math]::Round($file.Length / 1KB, 2)) KB - ändrad: $($file.LastWriteTime)"
}

Write-Host ""






#Section for recently modified files
Write-Host "Filer ändrade de senaste 7 dagarna"
Write-Host "--------------------"

#Go through network_configs and get files
$recentFiles = Get-ChildItem -Path "network_configs" -Recurse -File |

#Use Where-object to filter files with a LastWriteTime of 7 days or less
Where-Object { $_.LastWriteTime -gt $weekAgo } |

#Some files in assignment had 2025 as year for last edit
#and I don't think that was on purpose so this line
#should sort otu anything that is higher than the $now year, 2024
Where-Object { $_.LastWriteTime.Year -le $now.Year } |

#Sort from LastWriteTime, newest first
Sort-Object LastWriteTime -Descending
#Loop and print files names and date last edited
foreach ($file in $recentFiles) {
    Write-Host "$($file.Name) - ändrad: $($file.LastWriteTime)"
}

Write-Host ""






#Fetch all the files in network_configs and folders
$files = Get-ChildItem -Path "network_configs" -Recurse -File

#Empty list to hold file extensions
$fileTypeInfo = @{}


#Loop through all the files
foreach ($file in $files) {
    #Get the file extension
    $extension = $file.Extension

    #If extension is not yet on the list, add it
    if (-not $fileTypeInfo.ContainsKey($extension)) {
        #Create a post for the extension
        $fileTypeInfo[$extension] = @{
            Count  = 0
            SizeKB = 0
        }
    }

    # Add 1 to the counter of this extension
    $fileTypeInfo[$extension].Count++

    # Add filesize in KB to the total for this extension
    $fileTypeInfo[$extension].SizeKB += ($file.Length / 1KB)
}

#Print out result
Write-Host "Filtyper och storlek:"
Write-Host "---------------"
foreach ($extension in $fileTypeInfo.Keys) {
    $roundedSize = [math]::Round($fileTypeInfo[$extension].SizeKB, 2)
    Write-Host "$extension : $($fileTypeInfo[$extension].Count) filer - totalt $roundedSize KB"
}
Write-Host ""
$totalFiles = ($files | Measure-Object).Count
$totalSize = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1KB, 2)

Write-Host "Totalt antal filer: $totalFiles filer, total storlek: $totalSize KB"




Write-Host ""


Write-Host "De 5 största loggfilerna"
Write-Host "---------------"

#Fetch the files with .log extension
$largestLogs = Get-ChildItem -Path "network_configs" -Filter "*.log" -Recurse -File |

#Sort them in size, biggest first
Sort-Object Length -Descending |

#Select the 5 largest
Select-Object -First 5

#Loop through the list and calculate the size in MB
#Print out the file name and size in MB with 5 decimals
foreach ($log in $largestLogs) {
    $sizeMB = [math]::Round($log.Length / 1MB, 5)
    Write-Host "$($log.Name) - $sizeMB MB"
}
Write-Host ""




Write-Host ""
Write-Host "IP-adresser i konfigurationsfiler"
Write-Host "--------------------"

#Search through .conf files and look for IP patterns
$ipMatches = Get-ChildItem -Path "network_configs" -Recurse -Filter "*.conf" |
Select-String -Pattern "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"

#Extract only the unique IP addresses from the matches
$uniqueIPs = $ipMatches | Select-Object -ExpandProperty Matches | 
ForEach-Object { $_.Value } | Sort-Object -Unique

#Print out the found IP addresses
Write-Host "Hittade IP-adresser:"
foreach ($ip in $uniqueIPs) {
    Write-Host $ip
}
Write-Host ""
Write-Host "Totalt: $($uniqueIPs.Count) unika IP-adresser hittade"





Write-Host ""
Write-Host "Säkerhetsproblem i loggfiler"
Write-Host "--------------------"

#Find all the log files
$logFiles = Get-ChildItem -Path "network_configs" -Recurse -Filter "*.log"

#Loop through the files
foreach ($log in $logFiles) {
    #Reads the content of the file, line by line
    $content = Get-Content $log.FullName

    #Count how many times certain words appear in the files
    $errorCount = ($content | Select-String -Pattern "ERROR"  -SimpleMatch).Count
    $failedCount = ($content | Select-String -Pattern "FAILED" -SimpleMatch).Count
    $deniedCount = ($content | Select-String -Pattern "DENIED" -SimpleMatch).Count

    #Print out the result
    Write-Host "$($log.Name): ERROR=$errorCount, FAILED=$failedCount, DENIED=$deniedCount"
}



#Export file inventory to CSV
$allConfigs | Select-Object Name, FullName, 
@{Name = "SizeKB"; Expression = { [math]::Round($_.Length / 1KB, 2) } }, 
LastWriteTime |
Export-Csv -Path "config_inventory.csv" -NoTypeInformation

#Export IP addresses found
$uniqueIPs | ForEach-Object { [PSCustomObject]@{IPAddress = $_ } } |
Export-Csv -Path "found_ips.csv" -NoTypeInformation

#Export log file issues 
$logReport = @()
foreach ($log in $logFiles) {
    $content = Get-Content $log.FullName
    $errorCount = ($content | Select-String -Pattern "ERROR" -SimpleMatch).Count
    $failedCount = ($content | Select-String -Pattern "FAILED" -SimpleMatch).Count
    $deniedCount = ($content | Select-String -Pattern "DENIED" -SimpleMatch).Count
    
    $logReport += [PSCustomObject]@{
        FileName = $log.Name
        Errors   = $errorCount
        Failed   = $failedCount
        Denied   = $deniedCount
    }
}
$logReport | Export-Csv -Path "log_summary.csv" -NoTypeInformation
