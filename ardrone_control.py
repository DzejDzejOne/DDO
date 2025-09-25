import libardrone
from time import sleep

drone = libardrone.ARDrone()

drone.takeoff()
sleep(3)
drone.land()
sleep(3)