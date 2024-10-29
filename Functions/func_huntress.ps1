function Get-HuntressOrgs {
    param (
        [Parameter()]
        [string]$id,
        [Parameter()]
        [string]$url = $config.huntress.huntressbaseURI
    )

    if ($id) {
        $url = "$url/organizations/$id"
        Write-Log -message "Getting Huntress Organization $id"
    } else {
        Write-Log -message "Getting Huntress Organizations"
        $url = "$url/organizations?limit=200"
    }
    try {
        $Huntapikey = get-secret -Name $config.huntress.clientID -vault $config.keyvault -asplaintext
    } catch { 
        Write-Log -message "Failed to retrieve client ID from KeyVault: $($_.Exception.Message)"
        throw "Failed to retrieve client ID from KeyVault: $($_.Exception.Message)"
    }
    try {
        $HuntapiSecret = get-secret -Name $config.huntress.ClientSecret -vault $config.keyvault -asplaintext
    } catch { 
        write-log -message "Failed to retrieve client secret from KeyVault: $($_.Exception.Message)"
        throw "Failed to retrieve client secret from KeyVault: $($_.Exception.Message)"
    }

    $credpair = "$($Huntapikey):$($HuntapiSecret)"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credpair))

    Write-Log -message "Getting Huntress Organizations from $url"
    Write-Host "Getting Huntress Organizations" -ForegroundColor Cyan
    try {$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
        Authorization = "Basic $authInfo"
    }
    } catch {
        Write-Log -message "Failed to retrieve data from Huntress API: $($_.Exception.Message)"
        throw "Failed to retrieve data from Huntress API:" + $_Exception.Message
    }
    return $response
}