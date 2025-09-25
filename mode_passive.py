from drone_tools import (
    get_wlan_interface, run_airmon, verify_monitor_iface,
    gen_airodump, filter_scan_file, direct_scan, del_file
)
from pathlib import Path
from datetime import datetime

oui = ["00:12:1C", "00:26:7E", "90:03:B7", "90:3A:E6", "A0:14:3D"]


def run_passive_mode():
    print("\n[TRYB PASYWNY - PRZESZUKIWANIE PO OUI]\n")

    mon_interface = get_wlan_interface()
    if not mon_interface.endswith("mon"):
        run_airmon(mon_interface)
        mon_interface = get_wlan_interface()
        verify_monitor_iface(mon_interface)
    else:
        verify_monitor_iface(mon_interface)

    try:
        while True:
            print("\n[SKANOWANIE SIECI...]")
            gen_airodump(mon_interface)
            result = filter_scan_file(oui)
            del_file("Parrot_scan", "filtered")

            if result:
                bssid, channel, ssid, flag = result
                folder_name = bssid.replace(":", "-")
                Path(folder_name).mkdir(exist_ok=True)
                print(
                    f"Znaleziono drona: {ssid} ({bssid}) -> zapisywanie do katalogu {folder_name}")

                # Unikalny znacznik czasu
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

                # Unikalna ścieżka do plików skanowania
                direct_scan_file = f"{folder_name}/Parrot_scan_bsp_{timestamp}"

                # Direct scan i zapis
                direct_scan(bssid, channel, mon_interface,
                            filename=direct_scan_file, save_type="--output-format pcap")

            else:
                print("Brak drona w zasięgu.")

    except KeyboardInterrupt:
        print("\nZatrzymano tryb pasywny przez użytkownika.")
