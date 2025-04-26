local gpsTrackFile = nil
local gpsTrackFilePath = ""
local flightStartTime = 0
local lastLogTick = 0

local gpsSatId = -1
local gpsAltId = -1
local gpsSpeedId = -1
local gpsHeadingId = -1 -- Add heading ID variable

-- Hilfsfunktion zum Abrufen der Telemetrie-ID für einen bestimmten Sensor
local function getTelemetryId(name)
    local field = getFieldInfo(name)
    if field then
        return field.id
    else
        return -1
    end
end

-- GPS-Daten abrufen
local function getGpsData()
    local gpsId = getTelemetryId("GPS")
    if gpsId ~= -1 then
        local gpsData = getValue(gpsId)
        if type(gpsData) == "table" then
            return gpsData
        end
    end
    return nil
end

local function openGpsTrackFile()
    -- Datei immer sofort öffnen, ohne GPS-Prüfung
    local timestamp = getDateTime()
    local modelInfo = model.getInfo()
    local modelName = modelInfo and modelInfo.name or "UnknownModel"
    modelName = string.gsub(modelName, "[^%w_%-]", "_")
    local fname = string.format("/LOGS/%s_gps_track_%04d%02d%02d_%02d%02d%02d.csv",
        modelName,
        timestamp.year or 0, timestamp.mon or 0, timestamp.day or 0,
        timestamp.hour or 0, timestamp.min or 0, timestamp.sec or 0)
    gpsTrackFilePath = fname
    gpsTrackFile = io.open(fname, "w")
    if gpsTrackFile then
        io.write(gpsTrackFile,
            "time (us), GPS_numSat, GPS_coord[0], GPS_coord[1], GPS_altitude, GPS_speed (m/s), GPS_ground_course\r\n")
    end

    -- Telemetrie-IDs ermitteln
    gpsSatId = getTelemetryId("Sats")
    gpsAltId = getTelemetryId("Alt")
    gpsSpeedId = getTelemetryId("GSpd")
    gpsHeadingId = getTelemetryId("Hdg") -- Get the heading telemetry ID
    -- Fallbacks wie in main.lua
    if gpsAltId == -1 then gpsAltId = getTelemetryId("GAlt") end
    if gpsSatId == -1 then gpsSatId = getTelemetryId("Tmp2") end
end

local function closeGpsTrackFile()
    if gpsTrackFile then
        io.close(gpsTrackFile)
        gpsTrackFile = nil
    end
end

local function logGpsSample()
    if not gpsTrackFile then return end
    local gps = getGpsData()
    if gps then
        local lat = gps.lat or 0
        local lon = gps.lon or 0
        -- Prüfe, ob Koordinaten plausibel sind
        if lat == 0 or lon == 0 then return end

        local time_us = getTime() * 10000 -- getTime() in 1/100s, convert to us

        -- Satelliten, Höhe, Geschwindigkeit holen
        local numSat = getValue(gpsSatId) or 0
        if type(numSat) == "string" then
            -- wie in main.lua: Sats kann als String kommen, dann extrahieren
            if #numSat > 2 then
                numSat = tonumber(string.sub(numSat, 3, 6)) or 0
            else
                numSat = tonumber(string.sub(numSat, 0, 3)) or 0
            end
        end

        -- Prüfe, ob Satellitenanzahl sinnvoll ist (z.B. mindestens 3)
        if numSat < 3 then return end

        local alt = getValue(gpsAltId) or 0
        local speed = getValue(gpsSpeedId) or 0
        -- Use the heading telemetry value instead of GPS course
        local course = getValue(gpsHeadingId) or 0
        -- Fall back to GPS course if heading telemetry is not available
        if course == 0 and gps.course then
            course = gps.course
        end

        local line = string.format("%d,%d,%.7f,%.7f,%d,%.2f,%.1f\r\n",
            time_us, numSat, lat, lon, alt, speed, course)
        io.write(gpsTrackFile, line)
    end
end

local function run(event)
    if not gpsTrackFile then
        openGpsTrackFile()
        -- Nur wenn Datei wirklich geöffnet wurde, Startzeit setzen
        if gpsTrackFile then
            flightStartTime = getTime()
            lastLogTick = getTime()
        end
    end
    local now = getTime()
    if gpsTrackFile and now - lastLogTick >= 100 then -- 100 Ticks = 1000 ms
        logGpsSample()
        lastLogTick = now
    end
end

local function background(event)
    if gpsTrackFile then
        closeGpsTrackFile()
    end
end

local function init()
    -- Keine Initialisierung nötig
end

return { init = init, run = run, background = background }
