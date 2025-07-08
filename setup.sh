#!/bin/bash

echo "[*] Instalacja narzędzi dla bug bounty framework..."
echo "[*] Start: $(date)"

# Aktualizacja systemu
sudo apt update && sudo apt upgrade -y

# 1. Rekonesans i subdomeny
echo "[*] Instalacja: subfinder, amass, assetfinder"
sudo apt install subfinder amass assetfinder -y

# 2. HTTP fingerprinting
echo "[*] Instalacja: httpx, whatweb"
sudo apt install httpx whatweb -y

# 3. Skanery portów
echo "[*] Instalacja: masscan, nmap"
sudo apt install masscan nmap -y

# 4. CVE/podatności
echo "[*] Instalacja: exploitdb (searchsploit)"
sudo apt install exploitdb -y
searchsploit -u

# 5. Fuzzing
echo "[*] Instalacja: ffuf, gobuster"
sudo apt install ffuf gobuster -y

# 6. WAF/CDN detection
echo "[*] Instalacja: wafw00f"
sudo apt install wafw00f -y

# 7. WHOIS, DNS, IP info
echo "[*] Instalacja: whois, dnsutils, curl, jq"
sudo apt install whois dnsutils curl jq -y

# 8. Go tools
echo "[*] Instalacja: Go tools (gau, waybackurls)"
if ! command -v go &>/dev/null; then
    echo "[!] Go nie jest zainstalowane – instaluję Go..."
    sudo apt install golang -y
fi

echo "export PATH=\$PATH:\$HOME/go/bin" >> ~/.bashrc
source ~/.bashrc

go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest

# 9. Alias do searchsploit
echo "[*] Dodawanie aliasu dla searchsploit"
grep -q 'searchsploit' ~/.bashrc || echo 'alias searchsploit="searchsploit"' >> ~/.bashrc

# 10. Sprawdzenie wersji narzędzi
echo -e "\n[*] Wersje zainstalowanych narzędzi:"
tools=(subfinder amass assetfinder httpx whatweb masscan nmap searchsploit ffuf gobuster wafw00f whois dig curl jq gau waybackurls)

for tool in "${tools[@]}"; do
    echo -n " - $tool: "
    if command -v $tool &>/dev/null; then
        $tool --version 2>/dev/null | head -n 1 || echo "OK (brak opcji --version)"
    else
        echo "❌ nie znaleziono"
    fi
done

echo -e "\n[✓] Instalacja zakończona! Upewnij się, że zamkniesz i otworzysz terminal (jeśli potrzebne)"
