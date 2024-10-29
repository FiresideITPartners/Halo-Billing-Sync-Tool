#dot source include function files
Get-ChildItem -Path $PSScriptRoot\Functions\ -Filter 'func_*.ps1' -Recurse | ForEach-Object { . $_.FullName }
#Load Scripts and Config
$scripts = Get-ChildItem -Path $PSScriptRoot\scripts\Menu -Filter *.ps1
$config = Get-Content -Path $PSScriptRoot\Config\config.json | ConvertFrom-Json
$basepath = $PSScriptRoot
$date = Get-Date -Format "yyyy-MM-dd"
$logfile = Join-Path -Path $PSScriptRoot -ChildPath "$date.log"
Write-Log -message "###############################################"
Write-Log -message "Billing Sync Script Started"
Write-Log -message "###############################################"
#Before showing the menu we want to make sure the keyvault is configured and unlocked
Write-log -message "Verifying Keyvault is configured"
try {
    Test-Keyvault
} catch {
    Write-Host "Failed to verify Keyvault.  Please check the configuration and try again." -ForegroundColor Red
    Write-Host "Keyvault must be configured and unlocked to run this script." -ForegroundColor Red
    Exit
}
Show-Menu