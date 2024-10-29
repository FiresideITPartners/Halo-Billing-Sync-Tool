$Huntapikey = get-secret -Name $config.huntress.clientID -vault $config.keyvault -asplaintext
$HuntapiSecret = get-secret -Name $config.huntress.ClientSecret -vault $config.keyvault -asplaintext
function Get-HuntressOrgs {
    param (
        [Parameter()]
        [string]$id,
        [Parameter()]
        [string]$url = $config.huntress.huntressbaseURI,
        [Parameter()]
        [string]$apiKey = $Huntapikey,
        [Parameter()]
        [string]$apiSecret = $HuntapiSecret
    )

    if ($id) {
        $url = "$url/organizations/$id"
    } else {
        $url = "$url/organizations?limit=200"
    }

    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${apiKey}:${apiSecret}"))

    try {$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
        Authorization = "Basic $authInfo"
    }
    } catch {
        throw "Failed to retrieve data from Huntress API:" + $_Exception.Message
    }
    return $response
}
