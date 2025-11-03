# huntressmonitor

A PowerShell script to monitor the health status of Huntress EDR agent.

## Description

This repository contains a PowerShell script that queries the Huntress agent's local health API endpoint to determine if the agent is running and healthy. The script provides clear status reporting with color-coded output for easy visualization.

## Features

- **Health Status Check**: Queries the local Huntress agent health endpoint (`http://localhost:24799/health`)
- **Status Reporting**: Reports agent status as Healthy, Degraded, or Unhealthy
- **Color-Coded Output**: Uses color coding for easy status identification (Green=Healthy, Yellow=Degraded, Red=Unhealthy)
- **Detailed Information**: Optional verbose mode shows service states, versions, timestamps, and connectivity information
- **Error Handling**: Gracefully handles cases where the agent is not installed or not running
- **Exit Codes**: Returns appropriate exit codes for automation and monitoring systems
- **Syncro Integration**: Send alerts to Syncro RMM client software using custom asset fields (NEW)

## Prerequisites

- Windows PowerShell 5.1 or PowerShell Core 7+
- Huntress EDR agent must be installed on the system

## Usage

### Basic Health Check

```powershell
.\Check-HuntressHealth.ps1
```

This displays the basic health status of the Huntress agent.

### Detailed Health Check

```powershell
.\Check-HuntressHealth.ps1 -Verbose
```

This displays detailed information including:
- Service states for all Huntress components
- Version information
- Timestamps for recent activities
- Connectivity status

### JSON Output

```powershell
.\Check-HuntressHealth.ps1 -Json
```

This returns the raw JSON response from the health API, useful for integration with other systems.

### Syncro Integration

```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro
```

Checks Huntress health and sends alert data to Syncro client software. Requires Syncro client to be installed on the system.

**Custom Field Prefix:**

```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "hnt_"
```

Uses a custom prefix for Syncro custom field names (default is "huntress_").

**Combined with Verbose:**

```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose
```

Displays detailed health information and sends data to Syncro with verbose logging.

## Exit Codes

The script returns the following exit codes:

- `0` - Healthy: Agent is running and healthy
- `1` - Degraded: Agent is running but some components may have issues
- `2` - Unhealthy: Agent has significant issues
- `3` - Unknown: Status could not be determined
- `10` - Error: Unable to reach the health endpoint (agent not installed/running)

## Example Output

### Healthy Agent
```
Huntress Agent Health Check
==================================================

Overall Status: Healthy
```

### With Verbose Output
```
Huntress Agent Health Check
==================================================

Overall Status: Healthy

Service States:
  HuntressAgent: Running
  HuntressUpdater: Running

Versions:
  Agent: 1.2.3
  Updater: 1.0.1

Timestamps:
  LastError: 2025-11-02T10:00:00Z
  LastEvent: 2025-11-02T23:55:00Z
```

## Integration with Monitoring Systems

The script can be easily integrated with monitoring systems like:
- Scheduled Tasks (Windows Task Scheduler)
- RMM tools (Remote Monitoring and Management)
- SIEM systems
- Custom monitoring dashboards

Example for scheduled monitoring:

```powershell
# Run every 5 minutes and log results
$result = & .\Check-HuntressHealth.ps1
if ($LASTEXITCODE -ne 0) {
    # Send alert or log error
    Write-EventLog -LogName Application -Source "HuntressMonitor" -EventId 1001 -Message "Huntress agent health check failed with exit code: $LASTEXITCODE"
}
```

## Syncro RMM Integration

HuntressMonitor can send alert data to Syncro RMM client software installed on the same computer. This integration uses Syncro's custom asset fields to store and track Huntress agent health information.

### Prerequisites

- Syncro client software must be installed on the system
- Syncro is typically installed at: `C:\Program Files\RepairTech\Syncro\`
- The Syncro client executable (`kabuto.exe`) must be accessible

### How It Works

When the `-AlertSyncro` parameter is used:

1. **Detection**: The script automatically detects if Syncro client is installed
2. **Data Collection**: Huntress health data is collected from the health API
3. **Field Mapping**: Health data is mapped to Syncro custom asset fields
4. **Transmission**: Data is sent to Syncro using the Syncro CLI interface

### Syncro Custom Fields

The following custom asset fields are created/updated in Syncro (with default prefix `huntress_`):

| Field Name | Description | Example Value |
|------------|-------------|---------------|
| `huntress_status` | Current health status | Healthy, Degraded, or Unhealthy |
| `huntress_last_check` | Timestamp of last check | 2025-11-03 00:15:30 |
| `huntress_message` | Status message | All systems operational |
| `huntress_agent_version` | Huntress agent version | 1.2.3 |
| `huntress_services` | Service states | HuntressAgent:Running, HuntressUpdater:Running |

### Configuration Options

#### Default Prefix

```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro
```

Uses the default prefix `huntress_` for all custom fields.

#### Custom Prefix

```powershell
.\Check-HuntressHealth.ps1 -AlertSyncro -SyncroFieldPrefix "hnt_"
```

Uses a custom prefix (e.g., `hnt_`) for field names. This creates fields like `hnt_status`, `hnt_last_check`, etc.

### Scheduled Monitoring with Syncro

You can create a scheduled task to run the health check and update Syncro automatically:

```powershell
# Run every 15 minutes and update Syncro
.\Check-HuntressHealth.ps1 -AlertSyncro

# With verbose logging
.\Check-HuntressHealth.ps1 -AlertSyncro -Verbose
```

### Syncro Alerting

Once the custom fields are populated in Syncro, you can:

- Create Syncro alerts based on the `huntress_status` field
- Monitor trends using the `huntress_last_check` timestamp
- Track agent version updates via `huntress_agent_version`
- View service states in the Syncro dashboard

Example Syncro alert configuration:
- **Condition**: `huntress_status` equals "Degraded" or "Unhealthy"
- **Action**: Create ticket or send notification
- **Frequency**: Check every 15 minutes

### Security Considerations

- **Local Communication**: Data is sent only to the local Syncro client (no network transmission to external servers)
- **Official Interface**: Uses Syncro's official CLI interface (`kabuto.exe`)
- **Limited Data**: Only health status data is transmitted (no sensitive credentials or keys)
- **Authenticated**: Requires Syncro client to be installed and authenticated

### Troubleshooting

#### Syncro Not Found

If you see: `WARNING: Syncro client not found`

- Verify Syncro client is installed: Check `C:\Program Files\RepairTech\Syncro\`
- Ensure `kabuto.exe` exists in the Syncro directory
- Try reinstalling Syncro client if necessary

#### Field Update Failures

If custom fields fail to update:

- Run with `-Verbose` flag to see detailed error messages
- Check Syncro client service is running
- Verify Syncro client is properly authenticated
- Review Syncro logs for additional details

### Testing

Use the included test script to verify Syncro integration:

```powershell
.\Test-SyncroIntegration.ps1 -TestScenario "Installed"
```

This demonstrates how the integration works and what data is sent to Syncro.

## License

This project is open source and available for use.

## Support

For more information about the Huntress health API, visit:
- [Huntress EDR Agent Health API Documentation](https://support.huntress.io/hc/en-us/articles/41209077330323-EDR-Agent-Health-API)
- [Huntress API Reference](https://api.huntress.io/docs)