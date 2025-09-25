local ardrone_proto = Proto("ardrone_navdata", "AR.Drone 2.0 Telemetry Dissector")

-- Definicje pól protokołu (ProtoFields)
local f_header      = ProtoField.uint32("ardrone_navdata.header", "Header (Magic)", base.HEX)
local f_state       = ProtoField.uint32("ardrone_navdata.state", "AR.Drone State (bitmask)", base.HEX)
local f_seq         = ProtoField.uint32("ardrone_navdata.sequence", "Sequence Number", base.DEC)
local f_vision_flag = ProtoField.uint32("ardrone_navdata.vision_flag", "Vision Flag", base.DEC)
local f_opt_tag     = ProtoField.uint16("ardrone_navdata.option.tag", "Option Tag", base.DEC)
local f_opt_size    = ProtoField.uint16("ardrone_navdata.option.size", "Option Size", base.DEC)

ardrone_proto.fields = { 
    f_header, f_state, f_seq, f_vision_flag, 
    f_opt_tag, f_opt_size 
}

function ardrone_proto.dissector(buffer, pinfo, tree)
    if buffer:len() < 8 then return end  -- zbyt mały pakiet, pomiń
    pinfo.cols.protocol = "ARDRONE_NAV"

    local subtree = tree:add(ardrone_proto, buffer(), "Parrot AR.Drone 2.0 Navdata Telemetry")
    -- Nagłówek navdata (16 bajtów)
    subtree:add_le(f_header, buffer(0,4))                             -- Magic header 0x55667788
    local state_val = buffer(4,4):le_uint()
    local state_item = subtree:add_le(f_state, buffer(4,4))           -- Stan drona (flagi bitowe)
    subtree:add_le(f_seq, buffer(8,4))                                -- Numer sekwencyjny pakietu
    subtree:add_le(f_vision_flag, buffer(12,4))                       -- Flaga vision_defined

    local offset = 16
    while offset < buffer:len() do
        if offset + 4 > buffer:len() then break end  -- zabezpieczenie
        local tag  = buffer(offset,2):le_uint()
        local size = buffer(offset+2,2):le_uint()
        if size < 4 or offset + size > buffer:len() then 
            break  -- nieprawidłowy rozmiar, przerwij
        end

        local opt_start = offset
        local opt_len   = size
        local opt_data_len = size - 4
        offset = offset + 4 

        -- Nazwa opcji
        local opt_name = "Unknown"
        if     tag == 0      then opt_name = "navdata_demo"
        elseif tag == 1      then opt_name = "navdata_time"
        elseif tag == 2      then opt_name = "navdata_raw_measures"
        elseif tag == 3      then opt_name = "navdata_phys_measures"
        elseif tag == 4      then opt_name = "navdata_gyros_offsets"
        elseif tag == 5      then opt_name = "navdata_euler_angles"
        elseif tag == 6      then opt_name = "navdata_references"
        elseif tag == 7      then opt_name = "navdata_trims"
        elseif tag == 8      then opt_name = "navdata_rc_references"
        elseif tag == 9      then opt_name = "navdata_pwm"
        elseif tag == 10     then opt_name = "navdata_altitude"
        elseif tag == 11     then opt_name = "navdata_vision_raw"
        elseif tag == 12     then opt_name = "navdata_vision_of"
        elseif tag == 13     then opt_name = "navdata_vision"
        elseif tag == 14     then opt_name = "navdata_vision_perf"
        elseif tag == 15     then opt_name = "navdata_trackers_send"
        elseif tag == 16     then opt_name = "navdata_vision_detect"
        elseif tag == 17     then opt_name = "navdata_watchdog"
        elseif tag == 18     then opt_name = "navdata_adc_data_frame"
        elseif tag == 19     then opt_name = "navdata_video_stream"
        elseif tag == 20     then opt_name = "navdata_games"
        elseif tag == 21     then opt_name = "navdata_pressure_raw"
        elseif tag == 22     then opt_name = "navdata_magneto"
        elseif tag == 23     then opt_name = "navdata_wind_speed"
        elseif tag == 24     then opt_name = "navdata_kalman_pressure"
        elseif tag == 25     then opt_name = "navdata_hdvideo_stream"
        elseif tag == 26     then opt_name = "navdata_wifi"
        elseif tag == 27     then opt_name = "navdata_zimmu_3000"
        elseif tag == 0xFFFF then opt_name = "navdata_cks"
        end

        local opt_tree = subtree:add(buffer(opt_start, opt_len), opt_name.." (Tag "..tag..", Length "..opt_len.." bytes)")
        opt_tree:add_le(f_opt_tag,  buffer(opt_start,2))
        opt_tree:add_le(f_opt_size, buffer(opt_start+2,2))

        if tag == 0xFFFF then
            -- Suma kontrolna (ostatnia opcja)
            opt_tree:add_le(buffer(offset,4), "Checksum: 0x" .. string.format("%08X", buffer(offset,4):le_uint()))
            offset = offset + opt_data_len
            break  -- wyjście z pętli, to ostatnia opcja
        end

        -- Parsowanie zawartości opcji w zależności od tagu:
        if tag == 0 then
            -- navdata_demo
            opt_tree:add_le(buffer(offset,4),  "Control State: 0x" .. string.format("%08X", buffer(offset,4):le_uint()))
            opt_tree:add_le(buffer(offset+4,4),"Battery Level: " .. buffer(offset+4,4):le_uint() .. " %")
            opt_tree:add_le(buffer(offset+8,4),"Theta (pitch): " .. string.format("%.2f deg", buffer(offset+8,4):le_float()/1000))
            opt_tree:add_le(buffer(offset+12,4),"Phi (roll): " .. string.format("%.2f deg", buffer(offset+12,4):le_float()/1000))
            opt_tree:add_le(buffer(offset+16,4),"Psi (yaw): " .. string.format("%.2f deg", buffer(offset+16,4):le_float()/1000))
            opt_tree:add_le(buffer(offset+20,4),"Altitude: " .. buffer(offset+20,4):le_int() .. " cm")
            opt_tree:add_le(buffer(offset+24,4),"Vx: " .. string.format("%.2f mm/s", buffer(offset+24,4):le_float()))
            opt_tree:add_le(buffer(offset+28,4),"Vy: " .. string.format("%.2f mm/s", buffer(offset+28,4):le_float()))
            opt_tree:add_le(buffer(offset+32,4),"Vz: " .. string.format("%.2f mm/s", buffer(offset+32,4):le_float()))
            opt_tree:add_le(buffer(offset+36,4),"Frame Index: " .. buffer(offset+36,4):le_uint())
            -- Pola dot. kamery (deprecated)
            opt_tree:add(buffer(offset+40, 36+12+4+4+36+12), "[DEPRECATED camera params omitted]")
            local cam_type = buffer(offset+92,4):le_uint()
            opt_tree:append_text(string.format(" – Camera detect type: %d", cam_type))
            offset = offset + opt_data_len

        elseif tag == 1 then
            -- navdata_time
            local timeVal = buffer(offset,4):le_uint()
            opt_tree:add_le(buffer(offset,4), string.format("Time: 0x%08X (%.3f s)", timeVal, (bit.rshift(timeVal,21) + (timeVal & 0x1FFFFF) / 1000000.0)))
            offset = offset + opt_data_len

        elseif tag == 2 then
            -- navdata_raw_measures
            opt_tree:add_le(buffer(offset,2*3), "Raw accelerometers: " ..
                string.format("ax=%d, ay=%d, az=%d", 
                    buffer(offset,2):le_int(), buffer(offset+2,2):le_int(), buffer(offset+4,2):le_int()))
            opt_tree:add_le(buffer(offset+6,2*3), "Raw gyros: " ..
                string.format("gx=%d, gy=%d, gz=%d", 
                    buffer(offset+6,2):le_int(), buffer(offset+8,2):le_int(), buffer(offset+10,2):le_int()))
            opt_tree:add_le(buffer(offset+12,2*2), "Raw gyros 110deg: " ..
                string.format("g110_x=%d, g110_y=%d", 
                    buffer(offset+12,2):le_int(), buffer(offset+14,2):le_int()))
            opt_tree:add_le(buffer(offset+16,4), "Battery raw: " .. buffer(offset+16,4):le_uint() .. " mV")
            opt_tree:add(buffer(offset+20, opt_data_len-20), "Ultrasound raw data (omitted details)")
            offset = offset + opt_data_len

        elseif tag == 3 then
            -- navdata_phys_measures
            opt_tree:add_le(buffer(offset,4), "Accs Temp: " .. string.format("%.2f C", buffer(offset,4):le_float()))
            opt_tree:add_le(buffer(offset+4,2), "Gyro Temp RAW: " .. buffer(offset+4,2):le_uint())
            opt_tree:add_le(buffer(offset+6,4*3), "Physical accs: [%.3f, %.3f, %.3f] g" ..
                string.format("", buffer(offset+6,4):le_float(), buffer(offset+10,4):le_float(), buffer(offset+14,4):le_float()))
            opt_tree:add_le(buffer(offset+18,4*3),"Physical gyros: [%.2f, %.2f, %.2f] deg/s" ..
                string.format("", buffer(offset+18,4):le_float(), buffer(offset+22,4):le_float(), buffer(offset+26,4):le_float()))
            opt_tree:add_le(buffer(offset+30,4), "Alim3V3: " .. buffer(offset+30,4):le_uint() .. " LSB")
            opt_tree:add_le(buffer(offset+34,4), "Vref Epson: " .. buffer(offset+34,4):le_uint() .. " LSB")
            opt_tree:add_le(buffer(offset+38,4), "Vref IDG: " .. buffer(offset+38,4):le_uint() .. " LSB")
            offset = offset + opt_data_len

        elseif tag == 4 then
            -- navdata_gyros_offsets
            opt_tree:add_le(buffer(offset,4*3), "Gyros Offsets: [%.4f, %.4f, %.4f]" ..
                string.format("", buffer(offset,4):le_float(), buffer(offset+4,4):le_float(), buffer(offset+8,4):le_float()))
            offset = offset + opt_data_len

        elseif tag == 5 then
            -- navdata_euler_angles
            opt_tree:add_le(buffer(offset,4), "Theta_a: " .. string.format("%.4f", buffer(offset,4):le_float()))
            opt_tree:add_le(buffer(offset+4,4), "Phi_a: " .. string.format("%.4f", buffer(offset+4,4):le_float()))
            offset = offset + opt_data_len

        elseif tag == 6 then
            -- navdata_references (wybrane najważniejsze pola ze wszystjich)
            opt_tree:add_le(buffer(offset,4),  "ref_theta: " .. buffer(offset,4):le_int())
            opt_tree:add_le(buffer(offset+4,4),"ref_phi: " .. buffer(offset+4,4):le_int())
            opt_tree:add_le(buffer(offset+24,4),"ref_yaw: " .. buffer(offset+24,4):le_int())
            opt_tree:add_le(buffer(offset+28,4),"ref_psi: " .. buffer(offset+28,4):le_int())
            opt_tree:add_le(buffer(offset+44,4),"vx_ref: " .. string.format("%.2f", buffer(offset+44,4):le_float()))
            opt_tree:add_le(buffer(offset+48,4),"vy_ref: " .. string.format("%.2f", buffer(offset+48,4):le_float()))
            opt_tree:add(buffer(offset+52, opt_data_len-52), "(Other reference fields omitted)")
            offset = offset + opt_data_len

        elseif tag == 7 then
            -- navdata_trims
            opt_tree:add_le(buffer(offset,4), "Angular rate trim (r): " .. string.format("%.6f", buffer(offset,4):le_float()))
            opt_tree:add_le(buffer(offset+4,4), "Euler trim theta: " .. string.format("%.6f", buffer(offset+4,4):le_float()))
            opt_tree:add_le(buffer(offset+8,4), "Euler trim phi: " .. string.format("%.6f", buffer(offset+8,4):le_float()))
            offset = offset + opt_data_len

        elseif tag == 8 then
            -- navdata_rc_references
            opt_tree:add_le(buffer(offset,4),  "RC pitch: " .. buffer(offset,4):le_int())
            opt_tree:add_le(buffer(offset+4,4),"RC roll: " .. buffer(offset+4,4):le_int())
            opt_tree:add_le(buffer(offset+8,4),"RC yaw: " .. buffer(offset+8,4):le_int())
            opt_tree:add_le(buffer(offset+12,4),"RC gaz: " .. buffer(offset+12,4):le_int())
            opt_tree:add_le(buffer(offset+16,4),"RC ag: " .. buffer(offset+16,4):le_int())
            offset = offset + opt_data_len

        elseif tag == 9 then
            -- navdata_pwm
            opt_tree:add_le(buffer(offset,4), "Motor PWM: m1="..buffer(offset,1):le_uint()..", m2="..buffer(offset+1,1):le_uint()..", m3="..buffer(offset+2,1):le_uint()..", m4="..buffer(offset+3,1):le_uint())
            opt_tree:add_le(buffer(offset+4,4), "Motor PWM saturation: sat1="..buffer(offset+4,1):uint()..", sat2="..buffer(offset+5,1):uint()..", sat3="..buffer(offset+6,1):uint()..", sat4="..buffer(offset+7,1):uint())
            opt_tree:add_le(buffer(offset+8,4),  "Gaz feed forward: " .. string.format("%.3f", buffer(offset+8,4):le_float()))
            opt_tree:add_le(buffer(offset+12,4), "Gaz altitude: " .. string.format("%.3f", buffer(offset+12,4):le_float()))
            opt_tree:add_le(buffer(offset+16,4), "Altitude integral: " .. string.format("%.3f", buffer(offset+16,4):le_float()))
            opt_tree:add_le(buffer(offset+20,4), "Vz ref: " .. string.format("%.3f", buffer(offset+20,4):le_float()))
            opt_tree:add_le(buffer(offset+24,4), "u_pitch: " .. buffer(offset+24,4):le_int())
            opt_tree:add_le(buffer(offset+28,4), "u_roll: " .. buffer(offset+28,4):le_int())
            opt_tree:add_le(buffer(offset+32,4), "u_yaw: " .. buffer(offset+32,4):le_int())
            opt_tree:add_le(buffer(offset+36,4), "yaw_u_I: " .. string.format("%.3f", buffer(offset+36,4):le_float()))
            opt_tree:add(buffer(offset+40, opt_data_len-40), "(Additional PWM fields omitted)")
            offset = offset + opt_data_len

        elseif tag == 10 then
            -- navdata_altitude
            opt_tree:add_le(buffer(offset,4),  "Vision altitude: " .. buffer(offset,4):le_int() .. " mm")
            opt_tree:add_le(buffer(offset+4,4), "Velocity Z: " .. string.format("%.3f", buffer(offset+4,4):le_float()) .. " m/s")
            opt_tree:add_le(buffer(offset+8,4), "Reference altitude: " .. buffer(offset+8,4):le_int() .. " mm")
            opt_tree:add_le(buffer(offset+12,4),"Raw altitude: " .. buffer(offset+12,4):le_int() .. " mm")
            opt_tree:add_le(buffer(offset+16,4),"Obs accZ: " .. string.format("%.3f", buffer(offset+16,4):le_float()))
            opt_tree:add_le(buffer(offset+20,4),"Obs altitude: " .. string.format("%.3f", buffer(offset+20,4):le_float()))
            opt_tree:add(buffer(offset+24, opt_data_len-24), "(Estimator state data omitted)")
            offset = offset + opt_data_len

        elseif tag == 11 then
            -- navdata_vision_raw
            opt_tree:add_le(buffer(offset,4*3), "Vision raw transl.: ["..
                string.format("%.3f, %.3f, %.3f", buffer(offset,4):le_float(), buffer(offset+4,4):le_float(), buffer(offset+8,4):le_float()).."]")
            offset = offset + opt_data_len

        elseif tag == 12 then
            -- navdata_vision_of
            opt_tree:add_le(buffer(offset,4*5), "Optical flow dx: ["..
                string.format("%.3f, %.3f, %.3f, %.3f, %.3f", 
                    buffer(offset,4):le_float(), buffer(offset+4,4):le_float(), buffer(offset+8,4):le_float(), buffer(offset+12,4):le_float(), buffer(offset+16,4):le_float()).."]")
            opt_tree:add_le(buffer(offset+20,4*5),"Optical flow dy: ["..
                string.format("%.3f, %.3f, %.3f, %.3f, %.3f", 
                    buffer(offset+20,4):le_float(), buffer(offset+24,4):le_float(), buffer(offset+28,4):le_float(), buffer(offset+32,4):le_float(), buffer(offset+36,4):le_float()).."]")
            offset = offset + opt_data_len

        elseif tag == 13 then
            -- navdata_vision
            opt_tree:add_le(buffer(offset,4), "Vision state: 0x" .. string.format("%08X", buffer(offset,4):le_uint()))
            opt_tree:add_le(buffer(offset+8,4), "Vision phi trim: " .. string.format("%.4f", buffer(offset+8,4):le_float()))
            opt_tree:add_le(buffer(offset+16,4),"Vision theta trim: " .. string.format("%.4f", buffer(offset+16,4):le_float()))
            opt_tree:add_le(buffer(offset+24,4),"New raw picture: " .. buffer(offset+24,4):le_int())
            opt_tree:add_le(buffer(offset+28,4),"Theta capture: " .. string.format("%.2f deg", buffer(offset+28,4):le_float()))
            opt_tree:add_le(buffer(offset+32,4),"Phi capture: " .. string.format("%.2f deg", buffer(offset+32,4):le_float()))
            opt_tree:add_le(buffer(offset+36,4),"Psi capture: " .. string.format("%.2f deg", buffer(offset+36,4):le_float()))
            opt_tree:add_le(buffer(offset+40,4),"Altitude capture: " .. buffer(offset+40,4):le_int() .. " mm")
            opt_tree:add_le(buffer(offset+44,4),"Time capture: 0x" .. string.format("%08X", buffer(offset+44,4):le_uint()))
            opt_tree:add(buffer(offset+48, opt_data_len-48), "(Vision additional data omitted)")
            offset = offset + opt_data_len

        elseif tag == 14 then
            -- navdata_vision_perf
            opt_tree:add_le(buffer(offset,4*6), "Vision times (s): SZO="..
                string.format("%.4f", buffer(offset,4):le_float())..", corners="..
                string.format("%.4f", buffer(offset+4,4):le_float())..", compute="..
                string.format("%.4f", buffer(offset+8,4):le_float())..", tracking="..
                string.format("%.4f", buffer(offset+12,4):le_float())..", trans="..
                string.format("%.4f", buffer(offset+16,4):le_float())..", update="..
                string.format("%.4f", buffer(offset+20,4):le_float()))
            opt_tree:add(buffer(offset+24, opt_data_len-24), "(Custom times omitted)")
            offset = offset + opt_data_len

        elseif tag == 15 then
            -- navdata_trackers_send
            local nb_trackers = 0
            local total_trackers = 0
            local grid_count = 16  -- DEFAULT_NB_TRACKERS_WIDTH * DEFAULT_NB_TRACKERS_HEIGHT (np. 16*1? lub 8*8=64)
            if opt_data_len >= 4 then
                total_trackers = (opt_data_len / 2) / 4  -- ilość int32 w locked
                for i=0, total_trackers-1 do
                    if buffer(offset + i*4,4):le_int() ~= 0 then nb_trackers = nb_trackers + 1 end
                end
            end
            opt_tree:add(buffer(offset, opt_data_len), "Trackers: "..nb_trackers.." locked out of ~"..total_trackers.." (details omitted)")
            offset = offset + opt_data_len

        elseif tag == 16 then
            -- navdata_vision_detect
            local nb = buffer(offset,4):le_uint()
            opt_tree:add_le(buffer(offset,4), "Detected tags count: " .. nb)
            local arr_offset = offset + 4
            for i=0, nb-1 do
                local it_tree = opt_tree:add(buffer(arr_offset, 5*4), "Detection ["..(i+1).."]")
                it_tree:add_le(buffer(arr_offset,4),   "Type: " .. buffer(arr_offset,4):le_uint())
                it_tree:add_le(buffer(arr_offset+4,4), "XC: " .. buffer(arr_offset+4,4):le_uint())
                it_tree:add_le(buffer(arr_offset+8,4), "YC: " .. buffer(arr_offset+8,4):le_uint())
                it_tree:add_le(buffer(arr_offset+12,4),"Width: " .. buffer(arr_offset+12,4):le_uint())
                it_tree:add_le(buffer(arr_offset+16,4),"Height: " .. buffer(arr_offset+16,4):le_uint())
                it_tree:add_le(buffer(arr_offset+20,4),"Distance: " .. buffer(arr_offset+20,4):le_uint())
                it_tree:add_le(buffer(arr_offset+24,4),"Angle: " .. string.format("%.2f deg", buffer(arr_offset+24,4):le_float()))
                arr_offset = arr_offset + 4* (5 + 2 + 9 + 3 + 1)  -- przesuwamy o cały zestaw danych (5 pierwszych + dist+angle + rot(9)+trans(3)+camera_source(1) = 20*4 bytes)
            end
            offset = offset + opt_data_len

        elseif tag == 17 then
            -- navdata_watchdog
            opt_tree:add_le(buffer(offset,4), "Watchdog: " .. buffer(offset,4):le_int())
            offset = offset + opt_data_len

        elseif tag == 18 then
            -- navdata_adc_data_frame
            local version = buffer(offset,4):le_uint()
            opt_tree:add_le(buffer(offset,4), "ADC frame version: " .. version)
            if opt_data_len > 4 then
                opt_tree:add(buffer(offset+4, 32), "ADC data frame: " .. tostring(buffer(offset+4,32):bytes():tohex()))
            end
            offset = offset + opt_data_len

        elseif tag == 19 then
            -- navdata_video_stream
            opt_tree:add_le(buffer(offset,1), "Video quantizer: " .. buffer(offset,1):le_uint())
            opt_tree:add_le(buffer(offset+1,3), "Frame size: " .. buffer(offset+1,3):le_uint() .. " bytes")
            opt_tree:add_le(buffer(offset+4,4), "Frame number: " .. buffer(offset+4,4):le_uint())
            opt_tree:add_le(buffer(offset+8,4), "ATCMD ref seq: " .. buffer(offset+8,4):le_uint())
            opt_tree:add_le(buffer(offset+12,4),"ATCMD mean gap: " .. buffer(offset+12,4):le_uint() .. " ms")
            opt_tree:add_le(buffer(offset+16,4),"ATCMD var gap: " .. string.format("%.3f", buffer(offset+16,4):le_float()))
            opt_tree:add_le(buffer(offset+20,4),"ATCMD quality: " .. buffer(offset+20,4):le_uint())
            if opt_data_len > 24 then
                opt_tree:add_le(buffer(offset+24,4),"Out bitrate: " .. buffer(offset+24,4):le_uint() .. " bit/s")
                opt_tree:add_le(buffer(offset+28,4),"Desired bitrate: " .. buffer(offset+28,4):le_uint() .. " bit/s")
            end
            if opt_data_len > 40 then
                opt_tree:add_le(buffer(offset+40,4),"TCP queue level: " .. buffer(offset+40,4):le_uint())
                opt_tree:add_le(buffer(offset+44,4),"FIFO queue level: " .. buffer(offset+44,4):le_uint())
            end
            offset = offset + opt_data_len

        elseif tag == 20 then
            -- navdata_games
            opt_tree:add_le(buffer(offset,4), "Double tap count: " .. buffer(offset,4):le_uint())
            opt_tree:add_le(buffer(offset+4,4),"Finish line count: " .. buffer(offset+4,4):le_uint())
            offset = offset + opt_data_len

        elseif tag == 21 then
            -- navdata_pressure_raw
            opt_tree:add_le(buffer(offset,4), "UP (pressure raw): " .. buffer(offset,4):le_int())
            opt_tree:add_le(buffer(offset+4,2),"UT (temp raw): " .. buffer(offset+4,2):le_int())
            opt_tree:add_le(buffer(offset+6,4), "Temperature_meas: " .. buffer(offset+6,4):le_int())
            opt_tree:add_le(buffer(offset+10,4),"Pressure_meas: " .. buffer(offset+10,4):le_int())
            offset = offset + opt_data_len

        elseif tag == 22 then
            -- navdata_magneto
            local mx = buffer(offset,2):le_int()
            local my = buffer(offset+2,2):le_int()
            local mz = buffer(offset+4,2):le_int()
            opt_tree:add_le(buffer(offset,6), "Magnetometer (mG): X="..mx..", Y="..my..", Z="..mz)
            opt_tree:add_le(buffer(offset+6,4), "Heading (unwrapped): " .. string.format("%.2f deg", buffer(offset+6+30,4):le_float()))
            local cal_ok = buffer(offset+6+30+16,1):int()  -- magneto_calibration_ok (char)
            opt_tree:add_le(buffer(offset+6+30+16,1), "Magneto calibration ok: " .. (cal_ok~=0 and "YES" or "NO"))
            opt_tree:add_le(buffer(offset+6+30+17,4), "Magneto state: 0x" .. string.format("%08X", buffer(offset+6+30+17,4):le_uint()))
            opt_tree:add_le(buffer(offset+6+30+21,4), "Magneto radius: " .. string.format("%.2f", buffer(offset+6+30+21,4):le_float()))
            -- (Pozostałe pola error_mean, error_var pominięte)
            offset = offset + opt_data_len

        elseif tag == 23 then
            -- navdata_wind_speed
            opt_tree:add_le(buffer(offset,4), "Wind speed: " .. string.format("%.3f m/s", buffer(offset,4):le_float()))
            opt_tree:add_le(buffer(offset+4,4), "Wind angle: " .. string.format("%.2f deg", buffer(offset+4,4):le_float()*180/math.pi))
            opt_tree:add_le(buffer(offset+8,4), "Wind comp theta: " .. string.format("%.3f", buffer(offset+8,4):le_float()))
            opt_tree:add_le(buffer(offset+12,4),"Wind comp phi: " .. string.format("%.3f", buffer(offset+12,4):le_float()))
            opt_tree:add(buffer(offset+16, opt_data_len-16), "(Wind Kalman internal states omitted)")
            offset = offset + opt_data_len

        elseif tag == 24 then
            -- navdata_kalman_pressure
            opt_tree:add_le(buffer(offset,4), "Offset pressure: " .. string.format("%.3f", buffer(offset,4):le_float()))
            opt_tree:add_le(buffer(offset+4,4), "Estimated altitude (Z): " .. string.format("%.3f", buffer(offset+4,4):le_float()))
            opt_tree:add_le(buffer(offset+8,4), "Estimated Vz: " .. string.format("%.3f", buffer(offset+8,4):le_float()))
            opt_tree:add_le(buffer(offset+12,4),"Estimated PWM bias: " .. string.format("%.3f", buffer(offset+12,4):le_float()))
            opt_tree:add_le(buffer(offset+16,4),"Estimated pressure bias: " .. string.format("%.3f", buffer(offset+16,4):le_float()))
            opt_tree:add(buffer(offset+20, opt_data_len-20), "(Kalman filter additional data omitted)")
            offset = offset + opt_data_len

        elseif tag == 25 then
            -- navdata_hdvideo_stream
            local hd_state = buffer(offset,4):le_uint()
            opt_tree:add_le(buffer(offset,4), "HD Video state: 0x" .. string.format("%08X", hd_state))
            opt_tree:add_le(buffer(offset+4,4), "Storage FIFO pkts: " .. buffer(offset+4,4):le_uint())
            opt_tree:add_le(buffer(offset+8,4), "Storage FIFO size: " .. buffer(offset+8,4):le_uint())
            opt_tree:add_le(buffer(offset+12,4),"USB key size: " .. buffer(offset+12,4):le_uint() .. " kB")
            opt_tree:add_le(buffer(offset+16,4),"USB key free: " .. buffer(offset+16,4):le_uint() .. " kB")
            opt_tree:add_le(buffer(offset+20,4),"Frame number: " .. buffer(offset+20,4):le_uint())
            opt_tree:add_le(buffer(offset+24,4),"USB remaining time: " .. buffer(offset+24,4):le_uint() .. " s")
            offset = offset + opt_data_len

        elseif tag == 26 then
            -- navdata_wifi
            local link = buffer(offset,4):le_uint()
            opt_tree:add_le(buffer(offset,4), "WiFi link quality: " .. link)
            offset = offset + opt_data_len

        elseif tag == 27 then
            -- navdata_zimmu_3000
            opt_tree:add_le(buffer(offset,4), "vzimmuLSB: " .. buffer(offset,4):le_int())
            opt_tree:add_le(buffer(offset+4,4),"vzfind: " .. string.format("%.3f", buffer(offset+4,4):le_float()))
            offset = offset + opt_data_len

        else
            -- Nierozpoznana opcja
            opt_tree:add(buffer(offset, opt_data_len), "Data: " .. tostring(buffer(offset, opt_data_len):bytes():tohex()))
            offset = offset + opt_data_len
        end
    end
end

-- Rejestracja protokołu dla portu UDP 5554
local udp_port = DissectorTable.get("udp.port")
udp_port:add(5554, ardrone_proto)