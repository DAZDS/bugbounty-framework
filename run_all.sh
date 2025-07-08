#!/bin/bash

./check_tools.sh || exit 1

domain=$1

if [ -z "$domain" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

OUTPUT_DIR="modules/output/$domain"

echo -e "\n\033[1;36m[*] Running full bug bounty pipeline for: $domain\033[0m"

# === CHECK FOR EXISTING DATA ===
if [ -d "$OUTPUT_DIR" ]; then
    echo "Wyniki dla $domain już istnieją w $OUTPUT_DIR."
    read -p "Nadpisać istniejące dane (Y) czy kontynuować (C)? " choice
    case "$choice" in
        [Yy]* )
            echo "[*] Usuwam stare wyniki..."
            rm -rf "$OUTPUT_DIR"
            mkdir -p "$OUTPUT_DIR"
            ;;
        [Cc]* )
            echo "[*] Kontynuuję bez nadpisywania..."
            ;;
        * )
            echo "Anulowano."
            exit 1
            ;;
    esac
else
    mkdir -p "$OUTPUT_DIR"
fi

# === MODULES WITH FILE CHECKS ===

# Recon
if [ ! -f "$OUTPUT_DIR/subfinder.txt" ]; then
    modules/recon.sh $domain
else
    echo "[✓] Recon results exist – skipping recon.sh"
fi

# Portscan
if [ ! -f "$OUTPUT_DIR/nmap.txt" ]; then
    modules/portscan.sh $domain
else
    echo "[✓] Portscan results exist – skipping portscan.sh"
fi

# Fuzz
if [ ! -f "$OUTPUT_DIR/fuzz.txt" ]; then
    modules/fuzz.sh $domain
else
    echo "[✓] Fuzzing results exist – skipping fuzz.sh"
fi

# Vulnscan
if [ ! -f "$OUTPUT_DIR/vulnscan.txt" ]; then
    modules/vulnscan.sh $domain
else
    echo "[✓] Vulnscan results exist – skipping vulnscan.sh"
fi

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
