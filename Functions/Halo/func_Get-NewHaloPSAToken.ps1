function Get-NewHaloPSAToken {
    # Get the client ID and secret from the keyvault referenced in the config file.
    try {
      $HaloclientId = get-secret -Name $config.halo.clientID -vault $config.keyvault -asplaintext
      $HaloclientSecret = get-secret -Name $config.halo.clientSecret -vault $config.keyvault -asplaintext
      } catch {
      Write-Log -message "Failed to retrieve client ID or secret from KeyVault: $($_.Exception.Message)"
      throw "Failed to retrieve client ID or secret from KeyVault: $($_.Exception.Message)"
      }
      
      #HALO Base Url is defined in the config file.  Joining it to the standard Halo Auth path
      $HaloAuthUrl = $config.halo.HalobaseURI + "/auth/token"
      #Build Request Body
      $body = @{
          grant_type = "client_credentials"
          client_id = $HaloclientId
          client_secret = $HaloclientSecret
          scope = "all"
      }
  
      #Get the token from the Halo API, catching the exception if it fails.  Failure at this point is a critical error and will stop the script.
      Write-log -message "Getting Token from $HaloAuthUrl"
      try {
          $halotoken = Invoke-RestMethod -StatusCodeVariable "statusCode" -Method Post -Uri $HaloAuthUrl -Body $body
      }
      catch {
          Write-Log -message "Failed to retrieve token from Halo API: $($_.Exception.Message)"
          throw "Failed to retrieve token from Halo API: $($_.Exception.Message)"
      }
      #Set Global Variables for the token and the expiry time
      #Set Global Variables for the token and the expiry time
      $expirypadded = (Get-Date).AddSeconds($halotoken.expires_in).AddSeconds(-90)
      $global:HaloToken = $halotoken.access_token
      $global:HaloTokenExpiry = $expirypadded
  }