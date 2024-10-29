# Halo Universal Billing Sync  

This is a Powershell App to manage syncing profiles for a Halo tenant and any product with a Restful API you want to sync to Subscriptions.  

There will be some setup prerequisites to get this running.  Ideally we will script those as deployment steps, but for now we will document them as manual.  
  
- Powershell Secrets Vault
  - AzureKeyVault or Local
  - Stores API credentials for connecting services  
  - [SecretManagement in Powershell Overview](https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/overview?view=ps-modules)
- CustomTable to house sync mapping data
  - HaloAreaID (int)
  - ThirdPartySupplierID (int)
  - ThirdPartyCustomerID (int)
  - ThirdPartyMiscData (string)
- CustomTable for Subscription Name Matching and defaults
  - Name of Subscription in Halo (str)
  - Name of Product in Third Party (str)
  - Third Party SKU or unique ID (str, Supplier)
  - Manufacturer (Ususally Supplier, but may not be in case of products bought through Distribution)
  - BillingCycle
  - Cost (Purchase Price)
  - Selling Price
- CustomTable for tracking Synced Subscriptions
  - HaloSubscriptionID
  - ThirdPartyID

## Functions to Build

### Overall App Functionality

- Menu (Launching Point)
- *Save-Credentials (Add API credentials to Secrets Vault)*
  - **Decided to leave KeyVault management to end user.  Shifted to a config.json file where the secret names can be stored and recalled.**
- *Unlock-KeyVAult (Unlocks Configured Keyvault for use in App)*
- HaloAuthentication (Built, need to implement in a way that can be used by other companies)  
  - **Uses config file variables, the individual using this just needs to add their secret names to the variables in config.json**
- New-HaloCustomTable (Optional, part of initial deployment and setup)
  - **I will leave this as a manual deployment step, too many variables to account for between environments.  Custom Table variables will then be set in the config.json to allow custom labels without having to modify scripts.**
- Set-HaloCustomTableData (Add Data to CustomTable)  
  - Will we use a single Function for setting Data and pass hash-table for fields and values, or create a function for each table?  
- Get-HaloCustomers (List Active Halo Clients)
  - **Current Method is to do a single company lookup per company found in third party.  Halo's API has very noisy output, so this should limit memory usage and response sizes.**
- Get-HaloSuppliers (List Active Halo Suppliers.  ThirdParty syncs will be mapped to Suppliers)
- New-HaloSupplier (Create New Supplier)
- New-HaloSubscription (Creates a new subscription for a tenant)
- Update-HaloSubscription (Updates an existing subscription)
- Deactivate-HaloSubscription (Deletes an existing subscription)  
- Set-SyncRelationship (Creates or removes a sync mapping between Halo Client and ThirdParty)

### Per Sync'd Service

- API Authentication
- Get Customer/Tenant List
- Get Service Details/Qty's per tenant
  - Implementation will depend on third party, function must return a Product Name, Customer ID, QTY, and hopefully a product SKU or UID
