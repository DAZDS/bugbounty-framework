#!/bin/bash

echo "[*] Instalacja narzędzi dla bug bounty framework..."
echo "[*] Start: $(date)"

# 0. Tworzenie struktury katalogów
echo "[*] Tworzenie struktury katalogów projektu..."
mkdir -p modules output reports config/SecLists docs

# 1. Pytanie o nadpisanie istniejących plików w modules/
read -p "[?] Czy chcesz nadpisać istniejące pliki w modules/? [y/N] " overwrite_modules

# 2. Kopiowanie gotowych skryptów
if [[ "$overwrite_modules" == "y" || "$overwrite_modules" == "Y" ]]; then
  echo "[*] Nadpisuję pliki modules/..."
  cp -f /mnt/data/*.sh modules/
else
  echo "[*] Pomijam kopiowanie do modules/"
fi

# 3. Aktualizacja systemu
sudo apt update && sudo apt upgrade -y

# 4. Instalacja narzędzi
echo "[*] Instalacja: subfinder, amass, assetfinder"
sudo apt install subfinder amass assetfinder -y

echo "[*] Instalacja: httpx, whatweb"
sudo apt install httpx whatweb -y

echo "[*] Instalacja: masscan, nmap"
sudo apt install masscan nmap -y

echo "[*] Instalacja: exploitdb (searchsploit)"
sudo apt install exploitdb -y
searchsploit -u

echo "[*] Instalacja: ffuf, gobuster"
sudo apt install ffuf gobuster -y

echo "[*] Instalacja: wafw00f"
sudo apt install wafw00f -y

echo "[*] Instalacja: whois, dnsutils, curl, jq"
sudo apt install whois dnsutils curl jq -y

# 5. Go tools
echo "[*] Instalacja Go tools (gau, waybackurls)"
if ! command -v go &>/dev/null; then
    echo "[!] Go nie jest zainstalowane – instaluję Go..."
    sudo apt install golang -y
fi

echo "export PATH=$PATH:$HOME/go/bin" >> ~/.bashrc
source ~/.bashrc

go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest

# 6. Alias do searchsploit
echo "[*] Dodawanie aliasu dla searchsploit"
grep -q 'searchsploit' ~/.bashrc || echo 'alias searchsploit="searchsploit"' >> ~/.bashrc

# 7. Aktualizacja SecLists
function update_seclists() {
    echo "[*] Aktualizacja SecLists..."
    if [ -d "config/SecLists/.git" ]; then
        echo "[✓] SecLists już zainstalowane – pomijam."
    else
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git config/SecLists/
    fi
}
update_seclists

# 8. Wywołanie check_tools.sh jeśli istnieje
if [ -f check_tools.sh ]; then
    echo "[*] Sprawdzanie narzędzi z check_tools.sh..."
    bash check_tools.sh
fi

# 9. Zapisywanie informacji o środowisku
echo "[*] Zapisywanie informacji o środowisku..."
uname -a > output/env-check.txt
echo "Zainstalowane narzędzia:" >> output/env-check.txt
for tool in subfinder amass assetfinder httpx whatweb masscan nmap searchsploit ffuf gobuster wafw00f whois dig curl jq gau waybackurls; do
    echo -n "$tool: " >> output/env-check.txt
    if command -v $tool &>/dev/null; then
        $tool --version 2>/dev/null | head -n 1 >> output/env-check.txt || echo "OK (brak opcji --version)" >> output/env-check.txt
    else
        echo "❌ nie znaleziono" >> output/env-check.txt
    fi
done

echo -e "\n[✓] Instalacja zakończona!"
