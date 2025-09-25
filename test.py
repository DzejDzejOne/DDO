import csv
import subprocess

# Lista prefiksów OUI
oui = ["00:12:1C", "00:26:7E", "90:03:B7", "90:3A:E6", "A0:14:3D"]

def filter_scan_file_with_grep(file_name="test-01.csv"):
    # Uruchamiamy komendę grep, aby przefiltrować dane
    subprocess.run(f"grep -E 'Cipher' {file_name} > filtered.csv", shell=True)
    subprocess.run(f"grep -E '00:12:1C|00:26:7E|90:03:B7|90:3A:E6|A0:14:3D' {file_name} >> filtered.csv", shell=True)

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

# Przykład użycia:
result = filter_scan_file_with_grep()

if result:
    bssid, channel, ssid, flag = result
    print(f"Znaleziono drona:\nssid:{ssid}!\nbssid:{bssid}!\nkanal:{channel}!\nFlaga:{flag}!")
else:
    print("Nie znaleziono drona.")