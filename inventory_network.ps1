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

#Section for recently modified files
Write-Host "2. Filer ändrade de senaste 7 dagarna"
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



