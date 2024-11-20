function Update-HaloSyncMappingTable {
    <#
    .SYNOPSIS
    Adds a mapping between supplier and Halo customer information to the Halo Custom Table.

    .DESCRIPTION
    This script creates a custom object with supplier and Halo customer information and adds it to the Halo Custom Table. 
    The custom object requires the following properties:
    - supplierID: The ID of the supplier.
    - supplierclientID: The ID of the supplier's customer.
    - supplierclientName: The name of the supplier's customer record.
    - HalocustomerID: The ID of the matching customer from the Halo organization.
    - HalocustomerName: The name of the matching customer from the Halo organization.

    .PARAMETER data
    An array of custom objects containing the supplier and Halo customer information to be added to the Halo Custom Table.
    
    .EXAMPLE
    $data += [PSCustomObject]@{
        supplierID = $supplierID
        supplierclientID = $suppliercustomer.id
        supplierclientName = $suppliercustomerOrg.name
        HalocustomerID = $haloOrg.clients.id
        HalocustomerName = $haloOrg.clients.name
    }
    Update-HaloSyncMappingTable -data $data

    .NOTES
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [Object[]]$data,
        [Parameter(Position = 1)]
        [string]$haloURI = $config.halo.HalobaseURI
    )
    $uri = $haloURI + "/api/CustomTable"
    $headers = @{
        Authorization = "Bearer $(Connect-HaloPSA)"
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