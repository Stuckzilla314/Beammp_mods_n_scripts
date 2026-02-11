-- EventManager Plugin (Consolidated)
-- Unified event framework and all event logic in one place

-- List of admin player IDs (add your admin IDs here)
local admins = {
    "713962",
    "0"
    -- Example: "12345", "67890"
}

-- Event storage
local events = {}
local eventCount = 0
local activeEvent = nil

-- ============================================================================
-- CORE HELPERS
-- ============================================================================

local function isAdmin(playerID)
    local playerIDStr = tostring(playerID)
    for _, adminID in ipairs(admins) do
        if adminID == playerIDStr then
            return true
        end
    end
    return false
end

local function isEventActive(name)
    return activeEvent ~= nil and activeEvent.name == name
end

function RegisterEvent(eventName, eventData)
    if events[eventName] then
        print("[EventManager] Warning: Event '" .. eventName .. "' already registered. Overriding.")
    else
        eventCount = eventCount + 1
    end
    events[eventName] = eventData
    print("[EventManager] Registered event: " .. eventName)
end

local function startEvent(eventName, params)
    if activeEvent then
        return false, "An event is already running. Stop it first with /stopevent"
    end

    local event = events[eventName]
    if not event then
        return false, "Event '" .. eventName .. "' not found"
    end

    local success = event.onStart(params)
    if success then
        activeEvent = {
            name = eventName,
            event = event,
            startTime = os.time()
        }
        return true, "Event '" .. eventName .. "' started successfully"
    end

    return false, "Failed to start event '" .. eventName .. "'"
end

local function stopEvent()
    if not activeEvent then
        return false, "No event is currently running"
    end

    local success = activeEvent.event.onStop()
    if success then
        local eventName = activeEvent.name
        activeEvent = nil
        return true, "Event '" .. eventName .. "' stopped successfully"
    end

    return false, "Failed to stop event"
end

local function listEvents()
    local eventList = {}
    for name, event in pairs(events) do
        table.insert(eventList, name .. " - " .. (event.description or "No description"))
    end
    return eventList
end

local function broadcastClientEvent(eventName, data)
    local players = MP.GetPlayers()
    for id, _ in pairs(players) do
        MP.TriggerClientEvent(tonumber(id), eventName, data or "")
    end
end

-- ============================================================================
-- RACE EVENT (Gate-based)
-- ============================================================================

local raceState = {
    status = "idle",
    startGate = nil,
    endGate = nil,
    countdownTime = 0,
    countdownMax = 3,
    raceStartTime = 0,
    participants = {},
    finishedPlayers = {}
}

local playerPositions = {}
local RACE_GATE_RADIUS = 15
local RACE_START_SPACING = 4

local function raceDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function raceInGate(pos, gate)
    if not gate or not pos then return false end
    local distance = raceDistance(pos.x, pos.y, pos.z, gate.x, gate.y, gate.z)
    return distance <= gate.radius
end

local function raceParsePosition(posStr, includeRadius)
    local parts = {}
    for part in string.gmatch(posStr, "[^,]+") do
        table.insert(parts, tonumber(part))
    end

    if includeRadius and #parts == 4 then
        return {x = parts[1], y = parts[2], z = parts[3], radius = parts[4]}
    elseif #parts >= 3 then
        return {x = parts[1], y = parts[2], z = parts[3], radius = RACE_GATE_RADIUS}
    end

    return nil
end

local function raceSetStartGate(posStr)
    local gate = raceParsePosition(posStr, true)
    if gate then
        raceState.startGate = gate
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", gate.x, gate.y, gate.z, gate.radius)
        broadcastClientEvent("RaceGateSetStart", payload)
        return true
    end
    return false
end

local function raceSetEndGate(posStr)
    local gate = raceParsePosition(posStr, true)
    if gate then
        raceState.endGate = gate
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", gate.x, gate.y, gate.z, gate.radius)
        broadcastClientEvent("RaceGateSetEnd", payload)
        return true
    end
    return false
end

local function raceSetStartFromPosition(pos)
    if pos then
        raceState.startGate = {x = pos.x, y = pos.y, z = pos.z, radius = RACE_GATE_RADIUS}
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", pos.x, pos.y, pos.z, RACE_GATE_RADIUS)
        broadcastClientEvent("RaceGateSetStart", payload)
        return true
    end
    return false
end

local function raceSetEndFromPosition(pos)
    if pos then
        raceState.endGate = {x = pos.x, y = pos.y, z = pos.z, radius = RACE_GATE_RADIUS}
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", pos.x, pos.y, pos.z, RACE_GATE_RADIUS)
        broadcastClientEvent("RaceGateSetEnd", payload)
        return true
    end
    return false
end

local function raceStartCountdown()
    if not raceState.startGate or not raceState.endGate then
        return false, "Start and end gates must be set first!"
    end

    if raceState.status ~= "idle" then
        return false, "Race is already in progress!"
    end

    if next(raceState.participants) == nil then
        return false, "No players have joined the race!"
    end

    -- Teleport participants to a start line perpendicular to the start->end direction
    local startPos = raceState.startGate
    local endPos = raceState.endGate
    local dirX = endPos.x - startPos.x
    local dirY = endPos.y - startPos.y
    local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
    if dirLen < 0.001 then
        dirX, dirY = 1, 0
        dirLen = 1
    end
    dirX, dirY = dirX / dirLen, dirY / dirLen
    local rightX, rightY = -dirY, dirX

    local ids = {}
    for playerID, _ in pairs(raceState.participants) do
        table.insert(ids, tonumber(playerID))
    end
    table.sort(ids)

    local spacing = math.max(RACE_START_SPACING, (raceState.startGate.radius or RACE_GATE_RADIUS) * 0.5)
    local count = #ids
    local dirPayload = string.format("%.5f,%.5f", dirX, dirY)
    for i, playerID in ipairs(ids) do
        local offset = (i - (count + 1) / 2) * spacing
        local x = startPos.x + rightX * offset
        local y = startPos.y + rightY * offset
        local z = startPos.z
        local data = "{" .. x .. "," .. y .. "," .. z .. "}"
        MP.TeleportVehicle(playerID, -1, data)
        MP.TriggerClientEvent(playerID, "RaceOrient", dirPayload)
    end

    raceState.status = "countdown"
    raceState.countdownTime = raceState.countdownMax
    raceState.finishedPlayers = {}

    MP.SendChatMessage(-1, "========================================")
    MP.SendChatMessage(-1, "RACE STARTING!")
    MP.SendChatMessage(-1, "========================================")
    MP.SendChatMessage(-1, "COUNTDOWN: 3...")

    return true, "Race countdown started!"
end

