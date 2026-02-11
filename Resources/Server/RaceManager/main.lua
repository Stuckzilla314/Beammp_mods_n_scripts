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
    participants = {}, -- [playerID] = {vehicleID, name, finishTime}
    finishedPlayers = {} -- [{name, time, position}] ordered by finish
}

-- Configuration
local GATE_RADIUS = 15 -- meters

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
    
    -- Check if there are any participants
    if next(raceState.participants) == nil then
        return false, "No players have joined the race!"
    end
    
    raceState.status = "countdown"
    raceState.countdownTime = raceState.countdownMax
    raceState.finishedPlayers = {}
    
    -- Announce race start
    MP.SendChatMessage(-1, "========================================")
    MP.SendChatMessage(-1, "RACE STARTING!")
    MP.SendChatMessage(-1, "========================================")
    MP.SendChatMessage(-1, "COUNTDOWN: 3...")
    
    return true, "Race countdown started!"
end

-- Stop/reset the race
local function stopRace()
    raceState.status = "idle"
    raceState.participants = {}
    raceState.finishedPlayers = {}
    raceState.countdownTime = 0
    
    MP.SendChatMessage(-1, "Race has been stopped!")
    
    return true
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
    
    -- Show participants who haven't finished
    if raceState.status == "racing" or raceState.status == "countdown" then
        local unfinished = {}
        for playerID, data in pairs(raceState.participants) do
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
                MP.SendChatMessage(playerID, "/race start - Start the race countdown")
                MP.SendChatMessage(playerID, "/race countdown - Progress countdown (use 3x)")
                MP.SendChatMessage(playerID, "/race finish [player] [time] - Record finish")
                MP.SendChatMessage(playerID, "/race stop - Stop/reset the race")
            end
            return 1
        end
        
        -- /race join
        if command == "race join" then
            if raceState.status == "idle" or raceState.status == "countdown" then
                raceState.participants[playerID] = {
                    name = playerName,
                    vehicleID = -1, -- Will be updated when vehicle spawns
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
            
            -- /race countdown - Progress the countdown (manual trigger for each second)
            if command == "race countdown" then
                if raceState.status == "countdown" then
                    raceState.countdownTime = raceState.countdownTime - 1
                    if raceState.countdownTime > 0 then
                        MP.SendChatMessage(-1, "COUNTDOWN: " .. raceState.countdownTime .. "...")
                        MP.SendChatMessage(-1, "FREEZE! Don't move until GO!")
                        MP.SendChatMessage(playerID, "Countdown progressed. Use /race countdown again for next count.")
                    else
                        -- Start the race
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
            
            -- /race finish [playerName] [time] - Manually record a finish
            if string.sub(command, 1, 11) == "race finish" then
                if raceState.status ~= "racing" then
                    MP.SendChatMessage(playerID, "No race in progress!")
                    return 1
                end
                
                local playerName, timeStr = string.match(command, "race finish%s+(%S+)%s+(%S+)")
                if playerName and timeStr then
                    local finishTime = tonumber(timeStr)
                    if finishTime then
                        -- Find player in participants
                        local foundPlayerID = nil
                        for pID, data in pairs(raceState.participants) do
                            if data.name == playerName then
                                foundPlayerID = pID
                                break
                            end
                        end
                        
                        if foundPlayerID and not raceState.participants[foundPlayerID].finishTime then
                            raceState.participants[foundPlayerID].finishTime = finishTime
                            table.insert(raceState.finishedPlayers, {
                                name = playerName,
                                time = finishTime,
                                position = #raceState.finishedPlayers + 1
                            })
                            MP.SendChatMessage(-1, playerName .. " finished in position #" .. #raceState.finishedPlayers .. "! Time: " .. string.format("%.2f", finishTime) .. "s")
                        else
                            MP.SendChatMessage(playerID, "Player not found or already finished!")
                        end
                    else
                        MP.SendChatMessage(playerID, "Invalid time format!")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /race finish [playerName] [time]")
                end
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

-- Initialize plugin
function onInit()
    print("[RaceManager] Plugin loaded successfully!")
    print("[RaceManager] Use /race for commands")
    print("[RaceManager] " .. #admins .. " admin(s) configured")
end

-- Handle vehicle spawns to track vehicle IDs
function onVehicleSpawn(playerID, vehicleID, vehicleData)
    -- Update vehicle ID for participant if they're in the race
    if raceState.participants[playerID] then
        raceState.participants[playerID].vehicleID = vehicleID
    end
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
