# CyberAudit — Local Security Audit Skill

> Know your exposure. Fix what matters.
> *by cybersecurity experts*

## What This Skill Does

CyberAudit runs a local security audit on the user's machine. It checks 4 key areas, generates a security score (0–100), and produces a plain-English report with actionable fixes. No data leaves the machine.

## How to Run It

1. Detect the OS
2. Run the appropriate audit script
3. Parse the JSON output
4. Calculate the score
5. Present the formatted report to the user

### Detect OS
```
Windows → run audit-windows.ps1
Mac/Linux → run audit-unix.sh
```

### Run the script

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File audit-windows.ps1
```

**Mac/Linux (bash):**
```bash
bash audit-unix.sh
```

Both scripts output a single JSON object to stdout.

## JSON Output Schema

```json
{
  "firewall": true,
  "autoUpdate": false,
  "guestAccount": false,
  "riskyPorts": [3389, 5900]
}
```

## Score Calculation

Start at 0. Add points:

| Check | Points |
|---|---|
| Firewall ON | +30 |
| Auto-updates ON | +25 |
| Guest account disabled | +20 |
| No risky ports open | +25 |

Deduct 5 points per risky port found (minimum score: 0).

**Grade scale:**
- 90–100 → A
- 80–89 → B
- 70–79 → C
- 60–69 → D
- Below 60 → F

## Risky Ports Reference

| Port | Service | Risk |
|---|---|---|
| 21 | FTP | HIGH |
| 23 | Telnet | HIGH |
| 3389 | RDP | MEDIUM |
| 5900 | VNC | MEDIUM |
| 445 | SMB | HIGH |
| 135 | RPC | MEDIUM |

## Report Format

Present exactly like this to the user:

```
🔐 CyberAudit Report
━━━━━━━━━━━━━━━━━━━
Security Score: 72/100 (C)

✅ Firewall: Active
❌ Auto-Updates: Disabled
✅ Guest Account: Disabled
⚠️  Open Ports: 3389 (RDP) detected

📋 What to Fix:
1. [HIGH] Enable automatic updates
   → Windows: Settings > Windows Update > Advanced Options > Automatic
   → Mac: System Settings > General > Software Update > Automatic
2. [MEDIUM] Close port 3389 if you're not using Remote Desktop
   → Windows: Settings > System > Remote Desktop > toggle OFF

━━━━━━━━━━━━━━━━━━━
by cybersecurity experts | CyberAudit v1.0
```

**Status icons:**
- ✅ = passing
- ❌ = failing (deducted points)
- ⚠️ = warning (risky ports)

Only list items under "What to Fix" for checks that failed. If everything passes, say: "✅ No critical issues found. Nice work."
