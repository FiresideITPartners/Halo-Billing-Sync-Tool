function Get-HaloOrg {
    [CmdletBinding()]
    param (
        [Parameter()]
        $companyname,
        [Parameter()]
        $companyID,
        [Parameter()]
        $haloURI = $config.halo.HalobaseURI + "/api/client"
        )
        if ($companyID) {
            $uri = "$haloURI/$companyID"
        } elseif ($companyname) {
            # URL encode the company name
            $encodedCompanyName = [System.Web.HttpUtility]::UrlEncode($companyname)
            $uri = $haloURI + "?search_name_only=$encodedCompanyName"
        } else {
            $uri = $haloURI
        }
        try {
            $headers = @{
                Authorization = "Bearer $(Connect-HaloPSA)"
            }
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        } catch {
            Write-Log -message "Failed to retrieve data from Halo API: $($_.Exception.Message)"
            throw "Failed to retrieve data from Halo API: $($_.Exception.Message)"
        }
    
        return $response
    }