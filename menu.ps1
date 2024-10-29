#placeholder for the launch menu
$scripts = Get-ChildItem -Path $PSScriptRoot\scripts\ -Filter *.ps1
$config = Get-Content -Path $PSScriptRoot\Config\variables.json | ConvertFrom-Json
$date = Get-Date -Format "yyyy-MM-dd"
$logfile = Join-Path -Path $config.logpath -ChildPath "$date.log"
Start-Transcript -Path $logfile -Append
function Show-Menu {
    Write-Host "Welcome to the Launch Menu"
    Write-Host "Please select an option from the list below"
    $i = 1
    foreach ($script in $scripts) {
        Write-Host "$i. $($script.BaseName)"
        $i++
    }
    Write-Host "$i. Exit"
    $selection = Read-Host "Please select an option"
    if ($selection -eq $i) {
        Write-Host "Exiting"
        Stop-Transcript
        Exit
    } elseif ($selection -gt $scripts.Count) {
        Write-Host "Invalid selection"
        Show-Menu
    } else {
        $script = $scripts[$selection - 1]
        . $script.FullName
        Show-Menu
    }
}

Show-Menu