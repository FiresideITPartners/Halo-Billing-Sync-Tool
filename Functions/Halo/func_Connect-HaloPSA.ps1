function Connect-HaloPSA {

    $currentTimestamp = Get-Date

    if (!$null -eq $global:HaloToken -and $currentTimestamp -lt $global:HaloTokenExpiry) {
        return $global:HaloToken
    } else {
        Try {
            $halotoken = Get-NewHaloPSAToken
        } catch {
            Write-Log -message "Failed to retrieve token from Halo API: $($_.Exception.Message)"
            throw "Failed to retrieve token from Halo API: $($_.Exception.Message)"
        }
    }
    Return $global:HaloToken

}