#!/bin/bash

domain=$1
output_dir="modules/output/$domain"
report_file="$output_dir/FINAL_REPORT.md"

if [ -z "$domain" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

echo "[*] Generating final markdown report for $domain..."
mkdir -p "$output_dir"

# Start the report
echo "# Bug Bounty Report for $domain" > "$report_file"
echo "_Generated: $(date)_  " >> "$report_file"
echo "" >> "$report_file"

# Recon
if [ -f "$output_dir/subfinder.txt" ]; then
    echo "## Subdomains Found" >> "$report_file"
    cat "$output_dir/subfinder.txt" | sed 's/^/- /' >> "$report_file"
    echo "" >> "$report_file"
fi

# Nmap
for file in nmap.txt nmap_tcp.txt nmap_udp.txt; do
    if [ -f "$output_dir/$file" ]; then
        echo "## Ports ($file)" >> "$report_file"
        echo '```' >> "$report_file"
        cat "$output_dir/$file" >> "$report_file"
        echo '```' >> "$report_file"
        echo "" >> "$report_file"
    fi
done

# HTTP Methods
if [ -f "$output_dir/http_methods.txt" ]; then
    echo "## Supported HTTP Methods" >> "$report_file"
    cat "$output_dir/http_methods.txt" | sed 's/^/- /' >> "$report_file"
    echo "" >> "$report_file"
fi

# Fuzz
if [ -f "$output_dir/fuzz.txt" ]; then
    echo "## Fuzzing Results" >> "$report_file"
    echo '```' >> "$report_file"
    cat "$output_dir/fuzz.txt" >> "$report_file"
    echo '```' >> "$report_file"
    echo "" >> "$report_file"
fi

# Vulnscan
if [ -f "$output_dir/vulnscan.txt" ]; then
    echo "## CVE / CWE Detected" >> "$report_file"
    cat "$output_dir/vulnscan.txt" | sed 's/^/- /' >> "$report_file"
    echo "" >> "$report_file"
fi

# Exploitation Payload Replay
if [ -f "$output_dir/payload_replay.log" ]; then
    echo "## Payload Replay Results" >> "$report_file"
    echo '```' >> "$report_file"
    cat "$output_dir/payload_replay.log" >> "$report_file"
    echo '```' >> "$report_file"
    echo "" >> "$report_file"
fi

# mitmproxy
if [ -f "$output_dir/mitmproxy.log" ]; then
    echo "## Captured Traffic (mitmproxy)" >> "$report_file"
    echo '```' >> "$report_file"
    cat "$output_dir/mitmproxy.log" >> "$report_file"
    echo '```' >> "$report_file"
    echo "" >> "$report_file"
fi

# PoC
if [ -f "$output_dir/exploit.rc" ]; then
    echo "## Exploit PoC (Metasploit RC script)" >> "$report_file"
    echo '```' >> "$report_file"
    cat "$output_dir/exploit.rc" >> "$report_file"
    echo '```' >> "$report_file"
    echo "" >> "$report_file"
fi

# Intel Summary
if [ -f "$output_dir/intel_summary.txt" ]; then
    echo "## Intelligence Summary" >> "$report_file"
    cat "$output_dir/intel_summary.txt" >> "$report_file"
    echo "" >> "$report_file"
fi

echo "[✓] Report generated at: $report_file"
