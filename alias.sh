#!/bin/bash

echo "[*] Ustawianie aliasów w ~/.bashrc..."

# Dodaj aliasy do plików w modules/
{
  echo "alias recon='~/bugbounty-framework/modules/recon.sh'"
  echo "alias ports='~/bugbounty-framework/modules/portscan.sh'"
  echo "alias vulns='~/bugbounty-framework/modules/vulnscan.sh'"
  echo "alias fuzz='~/bugbounty-framework/modules/fuzz.sh'"
  echo "alias exploit='~/bugbounty-framework/modules/exploit.sh'"
  echo "alias intel='~/bugbounty-framework/modules/intel_report.sh'"
  echo "alias report='~/bugbounty-framework/modules/report.sh'"
  echo "alias fullrun='~/bugbounty-framework/main.sh'"
  echo "alias tools='~/bugbounty-framework/check_tools.sh'"
} >> ~/.bashrc

echo "[*] Wczytywanie ~/.bashrc..."
source ~/.bashrc

echo "[✓] Gotowe – możesz teraz używać aliasów typu: recon, ports, vulns, itd."