local function raceStop()
    raceState.status = "idle"
    raceState.participants = {}
    raceState.finishedPlayers = {}
    raceState.countdownTime = 0
    broadcastClientEvent("RaceGateClear", "")
    MP.SendChatMessage(-1, "Race has been stopped!")
    return true
end

local function raceLeaderboard(playerID)
    local targetID = playerID or -1

    if raceState.status == "idle" then
        MP.SendChatMessage(targetID, "No race in progress!")
        return
    end

    MP.SendChatMessage(targetID, "======== LEADERBOARD ========")

    if #raceState.finishedPlayers > 0 then
        MP.SendChatMessage(targetID, "--- FINISHED ---")
        for i, player in ipairs(raceState.finishedPlayers) do
            local timeStr = string.format("%.2f", player.time)
            MP.SendChatMessage(targetID, i .. ". " .. player.name .. " - " .. timeStr .. "s")
        end
    end

    if raceState.status == "racing" or raceState.status == "countdown" then
        local unfinished = {}
        for _, data in pairs(raceState.participants) do
            if not data.finishTime then
                table.insert(unfinished, data.name)
            end
        end

        if #unfinished > 0 then
            MP.SendChatMessage(targetID, "--- RACING ---")
            for i, name in ipairs(unfinished) do
                MP.SendChatMessage(targetID, i .. ". " .. name .. " - Still racing...")
            end
        end
    end

    MP.SendChatMessage(targetID, "============================")
end

local raceEvent = {
    name = "race",
    description = "Race event with gates, countdown, and leaderboard",
    onStart = function(params)
        raceState.status = "idle"
        raceState.countdownTime = 0
        raceState.finishedPlayers = {}
        MP.SendChatMessage(-1, "[EVENT] Race event is now active. Use /race join and /race setstart/setend.")
        return true
    end,
    onStop = function()
        raceStop()
        MP.SendChatMessage(-1, "[EVENT] Race event ended.")
        return true
    end
}

-- ============================================================================
-- DEMOLITION DERBY EVENT
-- ============================================================================

local DERBY_IDLE = 0
local DERBY_RUNNING = 1
local DERBY_ENDED = 2

local derbyState = DERBY_IDLE
local derbyParticipants = {}
local derbyEliminated = {}

local DERBY_STATIONARY_THRESHOLD = 5.0
local DERBY_STATIONARY_DISTANCE = 2.0
local DERBY_CHECK_INTERVAL = 1.0
local derbyLastCheckTime = 0

local function derbyDistance(pos1, pos2)
    if not pos1 or not pos2 then
        return 0
    end
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function derbyActiveCount()
    local count = 0
    for _, data in pairs(derbyParticipants) do
        if not data.eliminated then
            count = count + 1
        end
    end
    return count
end

local function derbyEndEvent(winnerID)
    if derbyState ~= DERBY_RUNNING then
        return
    end

    derbyState = DERBY_ENDED
    local winnerName = winnerID and MP.GetPlayerName(winnerID) or "Unknown"

    MP.SendChatMessage(-1, "====================================")
    MP.SendChatMessage(-1, "[DEMOLITION DERBY] Event finished!")
    MP.SendChatMessage(-1, "Winner: " .. winnerName .. "!")
    MP.SendChatMessage(-1, "====================================")

    local players = MP.GetPlayers()
    for playerID, _ in pairs(players) do
        MP.TriggerClientEvent(playerID, "DerbyEnableFeatures", "")
        MP.TriggerClientEvent(playerID, "DerbyResetVehicle", "")
    end

    derbyParticipants = {}
    derbyEliminated = {}
    derbyState = DERBY_IDLE
end

local function derbyEliminate(playerID)
    if derbyParticipants[playerID] and not derbyParticipants[playerID].eliminated then
        derbyParticipants[playerID].eliminated = true
        derbyEliminated[playerID] = true

        local playerName = MP.GetPlayerName(playerID)
        MP.SendChatMessage(-1, "[DEMOLITION DERBY] " .. playerName .. " has been eliminated!")

        local activeCount = derbyActiveCount()
        if activeCount == 1 then
            for pID, data in pairs(derbyParticipants) do
                if not data.eliminated then
                    derbyEndEvent(pID)
                    return
                end
            end
        elseif activeCount == 0 then
            derbyEndEvent(nil)
        end
    end
end

local function derbyStartEvent()
    if derbyState ~= DERBY_IDLE then
        return false, "Event is already running or has ended!"
    end

    local players = MP.GetPlayers()
    if not players or #players < 2 then
        return false, "Need at least 2 players to start the event!"
    end

    derbyParticipants = {}
    derbyEliminated = {}
    for playerID, _ in pairs(players) do
        derbyParticipants[playerID] = {
            eliminated = false,
            lastPosition = nil,
            stationaryTime = 0
        }
    end

    derbyState = DERBY_RUNNING
    derbyLastCheckTime = os.time()

    MP.SendChatMessage(-1, "====================================")
    MP.SendChatMessage(-1, "[DEMOLITION DERBY] Event starting!")
    MP.SendChatMessage(-1, "Stay moving! Stationary cars for 5 seconds are eliminated!")
    MP.SendChatMessage(-1, "Vehicle resets, teleports, and node grabber are DISABLED!")
    MP.SendChatMessage(-1, "====================================")

    for playerID, _ in pairs(derbyParticipants) do
        MP.TriggerClientEvent(playerID, "DerbyDisableFeatures", "")
    end

    return true, "Event started successfully!"
end

local function derbyCheckPositions()
    if derbyState ~= DERBY_RUNNING then
        return
    end

    local currentTime = os.time()
    local deltaTime = currentTime - derbyLastCheckTime
    if deltaTime < DERBY_CHECK_INTERVAL then
        return
    end

    derbyLastCheckTime = currentTime
    for playerID, data in pairs(derbyParticipants) do
        if not data.eliminated then
            MP.TriggerClientEvent(playerID, "DerbyRequestPosition", "")
        end
    end
end

local function derbyOnPositionUpdate(playerID, data)
    if derbyState ~= DERBY_RUNNING or not derbyParticipants[playerID] or derbyParticipants[playerID].eliminated then
        return
    end

    local x, y, z = string.match(data, "([^,]+),([^,]+),([^,]+)")
    if not x or not y or not z then
        print("[EventManager] Warning: Malformed derby position data from player " .. playerID)
        return
    end

    local currentPosition = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
    local lastPosition = derbyParticipants[playerID].lastPosition

    if lastPosition then
        local distance = derbyDistance(currentPosition, lastPosition)
        if distance < DERBY_STATIONARY_DISTANCE then
            derbyParticipants[playerID].stationaryTime = derbyParticipants[playerID].stationaryTime + DERBY_CHECK_INTERVAL
            if derbyParticipants[playerID].stationaryTime >= DERBY_STATIONARY_THRESHOLD then
                derbyEliminate(playerID)
            end
        else
            derbyParticipants[playerID].stationaryTime = 0
        end
    end

    derbyParticipants[playerID].lastPosition = currentPosition
