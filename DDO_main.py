from menu import show_menu
import sys

# Wywołanie menu i pobranie wyboru
choice = show_menu()

if choice == 0:
    print("Zamykam program...")
    sys.exit(0)

if choice == 1:
    from mode_passive import run_passive_mode
    run_passive_mode()

elif choice == 2:
    from mode_active import run_active_mode
    run_active_mode()

elif choice == 3:
    from mode_deauth import run_deauth_mode
    run_deauth_mode()
