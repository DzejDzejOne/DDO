-- Atrapy definiujące stałe używane w Wireshark
PI_NOTE = PI_NOTE or 0
PI_ERROR = PI_ERROR or 0
PI_MALFORMED = PI_MALFORMED or 0

local parrot_proto = Proto("parrot", "Parrot Commands")

-- Definiowanie pól Typ ramki, Buffer ID, Numer sekwecyjny, Długość ramki
local f_frame_type   = ProtoField.uint8("parrot.frame_type",   "Frame Type",   base.HEX)
local f_buffer_id    = ProtoField.uint8("parrot.buffer_id",    "Buffer ID",    base.DEC)
local f_seq_number   = ProtoField.uint8("parrot.seq_number",   "Sequence Number", base.DEC)
local f_frame_length = ProtoField.uint32("parrot.frame_length", "Frame Length", base.DEC, nil, littleendian)

-- Nowe pola dla argumentów (jednostka i opis)
local f_arg_unit         = ProtoField.string("parrot.arg.unit", "Unit")
local f_arg_description  = ProtoField.string("parrot.arg.description", "Description")

-- Ustawiamy pola tylko na zdefiniowane zmienne
parrot_proto.fields = {
  f_frame_type,
  f_buffer_id,
  f_seq_number,
  f_frame_length,
  f_arg_unit,
  f_arg_description
}

