-- DemolitionDerby Plugin
-- A demolition derby event script for BeamMP servers

-- Event states
local EVENT_IDLE = 0
local EVENT_RUNNING = 1
local EVENT_ENDED = 2

-- Event state
local eventState = EVENT_IDLE

-- Player data tracking
local participants = {}  -- playerID -> {eliminated = false, lastPosition = {x, y, z}, stationaryTime = 0}
local eliminatedPlayers = {}  -- Set of eliminated player IDs

-- Configuration
local STATIONARY_THRESHOLD = 5.0  -- Seconds a car must be stationary to be eliminated
local STATIONARY_DISTANCE = 2.0   -- Distance threshold in meters to consider a vehicle stationary
local CHECK_INTERVAL = 1.0        -- How often to check vehicle positions (seconds)

-- Admin list
local admins = {
    -- Add admin IDs here, e.g., "12345", "67890"
}

-- Timer tracking
local lastCheckTime = 0

-- Check if a player is an admin
local function isAdmin(playerID)
    local playerIDStr = tostring(playerID)
    for _, adminID in ipairs(admins) do
        if adminID == playerIDStr then
            return true
        end
    end
    return false
end

-- Calculate distance between two positions
local function calculateDistance(pos1, pos2)
    if not pos1 or not pos2 then
        return 0
    end
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Get active (non-eliminated) participant count
local function getActiveParticipantCount()
    local count = 0
    for playerID, data in pairs(participants) do
        if not data.eliminated then
            count = count + 1
        end
    end
    return count
end

-- Start the demolition derby event
local function startEvent()
    if eventState ~= EVENT_IDLE then
        return false, "Event is already running or has ended!"
    end
    
    -- Get all connected players
    local players = MP.GetPlayers()
    if not players or #players < 2 then
        return false, "Need at least 2 players to start the event!"
    end
    
    -- Initialize participants
    participants = {}
    eliminatedPlayers = {}
    
    for playerID, _ in pairs(players) do
        participants[playerID] = {
            eliminated = false,
            lastPosition = nil,
            stationaryTime = 0
        }
    end
    
    eventState = EVENT_RUNNING
    lastCheckTime = os.time()
    
    -- Announce event start
    MP.SendChatMessage(-1, "====================================")
    MP.SendChatMessage(-1, "[DEMOLITION DERBY] Event starting!")
    MP.SendChatMessage(-1, "Stay moving! Stationary cars for 5 seconds are eliminated!")
    MP.SendChatMessage(-1, "Vehicle resets, teleports, and node grabber are DISABLED!")
    MP.SendChatMessage(-1, "====================================")
    
    -- Send client event to disable features for all participants
    for playerID, _ in pairs(participants) do
        MP.TriggerClientEvent(playerID, "DerbyDisableFeatures", "")
    end
    
    return true, "Event started successfully!"
end

-- End the event and announce winner
local function endEvent(winnerID)
    if eventState ~= EVENT_RUNNING then
        return
    end
    
    eventState = EVENT_ENDED
    
    local winnerName = winnerID and MP.GetPlayerName(winnerID) or "Unknown"
    
    -- Announce winner
    MP.SendChatMessage(-1, "====================================")
    MP.SendChatMessage(-1, "[DEMOLITION DERBY] Event finished!")
    MP.SendChatMessage(-1, "Winner: " .. winnerName .. "!")
    MP.SendChatMessage(-1, "====================================")
    
    -- Re-enable features and reset vehicles for all players
    local players = MP.GetPlayers()
    for playerID, _ in pairs(players) do
        MP.TriggerClientEvent(playerID, "DerbyEnableFeatures", "")
        MP.TriggerClientEvent(playerID, "DerbyResetVehicle", "")
    end
    
    -- Reset state
    participants = {}
    eliminatedPlayers = {}
    eventState = EVENT_IDLE
end

