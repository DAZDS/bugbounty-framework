#!/bin/bash

TARGET=$1
BASE_DIR=~/bugbounty-framework/output/$TARGET
INFILE="$BASE_DIR/live_subdomains.txt"
OUTFILE="$BASE_DIR/vulnscan.txt"
RC_DIR="$BASE_DIR/metasploit"
CVE_MATCH_FILE="$BASE_DIR/service_cve_matches.txt"
FILTERED="$BASE_DIR/vulnscan_filtered.txt"

mkdir -p "$BASE_DIR" "$RC_DIR"

if [[ ! -f "$INFILE" ]]; then
    echo "[!] Live subdomains not found at $INFILE"
    exit 1
fi

echo "[*] Starting Nmap vulnerability scan for $TARGET at $(date)"
nmap -iL "$INFILE" -sV --script vuln -T4 -oN "$OUTFILE"

# === 1. Podstawowe filtrowanie CVE/podatności ===
echo "[*] Extracting vulnerable hosts from Nmap output..."
grep -iE "CVE|vuln|exploit" "$OUTFILE" > "$FILTERED"
if [[ -s "$FILTERED" ]]; then
    echo "[+] CVEs or known vulnerabilities found and saved to: $FILTERED"
    # notify-send "Vulnerabilities Found for $TARGET"
else
    echo "[!] No CVEs or known vulnerabilities found in Nmap output."
fi

# === 2. Dopasowanie fingerprintów usług do CVE przez searchsploit ===
echo "[*] Fingerprinting services and matching against ExploitDB (searchsploit)..."
> "$CVE_MATCH_FILE"
grep -E "[0-9]+/tcp.*open" "$OUTFILE" | while read -r line; do
    service=$(echo "$line" | awk '{$1=$1};1' | cut -d' ' -f4-)
    if [[ -n "$service" ]]; then
        echo -e "\n[+] Service: $service" >> "$CVE_MATCH_FILE"
        searchsploit "$service" >> "$CVE_MATCH_FILE"
    fi
done

echo "[✓] Fingerprint CVE matching saved to: $CVE_MATCH_FILE"

# === 3. RC Script Generator (dla każdego IP i portu) ===
echo "[*] Generating Metasploit RC scripts..."
awk '
    /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { ip=$1 }
    /open/ && /tcp/ {
        port=$1; gsub("/tcp.*", "", port)
        print ip, port
    }
' "$OUTFILE" | sort -u | while read ip port; do
    RC_FILE="$RC_DIR/exploit_${ip//./_}_$port.rc"
    cat > "$RC_FILE" <<EOF
use auxiliary/scanner/portscan/tcp
set RHOSTS $ip
set PORTS $port
run

# Możesz dodać konkretny exploit tu:
# use exploit/windows/smb/ms17_010_eternalblue
# set RHOST $ip
# set RPORT $port
# run
EOF
    echo "[+] RC script created: $RC_FILE"
done

# === 4. Opcjonalna notyfikacja końcowa ===
#notify-send "🔍 Vulnscan finished for $TARGET" "Znaleziono podatności. Sprawdź raporty."

# curl -H "Content-Type: application/json" -X POST -d '{"content":"[✓] Vulnscan finished for '$TARGET'"}' https://discord.com/api/webhooks/...

echo "[✓] All tasks completed. Review $FILTERED, $CVE_MATCH_FILE, and $RC_DIR/"
