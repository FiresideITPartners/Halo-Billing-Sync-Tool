function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$message
    )
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logmessage = "$date - $message"
    Add-Content -Path $logfile -Value $logmessage
}