-- DragRace Plugin
-- Drag racing event with staging, ready checks, and countdown locks

-- List of admin player IDs (add your admin IDs here)
local admins = {
    -- Example: "12345", "67890"
}

-- Configuration
local DEFAULT_COUNTDOWN = 3
local POSITION_UPDATE_INTERVAL = 0.2

-- Drag race state
local dragState = {
    active = false,
    countdown = false,
    racing = false,
    countdownTime = DEFAULT_COUNTDOWN,
    lastCountdownTick = 0,
    startGate = nil, -- {x, y, z, radius}
    endGate = nil,   -- {x, y, z, radius}
    participants = {}, -- [playerID] = {name, ready, finishTime}
    raceStartTime = 0
}

-- Player position cache
local playerPositions = {}

-- Helper: check if player is admin
local function isAdmin(playerID)
    local playerIDStr = tostring(playerID)
    for _, adminID in ipairs(admins) do
        if adminID == playerIDStr then
            return true
        end
    end
    return false
end

-- Helper: parse position from "x,y,z" or "x,y,z,radius"
local function parsePosition(posStr, includeRadius)
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

-- Helper: distance check
local function isInGate(pos, gate)
    if not pos or not gate then return false end
    local dx = pos.x - gate.x
    local dy = pos.y - gate.y
    local dz = pos.z - gate.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    return dist <= gate.radius
end

-- Helper: count participants and ready
local function getCounts()
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

local function allReady()
    local total, ready = getCounts()
    if total == 0 or ready ~= total or not dragState.startGate or not dragState.endGate then
        return false
    end

    for playerID, data in pairs(dragState.participants) do
        if data.ready then
            local pos = playerPositions[playerID]
            if not pos or not isInGate(pos, dragState.startGate) then
                return false
            end
        end
    end

    return true
end

local function broadcastToParticipants(eventName, data)
    for playerID, _ in pairs(dragState.participants) do
        MP.TriggerClientEvent(playerID, eventName, data or "")
    end
end

local function resetRaceState()
    dragState.countdown = false
    dragState.racing = false
    dragState.countdownTime = DEFAULT_COUNTDOWN
    dragState.lastCountdownTick = 0
    dragState.raceStartTime = 0
end

-- Start countdown when all ready
local function startCountdown()
    if dragState.countdown or dragState.racing then
        return
    end

    dragState.countdown = true
    dragState.countdownTime = DEFAULT_COUNTDOWN
    dragState.lastCountdownTick = os.time()

    MP.SendChatMessage(-1, "[DRAG] All racers are ready. Countdown starting!")
    broadcastToParticipants("DragLock", "")
    MP.SendChatMessage(-1, "[DRAG] COUNTDOWN: " .. dragState.countdownTime .. "...")
end

local function startRace()
    dragState.countdown = false
    dragState.racing = true
    dragState.raceStartTime = os.clock()

    for playerID, data in pairs(dragState.participants) do
        data.finishTime = nil
        data.ready = false
    end

    MP.SendChatMessage(-1, "[DRAG] GO! Drag race started!")
    broadcastToParticipants("DragUnlock", "")
end

local function stopRace()
    if dragState.racing or dragState.countdown then
        broadcastToParticipants("DragUnlock", "")
    end
    resetRaceState()
end

local function removeParticipant(playerID)
    if dragState.participants[playerID] then
        dragState.participants[playerID] = nil
        MP.TriggerClientEvent(playerID, "DragSetInactive", "")

        if dragState.countdown and not allReady() then
            MP.SendChatMessage(-1, "[DRAG] Countdown cancelled. Waiting for all racers to ready up.")
            broadcastToParticipants("DragUnlock", "")
            resetRaceState()
        end
    end
end

-- EventManager event definition
local dragEvent = {
    name = "drag",
    description = "Drag race with staging, ready checks, and countdown lock",
    onStart = function(params)
        if dragState.active then
            return false
        end

        dragState.active = true
        resetRaceState()
        dragState.participants = {}

        MP.SendChatMessage(-1, "[DRAG] Drag race event is now active! Use /drag join to participate.")
        return true
    end,
    onStop = function()
        if not dragState.active then
            return false
        end

        dragState.active = false
        stopRace()

        for playerID, _ in pairs(dragState.participants) do
            MP.TriggerClientEvent(playerID, "DragSetInactive", "")
        end

        dragState.participants = {}
        MP.SendChatMessage(-1, "[DRAG] Drag race event ended.")
        return true
    end
}

-- Chat commands
function onChatMessage(playerID, playerName, message)
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))

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

            dragState.participants[playerID] = {
                name = playerName,
                ready = false,
                finishTime = nil
            }
            MP.SendChatMessage(playerID, "You joined the drag race. Use /drag ready when ready.")
            MP.SendChatMessage(-1, "[DRAG] " .. playerName .. " joined the drag race.")
            MP.TriggerClientEvent(playerID, "DragSetActive", "")
            return 1
        end

        if command == "drag leave" then
            removeParticipant(playerID)
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

            local pos = playerPositions[playerID]
            if not pos then
                MP.SendChatMessage(playerID, "Position not available yet. Wait a moment and try again.")
                return 1
            end

            if not isInGate(pos, dragState.startGate) then
                MP.SendChatMessage(playerID, "You must be inside the start gate to ready up.")
                return 1
            end

            dragState.participants[playerID].ready = true
            local total, ready = getCounts()
            MP.SendChatMessage(-1, "[DRAG] " .. playerName .. " is ready (" .. ready .. "/" .. total .. ")")

            if allReady() then
                startCountdown()
            end
            return 1
        end

        if command == "drag status" then
            local total, ready = getCounts()
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
                    local gate = parsePosition(posStr, true)
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
                    local gate = parsePosition(posStr, true)
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

    return 0
end

-- Position updates from clients
function onDragPositionUpdate(playerID, data)
    if not dragState.active then return end
    if not dragState.participants[playerID] then return end

    local x, y, z = string.match(data, "([^,]+),([^,]+),([^,]+)")
    if not x or not y or not z then return end

    playerPositions[playerID] = {
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z)
    }

    if dragState.racing and dragState.participants[playerID].finishTime == nil then
        if isInGate(playerPositions[playerID], dragState.endGate) then
            local elapsed = os.clock() - dragState.raceStartTime
            dragState.participants[playerID].finishTime = elapsed
            MP.SendChatMessage(-1, string.format("[DRAG] %s finished in %.2fs", dragState.participants[playerID].name, elapsed))
        end
    end
end

-- Countdown tick
function onTick()
    if dragState.countdown then
        local now = os.time()
        if now > dragState.lastCountdownTick then
            dragState.lastCountdownTick = now
            dragState.countdownTime = dragState.countdownTime - 1
            if dragState.countdownTime > 0 then
                MP.SendChatMessage(-1, "[DRAG] COUNTDOWN: " .. dragState.countdownTime .. "...")
            else
                startRace()
            end
        end
    end
end

-- Cleanup on disconnect
function onPlayerDisconnect(playerID)
    removeParticipant(playerID)
    playerPositions[playerID] = nil
end

function onInit()
    print("[DragRace] Plugin loaded successfully!")

    if RegisterEvent then
        RegisterEvent("drag", dragEvent)
        print("[DragRace] Registered drag event with EventManager")
    else
        print("[DragRace] WARNING: EventManager not found. Drag event not registered")
    end
end

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("DragPositionUpdate", "onDragPositionUpdate")
MP.RegisterEvent("onTick", "onTick")
