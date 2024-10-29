. $PSScriptRoot\..\ThirdParty\Huntress\huntressfunctions.ps1
. $PSScriptRoot\..\Halo\HaloFunctions.ps1
Write-Host "Beginning to map Huntress Clients to Halo Companies"

#$haloOrgs = Get-HaloOrg
$supplierID = $config.huntress.halosupplierID
Write-Host "Getting Current Mapping"
Try {
    $CurrentMapping = Get-HaloPublishedReport $config.halo.syncmapreport
} catch {
    Write-Host "Failed to get current mapping.  Please check the report and try again."
    Show-Menu
}
Write-Host "Getting Huntress Organizations"
try {
    $huntressOrgs = Get-HuntressOrgs
} catch {
    Write-Host "Failed to get Huntress Organizations.  Please check the API and try again."
    Show-Menu
}
$mapping = @()
$failedmapping = @()
foreach ($huntressOrg in $huntressOrgs.organizations) {
    $mappingID = $CurrentMapping | Where-Object { $_.CFbillingsyncID -eq $huntressOrg.id }
    if ($null -eq $mappingID) {
        try {
            $haloOrg = Get-HaloOrg -companyname $huntressOrg.name
        } catch {
            Write-Host "Failed to get Halo Company for $($huntressOrg.name).  Please check the API and try again." -ForegroundColor Red
        }
        if ($haloOrg.record_count -eq 0) { 
            Write-Host "Halo Company not found for $($huntressOrg.name). You will need to map manually." -ForegroundColor Red
            $failedmapping += [PSCustomObject]@{
                huntressID = $huntressOrg.id
                huntressName = $huntressOrg.name
            } 
        } elseif ($haloOrg.record_count -eq 1) {
            #Write-Host "Mapping $($huntressOrg.name) to $($haloOrg.clients.name)"
            $mapping += [PSCustomObject]@{
                supplierID = $supplierID
                supplierclientID = $huntressOrg.id
                supplierclientName = $huntressOrg.name
                HalocustomerID = $haloOrg.clients.id
                HalocustomerName = $haloOrg.clients.name
            }
        } else {
            Write-Host "Multiple Halo Companies found for $($huntressOrg.name). You will need to map manually." -ForegroundColor Green
            $failedmapping += [PSCustomObject]@{
                huntressID = $huntressOrg.id
                huntressName = $huntressOrg.name
            }
        }
    } Else { 
        Write-Host "Mapping already exists for $($huntressOrg.name) to $($mappingID.CFbillingsyncID)" -ForegroundColor Green
    }
}

Write-Host "There are $($mapping.count) mappings to add." -ForegroundColor Green
Write-Host "Enter A to add mappings to the table, V to view mappings, or any other key to exit" -ForegroundColor Green
$addtomap = Read-Host
if ($addtomap -eq "A") {
    try {
        $tableupdate = Update-Table -data $mapping
        Write-Host "Table updated with $($tableupdate.count) records"
        $tableupdatelog = $tableupdate | Select-Object -Property SupplierCompany,status,response
        $tableupdatelog >> $logfile
    } catch {
        Write-Host "Failed to update table.  $($_.Exception.Message)" -ForegroundColor Red
    }
} elseif ($addtomap -eq "V") {
    Write-Host "Mappings to add:" -ForegroundColor Green
    $mapping | Format-Table
    Write-Host "Failed Mappings (Will need to manually add or fix):" -ForegroundColor Green
    $failedmapping | Format-Table
    Show-Menu
}
else {
    Write-Host "User declined to add mappings to table"
    Show-Menu
}