-- Tablica komend common i ardrone3 
-- Tabela komend projektu "common"
local common_commands = {
    [0] = {  -- Klasa "Network"
      [0] = {
        name = "Disconnect",
        deprecated = true,
        args = {}
      }
    },
    [1] = {  -- Klasa "NetworkEvent"
      [0] = {
        name = "Disconnection",
        content = "NOTIFICATION",
        args = {
          {
            name = "cause",
            type = "enum",
            enum = {
              off_button    = "off_button",
              unknown       = "unknown",
              reset_factory = "reset_factory"
            },
            unit = "",
            description = "Cause of the disconnection (off_button, unknown, reset_factory)"
          }
        }
      }
    },
    [2] = {  -- Klasa "Settings"
      [0] = {
        name = "AllSettings",
        timeout = "RETRY",
        args = {}
      },
      [1] = {
        name = "Reset",
        args = {}
      },
      [2] = {
        name = "ProductName",
        args = {
          {
            name = "name",
            type = "string",
            unit = "",
            description = "Product name (also used for Wifi SSID/BLE advertisement after reboot)"
          }
        }
      },
      [3] = {
        name = "Country",
        args = {
          {
            name = "code",
            type = "string",
            unit = "",
            description = "Country code in ISO 3166 format"
          }
        }
      },
      [4] = {
        name = "AutoCountry",
        args = {
          {
            name = "automatic",
            type = "u8",
            unit = "",
            description = "Boolean flag: 0 = Manual, 1 = Auto"
          }
        }
      }
    },
    [3] = {  -- Klasa "SettingsState"
      [0] = {
        name = "AllSettingsChanged",
        timeout = "RETRY",
        args = {}
      },
      [1] = {
        name = "ResetChanged",
        args = {}
      },
      [2] = {
        name = "ProductNameChanged",
        args = {
          {
            name = "name",
            type = "string",
            unit = "",
            description = "New product name"
          }
        }
      },
      [3] = {
        name = "ProductVersionChanged",
        args = {
          {
            name = "software",
            type = "string",
            unit = "",
            description = "Product software version"
          },
          {
            name = "hardware",
            type = "string",
            unit = "",
            description = "Product hardware version"
          }
        }
      },
      [4] = {
        name = "ProductSerialHighChanged",
        args = {
          {
            name = "high",
            type = "string",
            unit = "",
            description = "Serial high part (hexadecimal)"
          }
        }
      },
      [5] = {
        name = "ProductSerialLowChanged",
        args = {
          {
            name = "low",
            type = "string",
            unit = "",
            description = "Serial low part (hexadecimal)"
          }
        }
      },
      [6] = {
        name = "CountryChanged",
        args = {
          {
            name = "code",
            type = "string",
            unit = "",
            description = "Country code (ISO 3166), empty if unknown"
          }
        }
      },
      [7] = {
        name = "AutoCountryChanged",
        args = {
          {
            name = "automatic",
            type = "u8",
            unit = "",
            description = "Boolean flag: 0 = Manual, 1 = Auto"
          }
        }
      },
      [8] = {
        name = "BoardIdChanged",
        args = {
          {
            name = "id",
            type = "string",
            unit = "",
            description = "Board identifier"
          }
        }
      }
    },
    [4] = {  -- Klasa "Common"
      [0] = {
        name = "AllStates",
        timeout = "RETRY",
        args = {}
      },
      [1] = {
        name = "CurrentDate",
        deprecated = true,
        args = {
          {
            name = "date",
            type = "string",
            unit = "",
            description = "Date in ISO-8601 format"
          }
        }
      },
      [2] = {
        name = "CurrentTime",
        deprecated = true,
        args = {
          {
            name = "time",
            type = "string",
            unit = "",
            description = "Time in ISO-8601 format"
          }
        }
      },
      [3] = {
        name = "Reboot",
        args = {}
      },
      [4] = {
        name = "CurrentDateTime",
        args = {
          {
            name = "datetime",
            type = "string",
            unit = "",
            description = "Combined date and time in ISO-8601 short complete format (%Y%m%dT%H%M%S%z)"
          }
        }
      }
    },
    [5] = {  -- Klasa "CommonState"
      [0] = {
        name = "AllStatesChanged",
        args = {}
      },
      [1] = {
        name = "BatteryStateChanged",
        args = {
          {
            name = "percent",
            type = "u8",
            unit = "%",
            description = "Battery level in percentage"
          }
        }
      },
      [2] = {
        name = "MassStorageStateListChanged",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Unique mass storage identifier"
          },
          {
            name = "name",
            type = "string",
            unit = "",
            description = "Mass storage name"
          }
        }
      },
      [3] = {
        name = "MassStorageInfoStateListChanged",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Unique mass storage identifier"
          },
          {
            name = "size",
            type = "u32",
            unit = "MBytes",
            description = "Mass storage total size in megabytes"
          },
          {
            name = "used_size",
            type = "u32",
            unit = "MBytes",
            description = "Used mass storage size in megabytes"
          },
          {
            name = "plugged",
            type = "u8",
            unit = "",
            description = "1 if plugged, 0 otherwise"
          },
          {
            name = "full",
            type = "u8",
            unit = "",
            description = "1 if full, 0 otherwise"
          },
          {
            name = "internal",
            type = "u8",
            unit = "",
            description = "1 if internal, 0 otherwise"
          }
        }
      },
      [4] = {
        name = "CurrentDateChanged",
        deprecated = true,
        args = {
          {
            name = "date",
            type = "string",
            unit = "",
            description = "Date (ISO-8601)"
          }
        }
      },
      [5] = {
        name = "CurrentTimeChanged",
        deprecated = true,
        args = {
          {
            name = "time",
            type = "string",
            unit = "",
            description = "Time (ISO-8601)"
          }
        }
      },
      [6] = {
        name = "MassStorageInfoRemainingListChanged",
        type = "LIST_ITEM",
        deprecated = true,
        args = {
          {
            name = "free_space",
            type = "u32",
            unit = "MBytes",
            description = "Free space in megabytes"
          },
          {
            name = "rec_time",
            type = "u16",
            unit = "min",
            description = "Record time remaining in minutes"
          },
          {
            name = "photo_remaining",
            type = "u32",
            unit = "",
            description = "Remaining number of photos"
          }
        }
      },
      [7] = {
        name = "WifiSignalChanged",
        args = {
          {
            name = "rssi",
            type = "i16",
            unit = "dBm",
            description = "Signal strength in dBm (usually negative)"
          }
        }
      },
      [8] = {
        name = "SensorsStatesListChanged",
        type = "MAP_ITEM",
        args = {
          {
            name = "sensorName",
            type = "enum",
            enum = {
              IMU = "IMU",
              barometer = "barometer",
              ultrasound = "ultrasound",
              GPS = "GPS",
              magnetometer = "magnetometer",
              vertical_camera = "vertical_camera",
              vertical_tof = "vertical_tof"
            },
            unit = "",
            description = "Name of the sensor"
          },
          {
            name = "sensorState",
            type = "u8",
            unit = "",
            description = "Sensor state: 1 if OK, 0 if not"
          }
        }
      },
      [9] = {
        name = "ProductModel",
        args = {
          {
            name = "model",
            type = "enum",
            enum = {
              RS_TRAVIS = "RS_TRAVIS",
              RS_MARS = "RS_MARS",
              RS_SWAT = "RS_SWAT",
              RS_MCLANE = "RS_MCLANE",
              RS_BLAZE = "RS_BLAZE",
              RS_ORAK = "RS_ORAK",
              RS_NEWZ = "RS_NEWZ",
              JS_MARSHALL = "JS_MARSHALL",
              JS_DIESEL = "JS_DIESEL",
              JS_BUZZ = "JS_BUZZ",
              JS_MAX = "JS_MAX",
              JS_JETT = "JS_JETT",
              JS_TUKTUK = "JS_TUKTUK",
              SW_BLACK = "SW_BLACK",
              SW_WHITE = "SW_WHITE"
            },
            unit = "",
            description = "Product model (identifier)"
          }
        }
      },
      [10] = {
        name = "CountryListKnown",
        type = "LIST_ITEM",
        deprecated = true,
        args = {
          {
            name = "listFlags",
            type = "u8",
            unit = "",
            description = "Bitfield flags for list entry (First, Last, Empty)"
          },
          {
            name = "countryCodes",
            type = "string",
            unit = "",
            description = "List of country codes in ISO 3166 format separated by ';'"
          }
        }
      },
      [11] = {
        name = "DeprecatedMassStorageContentChanged",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Unique mass storage identifier"
          },
          {
            name = "nbPhotos",
            type = "u16",
            unit = "",
            description = "Number of photos (excluding raw images)"
          },
          {
            name = "nbVideos",
            type = "u16",
            unit = "",
            description = "Number of videos"
          },
          {
            name = "nbPuds",
            type = "u16",
            unit = "",
            description = "Number of puds"
          },
          {
            name = "nbCrashLogs",
            type = "u16",
            unit = "",
            description = "Number of crash logs"
          }
        }
      },
      [12] = {
        name = "MassStorageContent",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Unique mass storage identifier"
          },
          {
            name = "nbPhotos",
            type = "u16",
            unit = "",
            description = "Number of photos (excluding raw images)"
          },
          {
            name = "nbVideos",
            type = "u16",
            unit = "",
            description = "Number of videos"
          },
          {
            name = "nbPuds",
            type = "u16",
            unit = "",
            description = "Number of puds"
          },
          {
            name = "nbCrashLogs",
            type = "u16",
            unit = "",
            description = "Number of crash logs"
          },
          {
            name = "nbRawPhotos",
            type = "u16",
            unit = "",
            description = "Number of raw photos"
          }
        }
      },
      [13] = {
        name = "MassStorageContentForCurrentRun",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Unique mass storage identifier"
          },
          {
            name = "nbPhotos",
            type = "u16",
            unit = "",
            description = "Number of photos for current run (excluding raw images)"
          },
          {
            name = "nbVideos",
            type = "u16",
            unit = "",
            description = "Number of videos for current run"
          },
          {
            name = "nbRawPhotos",
            type = "u16",
            unit = "",
            description = "Number of raw photos for current run"
          }
        }
      },
      [14] = {
        name = "VideoRecordingTimestamp",
        deprecated = true,
        args = {
          {
            name = "startTimestamp",
            type = "u64",
            unit = "ms",
            description = "Video recording start timestamp (ms since epoch)"
          },
          {
            name = "stopTimestamp",
            type = "u64",
            unit = "ms",
            description = "Video recording stop timestamp (ms since epoch; 0 if still recording)"
          }
        }
      },
      [15] = {
        name = "CurrentDateTimeChanged",
        args = {
          {
            name = "datetime",
            type = "string",
            unit = "",
            description = "New combined date and time (ISO-8601 short complete format)"
          }
        }
      },
      [16] = {
        name = "LinkSignalQuality",
        args = {
          {
            name = "value",
            type = "u8",
            unit = "",
            description = "Link quality bit field: bits 0-3 (quality 1-5), bit 6 (4G interference), bit 7 (external perturbation)"
          }
        }
      },
      [17] = {
        name = "BootId",
        args = {
          {
            name = "bootId",
            type = "string",
            unit = "",
            description = "Current drone boot id"
          }
        }
      },
      [18] = {
        name = "FlightId",
        args = {
          {
            name = "flightId",
            type = "string",
            unit = "",
            description = "Current flight id (empty after landing)"
          }
        }
      }
    },
    [6] = {  -- Klasa "OverHeat"
      [0] = {
        name = "SwitchOff",
        deprecated = true,
        args = {}
      },
      [1] = {
        name = "Ventilate",
        deprecated = true,
        args = {}
      }
    },
    [7] = {  -- Klasa "OverHeatState"
      [0] = {
        name = "OverHeatChanged",
        deprecated = true,
        args = {}
      },
      [1] = {
        name = "OverHeatRegulationChanged",
        args = {
          {
            name = "regulationType",
            type = "u8",
            unit = "",
            description = "0 for ventilation, 1 for switch off"
          }
        }
      }
    },
    [8] = {  -- Klasa "Controller"
      [0] = {
        name = "isPiloting",
        deprecated = true,
        args = {
          {
            name = "piloting",
            type = "u8",
            unit = "",
            description = "1 if controller is in piloting HUD, 0 otherwise"
          }
        }
      },
      [1] = {
        name = "PeerStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { CONNECTED = "connected", DISCONNECTED = "disconnected" },
            unit = "",
            description = "Peer connection state"
          },
          {
            name = "type",
            type = "enum",
            enum = { UNKNOWN = "unknown", NET = "net", MUX = "mux" },
            unit = "",
            description = "SDK connection type"
          },
          {
            name = "peerName",
            type = "string",
            unit = "",
            description = "Name of the connecting peer (may be empty)"
          },
          {
            name = "peerId",
            type = "string",
            unit = "",
            description = "Peer identifier (may be empty)"
          },
          {
            name = "peerType",
            type = "string",
            unit = "",
            description = "Peer type (may be empty)"
          }
        }
      }
    },
    [9] = {  -- Klasa "WifiSettings"
      [0] = {
        name = "OutdoorSetting",
        args = {
          {
            name = "outdoor",
            type = "u8",
            unit = "",
            description = "1 if outdoor mode should be enabled, 0 otherwise"
          }
        }
      }
    },
    [10] = {  -- Klasa "WifiSettingsState"
      [0] = {
        name = "outdoorSettingsChanged",
        args = {
          {
            name = "outdoor",
            type = "u8",
            unit = "",
            description = "1 if outdoor mode is active, 0 otherwise"
          }
        }
      }
    },
    [11] = {  -- Klasa "Mavlink"
      [0] = {
        name = "Start",
        args = {
          {
            name = "filepath",
            type = "string",
            unit = "",
            description = "Flight plan file path from the mavlink FTP root"
          },
          {
            name = "type",
            type = "enum",
            enum = {
              FLIGHT_PLAN = "flightPlan",
              MAP_MY_HOUSE = "mapMyHouse",
              FLIGHT_PLAN_V2 = "flightPlanV2"
            },
            unit = "",
            description = "Type of mavlink file (flightPlan, mapMyHouse, flightPlanV2)"
          }
        }
      },
      [1] = {
        name = "Pause",
        args = {}
      },
      [2] = {
        name = "Stop",
        args = {}
      }
    },
    [12] = {  -- Klasa "MavlinkState"
      [0] = {
        name = "MavlinkFilePlayingStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = {
              playing = "playing",
              stopped = "stopped",
              paused = "paused",
              loaded = "loaded"
            },
            unit = "",
            description = "Current state of mavlink file playback"
          },
          {
            name = "filepath",
            type = "string",
            unit = "",
            description = "Flight plan file path"
          },
          {
            name = "type",
            type = "enum",
            enum = {
              flightPlan = "flightPlan",
              mapMyHouse = "mapMyHouse",
              flightPlanV2 = "flightPlanV2"
            },
            unit = "",
            description = "Type of mavlink file"
          }
        }
      },
      [1] = {
        name = "MavlinkPlayErrorStateChanged",
        deprecated = true,
        args = {
          {
            name = "error",
            type = "enum",
            enum = {
              none = "none",
              notInOutDoorMode = "notInOutDoorMode",
              gpsNotFixed = "gpsNotFixed",
              notCalibrated = "notCalibrated"
            },
            unit = "",
            description = "Error state for mavlink playback"
          }
        }
      },
      [2] = {
        name = "MissionItemExecuted",
        content = "NOTIFICATION",
        args = {
          {
            name = "idx",
            type = "u32",
            unit = "",
            description = "Index of the executed mission item (starting from 0)"
          }
        }
      }
    },
    [32] = {  -- Klasa "FlightPlanSettings"
      [0] = {
        name = "ReturnHomeOnDisconnect",
        args = {
          {
            name = "value",
            type = "u8",
            unit = "",
            description = "1 to enable, 0 to disable return home on disconnect"
          }
        }
      }
    },
    [33] = {  -- Klasa "FlightPlanSettingsState"
      [0] = {
        name = "ReturnHomeOnDisconnectChanged",
        args = {
          {
            name = "state",
            type = "u8",
            unit = "",
            description = "1 if enabled, 0 if disabled"
          },
          {
            name = "isReadOnly",
            type = "u8",
            unit = "",
            description = "1 if setting is read-only, 0 if writable"
          }
        }
      }
    },
    [13] = {  -- Klasa "Calibration"
      [0] = {
        name = "MagnetoCalibration",
        args = {
          {
            name = "calibrate",
            type = "u8",
            unit = "",
            description = "1 to start magnetometer calibration, 0 to abort"
          }
        }
      },
      [1] = {
        name = "PitotCalibration",
        args = {
          {
            name = "calibrate",
            type = "u8",
            unit = "",
            description = "1 to start pitot calibration, 0 to abort"
          }
        }
      }
    },
    [14] = {  -- Klasa "CalibrationState"
      [0] = {
        name = "MagnetoCalibrationStateChanged",
        args = {
          {
            name = "xAxisCalibration",
            type = "u8",
            unit = "",
            description = "1 if x-axis calibrated, 0 otherwise"
          },
          {
            name = "yAxisCalibration",
            type = "u8",
            unit = "",
            description = "1 if y-axis calibrated, 0 otherwise"
          },
          {
            name = "zAxisCalibration",
            type = "u8",
            unit = "",
            description = "1 if z-axis calibrated, 0 otherwise"
          },
          {
            name = "calibrationFailed",
            type = "u8",
            unit = "",
            description = "1 if calibration failed, 0 otherwise"
          }
        }
      },
      [1] = {
        name = "MagnetoCalibrationRequiredState",
        args = {
          {
            name = "required",
            type = "u8",
            unit = "",
            description = "1 if calibration required, 0 if valid, 2 if recommended"
          }
        }
      },
      [2] = {
        name = "MagnetoCalibrationAxisToCalibrateChanged",
        args = {
          {
            name = "axis",
            type = "enum",
            enum = { xAxis = "xAxis", yAxis = "yAxis", zAxis = "zAxis", none = "none" },
            unit = "",
            description = "Axis to be calibrated (xAxis, yAxis, zAxis) or 'none'"
          }
        }
      },
      [3] = {
        name = "MagnetoCalibrationStartedChanged",
        args = {
          {
            name = "started",
            type = "u8",
            unit = "",
            description = "1 if calibration started, 0 otherwise"
          }
        }
      },
      [4] = {
        name = "PitotCalibrationStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { done = "done", ready = "ready", in_progress = "in_progress", required = "required" },
            unit = "",
            description = "Current state of pitot calibration"
          },
          {
            name = "lastError",
            type = "u8",
            unit = "",
            description = "1 if an error occurred, 0 otherwise"
          }
        }
      }
    },
    [15] = {  -- Klasa "CameraSettingsState"
      [0] = {
        name = "CameraSettingsChanged",
        args = {
          {
            name = "fov",
            type = "float",
            unit = "°",
            description = "Horizontal FOV of the camera in degrees"
          },
          {
            name = "panMax",
            type = "float",
            unit = "°",
            description = "Maximum pan angle in degrees"
          },
          {
            name = "panMin",
            type = "float",
            unit = "°",
            description = "Minimum pan angle in degrees"
          },
          {
            name = "tiltMax",
            type = "float",
            unit = "°",
            description = "Maximum tilt angle in degrees"
          },
          {
            name = "tiltMin",
            type = "float",
            unit = "°",
            description = "Minimum tilt angle in degrees"
          }
        }
      }
    },
    [16] = {  -- Klasa "GPS"
      [0] = {
        name = "ControllerPositionForRun",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Controller latitude in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Controller longitude in decimal degrees"
          }
        }
      }
    },
    [17] = {  -- Klasa "FlightPlanState"
      [0] = {
        name = "AvailabilityStateChanged",
        args = {
          {
            name = "AvailabilityState",
            type = "u8",
            unit = "",
            description = "1 if FlightPlan is available, 0 otherwise"
          }
        }
      },
      [1] = {
        name = "ComponentStateListChanged",
        type = "MAP_ITEM",
        args = {
          {
            name = "component",
            type = "enum",
            enum = {
              GPS = "GPS",
              Calibration = "Calibration",
              Mavlink_File = "Mavlink_File",
              TakeOff = "TakeOff",
              WaypointsBeyondGeofence = "WaypointsBeyondGeofence",
              CameraAvailable = "CameraAvailable",
              Mavlink_State = "Mavlink_State",
              Mavlink_Media = "Mavlink_Media",
              FirstWaypointTooFar = "FirstWaypointTooFar"
            },
            unit = "",
            description = "Identifier for the FlightPlan component"
          },
          {
            name = "State",
            type = "u8",
            unit = "",
            description = "Component state: 1 if OK, 0 otherwise"
          }
        }
      },
      [2] = {
        name = "LockStateChanged",
        args = {
          {
            name = "LockState",
            type = "u8",
            unit = "",
            description = "1 if FlightPlan is locked, 0 if unlocked"
          }
        }
      }
    },
    [19] = {  -- Klasa "FlightPlanEvent"
      [0] = {
        name = "StartingErrorEvent",
        content = "NOTIFICATION",
        args = {}
      },
      [1] = {
        name = "SpeedBridleEvent",
        content = "NOTIFICATION",
        args = {}
      }
    },
    [18] = {  -- Klasa "ARLibsVersionsState"
      [0] = {
        name = "ControllerLibARCommandsVersion",
        args = {
          {
            name = "version",
            type = "string",
            unit = "",
            description = "Controller libARCommands version (e.g. '1.2.3.4')"
          }
        }
      },
      [1] = {
        name = "SkyControllerLibARCommandsVersion",
        args = {
          {
            name = "version",
            type = "string",
            unit = "",
            description = "SkyController libARCommands version"
          }
        }
      },
      [2] = {
        name = "DeviceLibARCommandsVersion",
        args = {
          {
            name = "version",
            type = "string",
            unit = "",
            description = "Device libARCommands version"
          }
        }
      }
    },
    [20] = {  -- Klasa "Audio"
      [0] = {
        name = "ControllerReadyForStreaming",
        args = {
          {
            name = "ready",
            type = "u8",
            unit = "",
            description = "Bit field: bit0 = controller ready for RX, bit1 = ready for TX"
          }
        }
      }
    },
    [21] = {  -- Klasa "AudioState"
      [0] = {
        name = "AudioStreamingRunning",
        args = {
          {
            name = "running",
            type = "u8",
            unit = "",
            description = "Bit field: bit0 = Drone TX running, bit1 = Drone RX running"
          }
        }
      }
    },
    [22] = {  -- Klasa "Headlights"
      [0] = {
        name = "intensity",
        args = {
          {
            name = "left",
            type = "u8",
            unit = "",
            description = "Left LED intensity (0..255)"
          },
          {
            name = "right",
            type = "u8",
            unit = "",
            description = "Right LED intensity (0..255)"
          }
        }
      }
    },
    [23] = {  -- Klasa "HeadlightsState"
      [0] = {
        name = "intensityChanged",
        args = {
          {
            name = "left",
            type = "u8",
            unit = "",
            description = "Left LED intensity (0..255)"
          },
          {
            name = "right",
            type = "u8",
            unit = "",
            description = "Right LED intensity (0..255)"
          }
        }
      }
    },
    [24] = {  -- Klasa "Animations"
      [0] = {
        name = "StartAnimation",
        args = {
          {
            name = "anim",
            type = "enum",
            enum = {
              HEADLIGHTS_FLASH = "HEADLIGHTS_FLASH",
              HEADLIGHTS_BLINK = "HEADLIGHTS_BLINK",
              HEADLIGHTS_OSCILLATION = "HEADLIGHTS_OSCILLATION",
              SPIN = "SPIN",
              TAP = "TAP",
              SLOW_SHAKE = "SLOW_SHAKE",
              METRONOME = "METRONOME",
              ONDULATION = "ONDULATION",
              SPIN_JUMP = "SPIN_JUMP",
              SPIN_TO_POSTURE = "SPIN_TO_POSTURE",
              SPIRAL = "SPIRAL",
              SLALOM = "SLALOM",
              BOOST = "BOOST",
              LOOPING = "LOOPING",
              BARREL_ROLL_180_RIGHT = "BARREL_ROLL_180_RIGHT",
              BARREL_ROLL_180_LEFT = "BARREL_ROLL_180_LEFT",
              BACKSWAP = "BACKSWAP"
            },
            unit = "",
            description = "Animation to start"
          }
        }
      },
      [1] = {
        name = "StopAnimation",
        args = {
          {
            name = "anim",
            type = "enum",
            enum = {
              HEADLIGHTS_FLASH = "HEADLIGHTS_FLASH",
              HEADLIGHTS_BLINK = "HEADLIGHTS_BLINK",
              HEADLIGHTS_OSCILLATION = "HEADLIGHTS_OSCILLATION",
              SPIN = "SPIN",
              TAP = "TAP",
              SLOW_SHAKE = "SLOW_SHAKE",
              METRONOME = "METRONOME",
              ONDULATION = "ONDULATION",
              SPIN_JUMP = "SPIN_JUMP",
              SPIN_TO_POSTURE = "SPIN_TO_POSTURE",
              SPIRAL = "SPIRAL",
              SLALOM = "SLALOM",
              BOOST = "BOOST",
              LOOPING = "LOOPING",
              BARREL_ROLL_180_RIGHT = "BARREL_ROLL_180_RIGHT",
              BARREL_ROLL_180_LEFT = "BARREL_ROLL_180_LEFT",
              BACKSWAP = "BACKSWAP"
            },
            unit = "",
            description = "Animation to stop"
          }
        }
      },
      [2] = {
        name = "StopAllAnimations",
        args = {}
      }
    },
    [25] = {  -- Klasa "AnimationsState"
      [0] = {
        name = "List",
        type = "MAP_ITEM",
        args = {
          {
            name = "anim",
            type = "enum",
            enum = {
              HEADLIGHTS_FLASH = "HEADLIGHTS_FLASH",
              HEADLIGHTS_BLINK = "HEADLIGHTS_BLINK",
              HEADLIGHTS_OSCILLATION = "HEADLIGHTS_OSCILLATION",
              SPIN = "SPIN",
              TAP = "TAP",
              SLOW_SHAKE = "SLOW_SHAKE",
              METRONOME = "METRONOME",
              ONDULATION = "ONDULATION",
              SPIN_JUMP = "SPIN_JUMP",
              SPIN_TO_POSTURE = "SPIN_TO_POSTURE",
              SPIRAL = "SPIRAL",
              SLALOM = "SLALOM",
              BOOST = "BOOST",
              LOOPING = "LOOPING",
              BARREL_ROLL_180_RIGHT = "BARREL_ROLL_180_RIGHT",
              BARREL_ROLL_180_LEFT = "BARREL_ROLL_180_LEFT",
              BACKSWAP = "BACKSWAP"
            },
            unit = "",
            description = "Animation type"
          },
          {
            name = "state",
            type = "enum",
            enum = { stopped = "stopped", started = "started", notAvailable = "notAvailable" },
            unit = "",
            description = "State of the animation"
          },
          {
            name = "error",
            type = "enum",
            enum = { ok = "ok", unknown = "unknown" },
            unit = "",
            description = "Error code (ok if none)"
          }
        }
      }
    },
    [26] = {  -- Klasa "Accessory"
      [0] = {
        name = "Config",
        args = {
          {
            name = "accessory",
            type = "enum",
            enum = { NO_ACCESSORY = "NO_ACCESSORY", STD_WHEELS = "STD_WHEELS", TRUCK_WHEELS = "TRUCK_WHEELS", HULL = "HULL", HYDROFOIL = "HYDROFOIL" },
            unit = "",
            description = "Accessory configuration to set"
          }
        }
      }
    },
    [27] = {  -- Klasa "AccessoryState"
      [0] = {
        name = "SupportedAccessoriesListChanged",
        type = "MAP_ITEM",
        args = {
          {
            name = "accessory",
            type = "enum",
            enum = { NO_ACCESSORY = "NO_ACCESSORY", STD_WHEELS = "STD_WHEELS", TRUCK_WHEELS = "TRUCK_WHEELS", HULL = "HULL", HYDROFOIL = "HYDROFOIL" },
            unit = "",
            description = "Supported accessory configuration"
          }
        }
      },
      [1] = {
        name = "AccessoryConfigChanged",
        args = {
          {
            name = "newAccessory",
            type = "enum",
            enum = { UNCONFIGURED = "UNCONFIGURED", NO_ACCESSORY = "NO_ACCESSORY", STD_WHEELS = "STD_WHEELS", TRUCK_WHEELS = "TRUCK_WHEELS", HULL = "HULL", HYDROFOIL = "HYDROFOIL", IN_PROGRESS = "IN_PROGRESS" },
            unit = "",
            description = "New accessory configuration reported"
          },
          {
            name = "error",
            type = "enum",
            enum = { OK = "OK", UNKNOWN = "UNKNOWN", FLYING = "FLYING" },
            unit = "",
            description = "Error code for accessory config change"
          }
        }
      },
      [2] = {
        name = "AccessoryConfigModificationEnabled",
        args = {
          {
            name = "enabled",
            type = "u8",
            unit = "",
            description = "1 if accessory config modification is enabled, 0 otherwise"
          }
        }
      }
    },
    [28] = {  -- Klasa "Charger"
      [0] = {
        name = "SetMaxChargeRate",
        deprecated = true,
        args = {
          {
            name = "rate",
            type = "enum",
            enum = { SLOW = "SLOW", MODERATE = "MODERATE", FAST = "FAST" },
            unit = "",
            description = "Maximum charge rate setting (SLOW, MODERATE, FAST)"
          }
        }
      }
    },
    [29] = {  -- Klasa "ChargerState"
      [0] = {
        name = "MaxChargeRateChanged",
        deprecated = true,
        args = {
          {
            name = "rate",
            type = "enum",
            enum = { SLOW = "SLOW", MODERATE = "MODERATE", FAST = "FAST" },
            unit = "",
            description = "Currently set maximum charge rate"
          }
        }
      },
      [1] = {
        name = "CurrentChargeStateChanged",
        deprecated = true,
        args = {
          {
            name = "status",
            type = "enum",
            enum = { DISCHARGING = "DISCHARGING", CHARGING_SLOW = "CHARGING_SLOW", CHARGING_MODERATE = "CHARGING_MODERATE", CHARGING_FAST = "CHARGING_FAST", BATTERY_FULL = "BATTERY_FULL" },
            unit = "",
            description = "Current charging status"
          },
          {
            name = "phase",
            type = "enum",
            enum = { UNKNOWN = "UNKNOWN", CONSTANT_CURRENT_1 = "CONSTANT_CURRENT_1", CONSTANT_CURRENT_2 = "CONSTANT_CURRENT_2", CONSTANT_VOLTAGE = "CONSTANT_VOLTAGE", CHARGED = "CHARGED" },
            unit = "",
            description = "Current charging phase"
          }
        }
      },
      [2] = {
        name = "LastChargeRateChanged",
        deprecated = true,
        args = {
          {
            name = "rate",
            type = "enum",
            enum = { UNKNOWN = "UNKNOWN", SLOW = "SLOW", MODERATE = "MODERATE", FAST = "FAST" },
            unit = "",
            description = "Charge rate from the last charge cycle"
          }
        }
      },
      [3] = {
        name = "ChargingInfo",
        args = {
          {
            name = "phase",
            type = "enum",
            enum = { UNKNOWN = "UNKNOWN", CONSTANT_CURRENT_1 = "CONSTANT_CURRENT_1", CONSTANT_CURRENT_2 = "CONSTANT_CURRENT_2", CONSTANT_VOLTAGE = "CONSTANT_VOLTAGE", CHARGED = "CHARGED", DISCHARGING = "DISCHARGING" },
            unit = "",
            description = "Current charging phase (info for charging)"
          },
          {
            name = "rate",
            type = "enum",
            enum = { UNKNOWN = "UNKNOWN", SLOW = "SLOW", MODERATE = "MODERATE", FAST = "FAST" },
            unit = "",
            description = "Current charging rate"
          },
          {
            name = "intensity",
            type = "u8",
            unit = "dA",
            description = "Charging intensity in deci-Amperes (e.g. 12dA = 1.2A)"
          },
          {
            name = "fullChargingTime",
            type = "u8",
            unit = "min",
            description = "Estimated full charging time in minutes"
          }
        }
      }
    },
    [30] = {  -- Klasa "RunState"
      [0] = {
        name = "RunIdChanged",
        args = {
          {
            name = "runId",
            type = "string",
            unit = "",
            description = "Unique run or flight identifier"
          }
        }
      }
    },
    [31] = {  -- Klasa "Factory"
      [0] = {
        name = "Reset",
        args = {}
      }
    },
    [34] = {  -- Klasa "UpdateState"
      [0] = {
        name = "UpdateStateChanged",
        args = {
          {
            name = "sourceVersion",
            type = "string",
            unit = "",
            description = "Software version before update"
          },
          {
            name = "targetVersion",
            type = "string",
            unit = "",
            description = "Target version after update (or failed update version)"
          },
          {
            name = "status",
            type = "enum",
            enum = { SUCCESS = "SUCCESS", FAILURE_BAD_FILE = "FAILURE_BAD_FILE", FAILURE_BAT_LEVEL_TOO_LOW = "FAILURE_BAT_LEVEL_TOO_LOW", FAILURE = "FAILURE" },
            unit = "",
            description = "Update status (SUCCESS, FAILURE_BAD_FILE, FAILURE_BAT_LEVEL_TOO_LOW, FAILURE)"
          }
        }
      }
    }
}

