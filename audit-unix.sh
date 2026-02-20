#!/bin/bash
# CyberAudit - Mac/Linux Audit Script
# Outputs structured JSON for the OpenClaw agent to parse

FIREWALL=false
AUTO_UPDATE=false
GUEST_ACCOUNT=false
RISKY_PORTS="[]"

# 1. Firewall check
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FW_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    [[ "$FW_STATUS" == *"enabled"* ]] && FIREWALL=true
else
    # Linux - check ufw or iptables
    if command -v ufw &>/dev/null; then
        UFW=$(ufw status 2>/dev/null | head -1)
        [[ "$UFW" == *"active"* ]] && FIREWALL=true
    elif command -v iptables &>/dev/null; then
        RULES=$(iptables -L 2>/dev/null | wc -l)
        [[ "$RULES" -gt 8 ]] && FIREWALL=true
    fi
fi

# 2. Auto-update check
if [[ "$OSTYPE" == "darwin"* ]]; then
    AU=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null)
    [[ "$AU" == "1" ]] && AUTO_UPDATE=true
else
    if dpkg -l unattended-upgrades &>/dev/null 2>&1; then
        AUTO_UPDATE=true
    fi
fi

# 3. Guest account check
if [[ "$OSTYPE" == "darwin"* ]]; then
    GUEST=$(dscl . -read /Users/Guest UserShell 2>/dev/null)
    [[ -n "$GUEST" ]] && GUEST_ACCOUNT=true
else
    if id guest &>/dev/null 2>&1; then
        GUEST_ACCOUNT=true
    fi
fi

# 4. Risky open ports
RISKY=(21 23 135 445 3389 5900)
FOUND=()

if command -v ss &>/dev/null; then
    LISTENING=$(ss -tuln 2>/dev/null)
elif command -v netstat &>/dev/null; then
    LISTENING=$(netstat -tuln 2>/dev/null)
fi

for PORT in "${RISKY[@]}"; do
    if echo "$LISTENING" | grep -q ":$PORT "; then
        FOUND+=("$PORT")
    fi
done

# Build ports JSON array
if [ ${#FOUND[@]} -eq 0 ]; then
    RISKY_PORTS="[]"
else
    RISKY_PORTS="[$(IFS=,; echo "${FOUND[*]}")]"
fi

# Output JSON
cat <<EOF
{"firewall":$FIREWALL,"autoUpdate":$AUTO_UPDATE,"guestAccount":$GUEST_ACCOUNT,"riskyPorts":$RISKY_PORTS}
EOF
