<#
.SYNOPSIS
    Checks the health status of the Huntress EDR agent.

.DESCRIPTION
    This script queries the Huntress agent's local health API endpoint to determine
    if the agent is running and healthy. It returns the overall status (Healthy, 
    Degraded, or Unhealthy) along with additional diagnostic information.

.PARAMETER Verbose
    Displays detailed information about the agent's health including service states,
    versions, and timestamps.

.PARAMETER Json
    Returns the raw JSON response from the health endpoint.

.PARAMETER AlertSyncro
    Sends alert information to Syncro client software using Syncro custom asset fields.
    Requires Syncro client to be installed on the system.

.PARAMETER SyncroFieldPrefix
    Prefix to use for Syncro custom field names. Default is "huntress_".
    For example, with default prefix, the status field will be "huntress_status".

.EXAMPLE
    .\Check-HuntressHealth.ps1
    Displays the basic health status of the Huntress agent.

.EXAMPLE
    .\Check-HuntressHealth.ps1 -Verbose
    Displays detailed health information including service states and versions.

.EXAMPLE
    .\Check-HuntressHealth.ps1 -Json
    Returns the raw JSON response from the health API.

.EXAMPLE
    .\Check-HuntressHealth.ps1 -AlertSyncro
    Checks Huntress health and sends alert data to Syncro client.

.EXAMPLE
    .\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "huntress_agent_"
    Checks Huntress health and sends data to Syncro with custom field prefix.

.NOTES
    Author: Huntress Monitor
    Version: 2.0
    The Huntress agent must be installed and running for this script to work.
    The health endpoint is available at: http://localhost:24799/health
    
    Syncro Integration:
    - Syncro client must be installed for -AlertSyncro to work
    - Custom asset fields will be created/updated with Huntress health data
    - Fields created: <prefix>status, <prefix>last_check, <prefix>agent_version
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Json,
    
    [Parameter(Mandatory=$false)]
    [switch]$AlertSyncro,
    
    [Parameter(Mandatory=$false)]
    [string]$SyncroFieldPrefix = "huntress_"
)

# Health endpoint URL
$healthEndpoint = "http://localhost:24799/health"

# Function to detect Syncro client installation
function Test-SyncroInstalled {
    <#
    .SYNOPSIS
        Checks if Syncro client is installed on the system.
    
    .DESCRIPTION
        Looks for Syncro client executable in common installation paths.
        Returns the path to the Syncro executable if found, otherwise returns $null.
    #>
    
    $syncroLocations = @(
        # Modern Syncro installation path - kabuto.exe is the primary CLI tool
        "${env:ProgramFiles}\RepairTech\Syncro\kabuto.exe",
        "${env:ProgramFiles(x86)}\RepairTech\Syncro\kabuto.exe",
        # Older installation paths
        "${env:ProgramData}\Syncro\kabuto.exe",
        "${env:ProgramData}\RepairTech\Syncro\kabuto.exe"
    )
    
    foreach ($location in $syncroLocations) {
        if (Test-Path $location) {
            Write-Verbose "Found Syncro client at: $location"
            return $location
        }
    }
    
    Write-Verbose "Syncro client not found in standard locations"
    return $null
}

