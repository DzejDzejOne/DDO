from drone_tools import (
    get_wlan_interface,  run_airmon, verify_monitor_iface
)
from datetime import datetime
from pathlib import Path
import subprocess


def run_active_mode():
    print("\n[TRYB AKTYWNY - PRZESZUKIWANIE PO SSID / MAC]\n")
    print("Wprowadź dane dokładnie tak, jak są widoczne w sieci (uwzględniając wielkość liter).")
    print("Możesz wyszukiwać po pełnym SSID (nazwa sieci) lub pełnym MAC adresie (BSSID).\n")

    mon_interface = get_wlan_interface()
    run_airmon(mon_interface)
    mon_interface = get_wlan_interface()
    verify_monitor_iface(mon_interface)

    print("[1] Szukaj po SSID (nazwa sieci)")
    print("[2] Szukaj po MAC (BSSID)")
    mode = input("Wybierz metodę wyszukiwania: ").strip()

    if mode == '1':
        search_ssid = input("Podaj dokładny SSID: ").strip()
        duration = input("Czas trwania skanu w sekundach: ").strip()
        folder_name = search_ssid.replace(":", "-")
        Path(folder_name).mkdir(exist_ok=True)
        print(
            f"Znaleziono drona: {search_ssid} -> zapisywanie do katalogu {folder_name}")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        direct_scan_file = f"{folder_name}/Parrot_scan_bsp_{timestamp}"
        subprocess.run(
            f"sudo timeout {duration}s airodump-ng -N {search_ssid} {mon_interface} --write {direct_scan_file} --output-format pcap",
            shell=True
        )

    elif mode == '2':
        search_mac = input("Podaj dokładny adres MAC (BSSID): ").strip()
        duration = input("Czas trwania skanu w sekundach: ").strip()
        folder_name = search_mac.replace(":", "-")
        Path(folder_name).mkdir(exist_ok=True)
        print(
            f"Znaleziono drona: ({search_mac}) -> zapisywanie do katalogu {folder_name}")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        direct_scan_file = f"{folder_name}/Parrot_scan_bsp_{timestamp}"
        subprocess.run(
            f"sudo timeout {duration}s airodump-ng -d {search_mac} {mon_interface} --write {direct_scan_file} --output-format pcap",
            shell=True
        )

    else:
        print("Nieprawidłowy wybór metody wyszukiwania.")