-- Tabela komend projektu "ardrone3"
local ardrone3_commands = {
    [0] = {  -- Klasa "Piloting"
      [1] = {
        name = "TakeOff",
        args = {}
      },
      [2] = {
        name = "PCMD",
        args = {
          {
            name = "flag",
            type = "u8",
            unit = "",
            description = "Boolean flag: 1 if roll/pitch should be considered, 0 otherwise"
          },
          {
            name = "roll",
            type = "i8",
            unit = "%",
            description = "Roll angle as a signed percentage (–100 to 100)"
          },
          {
            name = "pitch",
            type = "i8",
            unit = "%",
            description = "Pitch angle as a signed percentage (–100 to 100)"
          },
          {
            name = "yaw",
            type = "i8",
            unit = "%",
            description = "Yaw rotation speed as signed percentage (–100 to 100)"
          },
          {
            name = "gaz",
            type = "i8",
            unit = "%",
            description = "Throttle as signed percentage (–100 to 100); note: during landing, positive gaz cancels landing"
          },
          {
            name = "timestampAndSeqNum",
            type = "u32",
            unit = "ms",
            description = "Command timestamp (low 24 bits = ms) + sequence number (high 8 bits)"
          }
        }
      },
      [3] = {
        name = "Landing",
        args = {}
      },
      [4] = {
        name = "Emergency",
        args = {}
      },
      [5] = {
        name = "NavigateHome",
        args = {
          {
            name = "start",
            type = "u8",
            unit = "",
            description = "1 to start navigate home, 0 to cancel"
          }
        }
      },
      [7] = {
        name = "moveBy",
        args = {
          {
            name = "dX",
            type = "float",
            unit = "m",
            description = "Relative displacement along front axis in meters"
          },
          {
            name = "dY",
            type = "float",
            unit = "m",
            description = "Relative displacement along right axis in meters"
          },
          {
            name = "dZ",
            type = "float",
            unit = "m",
            description = "Relative displacement along down axis in meters"
          },
          {
            name = "dPsi",
            type = "float",
            unit = "rad",
            description = "Relative change in heading in radians"
          }
        }
      },
      [8] = {
        name = "UserTakeOff",
        args = {
          {
            name = "state",
            type = "u8",
            unit = "",
            description = "1 to enable user take off mode, 0 to disable"
          }
        }
      },
      [9] = {
        name = "Circle",
        args = {
          {
            name = "direction",
            type = "enum",
            enum = { front = "front", back = "back", right = "right", left = "left" },
            unit = "",
            description = "Direction for the circular maneuver"
          }
        }
      },
      [10] = {
        name = "moveTo",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Target latitude in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Target longitude in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Target altitude (above takeoff point) in meters"
          },
          {
            name = "orientation_mode",
            type = "enum",
            enum = {
              NONE = "NONE",
              TO_TARGET = "TO_TARGET",
              HEADING_START = "HEADING_START",
              HEADING_DURING = "HEADING_DURING"
            },
            unit = "",
            description = "Orientation mode for moveTo"
          },
          {
            name = "heading",
            type = "float",
            unit = "°",
            description = "Target heading in degrees (used if mode is HEADING_START or HEADING_DURING)"
          }
        }
      },
      [11] = {
        name = "CancelMoveTo",
        args = {}
      },
      [12] = {
        name = "StartPilotedPOI",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Latitude of the POI in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Longitude of the POI in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Altitude of the POI above takeoff in meters"
          }
        }
      },
      [15] = {
        name = "StartPilotedPOIV2",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Latitude of the POI in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Longitude of the POI in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Altitude of the POI above takeoff in meters"
          },
          {
            name = "mode",
            type = "enum",
            enum = { locked_gimbal = "locked_gimbal", locked_once_gimbal = "locked_once_gimbal", free_gimbal = "free_gimbal" },
            unit = "",
            description = "Gimbal behavior mode during POI"
          }
        }
      },
      [13] = {
        name = "StopPilotedPOI",
        args = {}
      },
      [14] = {
        name = "CancelMoveBy",
        args = {}
      },
      [16] = {
        name = "SmartTakeOffLand",
        args = {}
      }
    },
    [5] = {  -- Klasa "Animations" (ardrone3)
      [0] = {
        name = "Flip",
        args = {
          {
            name = "direction",
            type = "enum",
            enum = { front = "front", back = "back", right = "right", left = "left" },
            unit = "",
            description = "Flip direction (front, back, right, left)"
          }
        }
      }
    },
    [1] = {  -- Klasa "Camera" (ardrone3, deprecated)
      [0] = {
        name = "Orientation",
        args = {
          {
            name = "tilt",
            type = "i8",
            unit = "°",
            description = "Tilt camera consign (in degrees)"
          },
          {
            name = "pan",
            type = "i8",
            unit = "°",
            description = "Pan camera consign (in degrees)"
          }
        }
      },
      [1] = {
        name = "OrientationV2",
        args = {
          {
            name = "tilt",
            type = "float",
            unit = "°",
            description = "Tilt camera consign (in degrees)"
          },
          {
            name = "pan",
            type = "float",
            unit = "°",
            description = "Pan camera consign (in degrees)"
          }
        }
      },
      [2] = {
        name = "Velocity",
        args = {
          {
            name = "tilt",
            type = "float",
            unit = "°/s",
            description = "Tilt camera velocity (in deg/s); negative = move downward"
          },
          {
            name = "pan",
            type = "float",
            unit = "°/s",
            description = "Pan camera velocity (in deg/s); negative = move left"
          }
        }
      }
    },
    [7] = {  -- Klasa "MediaRecord" (ardrone3)
      [0] = {
        name = "Picture",
        deprecated = true,
        args = {
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Mass storage id to store the picture"
          }
        }
      },
      [1] = {
        name = "Video",
        deprecated = true,
        args = {
          {
            name = "record",
            type = "enum",
            enum = { stop = "stop", start = "start" },
            unit = "",
            description = "Command: start or stop video recording"
          },
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Mass storage id for video recording"
          }
        }
      },
      [2] = {
        name = "PictureV2",
        args = {}
      },
      [3] = {
        name = "VideoV2",
        args = {
          {
            name = "record",
            type = "enum",
            enum = { stop = "stop", start = "start" },
            unit = "",
            description = "Command: start or stop video recording"
          }
        }
      }
    },
    [8] = {  -- Klasa "MediaRecordState" (ardrone3)
      [0] = {
        name = "PictureStateChanged",
        deprecated = true,
        args = {
          {
            name = "state",
            type = "u8",
            unit = "",
            description = "1 if picture has been taken, 0 otherwise"
          },
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Mass storage id used"
          }
        }
      },
      [1] = {
        name = "VideoStateChanged",
        deprecated = true,
        args = {
          {
            name = "state",
            type = "enum",
            enum = { stopped = "stopped", started = "started", failed = "failed", autostopped = "autostopped" },
            unit = "",
            description = "Video recording state"
          },
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Mass storage id used for video"
          }
        }
      },
      [2] = {
        name = "PictureStateChangedV2",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { ready = "ready", busy = "busy", notAvailable = "notAvailable" },
            unit = "",
            description = "Picture recording state"
          },
          {
            name = "error",
            type = "enum",
            enum = { ok = "ok", unknown = "unknown", camera_ko = "camera_ko", memoryFull = "memoryFull", lowBattery = "lowBattery" },
            unit = "",
            description = "Error code if any"
          }
        }
      },
      [3] = {
        name = "VideoStateChangedV2",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { stopped = "stopped", started = "started", notAvailable = "notAvailable" },
            unit = "",
            description = "Video recording state"
          },
          {
            name = "error",
            type = "enum",
            enum = { ok = "ok", unknown = "unknown", camera_ko = "camera_ko", memoryFull = "memoryFull", lowBattery = "lowBattery" },
            unit = "",
            description = "Error code if any"
          }
        }
      }
    },
    [3] = {  -- Klasa "MediaRecordEvent" (ardrone3)
      [0] = {
        name = "PictureEventChanged",
        content = "NOTIFICATION",
        args = {
          {
            name = "event",
            type = "enum",
            enum = { taken = "taken", failed = "failed" },
            unit = "",
            description = "Event: picture taken or failed"
          },
          {
            name = "error",
            type = "enum",
            enum = { ok = "ok", unknown = "unknown", busy = "busy", notAvailable = "notAvailable", memoryFull = "memoryFull", lowBattery = "lowBattery" },
            unit = "",
            description = "Error code if any (when failed)"
          }
        }
      },
      [1] = {
        name = "VideoEventChanged",
        content = "NOTIFICATION",
        args = {
          {
            name = "event",
            type = "enum",
            enum = { start = "start", stop = "stop", failed = "failed" },
            unit = "",
            description = "Event: video started, stopped, or failed"
          },
          {
            name = "error",
            type = "enum",
            enum = { ok = "ok", unknown = "unknown", busy = "busy", notAvailable = "notAvailable", memoryFull = "memoryFull", lowBattery = "lowBattery", autoStopped = "autoStopped" },
            unit = "",
            description = "Error code if any (when failed)"
          }
        }
      }
    },
    [4] = {  -- Klasa "PilotingState" (ardrone3)
      [1] = {
        name = "FlyingStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = {
              landed = "landed",
              takingoff = "taking_off",
              hovering = "hovering",
              flying = "flying",
              landing = "landing",
              emergency = "emergency",
              usertakeoff = "user_take_off",
              motor_ramping = "motor_ramping",
              emergency_landing = "emergency_landing"
            },
            unit = "",
            description = "Drone flying state"
          }
        }
      },
      [2] = {
        name = "AlertStateChanged",
        deprecated = true,
        args = {
          {
            name = "state",
            type = "enum",
            enum = {
              none = "none",
              user = "user",
              cut_out = "cut_out",
              critical_battery = "critical_battery",
              low_battery = "low_battery",
              too_much_angle = "too_much_angle",
              almost_empty_battery = "almost_empty_battery",
              magneto_pertubation = "magneto_pertubation",
              magneto_low_earth_field = "magneto_low_earth_field"
            },
            unit = "",
            description = "Drone alert state"
          }
        }
      },
      [3] = {
        name = "NavigateHomeStateChanged",
        deprecated = true,
        args = {
          {
            name = "state",
            type = "enum",
            enum = { available = "available", inProgress = "inProgress", unavailable = "unavailable", pending = "pending" },
            unit = "",
            description = "Return home state"
          },
          {
            name = "reason",
            type = "enum",
            enum = {
              userRequest = "userRequest",
              connectionLost = "connectionLost",
              lowBattery = "lowBattery",
              finished = "finished",
              stopped = "stopped",
              disabled = "disabled",
              enabled = "enabled",
              flightplan = "flightplan",
              icing = "icing"
            },
            unit = "",
            description = "Reason for return home state"
          }
        }
      },
      [4] = {
        name = "PositionChanged",
        deprecated = true,
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Latitude in decimal degrees (500.0 if not available)"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Longitude in decimal degrees (500.0 if not available)"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Altitude from GPS in meters"
          }
        }
      },
      [5] = {
        name = "SpeedChanged",
        args = {
          {
            name = "speedX",
            type = "float",
            unit = "m/s",
            description = "Speed relative to North (m/s)"
          },
          {
            name = "speedY",
            type = "float",
            unit = "m/s",
            description = "Speed relative to East (m/s)"
          },
          {
            name = "speedZ",
            type = "float",
            unit = "m/s",
            description = "Vertical speed (m/s); positive when descending"
          }
        }
      },
      [6] = {
        name = "AttitudeChanged",
        args = {
          {
            name = "roll",
            type = "float",
            unit = "rad",
            description = "Roll in radians"
          },
          {
            name = "pitch",
            type = "float",
            unit = "rad",
            description = "Pitch in radians"
          },
          {
            name = "yaw",
            type = "float",
            unit = "rad",
            description = "Yaw in radians"
          }
        }
      },
      [8] = {
        name = "AltitudeChanged",
        args = {
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Altitude above takeoff point in meters"
          }
        }
      },
      [9] = {
        name = "GpsLocationChanged",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Latitude (decimal degrees; 500.0 if not available)"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Longitude (decimal degrees; 500.0 if not available)"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Altitude in meters"
          },
          {
            name = "latitude_accuracy",
            type = "i8",
            unit = "m",
            description = "Latitude error (meters, 1σ), -1 if not available"
          },
          {
            name = "longitude_accuracy",
            type = "i8",
            unit = "m",
            description = "Longitude error (meters, 1σ), -1 if not available"
          },
          {
            name = "altitude_accuracy",
            type = "i8",
            unit = "m",
            description = "Altitude error (meters, 1σ), -1 if not available"
          }
        }
      },
      [10] = {
        name = "LandingStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { linear = "linear", spiral = "spiral" },
            unit = "",
            description = "Landing mode (linear or spiral)"
          }
        }
      },
      [11] = {
        name = "AirSpeedChanged",
        args = {
          {
            name = "airSpeed",
            type = "float",
            unit = "m/s",
            description = "Air speed (m/s; always > 0)"
          }
        }
      },
      [12] = {
        name = "moveToChanged",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Target latitude in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Target longitude in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Target altitude above takeoff in meters"
          },
          {
            name = "orientation_mode",
            type = "enum",
            enum = { NONE = "NONE", TO_TARGET = "TO_TARGET", HEADING_START = "HEADING_START", HEADING_DURING = "HEADING_DURING" },
            unit = "",
            description = "Orientation mode for moveTo"
          },
          {
            name = "heading",
            type = "float",
            unit = "°",
            description = "Heading in degrees (used with HEADING_START/DURING)"
          },
          {
            name = "status",
            type = "enum",
            enum = { RUNNING = "RUNNING", DONE = "DONE", CANCELED = "CANCELED", ERROR = "ERROR" },
            unit = "",
            description = "Status of moveTo"
          }
        }
      },
      [13] = {
        name = "MotionState",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { steady = "steady", moving = "moving" },
            unit = "",
            description = "Motion state: steady or moving"
          }
        }
      },
      [14] = {
        name = "PilotedPOI",
        deprecated = true,
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "POI latitude (decimal degrees)"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "POI longitude (decimal degrees)"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "POI altitude above takeoff (in meters)"
          },
          {
            name = "status",
            type = "enum",
            enum = { UNAVAILABLE = "UNAVAILABLE", AVAILABLE = "AVAILABLE", PENDING = "PENDING", RUNNING = "RUNNING" },
            unit = "",
            description = "Status of the POI"
          }
        }
      },
      [22] = {
        name = "PilotedPOIV2",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "POI latitude (decimal degrees)"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "POI longitude (decimal degrees)"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "POI altitude above takeoff (in meters)"
          },
          {
            name = "mode",
            type = "enum",
            enum = { locked_gimbal = "locked_gimbal", locked_once_gimbal = "locked_once_gimbal", free_gimbal = "free_gimbal" },
            unit = "",
            description = "POI mode (defines gimbal control)"
          },
          {
            name = "status",
            type = "enum",
            enum = { UNAVAILABLE = "UNAVAILABLE", AVAILABLE = "AVAILABLE", PENDING = "PENDING", RUNNING = "RUNNING" },
            unit = "",
            description = "Status of the POI"
          }
        }
      },
      [15] = {
        name = "ReturnHomeBatteryCapacity",
        args = {
          {
            name = "status",
            type = "enum",
            enum = { OK = "OK", WARNING = "WARNING", CRITICAL = "CRITICAL", UNKNOWN = "UNKNOWN" },
            unit = "",
            description = "Battery capacity status for return home"
          }
        }
      },
      [16] = {
        name = "moveByChanged",
        args = {
          {
            name = "dXAsked",
            type = "float",
            unit = "m",
            description = "Distance asked along front axis (m)"
          },
          {
            name = "dYAsked",
            type = "float",
            unit = "m",
            description = "Distance asked along right axis (m)"
          },
          {
            name = "dZAsked",
            type = "float",
            unit = "m",
            description = "Distance asked along down axis (m)"
          },
          {
            name = "dPsiAsked",
            type = "float",
            unit = "rad",
            description = "Rotation asked on heading (radians)"
          },
          {
            name = "dX",
            type = "float",
            unit = "m",
            description = "Actual displacement along front axis (m)"
          },
          {
            name = "dY",
            type = "float",
            unit = "m",
            description = "Actual displacement along right axis (m)"
          },
          {
            name = "dZ",
            type = "float",
            unit = "m",
            description = "Actual displacement along down axis (m)"
          },
          {
            name = "dPsi",
            type = "float",
            unit = "rad",
            description = "Actual applied rotation on heading (rad)"
          },
          {
            name = "status",
            type = "enum",
            enum = { RUNNING = "RUNNING", DONE = "DONE", CANCELED = "CANCELED", ERROR = "ERROR" },
            unit = "",
            description = "Status of the relative move"
          }
        }
      },
      [17] = {
        name = "HoveringWarning",
        args = {
          {
            name = "no_gps_too_dark",
            type = "u8",
            unit = "",
            description = "1 if no GPS and insufficient light, 0 otherwise"
          },
          {
            name = "no_gps_too_high",
            type = "u8",
            unit = "",
            description = "1 if no GPS and flying too high, 0 otherwise"
          }
        }
      },
      [18] = {
        name = "ForcedLandingAutoTrigger",
        args = {
          {
            name = "reason",
            type = "enum",
            enum = {
              none = "NONE",
              battery_critical_soon = "BATTERY_CRITICAL_SOON",
              propeller_icing_critical = "PROPELLER_ICING_CRITICAL",
              battery_too_cold = "BATTERY_TOO_COLD",
              battery_too_hot = "BATTERY_TOO_HOT",
              esc_too_hot = "ESC_TOO_HOT"
            },
            unit = "",
            description = "Reason for forced landing auto trigger"
          },
          {
            name = "delay",
            type = "u32",
            unit = "s",
            description = "Delay in seconds until auto landing is triggered (if reason ≠ NONE)"
          }
        }
      },
      [19] = {
        name = "WindStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { ok = "ok", warning = "warning", critical = "critical" },
            unit = "",
            description = "Wind state: ok, warning, or critical"
          }
        }
      },
      [20] = {
        name = "VibrationLevelChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { ok = "ok", warning = "warning", critical = "critical" },
            unit = "",
            description = "Vibration level: ok, warning, or critical"
          }
        }
      },
      [21] = {
        name = "AltitudeAboveGroundChanged",
        args = {
          {
            name = "altitude",
            type = "float",
            unit = "m",
            description = "Altitude above ground in meters"
          }
        }
      },
      [23] = {
        name = "HeadingLockedStateChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { ok = "ok", warning = "warning", critical = "critical" },
            unit = "",
            description = "Heading lock state of the drone"
          }
        }
      },
      [26] = {
        name = "IcingLevelChanged",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { ok = "ok", warning = "warning", critical = "critical" },
            unit = "",
            description = "Propeller icing level state"
          }
        }
      }
    },
    [34] = {  -- Klasa "PilotingEvent" (ardrone3)
      [0] = {
        name = "moveByEnd",
        content = "NOTIFICATION",
        args = {
          {
            name = "dX",
            type = "float",
            unit = "m",
            description = "Distance traveled along the front axis (m)"
          },
          {
            name = "dY",
            type = "float",
            unit = "m",
            description = "Distance traveled along the right axis (m)"
          },
          {
            name = "dZ",
            type = "float",
            unit = "m",
            description = "Distance traveled along the down axis (m)"
          },
          {
            name = "dPsi",
            type = "float",
            unit = "rad",
            description = "Applied change in heading (radians)"
          },
          {
            name = "error",
            type = "enum",
            enum = { ok = "ok", unknown = "unknown", busy = "busy", notAvailable = "notAvailable", interrupted = "interrupted" },
            unit = "",
            description = "Error state for relative move (if any)"
          }
        }
      },
      [1] = {
        name = "UserTakeoffReady",
        args = {}
      }
    },
    [13] = {  -- Klasa "Network" (ardrone3)
      [0] = {
        name = "WifiScan",
        args = {
          {
            name = "band",
            type = "enum",
            enum = { ["2_4ghz"] = "2_4ghz", ["5ghz"] = "5ghz", all = "all" },
            unit = "",
            description = "WiFi band to scan: 2.4GHz, 5GHz, or all"
          }
        }
      },
      [1] = {
        name = "WifiAuthChannel",
        args = {}
      }
    },
    [14] = {  -- Klasa "NetworkState" (ardrone3)
      [0] = {
        name = "WifiScanListChanged",
        type = "MAP_ITEM",
        args = {
          {
            name = "ssid",
            type = "string",
            unit = "",
            description = "SSID of the access point"
          },
          {
            name = "rssi",
            type = "i16",
            unit = "dBm",
            description = "RSSI of the network (in dBm, negative)"
          },
          {
            name = "band",
            type = "enum",
            enum = { ["2_4ghz"] = "2_4ghz", ["5ghz"] = "5ghz" },
            unit = "",
            description = "WiFi band of the network"
          },
          {
            name = "channel",
            type = "u8",
            unit = "",
            description = "WiFi channel number"
          }
        }
      },
      [1] = {
        name = "AllWifiScanChanged",
        args = {}
      },
      [2] = {
        name = "WifiAuthChannelListChanged",
        type = "LIST_ITEM",
        args = {
          {
            name = "band",
            type = "enum",
            enum = { ["2_4ghz"] = "2_4ghz", ["5ghz"] = "5ghz" },
            unit = "",
            description = "WiFi band for the authorized channel"
          },
          {
            name = "channel",
            type = "u8",
            unit = "",
            description = "Authorized channel number"
          },
          {
            name = "in_or_out",
            type = "u8",
            unit = "",
            description = "Bitfield: bit0 = authorized outside, bit1 = authorized inside"
          }
        }
      },
      [3] = {
        name = "AllWifiAuthChannelChanged",
        args = {}
      }
    },
    [2] = {  -- Klasa "PilotingSettings" (ardrone3)
      [0] = {
        name = "MaxAltitude",
        args = {
          {
            name = "current",
            type = "float",
            unit = "m",
            description = "Maximum altitude (in meters)"
          }
        }
      },
      [1] = {
        name = "MaxTilt",
        args = {
          {
            name = "current",
            type = "float",
            unit = "°",
            description = "Maximum tilt (in degrees)"
          }
        }
      },
      [2] = {
        name = "AbsolutControl",
        deprecated = true,
        args = {
          {
            name = "on",
            type = "u8",
            unit = "",
            description = "1 to enable, 0 to disable"
          }
        }
      },
      [3] = {
        name = "MaxDistance",
        args = {
          {
            name = "value",
            type = "float",
            unit = "m",
            description = "Maximum distance (in meters)"
          }
        }
      },
      [4] = {
        name = "NoFlyOverMaxDistance",
        args = {
          {
            name = "shouldNotFlyOver",
            type = "u8",
            unit = "",
            description = "1 if drone must not fly beyond max distance, 0 if not"
          }
        }
      },
      [10] = {
        name = "BankedTurn",
        args = {
          {
            name = "value",
            type = "u8",
            unit = "",
            description = "1 to enable banked turn mode, 0 to disable"
          }
        }
      }
    },
    [6] = {  -- Klasa "PilotingSettingsState" (ardrone3)
      [0] = {
        name = "MaxAltitudeChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "m",
            description = "Current max altitude (m)"
          },
          {
            name = "min",
            type = "float",
            unit = "m",
            description = "Minimum allowed max altitude (m)"
          },
          {
            name = "max",
            type = "float",
            unit = "m",
            description = "Maximum allowed max altitude (m)"
          }
        }
      },
      [1] = {
        name = "MaxTiltChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "°",
            description = "Current max tilt (in degrees)"
          },
          {
            name = "min",
            type = "float",
            unit = "°",
            description = "Minimum allowed tilt (°)"
          },
          {
            name = "max",
            type = "float",
            unit = "°",
            description = "Maximum allowed tilt (°)"
          }
        }
      },
      [2] = {
        name = "AbsolutControlChanged",
        deprecated = true,
        args = {
          {
            name = "on",
            type = "u8",
            unit = "",
            description = "1 if enabled, 0 if disabled"
          }
        }
      },
      [3] = {
        name = "MaxDistanceChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "m",
            description = "Current max distance (m)"
          },
          {
            name = "min",
            type = "float",
            unit = "m",
            description = "Minimum allowed distance (m)"
          },
          {
            name = "max",
            type = "float",
            unit = "m",
            description = "Maximum allowed distance (m)"
          }
        }
      },
      [4] = {
        name = "NoFlyOverMaxDistanceChanged",
        args = {
          {
            name = "shouldNotFlyOver",
            type = "u8",
            unit = "",
            description = "1 if geofencing active, 0 otherwise"
          }
        }
      },
      [10] = {
        name = "BankedTurnChanged",
        args = {
          {
            name = "state",
            type = "u8",
            unit = "",
            description = "1 if banked turn mode is enabled, 0 if disabled"
          }
        }
      },
      [11] = {
        name = "MinAltitudeChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "m",
            description = "Current minimum altitude (m)"
          },
          {
            name = "min",
            type = "float",
            unit = "m",
            description = "Allowed minimum altitude (m)"
          },
          {
            name = "max",
            type = "float",
            unit = "m",
            description = "Allowed maximum minimum altitude (m)"
          }
        }
      },
      [12] = {
        name = "CirclingDirectionChanged",
        args = {
          {
            name = "value",
            type = "enum",
            enum = { CW = "CW", CCW = "CCW" },
            unit = "",
            description = "Circling direction (CW or CCW)"
          }
        }
      },
      [13] = {
        name = "CirclingRadiusChanged",
        deprecated = true,
        args = {
          {
            name = "current",
            type = "u16",
            unit = "m",
            description = "Current circling radius (m)"
          },
          {
            name = "min",
            type = "u16",
            unit = "m",
            description = "Minimum allowed circling radius (m)"
          },
          {
            name = "max",
            type = "u16",
            unit = "m",
            description = "Maximum allowed circling radius (m)"
          }
        }
      },
      [14] = {
        name = "CirclingAltitudeChanged",
        args = {
          {
            name = "current",
            type = "u16",
            unit = "m",
            description = "Current circling altitude (m)"
          },
          {
            name = "min",
            type = "u16",
            unit = "m",
            description = "Minimum allowed circling altitude (m)"
          },
          {
            name = "max",
            type = "u16",
            unit = "m",
            description = "Maximum allowed circling altitude (m)"
          }
        }
      },
      [15] = {
        name = "PitchModeChanged",
        args = {
          {
            name = "value",
            type = "enum",
            enum = { normal = "NORMAL", inverted = "INVERTED" },
            unit = "",
            description = "Pitch mode (NORMAL: positive lowers the nose, INVERTED: opposite)"
          }
        }
      },
      [16] = {
        name = "MotionDetection",
        args = {
          {
            name = "enabled",
            type = "u8",
            unit = "",
            description = "1 if motion detection is enabled, 0 otherwise"
          }
        }
      }
    },
    [11] = {  -- Klasa "SpeedSettings" (ardrone3)
      [0] = {
        name = "MaxVerticalSpeed",
        args = {
          {
            name = "current",
            type = "float",
            unit = "m/s",
            description = "Maximum vertical speed (m/s)"
          }
        }
      },
      [1] = {
        name = "MaxRotationSpeed",
        args = {
          {
            name = "current",
            type = "float",
            unit = "°/s",
            description = "Maximum yaw rotation speed (deg/s)"
          }
        }
      },
      [2] = {
        name = "HullProtection",
        args = {
          {
            name = "present",
            type = "u8",
            unit = "",
            description = "1 if hull protection is present, 0 if not"
          }
        }
      },
      [3] = {
        name = "Outdoor",
        deprecated = true,
        args = {
          {
            name = "outdoor",
            type = "u8",
            unit = "",
            description = "1 if outdoor mode, 0 if indoor"
          }
        }
      },
      [4] = {
        name = "MaxPitchRollRotationSpeed",
        args = {
          {
            name = "current",
            type = "float",
            unit = "°/s",
            description = "Maximum pitch/roll rotation speed (deg/s)"
          }
        }
      }
    },
    [12] = {  -- Klasa "SpeedSettingsState" (ardrone3)
      [0] = {
        name = "MaxVerticalSpeedChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "m/s",
            description = "Current max vertical speed (m/s)"
          },
          {
            name = "min",
            type = "float",
            unit = "m/s",
            description = "Minimum allowed vertical speed (m/s)"
          },
          {
            name = "max",
            type = "float",
            unit = "m/s",
            description = "Maximum allowed vertical speed (m/s)"
          }
        }
      },
      [1] = {
        name = "MaxRotationSpeedChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "°/s",
            description = "Current max yaw rotation speed (deg/s)"
          },
          {
            name = "min",
            type = "float",
            unit = "°/s",
            description = "Minimum allowed yaw speed (deg/s)"
          },
          {
            name = "max",
            type = "float",
            unit = "°/s",
            description = "Maximum allowed yaw speed (deg/s)"
          }
        }
      },
      [2] = {
        name = "HullProtectionChanged",
        args = {
          {
            name = "present",
            type = "u8",
            unit = "",
            description = "1 if hull protection is present, 0 otherwise"
          }
        }
      },
      [3] = {
        name = "OutdoorChanged",
        deprecated = true,
        args = {
          {
            name = "outdoor",
            type = "u8",
            unit = "",
            description = "1 if outdoor mode, 0 if indoor"
          }
        }
      },
      [4] = {
        name = "MaxPitchRollRotationSpeedChanged",
        args = {
          {
            name = "current",
            type = "float",
            unit = "°/s",
            description = "Current max pitch/roll rotation speed (deg/s)"
          },
          {
            name = "min",
            type = "float",
            unit = "°/s",
            description = "Minimum allowed value (deg/s)"
          },
          {
            name = "max",
            type = "float",
            unit = "°/s",
            description = "Maximum allowed value (deg/s)"
          }
        }
      }
    },
    [9] = {  -- Klasa "NetworkSettings" (ardrone3)
      [0] = {
        name = "WifiSelection",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { auto = "auto", manual = "manual" },
            unit = "",
            description = "Type of wifi selection (auto or manual)"
          },
          {
            name = "band",
            type = "enum",
            enum = { ["2_4ghz"] = "2_4ghz", ["5ghz"] = "5ghz", all = "all" },
            unit = "",
            description = "WiFi band (2.4GHz, 5GHz, or all)"
          },
          {
            name = "channel",
            type = "u8",
            unit = "",
            description = "WiFi channel (not used in auto mode)"
          }
        }
      },
      [1] = {
        name = "wifiSecurity",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { open = "open", wpa2 = "wpa2" },
            unit = "",
            description = "WiFi security type (open or wpa2)"
          },
          {
            name = "key",
            type = "string",
            unit = "",
            description = "Security key (empty if type is open)"
          },
          {
            name = "keyType",
            type = "enum",
            enum = { plain = "plain" },
            unit = "",
            description = "Key type (plain text)"
          }
        }
      }
    },
    [10] = {  -- Klasa "NetworkSettingsState" (ardrone3)
      [0] = {
        name = "WifiSelectionChanged",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { auto_all = "auto_all", auto_2_4ghz = "auto_2_4ghz", auto_5ghz = "auto_5ghz", manual = "manual" },
            unit = "",
            description = "WiFi selection type as currently active"
          },
          {
            name = "band",
            type = "enum",
            enum = { ["2_4ghz"] = "2_4ghz", ["5ghz"] = "5ghz", all = "all" },
            unit = "",
            description = "Current WiFi band state"
          },
          {
            name = "channel",
            type = "u8",
            unit = "",
            description = "Current WiFi channel"
          }
        }
      },
      [1] = {
        name = "wifiSecurityChanged",
        deprecated = true,
        args = {
          {
            name = "type",
            type = "enum",
            enum = { open = "open", wpa2 = "wpa2" },
            unit = "",
            description = "WiFi security type as changed"
          }
        }
      },
      [2] = {
        name = "wifiSecurity",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { open = "open", wpa2 = "wpa2" },
            unit = "",
            description = "WiFi security type"
          },
          {
            name = "key",
            type = "string",
            unit = "",
            description = "Security key (empty if open)"
          },
          {
            name = "keyType",
            type = "enum",
            enum = { plain = "plain" },
            unit = "",
            description = "Key type (plain)"
          }
        }
      }
    },
    [16] = {  -- Klasa "SettingsState" (ardrone3)
      [0] = {
        name = "ProductMotorVersionListChanged",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "motor_number",
            type = "u8",
            unit = "",
            description = "Motor number"
          },
          {
            name = "type",
            type = "string",
            unit = "",
            description = "Motor type"
          },
          {
            name = "software",
            type = "string",
            unit = "",
            description = "Motor software version"
          },
          {
            name = "hardware",
            type = "string",
            unit = "",
            description = "Motor hardware version"
          }
        }
      },
      [1] = {
        name = "ProductGPSVersionChanged",
        args = {
          {
            name = "software",
            type = "string",
            unit = "",
            description = "GPS software version"
          },
          {
            name = "hardware",
            type = "string",
            unit = "",
            description = "GPS hardware version"
          }
        }
      },
      [2] = {
        name = "MotorErrorStateChanged",
        args = {
          {
            name = "motorIds",
            type = "u8",
            unit = "",
            description = "Bitfield indicating affected motors"
          },
          {
            name = "motorError",
            type = "enum",
            enum = {
              noError = "noError",
              errorEEPRom = "errorEEPRom",
              errorMotorStalled = "errorMotorStalled",
              errorPropellerSecurity = "errorPropellerSecurity",
              errorCommLost = "errorCommLost",
              errorRCEmergencyStop = "errorRCEmergencyStop",
              errorRealTime = "errorRealTime",
              errorMotorSetting = "errorMotorSetting",
              errorTemperature = "errorTemperature",
              errorBatteryVoltage = "errorBatteryVoltage",
              errorLipoCells = "errorLipoCells",
              errorMOSFET = "errorMOSFET",
              errorBootloader = "errorBootloader",
              errorAssert = "errorAssert"
            },
            unit = "",
            description = "Motor error code"
          }
        }
      },
      [3] = {
        name = "MotorSoftwareVersionChanged",
        deprecated = true,
        args = {
          {
            name = "version",
            type = "string",
            unit = "",
            description = "Motor software version string"
          }
        }
      },
      [4] = {
        name = "MotorFlightsStatusChanged",
        args = {
          {
            name = "nbFlights",
            type = "u16",
            unit = "",
            description = "Total number of flights"
          },
          {
            name = "lastFlightDuration",
            type = "u16",
            unit = "s",
            description = "Duration of last flight in seconds"
          },
          {
            name = "totalFlightDuration",
            type = "u32",
            unit = "s",
            description = "Total flight duration in seconds"
          }
        }
      },
      [5] = {
        name = "MotorErrorLastErrorChanged",
        args = {
          {
            name = "motorError",
            type = "enum",
            enum = {
              noError = "noError",
              errorEEPRom = "errorEEPRom",
              errorMotorStalled = "errorMotorStalled",
              errorPropellerSecurity = "errorPropellerSecurity",
              errorCommLost = "errorCommLost",
              errorRCEmergencyStop = "errorRCEmergencyStop",
              errorRealTime = "errorRealTime",
              errorMotorSetting = "errorMotorSetting",
              errorBatteryVoltage = "errorBatteryVoltage",
              errorLipoCells = "errorLipoCells",
              errorMOSFET = "errorMOSFET",
              errorTemperature = "errorTemperature",
              errorBootloader = "errorBootloader",
              errorAssert = "errorAssert"
            },
            unit = "",
            description = "Last motor error code"
          }
        }
      },
      [6] = {
        name = "P7ID",
        deprecated = true,
        args = {
          {
            name = "serialID",
            type = "string",
            unit = "",
            description = "Product P7ID"
          }
        }
      },
      [7] = {
        name = "CPUID",
        args = {
          {
            name = "id",
            type = "string",
            unit = "",
            description = "Product main CPU id"
          }
        }
      }
    },
    [19] = {  -- Klasa "PictureSettings"
      [0] = {
        name = "PictureFormatSelection",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { raw = "raw", jpeg = "jpeg", snapshot = "snapshot", jpeg_fisheye = "jpeg_fisheye" },
            unit = "",
            description = "Picture format to set (raw, jpeg, snapshot, jpeg_fisheye)"
          }
        }
      },
      [1] = {
        name = "AutoWhiteBalanceSelection",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { auto = "auto", tungsten = "tungsten", daylight = "daylight", cloudy = "cloudy", cool_white = "cool_white" },
            unit = "",
            description = "Auto white balance mode (auto, tungsten, daylight, cloudy, cool_white)"
          }
        }
      },
      [2] = {
        name = "ExpositionSelection",
        args = {
          {
            name = "value",
            type = "float",
            unit = "",
            description = "Exposure value (bounds typically [-3;3])"
          }
        }
      },
      [3] = {
        name = "SaturationSelection",
        args = {
          {
            name = "value",
            type = "float",
            unit = "",
            description = "Saturation value (bounds typically [-100;100])"
          }
        }
      },
      [4] = {
        name = "TimelapseSelection",
        args = {
          {
            name = "enabled",
            type = "u8",
            unit = "",
            description = "1 if timelapse mode is enabled, 0 otherwise"
          },
          {
            name = "interval",
            type = "float",
            unit = "s",
            description = "Interval between pictures in seconds"
          }
        }
      },
      [5] = {
        name = "VideoAutorecordSelection",
        args = {
          {
            name = "enabled",
            type = "u8",
            unit = "",
            description = "1 if video autorecord is enabled, 0 otherwise"
          },
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Mass storage id for video autorecord"
          }
        }
      },
      [6] = {
        name = "VideoStabilizationMode",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { roll_pitch = "roll_pitch", pitch = "pitch", roll = "roll", none = "none" },
            unit = "",
            description = "Video stabilization mode"
          }
        }
      },
      [7] = {
        name = "VideoRecordingMode",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { quality = "quality", time = "time" },
            unit = "",
            description = "Video recording mode (quality or time)"
          }
        }
      },
      [8] = {
        name = "VideoFramerate",
        args = {
          {
            name = "framerate",
            type = "enum",
            enum = { ["24_FPS"] = "24_FPS", ["25_FPS"] = "25_FPS", ["30_FPS"] = "30_FPS" },
            unit = "",
            description = "Video framerate (24, 25, or 30 FPS)"
          }
        }
      },
      [9] = {
        name = "VideoResolutions",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { rec1080_stream480 = "rec1080_stream480", rec720_stream720 = "rec720_stream720" },
            unit = "",
            description = "Video resolutions: recording and streaming settings"
          }
        }
      }
    },
    [20] = {  -- Klasa "PictureSettingsState"
      [0] = {
        name = "PictureFormatChanged",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { raw = "raw", jpeg = "jpeg", snapshot = "snapshot", jpeg_fisheye = "jpeg_fisheye" },
            unit = "",
            description = "New picture format"
          }
        }
      },
      [1] = {
        name = "AutoWhiteBalanceChanged",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { auto = "auto", tungsten = "tungsten", daylight = "daylight", cloudy = "cloudy", cool_white = "cool_white" },
            unit = "",
            description = "New white balance mode"
          }
        }
      },
      [2] = {
        name = "ExpositionChanged",
        args = {
          {
            name = "value",
            type = "float",
            unit = "",
            description = "New exposure value"
          },
          {
            name = "min",
            type = "float",
            unit = "",
            description = "Minimum exposure value"
          },
          {
            name = "max",
            type = "float",
            unit = "",
            description = "Maximum exposure value"
          }
        }
      },
      [3] = {
        name = "SaturationChanged",
        args = {
          {
            name = "value",
            type = "float",
            unit = "",
            description = "New saturation value"
          },
          {
            name = "min",
            type = "float",
            unit = "",
            description = "Minimum saturation value"
          },
          {
            name = "max",
            type = "float",
            unit = "",
            description = "Maximum saturation value"
          }
        }
      },
      [4] = {
        name = "TimelapseChanged",
        args = {
          {
            name = "enabled",
            type = "u8",
            unit = "",
            description = "1 if timelapse is enabled, 0 otherwise"
          },
          {
            name = "interval",
            type = "float",
            unit = "s",
            description = "Current interval between photos in seconds"
          },
          {
            name = "minInterval",
            type = "float",
            unit = "s",
            description = "Minimum allowed interval (s)"
          },
          {
            name = "maxInterval",
            type = "float",
            unit = "s",
            description = "Maximum allowed interval (s)"
          }
        }
      },
      [5] = {
        name = "VideoAutorecordChanged",
        args = {
          {
            name = "enabled",
            type = "u8",
            unit = "",
            description = "1 if video autorecord is enabled, 0 otherwise"
          },
          {
            name = "mass_storage_id",
            type = "u8",
            unit = "",
            description = "Mass storage id used for video autorecord"
          }
        }
      },
      [6] = {
        name = "VideoStabilizationModeChanged",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { roll_pitch = "roll_pitch", pitch = "pitch", roll = "roll", none = "none" },
            unit = "",
            description = "New video stabilization mode"
          }
        }
      },
      [7] = {
        name = "VideoRecordingModeChanged",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { quality = "quality", time = "time" },
            unit = "",
            description = "New video recording mode"
          }
        }
      },
      [8] = {
        name = "VideoFramerateChanged",
        args = {
          {
            name = "framerate",
            type = "enum",
            enum = { ["24_FPS"] = "24_FPS", ["25_FPS"] = "25_FPS", ["30_FPS"] = "30_FPS" },
            unit = "",
            description = "New video framerate"
          }
        }
      },
      [9] = {
        name = "VideoResolutionsChanged",
        args = {
          {
            name = "type",
            type = "enum",
            enum = { rec1080_stream480 = "rec1080_stream480", rec720_stream720 = "rec720_stream720" },
            unit = "",
            description = "New video resolutions setting"
          }
        }
      }
    },
    [21] = {  -- Klasa "MediaStreaming" (ardrone3)
      [0] = {
        name = "VideoEnable",
        args = {
          {
            name = "enable",
            type = "u8",
            unit = "",
            description = "1 to enable video streaming, 0 to disable"
          }
        }
      },
      [1] = {
        name = "VideoStreamMode",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { low_latency = "low_latency", high_reliability = "high_reliability", high_reliability_low_framerate = "high_reliability_low_framerate" },
            unit = "",
            description = "Video stream mode (low_latency, high_reliability, or high_reliability_low_framerate)"
          }
        }
      }
    },
    [22] = {  -- Klasa "MediaStreamingState" (ardrone3)
      [0] = {
        name = "VideoEnableChanged",
        args = {
          {
            name = "enabled",
            type = "enum",
            enum = { enabled = "enabled", disabled = "disabled", error = "error" },
            unit = "",
            description = "Current video streaming status"
          }
        }
      },
      [1] = {
        name = "VideoStreamModeChanged",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { low_latency = "low_latency", high_reliability = "high_reliability", high_reliability_low_framerate = "high_reliability_low_framerate" },
            unit = "",
            description = "Current video stream mode"
          }
        }
      }
    },
    [23] = {  -- Klasa "GPSSettings" (ardrone3)
      [0] = {
        name = "SetHome",
        deprecated = true,
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Home latitude in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Home longitude in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Home altitude in meters"
          }
        }
      },
      [1] = {
        name = "ResetHome",
        deprecated = true,
        args = {}
      },
      [2] = {
        name = "SendControllerGPS",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Controller GPS latitude in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Controller GPS longitude in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Controller GPS altitude in meters"
          },
          {
            name = "horizontalAccuracy",
            type = "double",
            unit = "m",
            description = "Horizontal accuracy in meters (-1 if not available)"
          },
          {
            name = "verticalAccuracy",
            type = "double",
            unit = "m",
            description = "Vertical accuracy in meters (-1 if not available)"
          }
        }
      },
      [3] = {
        name = "HomeType",
        deprecated = true,
        args = {
          {
            name = "type",
            type = "enum",
            enum = { takeoff = "TAKEOFF", pilot = "PILOT", followee = "FOLLOWEE" },
            unit = "",
            description = "Preferred home type (TAKEOFF, PILOT, FOLLOWEE)"
          }
        }
      },
      [4] = {
        name = "ReturnHomeDelay",
        deprecated = true,
        args = {
          {
            name = "delay",
            type = "u16",
            unit = "s",
            description = "Return home delay in seconds"
          }
        }
      },
      [5] = {
        name = "ReturnHomeMinAltitude",
        deprecated = true,
        args = {
          {
            name = "value",
            type = "float",
            unit = "m",
            description = "Minimum altitude for return home (in meters)"
          }
        }
      }
    },
    [24] = {  -- Klasa "GPSSettingsState" (ardrone3)
      [0] = {
        name = "HomeChanged",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Home latitude in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Home longitude in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Home altitude in meters"
          }
        }
      },
      [1] = {
        name = "ResetHomeChanged",
        deprecated = true,
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Home latitude (reset) in decimal degrees"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Home longitude (reset) in decimal degrees"
          },
          {
            name = "altitude",
            type = "double",
            unit = "m",
            description = "Home altitude (reset) in meters"
          }
        }
      },
      [2] = {
        name = "GPSFixStateChanged",
        args = {
          {
            name = "fixed",
            type = "u8",
            unit = "",
            description = "1 if GPS fix is available, 0 otherwise"
          }
        }
      },
      [3] = {
        name = "GPSUpdateStateChanged",
        deprecated = true,
        args = {
          {
            name = "state",
            type = "enum",
            enum = { updated = "updated", in_progress = "inProgress", failed = "failed" },
            unit = "",
            description = "GPS update state"
          }
        }
      },
      [4] = {
        name = "HomeTypeChanged",
        deprecated = true,
        args = {
          {
            name = "type",
            type = "enum",
            enum = { takeoff = "TAKEOFF", pilot = "PILOT", followee = "FOLLOWEE" },
            unit = "",
            description = "New home type as chosen by drone"
          }
        }
      },
      [5] = {
        name = "ReturnHomeDelayChanged",
        deprecated = true,
        args = {
          {
            name = "delay",
            type = "u16",
            unit = "s",
            description = "New return home delay (seconds)"
          }
        }
      },
      [6] = {
        name = "GeofenceCenterChanged",
        args = {
          {
            name = "latitude",
            type = "double",
            unit = "°",
            description = "Geofence center latitude (decimal degrees)"
          },
          {
            name = "longitude",
            type = "double",
            unit = "°",
            description = "Geofence center longitude (decimal degrees)"
          }
        }
      },
      [7] = {
        name = "ReturnHomeMinAltitudeChanged",
        deprecated = true,
        args = {
          {
            name = "value",
            type = "float",
            unit = "m",
            description = "New minimum altitude for return home (m)"
          },
          {
            name = "min",
            type = "float",
            unit = "m",
            description = "Allowed lower bound (m)"
          },
          {
            name = "max",
            type = "float",
            unit = "m",
            description = "Allowed upper bound (m)"
          }
        }
      }
    },
    [25] = {  -- Klasa "CameraState" (ardrone3, deprecated)
      [0] = {
        name = "Orientation",
        deprecated = true,
        args = {
          {
            name = "tilt",
            type = "i8",
            unit = "°",
            description = "Camera tilt (in degrees)"
          },
          {
            name = "pan",
            type = "i8",
            unit = "°",
            description = "Camera pan (in degrees)"
          }
        }
      },
      [1] = {
        name = "defaultCameraOrientation",
        deprecated = true,
        args = {
          {
            name = "tilt",
            type = "i8",
            unit = "°",
            description = "Centered camera tilt (in degrees)"
          },
          {
            name = "pan",
            type = "i8",
            unit = "°",
            description = "Centered camera pan (in degrees)"
          }
        }
      },
      [2] = {
        name = "OrientationV2",
        deprecated = true,
        args = {
          {
            name = "tilt",
            type = "float",
            unit = "°",
            description = "Camera tilt (in degrees, float version)"
          },
          {
            name = "pan",
            type = "float",
            unit = "°",
            description = "Camera pan (in degrees, float version)"
          }
        }
      },
      [3] = {
        name = "defaultCameraOrientationV2",
        deprecated = true,
        args = {
          {
            name = "tilt",
            type = "float",
            unit = "°",
            description = "Centered camera tilt (in degrees, float version)"
          },
          {
            name = "pan",
            type = "float",
            unit = "°",
            description = "Centered camera pan (in degrees, float version)"
          }
        }
      },
      [4] = {
        name = "VelocityRange",
        deprecated = true,
        args = {
          {
            name = "max_tilt",
            type = "float",
            unit = "°/s",
            description = "Maximum tilt velocity (deg/s)"
          },
          {
            name = "max_pan",
            type = "float",
            unit = "°/s",
            description = "Maximum pan velocity (deg/s)"
          }
        }
      }
    },
    [29] = {  -- Klasa "Antiflickering" (ardrone3)
      [0] = {
        name = "electricFrequency",
        args = {
          {
            name = "frequency",
            type = "enum",
            enum = { fiftyHertz = "fiftyHertz", sixtyHertz = "sixtyHertz" },
            unit = "",
            description = "Set the electric frequency for anti-flickering (50Hz or 60Hz)"
          }
        }
      },
      [1] = {
        name = "setMode",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { auto = "auto", FixedFiftyHertz = "FixedFiftyHertz", FixedSixtyHertz = "FixedSixtyHertz" },
            unit = "",
            description = "Anti-flickering mode (auto, FixedFiftyHertz, FixedSixtyHertz)"
          }
        }
      }
    },
    [30] = {  -- Klasa "AntiflickeringState" (ardrone3)
      [0] = {
        name = "electricFrequencyChanged",
        args = {
          {
            name = "frequency",
            type = "enum",
            enum = { fiftyHertz = "fiftyHertz", sixtyHertz = "sixtyHertz" },
            unit = "",
            description = "Current electric frequency setting (for antiflickering)"
          }
        }
      },
      [1] = {
        name = "modeChanged",
        args = {
          {
            name = "mode",
            type = "enum",
            enum = { auto = "auto", FixedFiftyHertz = "FixedFiftyHertz", FixedSixtyHertz = "FixedSixtyHertz" },
            unit = "",
            description = "Current antiflickering mode"
          }
        }
      }
    },
    [31] = {  -- Klasa "GPSState" (ardrone3)
      [0] = {
        name = "NumberOfSatelliteChanged",
        args = {
          {
            name = "numberOfSatellite",
            type = "u8",
            unit = "",
            description = "Number of GPS satellites detected"
          }
        }
      },
      [1] = {
        name = "HomeTypeAvailabilityChanged",
        type = "MAP_ITEM",
        deprecated = true,
        args = {
          {
            name = "type",
            type = "enum",
            enum = { takeoff = "TAKEOFF", pilot = "PILOT", first_fix = "FIRST_FIX", followee = "FOLLOWEE" },
            unit = "",
            description = "Available home type"
          },
          {
            name = "available",
            type = "u8",
            unit = "",
            description = "1 if available, 0 otherwise"
          }
        }
      },
      [2] = {
        name = "HomeTypeChosenChanged",
        deprecated = true,
        args = {
          {
            name = "type",
            type = "enum",
            enum = { takeoff = "TAKEOFF", pilot = "PILOT", first_fix = "FIRST_FIX", followee = "FOLLOWEE" },
            unit = "",
            description = "Chosen home type by the drone"
          }
        }
      }
    },
    [32] = {  -- Klasa "PROState" (ardrone3)
      [0] = {
        name = "Features",
        deprecated = true,
        args = {
          {
            name = "features",
            type = "u64",
            unit = "",
            description = "Bitfield representing enabled PRO features"
          }
        }
      }
    },
    [33] = {  -- Klasa "AccessoryState" (ardrone3)
      [0] = {
        name = "ConnectedAccessories",
        type = "MAP_ITEM",
        args = {
          {
            name = "id",
            type = "u8",
            unit = "",
            description = "Accessory id for the session"
          },
          {
            name = "accessory_type",
            type = "enum",
            enum = { sequoia = "sequoia", flir = "flir" },
            unit = "",
            description = "Type of accessory (sequoia, flir)"
          },
          {
            name = "uid",
            type = "string",
            unit = "",
            description = "Unique identifier of the accessory"
          },
          {
            name = "swVersion",
            type = "string",
            unit = "",
            description = "Accessory software version"
          },
          {
            name = "list_flags",
            type = "u8",
            unit = "",
            description = "List flags (bitfield: First, Last, Empty, Remove)"
          }
        }
      },
      [1] = {
        name = "Battery",
        type = "MAP_ITEM",
        args = {
          {
            name = "id",
            type = "u8",
            unit = "",
            description = "Accessory id for the session"
          },
          {
            name = "batteryLevel",
            type = "u8",
            unit = "%",
            description = "Accessory battery level in percentage"
          },
          {
            name = "list_flags",
            type = "u8",
            unit = "",
            description = "List flags (bitfield: First, Last, Empty, Remove)"
          }
        }
      }
    },
    [35] = {  -- Klasa "Sound" (ardrone3)
      [0] = {
        name = "StartAlertSound",
        args = {}
      },
      [1] = {
        name = "StopAlertSound",
        args = {}
      }
    },
    [36] = {  -- Klasa "SoundState" (ardrone3)
      [0] = {
        name = "AlertSound",
        args = {
          {
            name = "state",
            type = "enum",
            enum = { stopped = "stopped", playing = "playing" },
            unit = "",
            description = "Alert sound state (stopped or playing)"
          }
        }
      }
    }
}

