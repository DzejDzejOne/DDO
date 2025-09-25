# Project Title

This project demonstrates an automated system to detect, intercept, and take over Parrot drones (e.g. AR.Drone series) that communicate with their operator via Wi-Fi. Parrot AR.Drones act as Wi-Fi access points (hotspots) with no encryption by defaul.

This lack of security allows an attacker to capture the communication between the drone and its pilot, decode it for information, and even hijack control of the drone. The project includes custom Wireshark plugins to decode Parrot drone protocols and a sequence of attack steps to disconnect the legitimate operator, assume control, download drone data, and safely land the drone.

## Features

- Automatic Drone Detection: The system scans for Wi-Fi networks and devices characteristic of Parrot drones. In passive mode, it uses vendor MAC prefixes (OUIs – Organizationally Unique Identifiers) to identify likely Parrot hardware. In active, targeted mode, it can look for a specific drone by its SSID (e.g., ardrone_xxxxxx) or by its full MAC address. By correlating SSID patterns and OUIs, the detector flags drones in the vicinity while reducing false positives.
- Data Interception: Using the Aircrack-ng suite (e.g., airmon-ng to enable monitor mode and airodump-ng to capture), the tool passively records traffic between the drone and its controller.
- Wireshark Protocol Decoding: Includes custom plugins (parrot_plugin and ARDrone_plugin) for Wireshark that decode the captured Parrot drone packets. These plugins interpret the drone’s commands and telemetry (such as flight commands, sensor data, battery status, etc.) in human-readable form.
- Deauthentication (Deauth) Attack: Using Aircrack-ng (especially aireplay-ng), the tool sends targeted 802.11 deauthentication frames to the operator’s station to forcibly disconnect them.
- Drone Takeover: After the original controller is disconnected, the attacker’s system connects to the drone’s Wi-Fi as the new controller. The attack continues to send periodic deauth frames (jamming) to prevent the original operator from reconnecting, ensuring exclusive control.
- Onboard Data Extraction: Leverages the drone’s open services to retrieve data. Parrot AR.Drones, for instance, host an FTP server on the drone with no credentials required. Using this, the system downloads all available onboard data such as photos, recorded videos, and flight route logs.
- Remote Command Injection (Landing): Finally, the system can inject control commands to the drone. For example, it sends a land command to bring the drone safely to the ground under the attacker’s control. This demonstrates full takeover – the drone is no longer under the original pilot’s command once landed.
