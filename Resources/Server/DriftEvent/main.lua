-- DriftEvent Plugin
-- Professional drift event system with scoring and leaderboards
-- Based on Formula Drift scoring criteria: Line, Angle, Style, Speed

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- List of admin player IDs (add your admin IDs here)
local admins = {
    -- Example: "12345", "67890"
}

-- Scoring weights (total = 100 points per second)
local SCORING = {
    DRIFT_TIME = 40,        -- Points per second of drifting
    ANGLE = 30,             -- Max points for drift angle
    PROXIMITY = 20,         -- Max points for proximity to objects
    SPEED = 10              -- Max points for speed
}

-- Drift detection thresholds
local DRIFT_THRESHOLD = {
    MIN_ANGLE = 10,         -- Minimum slip angle to count as drifting (degrees)
    MIN_SPEED = 15,         -- Minimum speed to count as drift (m/s)
    MAX_SPEED = 100,        -- Maximum speed for scoring normalization
    PROXIMITY_RANGE = 5     -- Distance to objects for proximity bonus (meters)
}

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local driftEvent = {
    active = false,         -- Is event currently running
    duration = 300,         -- Event duration in seconds (default 5 minutes)
    startTime = 0,          -- Event start timestamp
    endTime = 0,            -- Event end timestamp
    players = {}            -- Player scores and stats
}

local playerStats = {}      -- Real-time player drift stats

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

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

-- Format time in MM:SS format
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

-- Get remaining time in event
local function getRemainingTime()
    if not driftEvent.active then
        return 0
    end
    local elapsed = os.time() - driftEvent.startTime
    return math.max(0, driftEvent.duration - elapsed)
end

-- ============================================================================
-- SCORING SYSTEM
-- ============================================================================

-- Initialize player stats
local function initPlayerStats(playerID)
    if not playerStats[playerID] then
        playerStats[playerID] = {
            totalScore = 0,
            driftTime = 0,
            lastUpdate = os.time(),
            isDrifting = false,
            currentDriftStart = 0
        }
    end
end

-- Calculate drift score based on angle, speed, and proximity
local function calculateDriftScore(angle, speed, proximity)
    -- Normalize angle (0-90 degrees -> 0-1)
    local angleScore = math.min(angle / 90, 1) * SCORING.ANGLE
    
    -- Normalize speed (MIN_SPEED to MAX_SPEED -> 0-1)
    local speedNorm = math.max(0, math.min(1, 
        (speed - DRIFT_THRESHOLD.MIN_SPEED) / 
        (DRIFT_THRESHOLD.MAX_SPEED - DRIFT_THRESHOLD.MIN_SPEED)))
    local speedScore = speedNorm * SCORING.SPEED
    
    -- Proximity bonus (closer = better)
    local proximityScore = 0
    if proximity > 0 and proximity <= DRIFT_THRESHOLD.PROXIMITY_RANGE then
        proximityScore = (1 - proximity / DRIFT_THRESHOLD.PROXIMITY_RANGE) * SCORING.PROXIMITY
    end
    
    return angleScore + speedScore + proximityScore + SCORING.DRIFT_TIME
end

-- Update player drift statistics
local function updatePlayerDrift(playerID, isDrifting, angle, speed, proximity)
    if not driftEvent.active then
        return
    end
    
    initPlayerStats(playerID)
    local stats = playerStats[playerID]
    local currentTime = os.time()
    
    if isDrifting and angle >= DRIFT_THRESHOLD.MIN_ANGLE and speed >= DRIFT_THRESHOLD.MIN_SPEED then
        if not stats.isDrifting then
            -- Start new drift
            stats.isDrifting = true
            stats.currentDriftStart = currentTime
        end
        
        -- Calculate time delta
        local timeDelta = currentTime - stats.lastUpdate
        if timeDelta > 0 then
            -- Add drift time
            stats.driftTime = stats.driftTime + timeDelta
            
            -- Calculate and add score
            local score = calculateDriftScore(angle, speed, proximity) * timeDelta
            stats.totalScore = stats.totalScore + score
        end
    else
        -- Not drifting or below threshold
        if stats.isDrifting then
            stats.isDrifting = false
        end
    end
    
    stats.lastUpdate = currentTime
