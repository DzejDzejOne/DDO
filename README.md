# Project Title

This project demonstrates an automated system to detect, intercept, and take over Parrot drones (e.g. AR.Drone series) that communicate with their operator via Wi-Fi. Parrot AR.Drones act as Wi-Fi access points (hotspots) with no encryption by defaul.

This lack of security allows an attacker to capture the communication between the drone and its pilot, decode it for information, and even hijack control of the drone. The project includes custom Wireshark plugins to decode Parrot drone protocols and a sequence of attack steps to disconnect the legitimate operator, assume control, download drone data, and safely land the drone.
