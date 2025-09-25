from pyparrot.Bebop import Bebop

bebop = Bebop(ip_address="192.168.42.1")

print("connecting")
success = bebop.connect(10)
print(success)


if success:
    bebop.ask_for_state_update()
    bebop.safe_land(10)

    print("DONE - disconnecting")
    bebop.disconnect()
else:
    print("Nie udało się połączyć z dronem.")
