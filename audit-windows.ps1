# CyberAudit - Windows Audit Script
# Outputs structured JSON for the OpenClaw agent to parse

$result = @{
    firewall    = $false
    autoUpdate  = $false
    guestAccount = $false
    riskyPorts  = @()
}

# 1. Firewall check
try {
    $fw = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }
    $result.firewall = ($fw.Count -gt 0)
} catch {
    $result.firewall = $false
}

# 2. Auto-update check
try {
    $au = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -ErrorAction Stop).AUOptions
    # AUOptions 3 = auto download, 4 = auto install
    $result.autoUpdate = ($au -ge 3)
} catch {
    # Try alternate registry path
    try {
        $wuKey = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction Stop
        $result.autoUpdate = ($wuKey.NoAutoUpdate -eq 0)
    } catch {
        $result.autoUpdate = $false
    }
}

# 3. Guest account check
try {
    $guest = Get-LocalUser -Name "Guest" -ErrorAction Stop
    $result.guestAccount = $guest.Enabled
} catch {
    $result.guestAccount = $false
}

# 4. Risky open ports
$riskyPorts = @(21, 23, 135, 445, 3389, 5900)
$openPorts = @()

try {
    $connections = netstat -an | Select-String "LISTENING"
    foreach ($port in $riskyPorts) {
        if ($connections -match ":$port\s") {
            $openPorts += $port
        }
    }
} catch {}

$result.riskyPorts = $openPorts

# Output JSON
$result | ConvertTo-Json -Compress
