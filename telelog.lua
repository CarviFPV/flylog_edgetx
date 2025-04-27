local gpsTrackFile = nil
local gpsTrackFilePath = ""
local flightStartTime = 0
local lastLogTick = 0
local gpsSatId = -1
local gpsAltId = -1
local gpsSpeedId = -1
local gpsHeadingId = -1
local vSpeedId = -1
local pitchId = -1
local rollId = -1
local yawId = -1
local rxBtId = -1
local currId = -1
local capaId = -1
local rQlyId = -1
local tQlyId = -1
local tPwrId = -1

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
    local fname = string.format("/LOGS/%s_TeleLog_%04d%02d%02d_%02d%02d%02d.csv",
        modelName,
        timestamp.year or 0, timestamp.mon or 0, timestamp.day or 0,
        timestamp.hour or 0, timestamp.min or 0, timestamp.sec or 0)
    gpsTrackFilePath = fname
    gpsTrackFile = io.open(fname, "w")
    if gpsTrackFile then
        io.write(gpsTrackFile,
            "time,GPS_numSat,GPS_coord[0],GPS_coord[1],GPS_altitude,GPS_speed,GPS_ground_course,VSpd,Pitch,Roll,Yaw,RxBt,Curr,Capa,RQly,TQly,TPWR\r\n")
    end

    -- Telemetrie-IDs ermitteln
    gpsSatId = getTelemetryId("Sats")
    gpsAltId = getTelemetryId("Alt")
    gpsSpeedId = getTelemetryId("GSpd")
    gpsHeadingId = getTelemetryId("Hdg")
    vSpeedId = getTelemetryId("VSpd")
    pitchId = getTelemetryId("Ptch")
    rollId = getTelemetryId("Roll")
    yawId = getTelemetryId("Yaw")
    rxBtId = getTelemetryId("RxBt")
    currId = getTelemetryId("Curr")
    capaId = getTelemetryId("Capa")
    rQlyId = getTelemetryId("RQly")
    tQlyId = getTelemetryId("TQly")
    tPwrId = getTelemetryId("TPWR")
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
    
    local time_us = getTime() * 10000 -- getTime() in 1/100s, convert to us

    -- Default-Werte setzen, falls keine GPS-Daten vorhanden
    local lat = 0
    local lon = 0
    local numSat = 0
    
    -- GPS-Daten übernehmen wenn vorhanden
    if gps then
        lat = gps.lat or 0
        lon = gps.lon or 0
    end

    -- Satelliten, Höhe, Geschwindigkeit holen
    numSat = getValue(gpsSatId) or 0
    if type(numSat) == "string" then
        -- wie in main.lua: Sats kann als String kommen, dann extrahieren
        if #numSat > 2 then
            numSat = tonumber(string.sub(numSat, 3, 6)) or 0
        else
            numSat = tonumber(string.sub(numSat, 0, 3)) or 0
        end
    end

    local alt = getValue(gpsAltId) or 0
    local speed = getValue(gpsSpeedId) or 0
    -- Use the heading telemetry value instead of GPS course
    local course = getValue(gpsHeadingId) or 0
    -- Fall back to GPS course if heading telemetry is not available
    if course == 0 and gps and gps.course then
        course = gps.course
    end

    -- Get vertical speed
    local vSpeed = getValue(vSpeedId) or 0

    -- Get attitude data
    local pitch = getValue(pitchId) or 0
    local roll = getValue(rollId) or 0
    local yaw = getValue(yawId) or 0

    -- Get battery and current data
    local rxBt = getValue(rxBtId) or 0
    local curr = getValue(currId) or 0
    local capa = getValue(capaId) or 0

    -- Get link quality data
    local rQly = getValue(rQlyId) or 0
    local tQly = getValue(tQlyId) or 0
    local tPwr = getValue(tPwrId) or 0

    local line = string.format("%d,%d,%.7f,%.7f,%d,%.2f,%.1f,%.2f,%.1f,%.1f,%.1f,%.2f,%.2f,%d,%d,%d,%d\r\n",
        time_us, numSat, lat, lon, alt, speed, course, vSpeed, pitch, roll, yaw, rxBt, curr, capa, rQly, tQly, tPwr)
    io.write(gpsTrackFile, line)
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
    if gpsTrackFile and now - lastLogTick >= 80 then -- 80 Ticks = 800 ms
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