# Function to send alert to Syncro
function Send-SyncroAlert {
    <#
    .SYNOPSIS
        Sends alert information to Syncro client using custom asset fields.
    
    .DESCRIPTION
        Uses the Syncro client executable to set custom asset fields with
        Huntress health information.
    
    .PARAMETER SyncroPath
        Path to the Syncro executable.
    
    .PARAMETER HealthData
        Health data object from Huntress API response.
    
    .PARAMETER FieldPrefix
        Prefix for Syncro custom field names.
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$SyncroPath,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$HealthData,
        
        [Parameter(Mandatory=$false)]
        [string]$FieldPrefix = "huntress_"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Prepare the data to send to Syncro
        $syncroFields = @{
            "${FieldPrefix}status" = $HealthData.status
            "${FieldPrefix}last_check" = $timestamp
            "${FieldPrefix}message" = $HealthData.message
        }
        
        # Add agent version if available
        if ($HealthData.versions -and $HealthData.versions.Agent) {
            $syncroFields["${FieldPrefix}agent_version"] = $HealthData.versions.Agent
        }
        
        # Add service states if available
        if ($HealthData.serviceStates) {
            $serviceStatesStr = ($HealthData.serviceStates.PSObject.Properties | 
                ForEach-Object { "$($_.Name):$($_.Value)" }) -join ", "
            $syncroFields["${FieldPrefix}services"] = $serviceStatesStr
        }
        
        Write-Verbose "Sending alert data to Syncro..."
        
        # Set each custom field using Syncro's CLI
        foreach ($field in $syncroFields.GetEnumerator()) {
            $fieldName = $field.Key
            $fieldValue = $field.Value
            
            # Validate field name to prevent injection (alphanumeric, underscore, hyphen only)
            if ($fieldName -notmatch '^[a-zA-Z0-9_-]+$') {
                Write-Warning "Skipping invalid field name: $fieldName"
                continue
            }
            
            # Sanitize field value (remove potentially dangerous characters)
            $safeFieldValue = $fieldValue -replace '["`$]', ''
            
            Write-Verbose "Setting Syncro field: $fieldName = $safeFieldValue"
            
            # Use Syncro's asset field setting capability
            # Build arguments array for safe parameter passing
            $arguments = @(
                "asset_field",
                "set",
                $fieldName,
                $safeFieldValue
            )
            
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $SyncroPath
            $processInfo.Arguments = ($arguments | ForEach-Object { "`"$_`"" }) -join ' '
            $processInfo.UseShellExecute = $false
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.CreateNoWindow = $true
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            
            [void]$process.Start()
            
            # Read output asynchronously to prevent deadlock
            $output = $process.StandardOutput.ReadToEndAsync()
            $errorOutput = $process.StandardError.ReadToEndAsync()
            
            $process.WaitForExit()
            
            $outputText = $output.Result
            $errorText = $errorOutput.Result
            
            if ($process.ExitCode -eq 0) {
                Write-Verbose "Successfully set field: $fieldName"
            } else {
                Write-Warning "Failed to set field $fieldName. Exit code: $($process.ExitCode)"
                if ($errorText) {
                    Write-Verbose "Error details: $errorText"
                }
            }
        }
        
        Write-Host "`nSyncro Alert: Data sent to Syncro client" -ForegroundColor Green
        Write-Host "Fields updated with prefix: $FieldPrefix" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Warning "Failed to send alert to Syncro: $($_.Exception.Message)"
        Write-Verbose "Error details: $($_.Exception)"
        return $false
    }
}


try {
    Write-Verbose "Querying Huntress health endpoint at $healthEndpoint"
    
    # Query the health endpoint
    $response = Invoke-RestMethod -Uri $healthEndpoint -Method Get -ErrorAction Stop
    
    if ($Json) {
        # Return raw JSON response
        $response | ConvertTo-Json -Depth 10
        exit 0
    }
    
    # Display health status with color coding
    Write-Host "`nHuntress Agent Health Check" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    
    $status = $response.status
    $statusColor = switch ($status) {
        "Healthy" { "Green" }
        "Degraded" { "Yellow" }
        "Unhealthy" { "Red" }
        default { "White" }
    }
    
    Write-Host "`nOverall Status: " -NoNewline
    Write-Host $status -ForegroundColor $statusColor
    
    if ($response.message) {
        Write-Host "Message: $($response.message)"
    }
    
    # Display detailed information in verbose mode
    if ($VerbosePreference -eq 'Continue' -or $PSBoundParameters.ContainsKey('Verbose')) {
        if ($response.serviceStates) {
            Write-Host "`nService States:" -ForegroundColor Cyan
            $response.serviceStates.PSObject.Properties | ForEach-Object {
                $serviceStatus = if ($_.Value -eq "Running") { "Green" } else { "Red" }
                Write-Host "  $($_.Name): " -NoNewline
                Write-Host $_.Value -ForegroundColor $serviceStatus
            }
        }
        
        if ($response.versions) {
            Write-Host "`nVersions:" -ForegroundColor Cyan
            $response.versions.PSObject.Properties | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)"
            }
        }
        
        if ($response.timestamps) {
            Write-Host "`nTimestamps:" -ForegroundColor Cyan
            $response.timestamps.PSObject.Properties | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)"
            }
        }
        
        if ($response.connectivity) {
            Write-Host "`nConnectivity:" -ForegroundColor Cyan
            $response.connectivity.PSObject.Properties | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Value)"
            }
        }
    }
    
    Write-Host "`n" -NoNewline
    
    # Send alert to Syncro if requested
    if ($AlertSyncro) {
        Write-Verbose "Syncro alert requested, checking for Syncro installation..."
        $syncroPath = Test-SyncroInstalled
        
        if ($syncroPath) {
            Write-Verbose "Syncro client found, sending alert data..."
            $syncroSuccess = Send-SyncroAlert -SyncroPath $syncroPath -HealthData $response -FieldPrefix $SyncroFieldPrefix
            
            if (-not $syncroSuccess) {
                Write-Warning "Failed to send complete alert data to Syncro"
            }
        } else {
            Write-Warning "Syncro client not found. Install Syncro client to enable alert functionality."
            Write-Host "Syncro is typically installed at: C:\Program Files\RepairTech\Syncro\" -ForegroundColor Yellow
        }
    }
    
    # Set exit code based on status
    switch ($status) {
        "Healthy" { 
            exit 0 
        }
        "Degraded" { 
            exit 1 
        }
        "Unhealthy" { 
            exit 2 
        }
        default { 
            exit 3 
        }
    }
    
} catch {
    Write-Host "`nError: Unable to reach Huntress health endpoint" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPossible causes:" -ForegroundColor Yellow
    Write-Host "  - Huntress agent is not installed"
    Write-Host "  - Huntress agent is not running"
    Write-Host "  - Health API endpoint is not accessible"
    Write-Host "`nPlease ensure the Huntress agent is installed and running."
    exit 10
}
