#region Introduction
Write-Host @"
The Sync Tool uses a local SecretStore to store and manage credentials.  
This script will help you configure the SecretStore for use with the Sync Tool.
The SecretStore is a secure storage location for credentials that is protected by a password.  
The SecretStore is a local store that is only accessible to the user that created it.  
It is not shared between users or systems.
-------------------------------------------------------------
This script is going to test for an existing Secret Store and create one if it does not exist, 
or configure it to be used with the Sync Tool if it does exist.
Two Powershell modules may be required to be installed: Microsoft.PowerShell.SecretManagement and Microsoft.PowerShell.SecretStore
-------------------------------------------------------------
"@ -ForegroundColor Green
#endregion
#region Check for existing Secret Store
Write-Host "Checking for existing Secret Store..."
#region Check if the required modules are installed
$requiredModules = @("Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Debug "The required module '$module' is not installed. Installing it now..."
        Install-Module -Name $module -Force -Scope CurrentUser
    } else {
        Write-Debug "The required module '$module' is installed."
    }
}
#endregion
#region Vault Configuration
$keypath = "$PSScriptRoot\secretstorekey.xml"
$vault = get-secretvault | where-object {$_.ModuleName -eq 'Microsoft.Powershell.SecretStore'}
if ($null -eq $vault) {
    Write-Host "No SecretStore found. Creating a new SecretStore..."
    $vaultName = "SecretStore"
    register-SecretVault -Name $vaultName -Module Microsoft.Powershell.SecretStore -DefaultVault
    $vault = get-secretvault | where-object {$_.ModuleName -eq 'Microsoft.Powershell.SecretStore'}
    if ($null -eq $vault) {
        Write-Host "Failed to create the SecretStore. Exiting script."
        exit
    }
    Write-Host "Please create a password for the new SecretStore.  The App will use this password to unlock the SecretStore and access the stored credentials."
    Write-Host "You will be able to use this password to unlock the SecretStore in the future, outside of this app."
    $credential = Get-Credential -Message "Enter a password for the SecretStore" -UserName "SecretStore"
    $keypath = "$PSScriptRoot\secretstorekey.xml"
    $credential.Password | Export-Clixml -Path $keypath
    $SecretStoreKey = Import-Clixml -Path $keypath
    #Secret Store Configuration
    $storeConfiguration = @{
        Authentication = 'Password'
        PasswordTimeout = 3600 # 1 hour
        Interaction = 'None'
        Password = $SecretStoreKey
        Confirm = $false
    }
    Set-SecretStoreConfiguration @storeConfiguration
    Write-Host "SecretStore '$vaultName' created successfully."
} else {
    Write-Host "SecretStore found. Using existing SecretStore."
    if ($vault.Count -gt 1) {
        Write-Host "Multiple Local SecretStores found. This Scenario is not supported."
        exit
        }
    } else {
        $vaultName = $vault.Name
    }
    Write-Host "Using SecretStore '$vaultName'."
    if (Test-Path -Path $keypath) {
        Write-Host "Existing SecretStore key file found at $keypath. Using the existing key file."
        $SecretStoreKey = Import-Clixml -Path $keypath
    } else {
        Write-Host "No existing SecretStore key file found. Please enter the password for the existing SecretStore."
        $credential = Get-Credential -Message "Enter the password for the existing SecretStore" -UserName "SecretStore"
        $credential.Password | Export-Clixml -Path $keypath
        $SecretStoreKey = Import-Clixml -Path $keypath
    }
    try {
        Unlock-SecretStore -Password $SecretStoreKey
    }
    catch {
        Write-Host "Failed to unlock the SecretStore. Check provided password.  Exiting script."
        exit
    }
    #Secret Store Configuration
    $storeConfiguration = @{
        Authentication = 'Password'
        PasswordTimeout = 3600 # 1 hour
        Interaction = 'None'
        Confirm = $false
    }
    Set-SecretStoreConfiguration @storeConfiguration

#endregion
Write-Host "-------------------------------------------------------------"
#region Test Vault
try { 
    Unlock-SecretStore -Password $SecretStoreKey
}
catch { 
    Write-Host "Failed to unlock the SecretStore. Exiting script."
    exit 
}
try {
    $testSecret = "ThisIsATestSecret"
    Set-Secret -Name "TestSecret" -Secret $testSecret -Vault $vaultName
    Write-Host "Test secret has been saved in the SecretVault."
}
catch {
    Write-Host "Failed to save a test secret in the SecretStore. Exiting script."
    exit
}
try {
    Get-Secret -Name "TestSecret" -Vault $vaultName
    Write-Host "Test secret has been retrieved from the SecretVault."
}
catch {
    Write-Host "Failed to retrieve the test secret from the SecretStore. Exiting script."
    exit
}
#endregion

$SecretStoreConfiguration = @{
    VaultName = $vaultName
    SecretStoreKeyPath = $keypath
}
$SecretStoreConfiguration | Export-Clixml -Path "$PSScriptRoot\secretvaultconfig.xml"
Write-Host "SecretVault information has been set successfully."