end

-- ============================================================================
-- EVENT MANAGEMENT
-- ============================================================================

-- Start drift event
local function startDriftEvent(duration)
    driftEvent.active = true
    driftEvent.duration = duration or 300
    driftEvent.startTime = os.time()
    driftEvent.endTime = driftEvent.startTime + driftEvent.duration
    playerStats = {}
    
    MP.SendChatMessage(-1, "=================================")
    MP.SendChatMessage(-1, "DRIFT EVENT STARTED!")
    MP.SendChatMessage(-1, "Duration: " .. formatTime(driftEvent.duration))
    MP.SendChatMessage(-1, "Start drifting to earn points!")
    MP.SendChatMessage(-1, "=================================")
    
    print("[DriftEvent] Event started - Duration: " .. driftEvent.duration .. "s")
end

-- Stop drift event and display results
local function stopDriftEvent()
    if not driftEvent.active then
        return
    end
    
    driftEvent.active = false
    
    -- Create leaderboard
    local leaderboard = {}
    for playerID, stats in pairs(playerStats) do
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
    
    -- Sort by score
    table.sort(leaderboard, function(a, b) return a.score > b.score end)
    
    -- Display results
    MP.SendChatMessage(-1, "=================================")
    MP.SendChatMessage(-1, "DRIFT EVENT FINISHED!")
    MP.SendChatMessage(-1, "=================================")
    
    if #leaderboard == 0 then
        MP.SendChatMessage(-1, "No participants scored points")
    else
        MP.SendChatMessage(-1, "FINAL LEADERBOARD:")
        for i, entry in ipairs(leaderboard) do
            if i <= 10 then -- Show top 10
                local rank = i
                local medal = ""
                if rank == 1 then medal = "🥇 "
                elseif rank == 2 then medal = "🥈 "
                elseif rank == 3 then medal = "🥉 "
                end
                
                MP.SendChatMessage(-1, string.format("%s#%d: %s - %.0f points (%.1fs drift)", 
                    medal, rank, entry.name, entry.score, entry.driftTime))
            end
        end
    end
    MP.SendChatMessage(-1, "=================================")
    
    print("[DriftEvent] Event ended - " .. #leaderboard .. " participants")
end

-- Check if event should end (timer expired)
local function checkEventTimer()
    if driftEvent.active then
        local remaining = getRemainingTime()
        if remaining <= 0 then
            stopDriftEvent()
        end
    end
end

-- ============================================================================
-- COMMAND HANDLERS
-- ============================================================================

function onChatMessage(playerID, playerName, message)
    -- Check for commands
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))
        
        
        -- /driftstatus - Check event status (available to all)
        if command == "driftstatus" then
            if not driftEvent.active then
                MP.SendChatMessage(playerID, "No drift event is currently running")
            else
                local remaining = getRemainingTime()
                MP.SendChatMessage(playerID, "Drift event is active!")
                MP.SendChatMessage(playerID, "Time remaining: " .. formatTime(remaining))
                
                -- Show player's current score
                if playerStats[playerID] then
                    local stats = playerStats[playerID]
                    MP.SendChatMessage(playerID, string.format("Your score: %.0f points (%.1fs drift)", 
                        stats.totalScore, stats.driftTime))
                else
                    MP.SendChatMessage(playerID, "You haven't scored any points yet")
                end
            end
            return 1
        end
        
        -- /driftleaderboard - Show current leaderboard (available to all)
        if command == "driftleaderboard" or command == "driftlb" then
            if not driftEvent.active then
                MP.SendChatMessage(playerID, "No drift event is currently running")
                return 1
            end
            
            -- Create current leaderboard
            local leaderboard = {}
            for pID, stats in pairs(playerStats) do
                local pName = MP.GetPlayerName(pID)
                if pName then
                    table.insert(leaderboard, {
                        id = pID,
                        name = pName,
                        score = stats.totalScore,
                        driftTime = stats.driftTime
                    })
                end
            end
            
            table.sort(leaderboard, function(a, b) return a.score > b.score end)
            
            MP.SendChatMessage(playerID, "=== CURRENT LEADERBOARD ===")
            if #leaderboard == 0 then
                MP.SendChatMessage(playerID, "No scores yet")
            else
                for i, entry in ipairs(leaderboard) do
                    if i <= 5 then -- Show top 5
                        MP.SendChatMessage(playerID, string.format("#%d: %s - %.0f pts", 
                            i, entry.name, entry.score))
                    end
                end
            end
            return 1
        end
        
        -- /drifthelp - Show drift commands (available to all)
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
    end
    
    return 0
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function onInit()
    print("[DriftEvent] Plugin loaded successfully!")
    print("[DriftEvent] Scoring system: Time=" .. SCORING.DRIFT_TIME .. 
          ", Angle=" .. SCORING.ANGLE .. 
          ", Proximity=" .. SCORING.PROXIMITY .. 
          ", Speed=" .. SCORING.SPEED)
    print("[DriftEvent] Commands: /drifthelp for info")

    if RegisterEvent then
        RegisterEvent("drift", {
            name = "drift",
            description = "Drift event with scoring and leaderboard",
            onStart = function(params)
                if driftEvent.active then
                    return false
                end
                local duration = tonumber(params)
                duration = duration or 300
                if duration < 30 then
                    duration = 30
                end
                if duration > 3600 then
                    duration = 3600
                end
                startDriftEvent(duration)
                return true
            end,
            onStop = function()
                if not driftEvent.active then
                    return false
                end
                stopDriftEvent()
                return true
            end
        })
        print("[DriftEvent] Registered drift event with EventManager")
    else
        print("[DriftEvent] WARNING: EventManager not found. Drift event not registered")
    end
