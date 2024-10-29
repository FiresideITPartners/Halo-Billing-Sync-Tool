function Get-HuntressOrgs {
    param (
        [Parameter()]
        [string]$id,
        [Parameter()]
        [string]$url = $config.huntress.huntressbaseURI
    )

    if ($id) {
        $url = "$url/organizations/$id"
    } else {
        $url = "$url/organizations?limit=200"
    }
    try {
        $Huntapikey = get-secret -Name $config.huntress.clientID -vault $config.keyvault -asplaintext
    } catch { 
        throw "Failed to retrieve client ID from KeyVault: $($_.Exception.Message)"
    }
    try {
        $HuntapiSecret = get-secret -Name $config.huntress.ClientSecret -vault $config.keyvault -asplaintext
    } catch { 
        throw "Failed to retrieve client secret from KeyVault: $($_.Exception.Message)"
    }

    $credpair = "$($Huntapikey):$($HuntapiSecret)"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credpair))


    try {$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
        Authorization = "Basic $authInfo"
    }
    } catch {
        throw "Failed to retrieve data from Huntress API:" + $_Exception.Message
    }
    return $response
}