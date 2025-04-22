local gpsTrackFile = nil
local gpsTrackFilePath = ""
local flightStartTime = 0
local lastLogTick = 0

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
    local timestamp = getDateTime()
    local modelInfo = model.getInfo()
    local modelName = modelInfo and modelInfo.name or "UnknownModel"
    -- Ersetze Leerzeichen und ungültige Zeichen im Modelnamen
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
        local time_us = getTime() * 10000 -- getTime() in 1/100s, convert to us
        local numSat = gps.sat or 0
        local lat = gps.lat or 0
        local lon = gps.lon or 0
        local alt = gps.alt or 0
        local speed = gps.speed or 0
        local course = gps.course or 0
        local line = string.format("%d,%d,%.7f,%.7f,%d,%.2f,%.1f\r\n",
            time_us, numSat, lat, lon, alt, speed, course)
        io.write(gpsTrackFile, line)
    end
end

local function run(event)
    if not gpsTrackFile then
        openGpsTrackFile()
        flightStartTime = getTime()
        lastLogTick = getTime()
    end
    local now = getTime()
    if now - lastLogTick >= 100 then -- 100 Ticks = 1000 ms
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
