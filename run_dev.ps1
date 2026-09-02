param(
    [string]$d       = "",           # Device ID override
    [switch]$Emulator = $false,      # Use Android emulator loopback
    [switch]$Release  = $false       # Build in release mode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 1. Detect current LAN IP
function Get-LanIP {
    try {
        $wifiIP = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.InterfaceAlias -match "Wi-Fi|Wireless|WLAN" -and $_.IPAddress -notmatch "^(127|169\.254)\." } |
            Select-Object -ExpandProperty IPAddress -First 1

        if ($wifiIP) { return $wifiIP }

        $anyIP = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notmatch "^(127|169\.254)\." -and $_.PrefixOrigin -in @("Dhcp", "Manual") } |
            Select-Object -ExpandProperty IPAddress -First 1

        if ($anyIP) { return $anyIP }
    } catch {}

    return $null
}

# 2. Auto-detect connected Android device ID
function Get-AndroidDeviceId {
    try {
        $devicesOutput = & flutter devices 2>$null
        foreach ($line in $devicesOutput) {
            if ($line -match "\(mobile\)" -or $line -match "android") {
                if ($line.Contains("•")) {
                    $parts = $line.Split([char[]]@('•'))
                    if ($parts.Count -ge 2) {
                        $devId = $parts[1].Trim()
                        if ($devId) { return $devId }
                    }
                }
            }
        }
    } catch {}
    return $null
}

# 3. Resolve host
if ($Emulator) {
    $hostArg     = "--dart-define=USE_EMULATOR=true"
    $hostDisplay = "Android Emulator (10.0.2.2)"
} else {
    $ip = Get-LanIP
    if (-not $ip) {
        Write-Host ""
        Write-Host "  ERROR: No LAN/Wi-Fi IP detected." -ForegroundColor Red
        Write-Host "  Make sure your PC is on the same Wi-Fi as your phone," -ForegroundColor Yellow
        Write-Host "  or run: .\run_dev.ps1 -Emulator" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    $hostArg     = "--dart-define=DEV_HOST_IP=$ip"
    $hostDisplay = "http://$ip:8000/api/v1/"
}

# 4. Resolve device
$deviceDisplay = ""
if ($d) {
    $deviceDisplay = "Device (manual): $d"
} elseif (-not $Emulator) {
    $detected = Get-AndroidDeviceId
    if ($detected) {
        $d             = $detected
        $deviceDisplay = "Auto-detected: $d"
    } else {
        $deviceDisplay = "No Android device found"
    }
}

# 5. Print info
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "             Schemora Dev Runner                  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  API    : $hostDisplay" -ForegroundColor Cyan
Write-Host "  Device : $deviceDisplay" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 6. Build flutter run args
$flutterArgs = @("run", $hostArg)
if ($d)        { $flutterArgs += @("-d", $d) }
if ($Release)  { $flutterArgs += "--release" }

# 7. Launch
Push-Location "$PSScriptRoot\frontend"
try {
    $cmdStr = "flutter " + ($flutterArgs -join " ")
    Write-Host "  Running: $cmdStr" -ForegroundColor DarkGray
    Write-Host ""
    & flutter @flutterArgs
} finally {
    Pop-Location
}
