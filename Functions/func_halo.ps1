function Connect-HaloPSA {
    <#
.SYNOPSIS
Gets Bearer Token for HaloPSA API

.DESCRIPTION
Gets Bearer Token for HaloPSA API using client credentials.  API user and credentials must be created in Halo API.  

.PARAMETER clientId
Specifies the Client ID for Halo PSA API user.

.PARAMETER clientSecret
Specifies the Client Secret for Halo PSA API user.

.PARAMETER HaloAuthUrl
Specifies the Authorization endpoint for HaloPSA API.  Usually https://yourhalodomain.com/auth/token

.OUTPUTS
Returns the full response from the Authorization endpoint as a custom object.  
Reference $_.access_token for the Bearer Token in future calls. $_.expires_in will allow you to calculate expiry time.

.EXAMPLE
Connect-HaloPSA -clientId "clientID" -clientSecret "clientSecret" -HaloAuthUrl "https://yourhalodomain.com/auth/token"
@{scope=DEFINED SCOPES; token_type=Bearer; access_token=ACCESS_TOKEN; expires_in=3600; refresh_token=REFRESH_TOKEN; id_token=ID_TOKEN}
#>
    Param(
        [Parameter()]
        [string]$clientId = $HaloclientId,
        [Parameter()]
        [string]$clientSecret = $HaloclientSecret,
        [Parameter()]
        [string]$HaloURI = $config.halo.HalobaseURI
    )
    try {
        $HaloclientId = get-secret -Name $config.halo.clientID -vault $config.keyvault -asplaintext
    } catch {
        Write-Log -message "Failed to retrieve client ID from KeyVault: $($_.Exception.Message)"
        throw "Failed to retrieve client ID from KeyVault: $($_.Exception.Message)"
    }
    try { 
        $HaloclientSecret = get-secret -Name $config.halo.clientSecret -vault $config.keyvault -asplaintext
    } catch { 
        Write-Log -message "Failed to retrieve client secret from KeyVault: $($_.Exception.Message)"
        throw "Failed to retrieve client secret from KeyVault: $($_.Exception.Message)"
    }
    $HaloAuthUrl = $HaloURI + "/auth/token"
    $body = @{
        grant_type = "client_credentials"
        client_id = $HaloclientId
        client_secret = $HaloclientSecret
        scope = "all"
    }
    Write-log -message "Getting Token from $HaloAuthUrl"
    try {
        $halotoken = Invoke-RestMethod -StatusCodeVariable "statusCode" -Method Post -Uri $HaloAuthUrl -Body $body
    }
    catch {
        Write-Log -message "Failed to retrieve token from Halo API: $($_.Exception.Message)"
        throw "Failed to retrieve token from Halo API: $($_.Exception.Message)"
    }
    return $halotoken
}
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
    #Check if there is an existing token and it hasn't expired
    if ($null -eq $halotoken) {
        Write-Log -message "Halo Token is null, getting a new one"
        $halotoken = Connect-HaloPSA
        $haloTokenIssue = Get-Date
    } else {
            # Calculate the time when the token is set to expire
            $expiryTime = $haloTokenIssue.AddSeconds($halotoken.expires_in)
            # Subtract 90 seconds to account for any response delays
            $expiryTime = $expiryTime.AddSeconds(-90)
            Write-Log -Message "Token Expires at $($expiryTime)"
            if ((Get-Date) -gt $expiryTime) {
                Write-Log -Message "Token has expired, get a new one"
                $halotoken = Connect-HaloPSA
            } else {
                Write-Log -Message "Token is still valid, use the existing token"
            }
    }
    if ($companyID) {
        $uri = "$haloURI/$companyID"
    } elseif ($companyname) {
        $uri = $haloURI + "?search_name_only=$companyname"
    } else {
        $uri = $haloURI
    }

    try {
        $token = $halotoken.access_token
        $headers = @{
            Authorization = "Bearer $token"
        }
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    } catch {
        Write-Log -message "Failed to retrieve data from Halo API: $($_.Exception.Message)"
        throw "Failed to retrieve data from Halo API: $($_.Exception.Message)"
    }

    return $response
}
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
function Update-Table {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [Object[]]$data,
        [Parameter(Position = 1)]
        [string]$haloURI = $config.halo.HalobaseURI
    )
    #Check if there is an existing token and it hasn't expired
    if ($null -eq $halotoken) {
        Write-Log -message "Halo Token is null, getting a new one"
        $halotoken = Connect-HaloPSA
        $haloTokenIssue = Get-Date
    } else {
            # Calculate the time when the token is set to expire
            $expiryTime = $haloTokenIssue.AddSeconds($halotoken.expires_in)
            # Subtract 90 seconds to account for any response delays
            $expiryTime = $expiryTime.AddSeconds(-90)
            Write-Log -Message "Token Expires at $($expiryTime)"
            if ((Get-Date) -gt $expiryTime) {
                Write-Log -Message "Token has expired, get a new one"
                $halotoken = Connect-HaloPSA
            } else {
                Write-Log -Message "Token is still valid, use the existing token"
            }
    }
    $uri = $haloURI + "/api/CustomTable"
    $token = $halotoken.access_token
    $headers = @{
        Authorization = "Bearer $token"
        "Content-Type" = "application/json"
    }
    $colHaloCustomer = $config.halo.custom_table.halo_customer
    $colsupplierID = $config.halo.custom_table.supplier
    $colsuppliercustomer = $config.halo.custom_table.Supplier_customer_id
    #Build the body of the request with nested arrays
 $response = @()
 
    foreach ($row in $data) {
        $body = [PSCustomObject]@{
            id = $config.halo.custom_table.id
            _isimport = $true
            _importtype = "runbook"
            customfields = @(
                @{
                    id = $config.halo.custom_table.id
                    type = 7
                    usage = $config.halo.custom_table.id
                    value = @(
                        @{
                            customfields = @(
                                @{
                                    name = $colHaloCustomer
                                    value = $row.HalocustomerID
                                },
                                @{
                                    name = $colsupplierID
                                    value = $row.SupplierID
                                },                                    
                                @{
                                    name = $colsuppliercustomer
                                    value = $row.supplierclientID
                                }
                            ) 
                        }
                    )
                }
            )
        }
        try {
            $parameters = @{
                uri = $uri
                Method = "Post"
                Headers = $headers
                Body = "[" + ($body | ConvertTo-Json -Depth 20) + "]"
            }
            $update = Invoke-RestMethod @parameters
            $response += [PSCustomObject]@{
                SupplierCompany = $row.supplierclientName
                status = "success"
                response = $update
            }
        } catch {
            write-log -message "Failed to update table in Halo for $($row.supplierclientName): $($_.Exception.Message)"
            throw "Failed to update table in Halo for $($row.supplierclientName): $($_.Exception.Message)"
            $response += [PSCustomObject]@{
                SupplierCompany = $row.supplierclientName
                status = "error" 
                response = $_
            }
        }
    }
    return $response
}