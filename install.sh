#!/bin/bash
set -euo pipefail

echo "[1/5] Aktualizacja listy pakietów…"
sudo apt update

echo "[2/5] Uaktualnienie istniejących pakietów (bez usuwania)…"
sudo apt upgrade -y

echo "[3/5] Instalacja nowych pakietów systemowych…"
sudo apt install -y \
    aircrack-ng net-tools wireless-tools dnsutils \
    python3-pip python3-venv build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev \
    zlib1g-dev libjpeg-dev libpcap-dev unzip ftp curl

echo "[4/5] Tworzenie i aktywacja środowiska wirtualnego…"
python3 -m venv venv
source venv/bin/activate

echo "[5/5] Instalacja zależności Pythona…"
pip install --upgrade pip
pip install zeroconf pyparrot python-ardrone
sudo apt install python3-zeroconf
sudo apt install python3-pygame

echo "Instalacja zakończona. Aby uruchomić aplikację:"
echo "  source venv/bin/activate && python3 DDO_main.py"
