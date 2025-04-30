param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("igm", "email")]
    [string]$Type
)

# Path to the JSON config file
$ConfigFilePath = "C:\Scripts\Config.json"

# Validate the config file exists
if (-not (Test-Path $ConfigFilePath)) {
    Write-Host "Config file not found at path: $ConfigFilePath" -ForegroundColor Red
    exit 1
}

# Read and parse the JSON configuration
try {
    $Config = Get-Content -Path $ConfigFilePath | ConvertFrom-Json
} catch {
    Write-Host "Failed to parse the JSON config file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Construct the key and retrieve the domain name
$Key = "${Environment}_${Type}"
if (-not $Config.Domains.ContainsKey($Key)) {
    Write-Host "Invalid environment or type specified. Key: $Key not found in config file." -ForegroundColor Red
    exit 1
}

$Domain = $Config.Domains.$Key

# Retrieve the API key for the type
if (-not $Config.ApiKeys.ContainsKey($Type)) {
    Write-Host "API key for type '$Type' not found in config file." -ForegroundColor Red
    exit 1
}

$ApiKey = $Config.ApiKeys.$Type
$ApiUrl = "https://$Domain/api/health"

# Enable logging
$LogFile = "C:\Logs\CheckApiStatus.log"
Start-Transcript -Path $LogFile -Append

Write-Host "Environment: $Environment"
Write-Host "Type: $Type"
Write-Host "API URL: $ApiUrl"
Write-Host "Using API Key for Type: $Type"

# Call the API with the API key
try {
    $Response = Invoke-WebRequest -Uri $ApiUrl -Headers @{ "Authorization" = "Bearer $ApiKey" } -UseBasicParsing -TimeoutSec 30
    if ($Response.StatusCode -eq 200) {
        Write-Host "API call succeeded." -ForegroundColor Green
        Stop-Transcript
        exit 0
    } else {
        Write-Host "API call failed with status: $($Response.StatusCode)" -ForegroundColor Red
        Stop-Transcript
        exit 1
    }
} catch {
    Write-Host "API call failed: $($_.Exception.Message)" -ForegroundColor Red
    Stop-Transcript
    exit 1
}
