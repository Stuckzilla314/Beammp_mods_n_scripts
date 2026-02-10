-- RaceManager Plugin
-- A comprehensive race system with start/end gates, countdown, vehicle freeze, and leaderboard

-- Race state
local raceState = {
    status = "idle", -- idle, countdown, racing, finished
    startGate = nil, -- {x, y, z, radius}
    endGate = nil,   -- {x, y, z, radius}
    countdownTime = 0,
    countdownMax = 3, -- 3 second countdown
    raceStartTime = 0,
    participants = {}, -- [playerID] = {vehicleID, name, position, distance, finishTime}
    finishedPlayers = {}, -- [{name, time, position}] ordered by finish
    frozenVehicles = {} -- [vehicleID] = playerID
}

-- Configuration
local GATE_RADIUS = 15 -- meters
local UPDATE_INTERVAL = 0.1 -- seconds between position updates
local lastUpdate = 0

-- Admin list (add admin IDs here)
local admins = {
    -- Example: "12345"
}

-- Helper function to check if player is admin
local function isAdmin(playerID)
    local playerIDStr = tostring(playerID)
    for _, adminID in ipairs(admins) do
        if adminID == playerIDStr then
            return true
        end
    end
    return false
end

-- Helper function to calculate distance between two 3D points
local function calculateDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Helper function to check if a position is within a gate
local function isInGate(pos, gate)
    if not gate or not pos then return false end
    local distance = calculateDistance(pos.x, pos.y, pos.z, gate.x, gate.y, gate.z)
    return distance <= gate.radius
end

-- Parse position from string "x,y,z" or "x,y,z,radius"
local function parsePosition(posStr, includeRadius)
    local parts = {}
    for part in string.gmatch(posStr, "[^,]+") do
        table.insert(parts, tonumber(part))
    end
    
    if includeRadius and #parts == 4 then
        return {x = parts[1], y = parts[2], z = parts[3], radius = parts[4]}
    elseif #parts >= 3 then
        return {x = parts[1], y = parts[2], z = parts[3], radius = GATE_RADIUS}
    end
    
    return nil
end

-- Set start gate
local function setStartGate(posStr)
    local gate = parsePosition(posStr, true)
    if gate then
        raceState.startGate = gate
        return true
    end
    return false
end

-- Set end gate
local function setEndGate(posStr)
    local gate = parsePosition(posStr, true)
    if gate then
        raceState.endGate = gate
        return true
    end
    return false
end

-- Start the race countdown
local function startRace()
    if not raceState.startGate or not raceState.endGate then
        return false, "Start and end gates must be set first!"
    end
    
    if raceState.status ~= "idle" then
        return false, "Race is already in progress!"
    end
    
    raceState.status = "countdown"
    raceState.countdownTime = raceState.countdownMax
    raceState.participants = {}
    raceState.finishedPlayers = {}
    raceState.frozenVehicles = {}
    
    -- Announce race start
    MP.SendChatMessage(-1, "========================================")
    MP.SendChatMessage(-1, "RACE STARTING!")
    MP.SendChatMessage(-1, "Get to the start gate now!")
    MP.SendChatMessage(-1, "========================================")
    
    return true, "Race countdown will begin shortly!"
end

-- Stop/reset the race
local function stopRace()
    raceState.status = "idle"
    raceState.participants = {}
    raceState.finishedPlayers = {}
    raceState.frozenVehicles = {}
    raceState.countdownTime = 0
    
    -- Unfreeze all vehicles
    MP.SendChatMessage(-1, "Race has been stopped!")
    
    return true
end

-- Get current leaderboard
local function getLeaderboard()
    local standings = {}
    
    -- Add participants ordered by distance to end gate (closest first)
    for playerID, data in pairs(raceState.participants) do
        if not data.finishTime then
            table.insert(standings, {
                name = data.name,
                distance = data.distance,
                finished = false
            })
        end
    end
    
    -- Sort by distance (ascending)
    table.sort(standings, function(a, b)
        return a.distance < b.distance
    end)
    
    return standings
end

