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


