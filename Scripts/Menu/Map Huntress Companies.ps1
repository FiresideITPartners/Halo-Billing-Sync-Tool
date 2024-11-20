Write-Host "Beginning to map Huntress Clients to Halo Companies" -ForegroundColor Cyan
Write-Log -message "Beginning to map Huntress Clients to Halo Companies"
$mappingoutput = Join-Path -Path $basepath -ChildPath "MappingOutput_$($date).csv"
$supplierID = $config.huntress.halosupplierID
Write-Host "Getting Current Mapping" -ForegroundColor Cyan
Write-Log -message "Getting Current Mapping"
Try {
    $CurrentMapping = Get-HaloPublishedReport $config.halo.syncmapreport
} catch {
    Write-Host "Failed to get current mapping.  Please check the report and try again." -ForegroundColor Red
    Write-Log -message "Failed to get current mapping.  Please check the report and try again. Exiting to Menu."
    Show-Menu
}
Write-Host "Getting Huntress Organizations" -ForegroundColor Cyan
write-log -message "Getting Huntress Organizations"
try {
    $huntressOrgs = Get-HuntressOrgs
} catch {
    Write-Host "Failed to get Huntress Organizations.  Please check the API and try again."
    Write-Log -message "Failed to get Huntress Organizations.  Please check the API and try again. Exiting to Menu."
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
            Write-Log -message "Failed to get Halo Company for $($huntressOrg.name).  Please check the API and try again."
        }
        if ($haloOrg.record_count -eq 0) { 
            Write-Host "Halo Company not found for $($huntressOrg.name). You will need to map manually." -ForegroundColor Yellow
            Write-Log -message "Halo Company not found for $($huntressOrg.name). You will need to map manually."
            $failedmapping += [PSCustomObject]@{
                huntressID = $huntressOrg.id
                huntressName = $huntressOrg.name
                reason = "Halo Company not found"
            } 
        } elseif ($haloOrg.record_count -eq 1) {
            Write-Log -message "Mapping $($huntressOrg.name) to $($haloOrg.clients.name)"
            $mapping += [PSCustomObject]@{
                supplierID = $supplierID
                supplierclientID = $huntressOrg.id
                supplierclientName = $huntressOrg.name
                HalocustomerID = $haloOrg.clients.id
                HalocustomerName = $haloOrg.clients.name
            }
        } else {
            Write-Host "Multiple Halo Companies found for $($huntressOrg.name). You will need to map manually." -ForegroundColor Yellow
            $failedmapping += [PSCustomObject]@{
                huntressID = $huntressOrg.id
                huntressName = $huntressOrg.name
                reason = "Multiple Halo Companies found"
            }
        }
    } Else { 
        Write-Host "Mapping already exists for $($huntressOrg.name) to $($mappingID.CFbillingsyncID)" -ForegroundColor Cyan
    }
}
function Get-MappingDecision {
    Write-Host "There are $($mapping.count) mappings to add.  $($failedmapping.count) companies couldn't be matched." -ForegroundColor Green
    Write-Host "Enter A to add mappings to the table, V to view mappings, F to view failed mappings, or any other key to exit" -ForegroundColor Green
    $addtomap = Read-Host
    if ($addtomap -eq "A") {
        try {
            $tableupdate = Update-HaloSyncMappingTable -data $mapping
            Write-Host "Table updated with $($tableupdate.count) records"
            Write-Log -message "Table updated with $($tableupdate.count) records"
            $tableupdatelog = $tableupdate | Select-Object -Property SupplierCompany,status,response
            $tableupdatelog >> $mappingoutput
            Write-Host "Table update log saved to $mappingoutput" -ForegroundColor Green
            write-log -message "Table update log saved to $mappingoutput"
        } catch {
            Write-Host "Failed to update table.  $($_.Exception.Message)" -ForegroundColor Red
            Write-Log -message "Failed to update table.  $($_)"
        }
    } elseif ($addtomap -eq "V") {
        $mapping | Out-GridView -Wait
        $addtomap = $null
        Get-MappingDecision
    }
    elseif ($addtomap -eq "F") {
        $failedmapping | Out-GridView -Wait
        $addtomap = $null
        Get-MappingDecision
    }
    else {
        Write-Host "User declined to add mappings to table"
    }
}
Get-MappingDecision

Write-log -message "Mapping Huntress Clients to Halo Companies complete. Returning to Menu."