-- Tablica główna komend
-- Numery projektów -> [0] – projekt "common", [1] – projekt "ardrone3"
local projects_map = {
  [0] = common_commands,
  [1] = ardrone3_commands
}

local function get_command_def(project_id, class_id, cmd_id)
  local proj = projects_map[project_id]
  if not proj then
    return nil
  end

  local class = proj[class_id]
  if not class then
    return nil
  end

  return class[cmd_id]
end

-- Funkcja pomocnicza -> odczytuje dane z bufora według typu
local function read_field(buffer, offset, type_str)
  if type_str == "u8" then 
    return buffer(offset,1):uint(), 1 
  elseif type_str == "i8" then 
    return buffer(offset,1):int(), 1 
  elseif type_str == "u16" then 
    return buffer(offset,2):le_uint(), 2 
  elseif type_str == "u32" then 
    return buffer(offset,4):le_uint(), 4 
  elseif type_str == "u64" then 
    return buffer(offset,8):le_uint64(), 8 
  elseif type_str == "float" then 
    return buffer(offset,4):le_float(), 4 
  elseif type_str == "double" then 
    return buffer(offset,8):le_float(), 8 
  elseif type_str == "string" then 
    return buffer(offset):string(), buffer:len() - offset 
  elseif type_str == "enum" then 
    return buffer(offset,1):uint(), 1 
  else 
    return nil, 0 
  end
