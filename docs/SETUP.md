# Setup Instructions – DAZ Sentinel Bug Bounty Framework

This document explains how to install and use the DAZ Sentinel framework.

## 📦 Requirements

- OS: Kali Linux, Parrot OS, Ubuntu (preferred)
- Internet access
- `git`, `curl`, `jq`, `golang`

## ⚙️ Setup Steps

```bash
# Step 1: Clone the repository
git clone https://github.com/DAZDS/bugbounty-framework.git
cd bugbounty-framework

# Step 2: Run setup script
chmod +x setup.sh
./setup.sh
```

## 🧪 What setup.sh does:

- Installs tools: `amass`, `ffuf`, `gobuster`, `httpx`, `gau`, `waybackurls`, etc.
- Creates structure: `modules/`, `output/`, `config/`, `reports/`
- Clones and integrates SecLists
- Logs system environment in `output/env-check.txt`

## ✅ Run modules

Each module is inside the `modules/` directory and can be executed independently:

```bash
bash modules/recon.sh target.com
bash modules/vulnscan.sh target.com
bash modules/report.sh target.com
```

You can also run all steps:

```bash
bash run_all.sh target.com
```

## 📤 Push changes to GitHub

Use `push.sh` to commit and upload changes:

```bash
bash push.sh
```