end

local derbyEvent = {
    name = "derby",
    description = "Demolition derby event with elimination rules",
    onStart = function(params)
        local success = derbyStartEvent()
        return success
    end,
    onStop = function()
        if derbyState == DERBY_RUNNING then
            derbyEndEvent(nil)
            return true
        end
        return false
    end
}

-- ============================================================================
-- DRIFT EVENT
-- ============================================================================

local DRIFT_SCORING = {
    DRIFT_TIME = 40,
    ANGLE = 30,
    PROXIMITY = 20,
    SPEED = 10
}

local DRIFT_THRESHOLD = {
    MIN_ANGLE = 10,
    MIN_SPEED = 15,
    MAX_SPEED = 100,
    PROXIMITY_RANGE = 5
}

local driftEvent = {
    active = false,
    duration = 300,
    startTime = 0,
    endTime = 0
}

local driftStats = {}

local function driftFormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

local function driftRemainingTime()
    if not driftEvent.active then
        return 0
    end
    local elapsed = os.time() - driftEvent.startTime
    return math.max(0, driftEvent.duration - elapsed)
end

local function driftInitStats(playerID)
    if not driftStats[playerID] then
        driftStats[playerID] = {
            totalScore = 0,
            driftTime = 0,
            lastUpdate = os.time(),
            isDrifting = false,
            currentDriftStart = 0
        }
    end
end

local function driftScore(angle, speed, proximity)
    local angleScore = math.min(angle / 90, 1) * DRIFT_SCORING.ANGLE
    local speedNorm = math.max(0, math.min(1, (speed - DRIFT_THRESHOLD.MIN_SPEED) /
        (DRIFT_THRESHOLD.MAX_SPEED - DRIFT_THRESHOLD.MIN_SPEED)))
    local speedScore = speedNorm * DRIFT_SCORING.SPEED

    local proximityScore = 0
    if proximity > 0 and proximity <= DRIFT_THRESHOLD.PROXIMITY_RANGE then
        proximityScore = (1 - proximity / DRIFT_THRESHOLD.PROXIMITY_RANGE) * DRIFT_SCORING.PROXIMITY
    end

    return angleScore + speedScore + proximityScore + DRIFT_SCORING.DRIFT_TIME
end

local function driftUpdate(playerID, isDrifting, angle, speed, proximity)
    if not driftEvent.active then
        return
    end

    driftInitStats(playerID)
    local stats = driftStats[playerID]
    local currentTime = os.time()

    if isDrifting and angle >= DRIFT_THRESHOLD.MIN_ANGLE and speed >= DRIFT_THRESHOLD.MIN_SPEED then
        if not stats.isDrifting then
            stats.isDrifting = true
            stats.currentDriftStart = currentTime
        end

        local timeDelta = currentTime - stats.lastUpdate
        if timeDelta > 0 then
            stats.driftTime = stats.driftTime + timeDelta
            local score = driftScore(angle, speed, proximity) * timeDelta
            stats.totalScore = stats.totalScore + score
        end
    else
        if stats.isDrifting then
            stats.isDrifting = false
        end
    end

    stats.lastUpdate = currentTime
end

local function driftStart(duration)
    driftEvent.active = true
    driftEvent.duration = duration or 300
    driftEvent.startTime = os.time()
    driftEvent.endTime = driftEvent.startTime + driftEvent.duration
    driftStats = {}

    MP.SendChatMessage(-1, "=================================")
    MP.SendChatMessage(-1, "DRIFT EVENT STARTED!")
    MP.SendChatMessage(-1, "Duration: " .. driftFormatTime(driftEvent.duration))
    MP.SendChatMessage(-1, "Start drifting to earn points!")
    MP.SendChatMessage(-1, "=================================")

    print("[EventManager] Drift event started - Duration: " .. driftEvent.duration .. "s")
end

