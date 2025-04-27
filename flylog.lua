local logFile = "/LOGS/flylog.csv"
local flightStartTime = 0
local armed = 0          -- 0 means disarmed; non-zero means armed
local armingDetails = {} -- Table to store arming event details

-- Hilfsfunktion zum Abrufen der Telemetrie-ID für einen bestimmten Sensor
local function getTelemetryId(name)
    local field = getFieldInfo(name)
    if field then
        return field.id
    else
        return -1
    end
end

-- Funktion zum Abrufen der GPS-Koordinaten anhand der Telemetrie-ID "GPS"
local function getGpsCoordinates()
    local gpsId = getTelemetryId("GPS")
    if gpsId ~= -1 then
        local gpsData = getValue(gpsId)
        if type(gpsData) == "table" then
            local lat = gpsData["lat"] or 0
            local lon = gpsData["lon"] or 0
            return lat, lon
        end
    end
    return 0, 0
end

local function init()
    local file = io.open(logFile, "r")
    if not file then
        file = io.open(logFile, "a")
        if file then
            -- Kopfzeile inkl. zusätzlicher Spalten für GPS-Koordinaten
            io.write(file,
                "Arming,Date,Timestamp-TO,GPS-Arming-Lat,GPS-Arming-Lon,Disarming,Timestamp-LDG,GPS-Disarming-Lat,GPS-Disarming-Lon,Duration,ModelName\r\n")
            io.close(file)
        else
            error("Could not create log file!")
        end
    else
        io.close(file)
    end
end

local function logEvent(event, duration)
    local file = io.open(logFile, "a")
    if file then
        local timestamp    = getDateTime()
        local year         = timestamp.year or 0
        local mon          = timestamp.mon or 0
        local day          = timestamp.day or 0
        local hour         = timestamp.hour or 0
        local min          = timestamp.min or 0
        local sec          = timestamp.sec or 0

        local dateStr      = string.format("%04d-%02d-%02d", year, mon, day)
        local timeStr      = string.format("%02d:%02d:%02d", hour, min, sec)
        local safeDuration = duration or 0

        local modelInfo    = model.getInfo()
        local modelName    = modelInfo and modelInfo.name or "Unknown Model"

        if event == "Arming" then
            local lat, lon = getGpsCoordinates()
            armingDetails = {
                event     = event,
                dateStr   = dateStr,
                timeStr   = timeStr,
                modelName = modelName,
                gpsLat    = lat,
                gpsLon    = lon
            }
        elseif event == "Disarming" then
            local currentLat, currentLon = getGpsCoordinates()
            local logLine = string.format("%s,%s,%s,%.6f,%.6f,%s,%s,%.6f,%.6f,%.2f,%s\r\n",
                armingDetails.event,
                armingDetails.dateStr,
                armingDetails.timeStr,
                armingDetails.gpsLat,
                armingDetails.gpsLon,
                event,
                timeStr,
                currentLat,
                currentLon,
                safeDuration,
                armingDetails.modelName)
            io.write(file, logLine)
            io.close(file)
            print("Logged:", logLine)
        end
    else
        error("Could not open log file for writing!")
    end
end

local function run(event)
    if armed == 0 then
        flightStartTime = getTime()
        print("Flight Start Time:", flightStartTime)
        logEvent("Arming", 0)
        armed = 1
    end
end

local function background(event)
    if armed == 1 then
        local flightDuration = (getTime() - flightStartTime) / 100
        logEvent("Disarming", flightDuration)
        armed = 0
    end
end

return { init = init, run = run, background = background }
