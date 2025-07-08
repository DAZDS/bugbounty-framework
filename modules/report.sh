#!/bin/bash

domain=$1
format=$2  # np. --pdf
output_dir="output/$domain"
report_file="$output_dir/report_${domain}.txt"
pdf_file="$output_dir/report_${domain}.pdf"

mkdir -p "$output_dir"
rm -f "$report_file"

function append_section() {
    section_name=$1
    section_path=$2

    echo -e "\n==== $section_name ====" >> "$report_file"
    
    if ls "$section_path"/*.txt &>/dev/null; then
        cat "$section_path"/*.txt >> "$report_file"
    else
        echo "[!] No data found for $section_name." >> "$report_file"
    fi
}

echo "[*] Generating report for $domain..."

# Header
echo "======================================" >> "$report_file"
echo "   BUG BOUNTY REPORT FOR: $domain" >> "$report_file"
echo "   Generated: $(date)" >> "$report_file"
echo "======================================" >> "$report_file"

# Sections
append_section "Intel Summary" "$output_dir"
append_section "Recon" "output/recon/$domain"
append_section "Port Scan" "output/portscan/$domain"
append_section "Fuzz Results" "output/fuzz/$domain"
append_section "Vulnerability Scan" "output/vulnscan/$domain"
append_section "Secrets / Parameters" "$output_dir"

# PDF generation
if [[ "$format" == "--pdf" ]]; then
    echo "[*] Generating PDF report..."
    enscript "$report_file" -o - | ps2pdf - "$pdf_file"

    if [[ -f "$pdf_file" ]]; then
        echo "[✓] PDF report saved to: $pdf_file"
    else
        echo "[!] PDF generation failed."
    fi
else
    echo "[✓] Report saved to: $report_file"
fi
