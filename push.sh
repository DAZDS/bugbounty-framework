#!/bin/bash

# Sprawdzenie, czy jesteś w katalogu z repozytorium Git
if [ ! -d .git ]; then
  echo "[!] This directory is not a Git repository. Run 'git init' first."
  exit 1
fi

echo "[*] Adding changes..."
git add .

echo "[*] Committing changes..."
git commit -m "Update framework files and documentation"

echo "[*] Pushing to GitHub..."
git push origin master
