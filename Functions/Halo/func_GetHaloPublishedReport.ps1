function Get-HaloPublishedReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$reportID,
        [Parameter()]
        [string]$haloURI = $config.halo.HalobaseURI + "/api/ReportData"
    )
    Try {
        $HaloreportProfile = get-secret -Name $config.halo.reportprofile -vault $config.keyvault -asplaintext
    } catch { 
        Write-Log -message "Failed to retrieve report profile from KeyVault: $($_.Exception.Message)"
        throw "Failed to retrieve report profile from KeyVault: $($_.Exception.Message)"
    }
    try {
        $HaloreportSecret = get-secret -Name $config.halo.reportSecret -vault $config.keyvault -asplaintext
    } catch { 
        Write-Log -message "Failed to retrieve report secret from KeyVault: $($_.Exception.Message)"
        throw "Failed to retrieve report secret from KeyVault: $($_.Exception.Message)"
    }
    $credpair = "$($HaloreportProfile):$($HaloReportSecret)"
    $uri = "$haloURI/$reportID"
    $reportauth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credpair))
    try {
        $headers = @{
            Authorization = "Basic $reportauth"
        }
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    } catch {
        Write-Log -message "Error Getting Report: $($_.Exception.Message)"
        Throw "Error Getting Report: $($_.Exception.Message)"
    }

    return $response
}