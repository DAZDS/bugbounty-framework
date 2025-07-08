#!/bin/bash

TARGET=$1
OUTDIR=~/bugbounty-framework/output/$TARGET
INFILE="$OUTDIR/live_subdomains.txt"
PORTDIR="$OUTDIR/portscan"

mkdir -p "$PORTDIR"

IP_LIST="$PORTDIR/ip_list.txt"
MASSCAN_OUT="$PORTDIR/masscan.txt"
NMAP_TCP_OUT="$PORTDIR/nmap_tcp.txt"
NMAP_UDP_OUT="$PORTDIR/nmap_udp.txt"
NMAP_SUMMARY="$PORTDIR/summary.txt"

echo "[*] Starting port scan for $TARGET..."
echo "[*] Output directory: $PORTDIR"

# === Extract IPs from live subdomains ===
echo "[*] Extracting IPs from live subdomains..."
cat "$INFILE" | dnsx -resp-only -silent | sort -u > "$IP_LIST"
echo "[*] Found $(wc -l < $IP_LIST) unique IPs"

# === STEP 1: Fast TCP scan with Masscan ===
echo "[*] Step 1: Fast TCP scan with Masscan (top 1000 ports)..."
masscan -iL "$IP_LIST" -p1-1000 --rate=1000 -oL "$MASSCAN_OUT" --wait=5

# === STEP 2: Full TCP scan with Nmap ===
echo "[*] Step 2: Full TCP scan with Nmap..."
nmap -iL "$IP_LIST" -p- -T4 -sS -Pn -sV -oN "$NMAP_TCP_OUT"

# === STEP 3: UDP scan with Nmap (top 100 ports) ===
echo "[*] Step 3: UDP scan with Nmap (top 100 ports)..."
nmap -iL "$IP_LIST" -sU --top-ports 100 -T4 -Pn -sV -oN "$NMAP_UDP_OUT"

# === STEP 4: Summary report ===
echo "[*] Creating summary report..."

{
    echo -e "\n[+] Open TCP Ports & Services:"
    grep -E "^[0-9]+/tcp" "$NMAP_TCP_OUT" | grep -i "open" | sort -u

    echo -e "\n[+] Open UDP Ports & Services:"
    grep -E "^[0-9]+/udp" "$NMAP_UDP_OUT" | grep -i "open" | sort -u
} | tee "$NMAP_SUMMARY"

echo "[+] Port scan completed for $TARGET. Results saved in $PORTDIR"
