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

## License

This project is open source and available for use.

## Support

For more information about the Huntress health API, visit:
- [Huntress EDR Agent Health API Documentation](https://support.huntress.io/hc/en-us/articles/41209077330323-EDR-Agent-Health-API)
- [Huntress API Reference](https://api.huntress.io/docs)