function Show-Menu {
    Write-Host "Welcome to the Launch Menu" -ForegroundColor Green
    Write-Host "Please select an option from the list below" -ForegroundColor Green
    $i = 1
    foreach ($script in $scripts) {
        Write-Host "$i. $($script.BaseName)"
        $i++
    }
    Write-Host "$i. Exit"
    $selection = Read-Host "Please select an option"
    if ($selection -eq $i) {
        Write-Host "Exiting" -ForegroundColor Red
        Write-Log -message "Exiting"
        Exit
    } elseif ($selection -gt $scripts.Count) {
        Write-Host "Invalid selection" -ForegroundColor Red
        Write-Log -message "Invalid selection"
        Show-Menu
    } else {
        $script = $scripts[$selection - 1]
        Write-Host "Running $($script.BaseName)" -ForegroundColor Green
        Write-Log -message "Running $($script.BaseName)"
        . $script.FullName
        Show-Menu
    }
}