#!/bin/bash

LOG="output/tools.log"
mkdir -p output
echo -e "\n[*] === TOOL CHECK STARTED AT: $(date) ===" | tee -a "$LOG"

# Sprawdzenie Go (dla instalacji z GitHub)
if ! command -v go &>/dev/null; then
  echo "[!] Go not found. Installing Go..." | tee -a "$LOG"
  sudo apt install -y golang &>> "$LOG"
  echo "export PATH=\$PATH:\$HOME/go/bin" >> ~/.bashrc
  export PATH=$PATH:$HOME/go/bin
  source ~/.bashrc
fi

# Lista narzędzi i poleceń instalacyjnych
declare -A tools=(
  [amass]="apt install -y amass"
  [assetfinder]="go install github.com/tomnomnom/assetfinder@latest && ln -sf ~/go/bin/assetfinder /usr/local/bin/"
  [subfinder]="go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && ln -sf ~/go/bin/subfinder /usr/local/bin/"
  [httpx]="go install github.com/projectdiscovery/httpx/cmd/httpx@latest && ln -sf ~/go/bin/httpx /usr/local/bin/"
  [gau]="go install github.com/lc/gau/v2/cmd/gau@latest && ln -sf ~/go/bin/gau /usr/local/bin/"
  [waybackurls]="go install github.com/tomnomnom/waybackurls@latest && ln -sf ~/go/bin/waybackurls /usr/local/bin/"
  [nmap]="apt install -y nmap"
  [masscan]="apt install -y masscan"
  [ffuf]="go install github.com/ffuf/ffuf@latest && ln -sf ~/go/bin/ffuf /usr/local/bin/"
  [gobuster]="apt install -y gobuster"
  [jq]="apt install -y jq"
  [whatweb]="apt install -y whatweb"
  [wafw00f]="apt install -y wafw00f"
  [whois]="apt install -y whois"
  [dig]="apt install -y dnsutils"
  [curl]="apt install -y curl"
  [searchsploit]="apt install -y exploitdb"
)

not_installed=()

for tool in "${!tools[@]}"; do
  echo -n "[*] Checking $tool... " | tee -a "$LOG"
  if ! command -v $tool &>/dev/null; then
    echo "not found. Installing..." | tee -a "$LOG"
    eval "${tools[$tool]}" &>> "$LOG"
    if command -v $tool &>/dev/null; then
      echo "[+] $tool successfully installed." | tee -a "$LOG"
    else
      echo "[X] Failed to install $tool." | tee -a "$LOG"
      not_installed+=("$tool")
    fi
  else
    echo "[✓] already installed." | tee -a "$LOG"
  fi
done

if [[ ${#not_installed[@]} -gt 0 ]]; then
  echo -e "\n[X] The following tools failed to install:" | tee -a "$LOG"
  for tool in "${not_installed[@]}"; do
    echo "   - $tool" | tee -a "$LOG"
  done
else
  echo -e "\n[✓] All tools are installed and ready." | tee -a "$LOG"
fi

echo -e "[*] === TOOL CHECK COMPLETED AT: $(date) ===\n" | tee -a "$LOG"