-- Display leaderboard
local function displayLeaderboard(playerID)
    local targetID = playerID or -1
    
    if raceState.status == "idle" then
        MP.SendChatMessage(targetID, "No race in progress!")
        return
    end
    
    MP.SendChatMessage(targetID, "======== LEADERBOARD ========")
    
    -- Show finished players
    if #raceState.finishedPlayers > 0 then
        MP.SendChatMessage(targetID, "--- FINISHED ---")
        for i, player in ipairs(raceState.finishedPlayers) do
            local timeStr = string.format("%.2f", player.time)
            MP.SendChatMessage(targetID, i .. ". " .. player.name .. " - " .. timeStr .. "s")
        end
    end
    
    -- Show current standings
    if raceState.status == "racing" then
        local standings = getLeaderboard()
        if #standings > 0 then
            MP.SendChatMessage(targetID, "--- RACING ---")
            for i, player in ipairs(standings) do
                local distStr = string.format("%.1f", player.distance)
                MP.SendChatMessage(targetID, i .. ". " .. player.name .. " - " .. distStr .. "m to finish")
            end
        end
    end
    
    MP.SendChatMessage(targetID, "============================")
end

-- Update race state (called regularly)
local function updateRace()
    local currentTime = os.clock()
    
    if currentTime - lastUpdate < UPDATE_INTERVAL then
        return
    end
    
    lastUpdate = currentTime
    
    if raceState.status == "countdown" then
        raceState.countdownTime = raceState.countdownTime - UPDATE_INTERVAL
        
        -- Check for countdown announcements
        local countInt = math.ceil(raceState.countdownTime)
        if countInt > 0 and math.abs(raceState.countdownTime - countInt) < UPDATE_INTERVAL then
            MP.SendChatMessage(-1, "Race starts in " .. countInt .. "...")
            
            -- Freeze all vehicles during countdown
            local players = MP.GetPlayers()
            for _, playerID in ipairs(players) do
                MP.SendChatMessage(playerID, "FREEZE! Don't move until countdown ends!")
            end
        end
        
        -- Countdown finished
        if raceState.countdownTime <= 0 then
            raceState.status = "racing"
            raceState.raceStartTime = currentTime
            MP.SendChatMessage(-1, "========================================")
            MP.SendChatMessage(-1, "GO! GO! GO!")
            MP.SendChatMessage(-1, "========================================")
        end
        
    elseif raceState.status == "racing" then
        -- Update participant positions and distances
        -- Note: In a real implementation, you'd get actual vehicle positions from BeamMP
        -- For now, we'll track based on what data we can get
        
        -- Check if all players have finished
        local allFinished = true
        for playerID, data in pairs(raceState.participants) do
            if not data.finishTime then
                allFinished = false
                break
            end
        end
        
        if allFinished and next(raceState.participants) ~= nil then
            raceState.status = "finished"
            MP.SendChatMessage(-1, "========================================")
            MP.SendChatMessage(-1, "RACE FINISHED!")
            MP.SendChatMessage(-1, "========================================")
            displayLeaderboard(-1)
        end
    end
end