-- Eliminate a player
local function eliminatePlayer(playerID)
    if participants[playerID] and not participants[playerID].eliminated then
        participants[playerID].eliminated = true
        eliminatedPlayers[playerID] = true
        
        local playerName = MP.GetPlayerName(playerID)
        MP.SendChatMessage(-1, "[DEMOLITION DERBY] " .. playerName .. " has been eliminated!")
        
        -- Check if only one player remains
        local activeCount = getActiveParticipantCount()
        if activeCount == 1 then
            -- Find the winner
            for pID, data in pairs(participants) do
                if not data.eliminated then
                    endEvent(pID)
                    return
                end
            end
        elseif activeCount == 0 then
            -- No winners (shouldn't happen, but handle it)
            endEvent(nil)
        end
    end
end

-- Check vehicle positions and eliminate stationary players
local function checkVehiclePositions()
    if eventState ~= EVENT_RUNNING then
        return
    end
    
    local currentTime = os.time()
    local deltaTime = currentTime - lastCheckTime
    
    if deltaTime < CHECK_INTERVAL then
        return
    end
    
    lastCheckTime = currentTime
    
    -- We need to track positions via client events since server doesn't have direct position access
    -- Request position updates from all active participants
    for playerID, data in pairs(participants) do
        if not data.eliminated then
            MP.TriggerClientEvent(playerID, "DerbyRequestPosition", "")
        end
    end
end

-- Handle position updates from clients
local function onPositionUpdate(playerID, data)
    if eventState ~= EVENT_RUNNING or not participants[playerID] or participants[playerID].eliminated then
        return
    end
    
    -- Parse position data (expected format: "x,y,z")
    local x, y, z = string.match(data, "([^,]+),([^,]+),([^,]+)")
    if not x or not y or not z then
        return
    end
    
    local currentPosition = {
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z)
    }
    
    local lastPosition = participants[playerID].lastPosition
    
    if lastPosition then
        local distance = calculateDistance(currentPosition, lastPosition)
        
        if distance < STATIONARY_DISTANCE then
            -- Vehicle is stationary, increment timer
            participants[playerID].stationaryTime = participants[playerID].stationaryTime + CHECK_INTERVAL
            
            if participants[playerID].stationaryTime >= STATIONARY_THRESHOLD then
                eliminatePlayer(playerID)
            end
        else
            -- Vehicle is moving, reset timer
            participants[playerID].stationaryTime = 0
        end
    end
    
    participants[playerID].lastPosition = currentPosition
end

-- Handle chat commands
function onChatMessage(playerID, playerName, message)
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))
        
        -- /startderby command
        if command == "startderby" then
            if not isAdmin(playerID) then
                MP.SendChatMessage(playerID, "You don't have permission to use this command")
                return 1
            end
            
            local success, msg = startEvent()
            MP.SendChatMessage(playerID, msg)
            return 1
        end
        
        -- /stopderby command (for testing/emergencies)
        if command == "stopderby" then
            if not isAdmin(playerID) then
                MP.SendChatMessage(playerID, "You don't have permission to use this command")
                return 1
            end
            
            if eventState == EVENT_RUNNING then
                endEvent(nil)
                MP.SendChatMessage(playerID, "Event stopped by admin")
            else
                MP.SendChatMessage(playerID, "No event is running")
            end
            return 1
        end
    end
    
    return 0
end

-- Handle custom events from clients
function onDerbyPositionUpdate(playerID, data)
    onPositionUpdate(playerID, data)
end

-- Handle vehicle reset attempts during event
function onVehicleReset(playerID, vehicleID)
    if eventState == EVENT_RUNNING and participants[playerID] and not participants[playerID].eliminated then
        MP.SendChatMessage(playerID, "[DEMOLITION DERBY] Vehicle resets are disabled during the event!")
        return 1  -- Cancel the reset
    end
    return 0  -- Allow the reset
end

-- Periodic update function
function onTick()
    checkVehiclePositions()
end

-- Handle player disconnects
function onPlayerDisconnect(playerID)
    if eventState == EVENT_RUNNING and participants[playerID] and not participants[playerID].eliminated then
        eliminatePlayer(playerID)
    end
end

function onInit()
    print("[DemolitionDerby] Plugin loaded successfully!")
    print("[DemolitionDerby] Use /startderby to begin an event (admin only)")
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onVehicleReset", "onVehicleReset")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("DerbyPositionUpdate", "onDerbyPositionUpdate")

-- Note: onTick might not be available in all BeamMP versions
-- If onTick is not available, we'll need to use a different approach for periodic checks
-- The position checking will primarily rely on client-side events
