function Test-Keyvault {
    if ($null -eq $config.keyvault) {
        Write-Host "KeyVault not configured." -ForegroundColor Cyan
        Write-Log -message "KeyVault not configured"
        $regvaults = Get-SecretVault
        if ($null -eq $regvaults) {
            Write-Host "No registered vaults found.  Please register a vault and try again." -ForegroundColor Green
            Write-Log -message "No registered vaults found"
            Exit
        } else {
            Write-Host "Registered vaults found.  Please select a vault to use." -ForegroundColor Green
            $i = 1
            foreach ($vault in $regvaults) {
                Write-Host "$i. $($vault.Name)"
                $i++
            }
            $selection = Read-Host "Please select a vault"
            if ($selection -gt $regvaults.Count) {
                Write-Host "Invalid selection" -ForegroundColor Red
                Write-Log -message "Invalid selection"
                Exit
            } else {
                $config.keyvault = $regvaults[$selection - 1].Name
                Write-Host "Using $($config.keyvault)" -ForegroundColor Green
                Write-Log -message "Using $($config.keyvault)"
                Write-Host "Saving configuration" -ForegroundColor Cyan
                try {
                    $config | ConvertTo-Json | Set-Content -Path $basepath\Config\config.json
                } catch {
                    Write-Host "Failed to save configuration.  $($_.Exception.Message)" -ForegroundColor Red
                    Write-Log -message "Failed to save configuration"
                } 
                Write-Host "KeyVault Configuration Saved" -ForegroundColor Cyan
                write-log -message "KeyVault Configuration Saved"

            }
        }
    } else {
        Write-Host "KeyVault configured." -ForegroundColor Cyan
        Write-Log -message "KeyVault already configured"
    }
    Write-Host "Checking KeyVault access" -ForegroundColor Cyan
    Write-Log -message "Checking KeyVault access"
    Try {
        $kvtest = Get-Secret -Name $config.halo.clientID -Vault $config.keyvault
    } catch {
        Write-Host "Failed to retrieve client ID from KeyVault.  Please check the vault and try again. $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -message "Failed to retrieve client ID from KeyVault"
        Exit
    } if ($null -eq $kvtest -or $kvtest -like "*not found*") {
        Write-Host "Failed to retrieve client ID from KeyVault.  Please check the vault and try again." -ForegroundColor Red
        Write-Log -message "Failed to retrieve client ID from KeyVault"
        Exit
    } else {
        Write-Host "KeyVault access verified" -ForegroundColor Cyan
        Write-Log -message "KeyVault access verified"
    }
}