end

function onPlayerJoin(playerID)
    initPlayerStats(playerID)
    
    if driftEvent.active then
        local remaining = getRemainingTime()
        MP.SendChatMessage(playerID, "A drift event is currently running!")
        MP.SendChatMessage(playerID, "Time remaining: " .. formatTime(remaining))
        MP.SendChatMessage(playerID, "Type /drifthelp for commands")
    end
end

function onPlayerDisconnect(playerID)
    -- Keep their score for the leaderboard even if they disconnect
    if playerStats[playerID] then
        print("[DriftEvent] Player " .. playerID .. " disconnected with score: " .. 
              playerStats[playerID].totalScore)
    end
end

-- Simulate drift detection from vehicle data
-- In a real implementation, this would parse actual vehicle telemetry
function onVehicleSpawn(playerID, vehicleID, vehicleData)
    -- Initialize player when they spawn a vehicle
    if driftEvent.active then
        initPlayerStats(playerID)
    end
end

-- ============================================================================
-- DRIFT DETECTION (Requires Integration)
-- ============================================================================

-- Note: BeamMP doesn't expose vehicle telemetry directly in the base Lua API.
-- To enable real-time drift scoring, you need to implement one of these methods:
--
-- Method 1: Client-Side Telemetry Mod (Recommended)
--   - Create a client mod that monitors vehicle data
--   - Send data to server via MP.TriggerServerEvent()
--   - Handle in a custom event handler
--
-- Method 2: Parse Vehicle Data Packets
--   - Hook into BeamMP's vehicle data events
--   - Extract angle, speed, and position from packets
--
-- Method 3: Timer-Based Polling
--   - Use MP.CreateTimer() for periodic checks
--   - Poll available vehicle information
--
-- See INTEGRATION.md for complete implementation examples.
--
-- Example event handler for client telemetry:
--
-- function onDriftTelemetry(playerID, data)
--     if not driftEvent.active then return end
--     
--     local isDrifting = (data.slipAngle >= DRIFT_THRESHOLD.MIN_ANGLE and 
--                        data.speed >= DRIFT_THRESHOLD.MIN_SPEED)
--     updatePlayerDrift(playerID, isDrifting, data.slipAngle, data.speed, data.proximity)
-- end
-- 
-- MP.RegisterEvent("DriftTelemetry", "onDriftTelemetry")
--
-- Example timer for event management:
--
-- function checkEventTimerPeriodic()
--     checkEventTimer()
-- end
--
-- MP.CreateTimer(checkEventTimerPeriodic, 1000)  -- Check every second

-- ============================================================================
-- REGISTER EVENTS
-- ============================================================================

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")