end

-- Główna funkcja dissektora
function parrot_proto.dissector(buffer, pinfo, tree)
  pinfo.cols.protocol = "PARROT"

  if buffer:len() < 7 then 
    return 
  end

  -- Dodanie głównego poddrzewa z danymi BSP Parrot
  local subtree = tree:add(parrot_proto, buffer(), "Parrot Drone Data")

  -- Odczyt nagłówków ramek
  local frame_type   = buffer(0,1):uint()
  local buffer_id    = buffer(1,1):uint()
  local seq_number   = buffer(2,1):uint()
  local frame_length = buffer(3,4):le_uint()

  -- Informacje o nagłówku ramki do poddrzewa:
  subtree:add(f_frame_type, buffer(0,1))
    :append_text(" (0x"..string.format("%02X", frame_type)..")")
  subtree:add(f_buffer_id, buffer(1,1))
    :append_text(" ("..buffer_id..")")
  subtree:add(f_seq_number, buffer(2,1))
    :append_text(" ("..seq_number..")")
  subtree:add(f_frame_length, buffer(3,2))
    :append_text(" ("..frame_length..")")

  -- Sprawdzenie, czy bufor zawiera wystarczającą ilość bajtów zgodnie z wartością frame_length z nagłówka
  if buffer:len() < frame_length then 
    return 
  end
  
  -- Odczyt identyfikatorów komendy (project_id, class_id i cmd_id)
  local offset = 7
  if buffer:len() < offset + 3 then
    subtree:add_expert_info(PI_MALFORMED, PI_ERROR, "Za mało bajtów dla identyfikatorów (project, class, cmd)")
    return
  end

  local project_id = buffer(offset,1):uint()    -- Bajt 7
  local class_id   = buffer(offset+1,1):uint()    -- Bajt 8
  local cmd_id     = buffer(offset+2,1):uint()    -- Bajt 9
  offset = offset + 4
  
  local cmd_def = get_command_def(project_id, class_id, cmd_id)
  if cmd_def then
    subtree:add(buffer(7,3),
      string.format("%s (PID=%d, CID=%d, CMD=%d)",
        cmd_def.name, project_id, class_id, cmd_id))
  else
    subtree:add(buffer(7,3),
      string.format("Nieznana komenda (PID=%d, CID=%d, CMD=%d)",
        project_id, class_id, cmd_id))
    return  -- Jeśli komenda nieznana – nie próbujemy dekodować argumentów
  end

  -- Odczyt argumentów komendy, jeśli są zdefiniowane
  if cmd_def.args then
    for _, arg in ipairs(cmd_def.args) do
      local value, bytes_consumed = read_field(buffer, offset, arg.type)
      local arg_range = buffer(offset, bytes_consumed)
      offset = offset + bytes_consumed
      local text = arg.name .. ": " .. tostring(value)
      if arg.type == "enum" and arg.enum then
        for k, v in pairs(arg.enum) do
          if tostring(value) == v then
            text = text .. " (" .. k .. ")"
            break
          end
        end
      end
      local arg_item = subtree:add(arg_range, text)
      if arg.unit and arg.unit ~= "" then
        arg_item:add(f_arg_unit, buffer(0,0), arg.unit)
      end
      if arg.description and arg.description ~= "" then
        arg_item:add(f_arg_description, buffer(0,0), arg.description)
      end
    end
  end
end

-- Rejestracja dissektora na portach UDP
local udp_table = DissectorTable.get("udp.port")
udp_table:add(44444, parrot_proto)
udp_table:add(54321, parrot_proto)
udp_table:add(43210, parrot_proto)