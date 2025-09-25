def show_menu():
    print("""
##############################################
#                                            #
#     #####      #####          ####         #
#     ##  ##     ##  ##        ##  ##        #
#     ##   ##    ##   ##      ##    ##       #
#     ##    ##   ##    ##    ##      ##      #
#     ##    ##   ##    ##   ##        ##     #
#     ##    ##   ##    ##    ##      ##      #
#     ##   ##    ##   ##      ##    ##       #
#     ##  ##     ##  ##        ##  ##        #
#     #####      #####          ####         #
#                DzejDzejOne                 #
##############################################

    === MENU DDO ===
    [1] Podsłuch pasywny sieci (przeszukiwanie po OUI)
    [2] Podsłuch aktywny sieci (przeszukiwanie po nazwie sieci lub adresie MAC)
    [3] Atak deauth
    [0] Wyjście
    """)

    while True:
        try:
            choice = int(input("Wybierz opcję: "))
            if choice in [0, 1, 2, 3]:
                return choice
            else:
                print("Nieprawidłowy wybór. Wprowadź cyfrę 0-3.")
        except ValueError:
            print("Nieprawidłowy format. Wprowadź cyfrę.")