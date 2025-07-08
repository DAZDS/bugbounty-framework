#!/bin/bash

domain=$1
wordlist="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
extensions="php,html,txt,bak,zip"
output_dir="output/fuzz/$domain"
summary_file="$output_dir/summary.txt"

mkdir -p "$output_dir"

echo -e "\n\033[1;36m[+] === STARTING FUZZING FOR $domain ===\033[0m"
echo -e "\033[1;36m[*] Output Directory: $output_dir\033[0m"
echo "[*] Started at: $(date)" > "$summary_file"

# ---- 1. Check HTTP or HTTPS ----
if curl -s --head "https://$domain" | grep -q "200 OK"; then
    base_url="https://$domain"
else
    base_url="http://$domain"
fi

echo "[*] Using base URL: $base_url" | tee -a "$summary_file"

# ---- 2. FFUF - Directory/File Fuzzing ----
echo -e "\n[*] Running FFUF (directories + extensions)..."
ffuf -u "$base_url/FUZZ" \
     -w "$wordlist" \
     -e ".$extensions" \
     -mc 200,204,301,302,403 \
     -of json \
     -o "$output_dir/ffuf.json" \
     -t 40

echo "[+] FFUF done." | tee -a "$summary_file"

# ---- 3. Gobuster - Basic Dir Fuzzing ----
echo -e "\n[*] Running Gobuster..."
gobuster dir -u "$base_url" \
            -w "$wordlist" \
            -x "$extensions" \
            -t 30 \
            -o "$output_dir/gobuster.txt" \
            -q

echo "[+] Gobuster done." | tee -a "$summary_file"

# ---- 4. Parameter Fuzzing (GET & POST) ----
echo -e "\n[*] Parameter fuzzing (query + POST)..."
ffuf -u "$base_url?FUZZ=test" \
     -w "$wordlist" \
     -mc 200,403 \
     -of json \
     -o "$output_dir/ffuf_params.json" \
     -t 25

# Optional: POST param fuzzing
ffuf -u "$base_url" \
     -X POST \
     -d "FUZZ=test" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -w "$wordlist" \
     -mc 200,403 \
     -of json \
     -o "$output_dir/ffuf_post_params.json" \
     -t 25

echo "[+] Param fuzzing done." | tee -a "$summary_file"

# ---- 5. HTTP Method Fuzzing ----
echo -e "\n[*] HTTP Method fuzzing..."
methods=( GET POST PUT DELETE OPTIONS TRACE CONNECT PATCH )
for method in "${methods[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$base_url")
    echo "[+] Method $method => $status" | tee -a "$output_dir/http_methods.txt"
done

# ---- 6. Summary ----
echo -e "\n[*] Generating short summary..."
cat "$output_dir/http_methods.txt" >> "$summary_file"
jq -r '.results[] | select(.status | inside([200,204,301,302,403])) | .input.FUZZ + " (" + (.status|tostring) + ")"' "$output_dir/ffuf.json" >> "$summary_file"

echo -e "\n\033[1;32m[✓] Fuzzing completed. Summary saved to: $summary_file\033[0m"