local function driftStop()
    if not driftEvent.active then
        return
    end

    driftEvent.active = false
    local leaderboard = {}
    for playerID, stats in pairs(driftStats) do
        local playerName = MP.GetPlayerName(playerID)
        if playerName then
            table.insert(leaderboard, {
                id = playerID,
                name = playerName,
                score = stats.totalScore,
                driftTime = stats.driftTime
            })
        end
    end

    table.sort(leaderboard, function(a, b) return a.score > b.score end)

    MP.SendChatMessage(-1, "=================================")
    MP.SendChatMessage(-1, "DRIFT EVENT FINISHED!")
    MP.SendChatMessage(-1, "=================================")

    if #leaderboard == 0 then
        MP.SendChatMessage(-1, "No participants scored points")
    else
        MP.SendChatMessage(-1, "FINAL LEADERBOARD:")
        for i, entry in ipairs(leaderboard) do
            if i <= 10 then
                local medal = ""
                if i == 1 then medal = "🥇 "
                elseif i == 2 then medal = "🥈 "
                elseif i == 3 then medal = "🥉 "
                end
                MP.SendChatMessage(-1, string.format("%s#%d: %s - %.0f points (%.1fs drift)",
                    medal, i, entry.name, entry.score, entry.driftTime))
            end
        end
    end

    MP.SendChatMessage(-1, "=================================")
    print("[EventManager] Drift event ended - " .. #leaderboard .. " participants")
end

local function driftCheckTimer()
    if driftEvent.active then
        if driftRemainingTime() <= 0 then
            driftStop()
        end
    end
end

local driftEventDef = {
    name = "drift",
    description = "Drift event with scoring and leaderboard",
    onStart = function(params)
        if driftEvent.active then
            return false
        end
        local duration = tonumber(params)
        duration = duration or 300
        if duration < 30 then duration = 30 end
        if duration > 3600 then duration = 3600 end
        driftStart(duration)
        return true
    end,
    onStop = function()
        if not driftEvent.active then
            return false
        end
        driftStop()
        return true
    end
}

-- ============================================================================
-- DRAG RACE EVENT
-- ============================================================================

local DRAG_DEFAULT_COUNTDOWN = 3
local dragState = {
    active = false,
    countdown = false,
    racing = false,
    countdownTime = DRAG_DEFAULT_COUNTDOWN,
    lastCountdownTick = 0,
    startGate = nil,
    endGate = nil,
    participants = {},
    raceStartTime = 0
}

local dragPositions = {}

local function dragParsePosition(posStr, includeRadius)
    local parts = {}
    for part in string.gmatch(posStr, "[^,]+") do
        table.insert(parts, tonumber(part))
    end

    if includeRadius and #parts == 4 then
        return {x = parts[1], y = parts[2], z = parts[3], radius = parts[4]}
    elseif #parts >= 3 then
        return {x = parts[1], y = parts[2], z = parts[3], radius = 12}
    end

    return nil
end

local function dragInGate(pos, gate)
    if not pos or not gate then return false end
    local dx = pos.x - gate.x
    local dy = pos.y - gate.y
    local dz = pos.z - gate.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    return dist <= gate.radius
end

local function dragCounts()
    local total = 0
    local ready = 0
    for _, data in pairs(dragState.participants) do
        total = total + 1
        if data.ready then
            ready = ready + 1
        end
    end
    return total, ready
end

local function dragAllReady()
    local total, ready = dragCounts()
    if total == 0 or ready ~= total or not dragState.startGate or not dragState.endGate then
        return false
    end

    for playerID, data in pairs(dragState.participants) do
        if data.ready then
            local pos = dragPositions[playerID]
            if not pos or not dragInGate(pos, dragState.startGate) then
                return false
            end
        end
    end

    return true
end

local function dragBroadcast(eventName, data)
    for playerID, _ in pairs(dragState.participants) do
        MP.TriggerClientEvent(playerID, eventName, data or "")
    end
end

local function dragReset()
    dragState.countdown = false
    dragState.racing = false
    dragState.countdownTime = DRAG_DEFAULT_COUNTDOWN
    dragState.lastCountdownTick = 0
    dragState.raceStartTime = 0
end

local function dragStartCountdown()
    if dragState.countdown or dragState.racing then
        return
    end

    dragState.countdown = true
    dragState.countdownTime = DRAG_DEFAULT_COUNTDOWN
    dragState.lastCountdownTick = os.time()

    MP.SendChatMessage(-1, "[DRAG] All racers are ready. Countdown starting!")
    dragBroadcast("DragLock", "")
    MP.SendChatMessage(-1, "[DRAG] COUNTDOWN: " .. dragState.countdownTime .. "...")
end

local function dragStartRace()
    dragState.countdown = false
    dragState.racing = true
    dragState.raceStartTime = os.clock()

    for _, data in pairs(dragState.participants) do
        data.finishTime = nil
        data.ready = false
    end

    MP.SendChatMessage(-1, "[DRAG] GO! Drag race started!")
    dragBroadcast("DragUnlock", "")
end

local function dragStopRace()
    if dragState.racing or dragState.countdown then
        dragBroadcast("DragUnlock", "")
    end
    dragReset()
end

local function dragRemoveParticipant(playerID)
    if dragState.participants[playerID] then
        dragState.participants[playerID] = nil
        MP.TriggerClientEvent(playerID, "DragSetInactive", "")

        if dragState.countdown and not dragAllReady() then
            MP.SendChatMessage(-1, "[DRAG] Countdown cancelled. Waiting for all racers to ready up.")
            dragBroadcast("DragUnlock", "")
            dragReset()
        end
    end
end

local dragEvent = {
    name = "drag",
    description = "Drag race with staging, ready checks, and countdown lock",
    onStart = function(params)
        if dragState.active then
            return false
        end
        dragState.active = true
        dragReset()
        dragState.participants = {}
        MP.SendChatMessage(-1, "[DRAG] Drag race event is now active! Use /drag join to participate.")
        return true
    end,
    onStop = function()
        if not dragState.active then
            return false
        end
        dragState.active = false
        dragStopRace()
        for playerID, _ in pairs(dragState.participants) do
            MP.TriggerClientEvent(playerID, "DragSetInactive", "")
        end
        dragState.participants = {}
        MP.SendChatMessage(-1, "[DRAG] Drag race event ended.")
        return true
    end
}

-- ============================================================================
-- CUSTOM EVENTS
-- ============================================================================

local timeTrialEvent = {
    name = "timetrial",
    description = "Time trial race - beat the clock!",
    startTime = nil,

    onStart = function(params)
        print("[EventManager] Starting time trial event")
        local players = MP.GetPlayers()
        local participantCount = 0
        for id, _ in pairs(players) do
            participantCount = participantCount + 1
            MP.SendChatMessage(tonumber(id), "[EVENT] Time trial started! Beat the clock!")
            MP.TriggerClientEvent(tonumber(id), "startTimeTrial", "")
        end
        MP.SendChatMessage(-1, "[EVENT] Time Trial event started with " .. participantCount .. " participants")
        MP.SendChatMessage(-1, "[EVENT] You have 5 minutes to complete the course!")
        timeTrialEvent.startTime = os.time()
        return true
    end,

    onStop = function()
        if timeTrialEvent.startTime then
            local duration = os.time() - timeTrialEvent.startTime
            MP.SendChatMessage(-1, "[EVENT] Time Trial event ended! Duration: " .. duration .. " seconds")
        else
            MP.SendChatMessage(-1, "[EVENT] Time Trial event ended!")
        end

        local players = MP.GetPlayers()
        for id, _ in pairs(players) do
            MP.TriggerClientEvent(tonumber(id), "stopTimeTrial", "")
        end

        timeTrialEvent.startTime = nil
        return true
    end
}

local tagEvent = {
    name = "tag",
    description = "Tag game - one player is 'it'",
    itPlayer = nil,
    onStart = function(params)
        print("[EventManager] Starting tag event")
        local players = MP.GetPlayers()
        local playerList = {}
        for id, _ in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        if #playerList < 2 then
            MP.SendChatMessage(-1, "[EVENT] Need at least 2 players for tag!")
            return false
        end
        math.randomseed(os.time())
        tagEvent.itPlayer = playerList[math.random(#playerList)]
        MP.SendChatMessage(-1, "[EVENT] Tag game started!")
        MP.SendChatMessage(tagEvent.itPlayer, "You are IT! Tag other players by colliding with them!")
        for _, id in ipairs(playerList) do
            if id ~= tagEvent.itPlayer then
                MP.SendChatMessage(id, "Don't get tagged! Avoid player " .. tagEvent.itPlayer .. "!")
            end
        end
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Tag game ended!")
        if tagEvent.itPlayer then
            MP.SendChatMessage(-1, "[EVENT] Player " .. tagEvent.itPlayer .. " was 'it' when the game ended!")
        end
        tagEvent.itPlayer = nil
        return true
    end
}

local convoyEvent = {
    name = "convoy",
    description = "Follow the leader convoy event",
    leader = nil,
    onStart = function(params)
        print("[EventManager] Starting convoy event")
        local players = MP.GetPlayers()
        local playerList = {}
        for id, _ in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        if #playerList < 2 then
            MP.SendChatMessage(-1, "[EVENT] Need at least 2 players for convoy!")
            return false
        end
        table.sort(playerList)
        convoyEvent.leader = playerList[1]
        MP.SendChatMessage(-1, "[EVENT] Convoy event started!")
        MP.SendChatMessage(convoyEvent.leader, "You are the leader! Drive carefully, everyone is following you!")
        for _, id in ipairs(playerList) do
            if id ~= convoyEvent.leader then
                MP.SendChatMessage(id, "Follow player " .. convoyEvent.leader .. " in a convoy! Stay close!")
            end
        end
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Convoy event ended!")
        MP.SendChatMessage(-1, "[EVENT] Thanks for following player " .. (convoyEvent.leader or "unknown") .. "!")
        convoyEvent.leader = nil
        return true
    end
}

local policeChaseEvent = {
    name = "policechase",
    description = "Police chase - cops vs robbers",
    cops = {},
    robbers = {},
    onStart = function(params)
        print("[EventManager] Starting police chase event")
        local players = MP.GetPlayers()
        local playerList = {}
        for id, _ in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        if #playerList < 2 then
            MP.SendChatMessage(-1, "[EVENT] Need at least 2 players for police chase!")
            return false
        end
        math.randomseed(os.time())
        policeChaseEvent.cops = {}
        policeChaseEvent.robbers = {}
        for i, id in ipairs(playerList) do
            if i <= math.ceil(#playerList / 2) then
                table.insert(policeChaseEvent.cops, id)
                MP.SendChatMessage(id, "[EVENT] You are a COP! Chase down the robbers!")
            else
                table.insert(policeChaseEvent.robbers, id)
                MP.SendChatMessage(id, "[EVENT] You are a ROBBER! Escape from the cops!")
            end
        end
        MP.SendChatMessage(-1, "[EVENT] Police Chase started!")
        MP.SendChatMessage(-1, "[EVENT] " .. #policeChaseEvent.cops .. " cops vs " .. #policeChaseEvent.robbers .. " robbers!")
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Police Chase ended!")
        MP.SendChatMessage(-1, "[EVENT] Cops: " .. #policeChaseEvent.cops .. " | Robbers: " .. #policeChaseEvent.robbers)
        policeChaseEvent.cops = {}
        policeChaseEvent.robbers = {}
        return true
    end
}

local carShowEvent = {
    name = "carshow",
    description = "Car show - show off your best vehicles",
    onStart = function(params)
        print("[EventManager] Starting car show event")
        MP.SendChatMessage(-1, "[EVENT] Car Show started!")
        MP.SendChatMessage(-1, "[EVENT] Show off your best vehicles!")
        MP.SendChatMessage(-1, "[EVENT] Park your vehicles in the designated area")
        local players = MP.GetPlayers()
        for id, _ in pairs(players) do
            MP.SendChatMessage(tonumber(id), "[EVENT] Time to show off! Spawn your coolest vehicle!")
        end
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Car Show ended!")
        MP.SendChatMessage(-1, "[EVENT] Thanks for participating!")
        return true
    end
}

-- ============================================================================
-- BUILT-IN EVENT: FREE ROAM
-- ============================================================================

local freeRoamEvent = {
    name = "freeroam",
    description = "Free roam exploration event",
    onStart = function(params)
        MP.SendChatMessage(-1, "[EVENT] Free Roam event started - explore the map!")
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Free Roam event has ended!")
        return true
    end
}

-- ============================================================================
-- COMMAND HANDLERS
-- ============================================================================

function onChatMessage(playerID, playerName, message)
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))

        -- /events command (available to all)
        if command == "events" or command == "listevents" then
            MP.SendChatMessage(playerID, "Available events:")
            for _, eventInfo in ipairs(listEvents()) do
                MP.SendChatMessage(playerID, "  - " .. eventInfo)
            end
            if activeEvent then
                MP.SendChatMessage(playerID, "Current event: " .. activeEvent.name)
            else
                MP.SendChatMessage(playerID, "No event currently running")
            end
            return 1
        end

        -- Race commands
        if string.sub(command, 1, 4) == "race" then
            local isSetGateCommand = string.sub(command, 1, 13) == "race setstart" or string.sub(command, 1, 11) == "race setend"
            if not isSetGateCommand and not isEventActive("race") then
                if command == "race" or command == "race help" then
                    MP.SendChatMessage(playerID, "Race event is not active. Use /startevent race to begin.")
                else
                    MP.SendChatMessage(playerID, "Race event is not active. Use /startevent race to begin.")
                    return 1
                end
            end

            if command == "race" or command == "race help" then
                MP.SendChatMessage(playerID, "=== Race Commands ===")
                MP.SendChatMessage(playerID, "/race join - Join the current race")
                MP.SendChatMessage(playerID, "/race leave - Leave the current race")
                MP.SendChatMessage(playerID, "/race leaderboard - Show leaderboard")
                if isAdmin(playerID) then
                    MP.SendChatMessage(playerID, "=== Admin Commands ===")
                    MP.SendChatMessage(playerID, "/startevent race - Activate the race event")
                    MP.SendChatMessage(playerID, "/race setstart x,y,z[,radius] - Set start gate")
                    MP.SendChatMessage(playerID, "/race setend x,y,z[,radius] - Set end gate")
                    MP.SendChatMessage(playerID, "/race start - Start the race countdown")
                    MP.SendChatMessage(playerID, "/race countdown - Progress countdown (use 3x)")
                    MP.SendChatMessage(playerID, "/race finish [player] [time] - Record finish")
                    MP.SendChatMessage(playerID, "/race stop - Stop/reset the race")
                end
                return 1
            end

            if command == "race join" then
                if raceState.status == "idle" or raceState.status == "countdown" then
                    raceState.participants[playerID] = {
                        name = playerName,
                        vehicleID = -1,
                        finishTime = nil
                    }
                    MP.SendChatMessage(playerID, "You joined the race!")
                    MP.SendChatMessage(-1, playerName .. " joined the race!")
                else
                    MP.SendChatMessage(playerID, "Cannot join - race already started!")
                end
                return 1
            end

            if command == "race leave" then
                if raceState.participants[playerID] then
                    raceState.participants[playerID] = nil
                    MP.SendChatMessage(playerID, "You left the race!")
                else
                    MP.SendChatMessage(playerID, "You are not in the race!")
                end
                return 1
            end

            if string.sub(command, 1, 17) == "race leaderboard" then
                raceLeaderboard(playerID)
                return 1
            end

            if isAdmin(playerID) then
                if string.sub(command, 1, 13) == "race setstart" then
                    local posStr = string.match(command, "race setstart%s+(.+)")
                    if posStr then
                        if raceSetStartGate(posStr) then
                            MP.SendChatMessage(playerID, "Start gate set at: " .. posStr)
                            MP.SendChatMessage(-1, "Race start gate has been set!")
                        else
                            MP.SendChatMessage(playerID, "Invalid position format. Use: x,y,z or x,y,z,radius")
                        end
                    else
                        local pos = playerPositions[playerID]
                        if pos and raceSetStartFromPosition(pos) then
                            MP.SendChatMessage(playerID, "Start gate set at your current position")
                            MP.SendChatMessage(-1, "Race start gate has been set!")
                        else
                            MP.SendChatMessage(playerID, "Position not available. Spawn a vehicle and try again.")
                        end
                    end
                    return 1
                end

                if string.sub(command, 1, 11) == "race setend" then
                    local posStr = string.match(command, "race setend%s+(.+)")
                    if posStr then
                        if raceSetEndGate(posStr) then
                            MP.SendChatMessage(playerID, "End gate set at: " .. posStr)
                            MP.SendChatMessage(-1, "Race finish line has been set!")
                        else
                            MP.SendChatMessage(playerID, "Invalid position format. Use: x,y,z or x,y,z,radius")
                        end
                    else
                        local pos = playerPositions[playerID]
                        if pos and raceSetEndFromPosition(pos) then
                            MP.SendChatMessage(playerID, "End gate set at your current position")
                            MP.SendChatMessage(-1, "Race finish line has been set!")
                        else
                            MP.SendChatMessage(playerID, "Position not available. Spawn a vehicle and try again.")
                        end
                    end
                    return 1
                end

                if command == "race start" then
                    local success, msg = raceStartCountdown()
                    MP.SendChatMessage(playerID, msg)
                    return 1
                end

                if command == "race countdown" then
                    if raceState.status == "countdown" then
                        raceState.countdownTime = raceState.countdownTime - 1
                        if raceState.countdownTime > 0 then
                            MP.SendChatMessage(-1, "COUNTDOWN: " .. raceState.countdownTime .. "...")
                            MP.SendChatMessage(-1, "FREEZE! Don't move until GO!")
                            MP.SendChatMessage(playerID, "Countdown progressed. Use /race countdown again for next count.")
                        else
                            raceState.status = "racing"
                            raceState.raceStartTime = os.clock()
                            MP.SendChatMessage(-1, "========================================")
                            MP.SendChatMessage(-1, "GO! GO! GO!")
                            MP.SendChatMessage(-1, "========================================")
                            MP.SendChatMessage(playerID, "Race has begun!")
                        end
                    elseif raceState.status == "idle" then
                        MP.SendChatMessage(playerID, "No countdown in progress. Use /race start first.")
                    else
                        MP.SendChatMessage(playerID, "Race is already running!")
                    end
                    return 1
                end

                if string.sub(command, 1, 11) == "race finish" then
                    if raceState.status ~= "racing" then
                        MP.SendChatMessage(playerID, "No race in progress!")
                        return 1
                    end

                    local args = string.match(command, "race finish%s+(.+)")
                    if args then
                        local lastSpace = args:match("^.*()%s")
                        if lastSpace then
                            local targetName = args:sub(1, lastSpace - 1)
                            local timeStr = args:sub(lastSpace + 1)
                            local finishTime = tonumber(timeStr)
                            if finishTime then
                                local foundPlayerID = nil
                                for pID, data in pairs(raceState.participants) do
                                    if data.name == targetName then
                                        foundPlayerID = pID
                                        break
                                    end
                                end
                                if foundPlayerID and not raceState.participants[foundPlayerID].finishTime then
                                    raceState.participants[foundPlayerID].finishTime = finishTime
                                    table.insert(raceState.finishedPlayers, {
                                        name = targetName,
                                        time = finishTime,
                                        position = #raceState.finishedPlayers + 1
                                    })
                                    MP.SendChatMessage(-1, targetName .. " finished in position #" .. #raceState.finishedPlayers .. "! Time: " .. string.format("%.2f", finishTime) .. "s")
                                else
                                    MP.SendChatMessage(playerID, "Player not found or already finished!")
                                end
                            else
                                MP.SendChatMessage(playerID, "Invalid time format!")
                            end
                        else
                            MP.SendChatMessage(playerID, "Usage: /race finish [playerName] [time]")
                        end
                    else
                        MP.SendChatMessage(playerID, "Usage: /race finish [playerName] [time]")
                    end
                    return 1
                end

                if command == "race stop" then
                    raceStop()
                    MP.SendChatMessage(playerID, "Race stopped and reset!")
                    return 1
                end
            end
        end

        -- Derby commands
        if command == "derbyhelp" then
            MP.SendChatMessage(playerID, "=== Demolition Derby Commands ===")
            MP.SendChatMessage(playerID, "/derbyhelp - Show this help message")
            MP.SendChatMessage(playerID, "/derbystatus - Show current event status")
            if isAdmin(playerID) then
                MP.SendChatMessage(playerID, "/startevent derby - Start a demolition derby event")
                MP.SendChatMessage(playerID, "/stopevent - Stop the current event")
            end
            return 1
        end

        if command == "derbystatus" then
            if derbyState == DERBY_IDLE then
                MP.SendChatMessage(playerID, "[DERBY] No event is currently running")
            elseif derbyState == DERBY_RUNNING then
                MP.SendChatMessage(playerID, "[DERBY] Event is running - " .. derbyActiveCount() .. " players remaining")
            else
                MP.SendChatMessage(playerID, "[DERBY] Event is ending...")
            end
            return 1
        end

        -- Drift commands
        if command == "driftstatus" then
            if not driftEvent.active then
                MP.SendChatMessage(playerID, "No drift event is currently running")
            else
                local remaining = driftRemainingTime()
                MP.SendChatMessage(playerID, "Drift event is active!")
                MP.SendChatMessage(playerID, "Time remaining: " .. driftFormatTime(remaining))
                if driftStats[playerID] then
                    local stats = driftStats[playerID]
                    MP.SendChatMessage(playerID, string.format("Your score: %.0f points (%.1fs drift)", stats.totalScore, stats.driftTime))
                else
                    MP.SendChatMessage(playerID, "You haven't scored any points yet")
                end
            end
            return 1
        end

        if command == "driftleaderboard" or command == "driftlb" then
            if not driftEvent.active then
                MP.SendChatMessage(playerID, "No drift event is currently running")
                return 1
            end
            local leaderboard = {}
            for pID, stats in pairs(driftStats) do
                local pName = MP.GetPlayerName(pID)
                if pName then
                    table.insert(leaderboard, {id = pID, name = pName, score = stats.totalScore, driftTime = stats.driftTime})
                end
            end
            table.sort(leaderboard, function(a, b) return a.score > b.score end)
            MP.SendChatMessage(playerID, "=== CURRENT LEADERBOARD ===")
            if #leaderboard == 0 then
                MP.SendChatMessage(playerID, "No scores yet")
            else
                for i, entry in ipairs(leaderboard) do
                    if i <= 5 then
                        MP.SendChatMessage(playerID, string.format("#%d: %s - %.0f pts", i, entry.name, entry.score))
                    end
                end
            end
            return 1
        end

        if command == "drifthelp" then
            MP.SendChatMessage(playerID, "=== DRIFT EVENT COMMANDS ===")
            MP.SendChatMessage(playerID, "/driftstatus - Check event status and your score")
            MP.SendChatMessage(playerID, "/driftleaderboard (or /driftlb) - Show current rankings")
            MP.SendChatMessage(playerID, "/drifthelp - Show this help message")
            if isAdmin(playerID) then
                MP.SendChatMessage(playerID, "=== ADMIN COMMANDS ===")
                MP.SendChatMessage(playerID, "/startevent drift [seconds] - Start event (default: 300s)")
                MP.SendChatMessage(playerID, "/stopevent - End event early")
            end
            return 1
        end

        -- Drag commands
        if string.sub(command, 1, 4) == "drag" then
            if string.sub(command, 1, 4) == "drag" and not dragState.active then
                MP.SendChatMessage(playerID, "Drag event is not active. Use /startevent drag to begin.")
                return 1
            end

            if command == "drag" or command == "drag help" then
                MP.SendChatMessage(playerID, "=== Drag Race Commands ===")
                MP.SendChatMessage(playerID, "/drag join - Join the drag race")
                MP.SendChatMessage(playerID, "/drag leave - Leave the drag race")
                MP.SendChatMessage(playerID, "/drag ready - Ready up for the start")
                MP.SendChatMessage(playerID, "/drag status - Show drag status")
                if isAdmin(playerID) then
                    MP.SendChatMessage(playerID, "=== Admin Commands ===")
                    MP.SendChatMessage(playerID, "/startevent drag - Activate the drag event")
                    MP.SendChatMessage(playerID, "/drag setstart x,y,z[,radius] - Set start gate")
                    MP.SendChatMessage(playerID, "/drag setend x,y,z[,radius] - Set end gate")
                    MP.SendChatMessage(playerID, "/stopevent - End the drag event")
                end
                return 1
            end

            if command == "drag join" then
                if dragState.countdown or dragState.racing then
                    MP.SendChatMessage(playerID, "Drag race is already starting or running. Wait for the next round.")
                    return 1
                end
                dragState.participants[playerID] = {name = playerName, ready = false, finishTime = nil}
                MP.SendChatMessage(playerID, "You joined the drag race. Use /drag ready when ready.")
                MP.SendChatMessage(-1, "[DRAG] " .. playerName .. " joined the drag race.")
                MP.TriggerClientEvent(playerID, "DragSetActive", "")
                return 1
            end

            if command == "drag leave" then
                dragRemoveParticipant(playerID)
                MP.SendChatMessage(playerID, "You left the drag race.")
                return 1
            end

            if command == "drag ready" then
                if not dragState.participants[playerID] then
                    MP.SendChatMessage(playerID, "You are not in the drag race. Use /drag join first.")
                    return 1
                end
                if not dragState.startGate then
                    MP.SendChatMessage(playerID, "Start gate is not set. Ask an admin to set it.")
                    return 1
                end
                local pos = dragPositions[playerID]
                if not pos then
                    MP.SendChatMessage(playerID, "Position not available yet. Wait a moment and try again.")
                    return 1
                end
                if not dragInGate(pos, dragState.startGate) then
                    MP.SendChatMessage(playerID, "You must be inside the start gate to ready up.")
                    return 1
                end
                dragState.participants[playerID].ready = true
                local total, ready = dragCounts()
                MP.SendChatMessage(-1, "[DRAG] " .. playerName .. " is ready (" .. ready .. "/" .. total .. ")")
                if dragAllReady() then
                    dragStartCountdown()
                end
                return 1
            end

            if command == "drag status" then
                local total, ready = dragCounts()
                local status = "inactive"
                if dragState.countdown then status = "countdown"
                elseif dragState.racing then status = "racing"
                elseif dragState.active then status = "active" end
                MP.SendChatMessage(playerID, "[DRAG] Status: " .. status)
                MP.SendChatMessage(playerID, "[DRAG] Racers: " .. ready .. "/" .. total .. " ready")
                MP.SendChatMessage(playerID, "[DRAG] Start gate: " .. (dragState.startGate and "set" or "not set"))
                MP.SendChatMessage(playerID, "[DRAG] End gate: " .. (dragState.endGate and "set" or "not set"))
                return 1
            end

            if isAdmin(playerID) then
                if string.sub(command, 1, 13) == "drag setstart" then
                    local posStr = string.match(command, "drag setstart%s+(.+)")
                    if posStr then
                        local gate = dragParsePosition(posStr, true)
                        if gate then
                            dragState.startGate = gate
                            MP.SendChatMessage(playerID, "Start gate set.")
                            MP.SendChatMessage(-1, "[DRAG] Start gate set by admin.")
                        else
                            MP.SendChatMessage(playerID, "Invalid position format. Use x,y,z or x,y,z,radius")
                        end
                    else
                        MP.SendChatMessage(playerID, "Usage: /drag setstart x,y,z[,radius]")
                    end
                    return 1
                end

                if string.sub(command, 1, 11) == "drag setend" then
                    local posStr = string.match(command, "drag setend%s+(.+)")
                    if posStr then
                        local gate = dragParsePosition(posStr, true)
                        if gate then
                            dragState.endGate = gate
                            MP.SendChatMessage(playerID, "End gate set.")
                            MP.SendChatMessage(-1, "[DRAG] End gate set by admin.")
                        else
                            MP.SendChatMessage(playerID, "Invalid position format. Use x,y,z or x,y,z,radius")
                        end
                    else
                        MP.SendChatMessage(playerID, "Usage: /drag setend x,y,z[,radius]")
                    end
                    return 1
                end
            end
        end

        -- Admin-only commands: /startevent and /stopevent
        if isAdmin(playerID) then
            if string.match(command, "^startevent%s") or command == "startevent" then
                local eventName, params = string.match(command, "^startevent%s+(%S+)%s*(.*)$")
                if eventName then
                    local success, msg = startEvent(eventName, params or "")
                    MP.SendChatMessage(playerID, msg)
                    if success then
                        MP.SendChatMessage(-1, "[SERVER] Admin started event: " .. eventName)
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /startevent [event_name]")
                    MP.SendChatMessage(playerID, "Use /events to see available events")
                end
                return 1
            end

            if command == "stopevent" then
                local success, msg = stopEvent()
                MP.SendChatMessage(playerID, msg)
                if success then
                    MP.SendChatMessage(-1, "[SERVER] Admin stopped the event")
                end
                return 1
            end
        else
            if string.match(command, "^startevent") or command == "stopevent" then
                MP.SendChatMessage(playerID, "You don't have permission to use this command")
                return 1
            end
        end
    end

    return 0
end

-- ============================================================================
-- EVENT LOOP / HANDLERS
-- ============================================================================

function onInit()
    print("[EventManager] Plugin loaded successfully!")

    RegisterEvent("race", raceEvent)
    RegisterEvent("derby", derbyEvent)
    RegisterEvent("drift", driftEventDef)
    RegisterEvent("drag", dragEvent)
    RegisterEvent("freeroam", freeRoamEvent)
    RegisterEvent("timetrial", timeTrialEvent)
    RegisterEvent("tag", tagEvent)
    RegisterEvent("convoy", convoyEvent)
    RegisterEvent("policechase", policeChaseEvent)
    RegisterEvent("carshow", carShowEvent)

    print("[EventManager] Registered " .. eventCount .. " events")
    print("[EventManager] Use /events to list available events")

    if raceState.startGate then
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", raceState.startGate.x, raceState.startGate.y, raceState.startGate.z, raceState.startGate.radius)
        broadcastClientEvent("RaceGateSetStart", payload)
    end
    if raceState.endGate then
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", raceState.endGate.x, raceState.endGate.y, raceState.endGate.z, raceState.endGate.radius)
        broadcastClientEvent("RaceGateSetEnd", payload)
    end
end

function onPlayerJoin(playerID)
    driftInitStats(playerID)

    if driftEvent.active then
        local remaining = driftRemainingTime()
        MP.SendChatMessage(playerID, "A drift event is currently running!")
        MP.SendChatMessage(playerID, "Time remaining: " .. driftFormatTime(remaining))
        MP.SendChatMessage(playerID, "Type /drifthelp for commands")
    end

    if raceState.startGate then
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", raceState.startGate.x, raceState.startGate.y, raceState.startGate.z, raceState.startGate.radius)
        MP.TriggerClientEvent(playerID, "RaceGateSetStart", payload)
    end
    if raceState.endGate then
        local payload = string.format("%.3f,%.3f,%.3f,%.3f", raceState.endGate.x, raceState.endGate.y, raceState.endGate.z, raceState.endGate.radius)
        MP.TriggerClientEvent(playerID, "RaceGateSetEnd", payload)
    end
end

function onPlayerDisconnect(playerID)
    if raceState.participants[playerID] then
        raceState.participants[playerID] = nil
    end
    playerPositions[playerID] = nil

    if dragState.participants[playerID] then
        dragRemoveParticipant(playerID)
    end
    dragPositions[playerID] = nil

    if derbyState == DERBY_RUNNING and derbyParticipants[playerID] and not derbyParticipants[playerID].eliminated then
        derbyEliminate(playerID)
    end
end

function onVehicleSpawn(playerID, vehicleID, vehicleData)
    if raceState.participants[playerID] then
        raceState.participants[playerID].vehicleID = vehicleID
    end

    if not playerPositions[playerID] then
        playerPositions[playerID] = {x = 0, y = 0, z = 0}
    end

    if vehicleData and type(vehicleData) == "string" then
        local x, y, z = string.match(vehicleData, '"pos":%[([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%]')
        if x and y and z then
            playerPositions[playerID] = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
        end
    end

    if driftEvent.active then
        driftInitStats(playerID)
    end
end

function onVehicleReset(playerID, vehicleID)
    if derbyState == DERBY_RUNNING and derbyParticipants[playerID] and not derbyParticipants[playerID].eliminated then
        MP.SendChatMessage(playerID, "[DEMOLITION DERBY] Vehicle resets are disabled during the event!")
        return 1
    end
    return 0
end

function onDerbyPositionUpdate(playerID, data)
    derbyOnPositionUpdate(playerID, data)
end

function onDragPositionUpdate(playerID, data)
    if not dragState.active then return end
    if not dragState.participants[playerID] then return end

    local x, y, z = string.match(data, "([^,]+),([^,]+),([^,]+)")
    if not x or not y or not z then return end

    dragPositions[playerID] = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}

    if dragState.racing and dragState.participants[playerID].finishTime == nil then
        if dragInGate(dragPositions[playerID], dragState.endGate) then
            local elapsed = os.clock() - dragState.raceStartTime
            dragState.participants[playerID].finishTime = elapsed
            MP.SendChatMessage(-1, string.format("[DRAG] %s finished in %.2fs", dragState.participants[playerID].name, elapsed))
        end
    end
end

function onDriftTelemetry(playerID, data)
    -- Expected data format: "isDrifting,angle,speed,proximity"
    local isDriftingStr, angleStr, speedStr, proxStr = string.match(data, "([^,]+),([^,]+),([^,]+),([^,]+)")
    if not isDriftingStr then return end
    local isDrifting = isDriftingStr == "1" or isDriftingStr == "true"
    local angle = tonumber(angleStr) or 0
    local speed = tonumber(speedStr) or 0
    local proximity = tonumber(proxStr) or 0
    driftUpdate(playerID, isDrifting, angle, speed, proximity)
end

function onTick()
    derbyCheckPositions()

    if dragState.countdown then
        local now = os.time()
        if now > dragState.lastCountdownTick then
            dragState.lastCountdownTick = now
            dragState.countdownTime = dragState.countdownTime - 1
            if dragState.countdownTime > 0 then
                MP.SendChatMessage(-1, "[DRAG] COUNTDOWN: " .. dragState.countdownTime .. "...")
            else
                dragStartRace()
            end
        end
    end

    driftCheckTimer()
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
MP.RegisterEvent("onVehicleReset", "onVehicleReset")
MP.RegisterEvent("DerbyPositionUpdate", "onDerbyPositionUpdate")
MP.RegisterEvent("DragPositionUpdate", "onDragPositionUpdate")
MP.RegisterEvent("DriftTelemetry", "onDriftTelemetry")
MP.RegisterEvent("onTick", "onTick")

-- Export helpers
_G.RegisterEvent = RegisterEvent
_G.GetActiveEventName = function()
    if activeEvent then
        return activeEvent.name
    end
    return nil
end
_G.IsEventActive = function(eventName)
    return activeEvent ~= nil and activeEvent.name == eventName
end