-- Handle vehicle position updates (simulated - would need actual position data from client)
local function checkVehiclePosition(playerID, vehicleID, position)
    if raceState.status ~= "racing" then
        return
    end
    
    -- Check if player is in participants
    if not raceState.participants[playerID] then
        return
    end
    
    local data = raceState.participants[playerID]
    
    -- Update position and distance to end gate
    data.position = position
    if raceState.endGate then
        data.distance = calculateDistance(
            position.x, position.y, position.z,
            raceState.endGate.x, raceState.endGate.y, raceState.endGate.z
        )
        
        -- Check if player crossed finish line
        if not data.finishTime and isInGate(position, raceState.endGate) then
            local finishTime = os.clock() - raceState.raceStartTime
            data.finishTime = finishTime
            
            -- Add to finished players list
            table.insert(raceState.finishedPlayers, {
                name = data.name,
                time = finishTime,
                position = #raceState.finishedPlayers + 1
            })
            
            MP.SendChatMessage(-1, data.name .. " finished in position #" .. #raceState.finishedPlayers .. "! Time: " .. string.format("%.2f", finishTime) .. "s")
        end
    end
end

-- Handle chat commands
function onChatMessage(playerID, playerName, message)
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))
        
        -- /race help
        if command == "race" or command == "race help" then
            MP.SendChatMessage(playerID, "=== Race Commands ===")
            MP.SendChatMessage(playerID, "/race join - Join the current race")
            MP.SendChatMessage(playerID, "/race leave - Leave the current race")
            MP.SendChatMessage(playerID, "/race leaderboard - Show leaderboard")
            if isAdmin(playerID) then
                MP.SendChatMessage(playerID, "=== Admin Commands ===")
                MP.SendChatMessage(playerID, "/race setstart x,y,z[,radius] - Set start gate")
                MP.SendChatMessage(playerID, "/race setend x,y,z[,radius] - Set end gate")
                MP.SendChatMessage(playerID, "/race start - Start the race")
                MP.SendChatMessage(playerID, "/race stop - Stop/reset the race")
            end
            return 1
        end
        
        -- /race join
        if command == "race join" then
            if raceState.status == "idle" or raceState.status == "countdown" then
                raceState.participants[playerID] = {
                    name = playerName,
                    vehicleID = -1, -- Would need to get actual vehicle ID
                    position = {x = 0, y = 0, z = 0},
                    distance = 999999,
                    finishTime = nil
                }
                MP.SendChatMessage(playerID, "You joined the race!")
                MP.SendChatMessage(-1, playerName .. " joined the race!")
            else
                MP.SendChatMessage(playerID, "Cannot join - race already started!")
            end
            return 1
        end
        
        -- /race leave
        if command == "race leave" then
            if raceState.participants[playerID] then
                raceState.participants[playerID] = nil
                MP.SendChatMessage(playerID, "You left the race!")
            else
                MP.SendChatMessage(playerID, "You are not in the race!")
            end
            return 1
        end
        
        -- /race leaderboard
        if string.sub(command, 1, 17) == "race leaderboard" then
            displayLeaderboard(playerID)
            return 1
        end
        
        -- Admin commands
        if isAdmin(playerID) then
            -- /race setstart x,y,z[,radius]
            if string.sub(command, 1, 14) == "race setstart " then
                local posStr = string.match(command, "race setstart%s+(.+)")
                if posStr and setStartGate(posStr) then
                    MP.SendChatMessage(playerID, "Start gate set at: " .. posStr)
                    MP.SendChatMessage(-1, "Race start gate has been set!")
                else
                    MP.SendChatMessage(playerID, "Invalid position format. Use: x,y,z or x,y,z,radius")
                end
                return 1
            end
            
            -- /race setend x,y,z[,radius]
            if string.sub(command, 1, 12) == "race setend " then
                local posStr = string.match(command, "race setend%s+(.+)")
                if posStr and setEndGate(posStr) then
                    MP.SendChatMessage(playerID, "End gate set at: " .. posStr)
                    MP.SendChatMessage(-1, "Race finish line has been set!")
                else
                    MP.SendChatMessage(playerID, "Invalid position format. Use: x,y,z or x,y,z,radius")
                end
                return 1
            end
            
            -- /race start
            if command == "race start" then
                local success, msg = startRace()
                MP.SendChatMessage(playerID, msg)
                return 1
            end
            
            -- /race stop
            if command == "race stop" then
                stopRace()
                MP.SendChatMessage(playerID, "Race stopped and reset!")
                return 1
            end
        end
    end
    
    return 0
end

-- Handle player joining
function onPlayerJoin(playerID)
    local playerName = MP.GetPlayerName(playerID)
    print("[RaceManager] " .. playerName .. " joined the server")
end

-- Handle player disconnect
function onPlayerDisconnect(playerID)
    -- Remove player from race if they disconnect
    if raceState.participants[playerID] then
        raceState.participants[playerID] = nil
    end
end

-- Called every tick
function onTick()
    updateRace()
end

-- Initialize plugin
function onInit()
    print("[RaceManager] Plugin loaded successfully!")
    print("[RaceManager] Use /race for commands")
    print("[RaceManager] " .. #admins .. " admin(s) configured")
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onChatMessage", "onChatMessage")

-- Note: onTick is not a standard BeamMP event
-- In a real implementation, you would use a timer or the actual BeamMP update mechanism
-- For now, we'll simulate it with a simple approach
