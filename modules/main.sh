#!/bin/bash

TARGET=$1

if [[ -z "$TARGET" ]]; then
  echo "[!] Użycie: ./main.sh example.com"
  exit 1
fi

echo "[*] === BUG BOUNTY AUTOMATION FOR: $TARGET ==="

# 1. Rekonesans
echo "[1/7] Recon..."
./recon.sh $TARGET

# 2. Skan portów
echo "[2/7] Portscan..."
./portscan.sh $TARGET

# 3. Fuzzing
echo "[3/7] Fuzzing..."
./fuzz.sh $TARGET

# 4. Wykrywanie podatności
echo "[4/7] Vulnerability scan..."
./vulnscan.sh $TARGET

# 5. Eksploatacja (manualna lub półautomatyczna)
echo "[5/7] Exploitation hints..."
./exploit.sh $TARGET

# 6. Raport wywiadowczy
echo "[6/7] Intel report..."
./intel_report.sh $TARGET

# 7. Raport końcowy
echo "[7/7] Final report..."
./report.sh $TARGET

echo -e "\n[✓] Wszystkie etapy zakończone. Sprawdź katalog: output/$TARGET"
