#!/bin/bash

TARGET=$1
OUTDIR="output/$TARGET"
mkdir -p "$OUTDIR"

echo -e "\n\033[1;36m[*] Starting recon for $TARGET\033[0m"
echo -e "\033[1;36m[*] Scan started at: $(date)\033[0m"
echo -e "\033[1;36m[*] User: $(whoami)\033[0m"

# === VPN Check ===
echo -e "\n\033[1;35m[*] Sprawdzam status VPN...\033[0m"
VPN_STATUS=$(systemctl is-active cyberghost-vpn.service)

if [[ "$VPN_STATUS" == "active" ]]; then
    echo -e "\033[1;32m[+] VPN już działa.\033[0m"
else
    echo -e "\033[1;33m[~] VPN nieaktywny – uruchamiam...\033[0m"
    sudo systemctl start cyberghost-vpn.service
    sleep 5

    VPN_STATUS=$(systemctl is-active cyberghost-vpn.service)
    if [[ "$VPN_STATUS" != "active" ]]; then
        echo -e "\033[1;31m[!] VPN nie został uruchomiony poprawnie. Zatrzymuję skan.\033[0m"
        exit 1
    fi
    echo -e "\033[1;32m[+] VPN działa.\033[0m"
fi

# === Step 1: Subfinder ===
echo -e "\n\033[1;34m[*] Running Subfinder...\033[0m"
subfinder -d "$TARGET" -silent -o "$OUTDIR/subfinder.txt"

# === Step 2: Amass (passive) ===
echo -e "\033[1;34m[*] Running Amass (passive)...\033[0m"
amass enum -passive -d "$TARGET" -o "$OUTDIR/amass_raw.txt"

# --- Extract only FQDNs from Amass output ---
grep -oP '\b([a-zA-Z0-9-]+\.)+'"$TARGET" "$OUTDIR/amass_raw.txt" | sort -u > "$OUTDIR/amass.txt"

# === Step 3: Assetfinder ===
echo -e "\033[1;34m[*] Running Assetfinder...\033[0m"
assetfinder --subs-only "$TARGET" > "$OUTDIR/assetfinder.txt"

# === Step 4: Combine and deduplicate subdomains ===
echo -e "\033[1;34m[*] Combining subdomain results...\033[0m"
cat "$OUTDIR/"*.txt | sort -u > "$OUTDIR/all_subdomains.txt"
cp "$OUTDIR/all_subdomains.txt" "$OUTDIR/subdomains.txt"

# === Step 5: Check live subdomains with httpx ===
if [ -s "$OUTDIR/all_subdomains.txt" ]; then
    echo -e "\033[1;34m[*] Checking live subdomains with httpx...\033[0m"
    cat "$OUTDIR/all_subdomains.txt" | httpx -silent -threads 50 -timeout 10 -retries 2 \
        -status-code -follow-redirects -ip -title -location -web-server -tech-detect \
        -o "$OUTDIR/live_subdomains.txt"
else
    echo -e "\033[1;33m[!] Plik $OUTDIR/all_subdomains.txt nie istnieje lub jest pusty. Pomijam etap httpx.\033[0m"
fi

# === Step 6: Historical URLs (gau + waybackurls) ===
echo -e "\033[1;34m[*] Gathering historical URLs from gau and waybackurls...\033[0m"

if [ -s "$OUTDIR/live_subdomains.txt" ]; then
    > "$OUTDIR/gau.txt"
    > "$OUTDIR/waybackurls.txt"

    cut -d ' ' -f1 "$OUTDIR/live_subdomains.txt" | sed -E 's#https?://##' | cut -d '/' -f1 | sort -u > "$OUTDIR/unique_domains.txt"

    while read -r domain; do
        echo "[*] Fetching for $domain"
        gau "$domain" >> "$OUTDIR/gau.txt" 2>/dev/null
        waybackurls "$domain" >> "$OUTDIR/waybackurls.txt" 2>/dev/null
    done < "$OUTDIR/unique_domains.txt"
else
    echo -e "\033[1;33m[!] live_subdomains.txt not found – skipping historical URL gathering.\033[0m"
fi

# === Step 7: Clean and deduplicate historical data ===
echo -e "\033[1;34m[*] Cleaning and deduplicating historical URL data...\033[0m"
sort -u "$OUTDIR/gau.txt" > "$OUTDIR/gau_clean.txt" 2>/dev/null
sort -u "$OUTDIR/waybackurls.txt" > "$OUTDIR/wayback_clean.txt" 2>/dev/null

echo -e "\n\033[1;32m[+] Recon completed for $TARGET. Output in $OUTDIR\033[0m"
