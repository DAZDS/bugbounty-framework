#!/bin/bash

./check_tools.sh || exit 1

domain=$1

if [ -z "$domain" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

echo -e "\n\033[1;36m[*] Running full bug bounty pipeline for: $domain\033[0m"

# === MODULES ===
modules/recon.sh $domain
modules/portscan.sh $domain
modules/fuzz.sh $domain
modules/vulnscan.sh $domain

# === INTEL REPORT ===
echo -e "\n\033[1;36m[+] Generating Intelligence Report...\033[0m"
modules/intel_report.sh $domain

# === ASK TO CONTINUE ===
read -p $'\n\033[1;33m[?] Do you want to continue to exploitation? [Y/n]: \033[0m' answer
answer=${answer:-Y}

if [[ "$answer" =~ ^[Yy]$ ]]; then
    modules/exploit.sh $domain
else
    echo -e "\033[1;31m[!] Exploitation phase skipped.\033[0m"
fi

modules/report.sh $domain

echo -e "\n\033[1;32m[✓] All modules completed.\033[0m"
