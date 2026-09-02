#!/usr/bin/env pwsh
# ─────────────────────────────────────────────────────────────────────────────
# Schemora Dev Runner
# Automatically detects the current Wi-Fi / LAN IP and launches Flutter with
# the correct --dart-define=DEV_HOST_IP so the physical Android device can
# always reach the backend, regardless of which network you are on.
#
# Usage:
#   .\run_dev.ps1                  # flutter run (default device)
#   .\run_dev.ps1 -d <device-id>   # specify device
#   .\run_dev.ps1 -Emulator        # Android emulator mode (uses 10.0.2.2)
# ─────────────────────────────────────────────────────────────────────────────

param(
    [string]$d = "",          # Device ID
    [switch]$Emulator = $false  # Use emulator loopback instead
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── 1. Detect current LAN IP ──────────────────────────────────────────────────
function Get-LanIP {
    # Prefer Wi-Fi adapter, then any active Ethernet with a real IP
    $adapters = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notmatch "^127\." -and
            $_.IPAddress -notmatch "^169\.254\." -and
            $_.PrefixOrigin -in @("Dhcp", "Manual")
        } |
        Sort-Object InterfaceAlias

    # Prefer Wi-Fi
    $wifi = $adapters | Where-Object { $_.InterfaceAlias -match "Wi-Fi|Wireless|WLAN" } | Select-Object -First 1
    if ($wifi) { return $wifi.IPAddress }

    # Fallback to first available
    $first = $adapters | Select-Object -First 1
    if ($first) { return $first.IPAddress }

    return $null
}

# ── 2. Resolve host ───────────────────────────────────────────────────────────
if ($Emulator) {
    $hostArg  = "--dart-define=USE_EMULATOR=true"
    $hostDisplay = "Android Emulator (10.0.2.2)"
} else {
    $ip = Get-LanIP
    if (-not $ip) {
        Write-Host ""
        Write-Host "  ERROR: Could not detect a LAN/Wi-Fi IP address." -ForegroundColor Red
        Write-Host "  Make sure your PC is connected to the same Wi-Fi as your phone," -ForegroundColor Yellow
        Write-Host "  or run:  .\run_dev.ps1 -Emulator" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    $hostArg  = "--dart-define=DEV_HOST_IP=$ip"
    $hostDisplay = "Physical device  →  http://$ip:8000/api/v1/"
}

# ── 3. Print banner ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║           Schemora  ·  Dev Runner                   ║" -ForegroundColor Cyan
Write-Host "  ╠══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "  ║  Target : $($hostDisplay.PadRight(42))  ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 4. Build flutter run args ─────────────────────────────────────────────────
$flutterArgs = @("run", $hostArg)
if ($d) { $flutterArgs += @("-d", $d) }

# ── 5. Change to frontend dir and run ─────────────────────────────────────────
Push-Location "$PSScriptRoot\frontend"
try {
    Write-Host "  Running: flutter $($flutterArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & flutter @flutterArgs
} finally {
    Pop-Location
}
