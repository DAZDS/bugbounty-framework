#!/bin/bash

domain=$1
output_dir="output/$domain"
fuzz_dir="output/fuzz/$domain"
intel_file="$output_dir/intel_summary.txt"

mkdir -p "$output_dir"

echo -e "\n\033[1;36m[+] === INTEL REPORT FOR $domain ===\033[0m" | tee "$intel_file"
echo -e "\033[1;36m[*] Scan started at: $(date)\033[0m" | tee -a "$intel_file"
echo -e "\033[1;36m[*] User: $(whoami)\033[0m" | tee -a "$intel_file"

# WHOIS
echo -e "\n\033[1;36m[*] WHOIS:\033[0m" | tee -a "$intel_file"
command -v whois &>/dev/null && whois $domain | head -n 25 | tee -a "$intel_file" || echo "[!] whois not installed." | tee -a "$intel_file"

# DNS
echo -e "\n\033[1;36m[*] DNS Records:\033[0m" | tee -a "$intel_file"
dig ANY $domain +short | tee -a "$intel_file"

# IP & Geolocation
ip=$(dig +short $domain | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
if [[ -n "$ip" ]]; then
    echo -e "\n\033[1;36m[*] IP Info ($ip):\033[0m" | tee -a "$intel_file"
    curl -s ipinfo.io/$ip | tee -a "$intel_file"
fi

# HTTP Headers
echo -e "\n\033[1;36m[*] HTTP Headers:\033[0m" | tee -a "$intel_file"
curl -sI http://$domain | tee -a "$intel_file"

# WAF/CDN & Web Tech Detection
echo -e "\n\033[1;34m[*] WAF/CDN & Technology Fingerprinting:\033[0m" | tee -a "$intel_file"

if command -v wafw00f &> /dev/null; then
    echo -e "[•] WAF/CDN (wafw00f):" | tee -a "$intel_file"
    wafw00f $domain 2>/dev/null | tee -a "$intel_file"
else
    echo "[!] wafw00f not installed." | tee -a "$intel_file"
fi

if command -v whatweb &> /dev/null; then
    echo -e "[•] Web Tech (whatweb):" | tee -a "$intel_file"
    whatweb --no-errors --log-verbose="$output_dir/whatweb.log" $domain | tee -a "$intel_file"
else
    echo "[!] whatweb not installed." | tee -a "$intel_file"
fi

# Optional: Nuclei Fingerprinting
if command -v nuclei &>/dev/null; then
    echo -e "\n\033[1;34m[*] Nuclei Web Fingerprint:\033[0m" | tee -a "$intel_file"
    echo "$domain" | nuclei -silent -tags tech -o "$output_dir/nuclei_tech.txt"
    cat "$output_dir/nuclei_tech.txt" | tee -a "$intel_file"
fi

# Optional: CDN Check
if command -v cdncheck &>/dev/null; then
    echo -e "\n\033[1;34m[*] CDN Detection (cdncheck):\033[0m" | tee -a "$intel_file"
    cdncheck -d $domain | tee -a "$intel_file"
fi

# Ports
if [[ -f "$output_dir/nmap_results.txt" ]]; then
    echo -e "\n\033[1;33m[*] Open Ports & Services (Nmap):\033[0m" | tee -a "$intel_file"
    grep -E "^[0-9]+/(tcp|udp)" "$output_dir/nmap_results.txt" | grep -v "filtered" | tee -a "$intel_file"
else
    echo "[!] Nmap results not found." | tee -a "$intel_file"
fi

# Vulnerabilities
if [[ -f "$output_dir/vulnscan.txt" ]]; then
    echo -e "\n\033[1;31m[*] Potential Vulnerabilities (CVE, vuln keywords):\033[0m" | tee -a "$intel_file"
    grep -iE "CVE|vuln|exploit" "$output_dir/vulnscan.txt" | sort -u | head -n 20 | tee -a "$intel_file"
fi

# Fuzzing results
if [[ -f "$fuzz_dir/gobuster.txt" ]]; then
    echo -e "\n\033[1;32m[*] Gobuster Directories:\033[0m" | tee -a "$intel_file"
    grep "Status:" "$fuzz_dir/gobuster.txt" | awk '{print $2}' | sort -u | tee -a "$intel_file"
fi

if [[ -f "$fuzz_dir/ffuf.json" && -x "$(command -v jq)" ]]; then
    echo -e "\n\033[1;32m[*] FFUF Directories:\033[0m" | tee -a "$intel_file"
    jq -r '.results[] | select(.status | inside([200,204,301,302,403])) | .input.FUZZ + " (" + (.status|tostring) + ")"' "$fuzz_dir/ffuf.json" | tee -a "$intel_file"
fi

# JS Params
[[ -f "$output_dir/params.txt" ]] && echo -e "\n\033[1;35m[*] JS Parameters:\033[0m" | tee -a "$intel_file" && cat "$output_dir/params.txt" | tee -a "$intel_file"

# Secrets
[[ -f "$output_dir/secrets.txt" ]] && echo -e "\n\033[1;35m[*] Secrets or Tokens:\033[0m" | tee -a "$intel_file" && cat "$output_dir/secrets.txt" | tee -a "$intel_file"

# Subdomains
[[ -f "$output_dir/subdomains.txt" ]] && echo -e "\n\033[1;36m[*] Subdomains:\033[0m" | tee -a "$intel_file" && cat "$output_dir/subdomains.txt" | tee -a "$intel_file"

# Sensitive Files Discovery
echo -e "\n\033[1;34m[*] File Intel Scan (Sensitive Files):\033[0m" | tee -a "$intel_file"
sensitive_files=( ".env" ".git/config" ".htpasswd" ".htaccess" ".DS_Store" "backup.zip" "db.sql" "config.bak" "admin.bak" "phpinfo.php" "config.php~" "web.config.old" ".idea/workspace.xml" "debug.log" )
for file in "${sensitive_files[@]}"; do
    url="http://$domain/$file"
    response=$(curl -s -o /tmp/tmp_file -w "%{http_code}" "$url")
    if [[ "$response" =~ ^(200|401|403)$ ]]; then
        hash=$(md5sum /tmp/tmp_file | awk '{print $1}')
        echo "[+] Found: $file ($response) – MD5: $hash" | tee -a "$intel_file"
    fi
done
rm -f /tmp/tmp_file

# === SUMMARY ===
echo -e "\n\033[1;36m[*] === SUMMARY ===\033[0m" | tee -a "$intel_file"

if [[ -f "$output_dir/portscan/summary.txt" ]]; then
    echo -e "\n\033[1;33m[+] Portscan Summary (TCP/UDP):\033[0m" | tee -a "$intel_file"
    cat "$output_dir/portscan/summary.txt" | tee -a "$intel_file"
else
    echo "[!] Portscan summary not found." | tee -a "$intel_file"
fi

[[ -f "$output_dir/vulnscan.txt" ]] && echo " - $(grep -iE 'CVE' "$output_dir/vulnscan.txt" | wc -l) vulnerabilities" | tee -a "$intel_file"
[[ -f "$output_dir/subdomains.txt" ]] && echo " - $(cat "$output_dir/subdomains.txt" | wc -l) subdomains" | tee -a "$intel_file"
[[ -f "$output_dir/secrets.txt" ]] && echo " - $(cat "$output_dir/secrets.txt" | wc -l) secrets/tokens" | tee -a "$intel_file"

echo -e "\n\033[1;36m[✓] === END OF REPORT ===\033[0m" | tee -a "$intel_file"
