#!/bin/bash

./check_tools.sh || exit 1

domain=$1
mode=$2 # opcjonalny tryb automatyczny np. --auto

if [ -z "$domain" ]; then
    echo "Usage: $0 <domain> [--auto]"
    exit 1
fi

OUTPUT_DIR="modules/output/$domain"
mkdir -p "$OUTPUT_DIR"

done_flag="$OUTPUT_DIR"

echo -e "\n\033[1;36m[*] Running full bug bounty pipeline for: $domain\033[0m"

# === ZARZĄDZANIE DANYMI ===
if [ -d "$OUTPUT_DIR" ] && [ ! -f "$done_flag/.pipeline_started" ]; then
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
fi

touch "$done_flag/.pipeline_started"

# === KROKI Z CHECKPOINTAMI ===

step() {
    local step_name=$1
    local script=$2
    local done_file="$done_flag/${step_name}.done"

    if [ -f "$done_file" ]; then
        echo "[✓] $step_name already completed – skipping"
    else
        echo -e "\n\033[1;34m[*] Starting: $step_name\033[0m"
        $script $domain
        if [ $? -eq 0 ]; then
            touch "$done_file"
        else
            echo -e "\033[1;31m[!] $step_name failed.\033[0m"
            exit 1
        fi
    fi
}

# === FAZA RECON ===
step "recon" modules/recon.sh

# === FAZA PORTSCAN ===
step "portscan" modules/portscan.sh

# === FAZA FUZZ ===
step "fuzz" modules/fuzz.sh

# === FAZA VULNSCAN ===
step "vulnscan" modules/vulnscan.sh

# === FAZA RAPORTU INTEL ===
step "intel" modules/intel_report.sh

# === FAZA EXPLOIT ===
if [ "$mode" == "--auto" ]; then
    echo -e "\n\033[1;33m[*] AUTO mode: launching exploitation without prompt\033[0m"
    step "exploit" modules/exploit.sh
else
    read -p $'\n\033[1;33m[?] Do you want to continue to exploitation? [Y/n]: \033[0m' answer
    answer=${answer:-Y}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        step "exploit" modules/exploit.sh
    else
        echo -e "\033[1;31m[!] Exploitation phase skipped.\033[0m"
    fi
fi

# === RAPORT KOŃCOWY ===
step "report" modules/report.sh

echo -e "\n\033[1;32m[✓] All modules completed for $domain.\033[0m"
