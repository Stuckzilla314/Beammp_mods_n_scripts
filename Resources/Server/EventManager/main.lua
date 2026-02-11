-- EventManager Plugin
-- Framework for managing and starting custom events and BeamNG races

-- List of admin player IDs (add your admin IDs here)
local admins = {
    -- Example: "12345", "67890"
}

-- Event storage
local events = {}
local eventCount = 0
local activeEvent = nil
local eventParticipants = {}

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

-- Register a new event
function RegisterEvent(eventName, eventData)
    if events[eventName] then
        print("[EventManager] Warning: Event '" .. eventName .. "' already registered. Overriding.")
    else
        eventCount = eventCount + 1
    end
    events[eventName] = eventData
    print("[EventManager] Registered event: " .. eventName)
end

-- Built-in event: Race
local raceEvent = {
    name = "race",
    description = "Standard BeamNG race event",
    onStart = function(params)
        print("[EventManager] Starting race event")
        eventParticipants = {}
        
        -- Get all connected players
        local players = MP.GetPlayers()
        for id, name in pairs(players) do
            table.insert(eventParticipants, tonumber(id))
        end
        
        MP.SendChatMessage(-1, "[EVENT] Race event has started!")
        MP.SendChatMessage(-1, "[EVENT] " .. #eventParticipants .. " participants registered")
        
        -- Trigger race event on all clients
        for _, playerID in ipairs(eventParticipants) do
            MP.TriggerClientEvent(playerID, "startRace", params or "")
        end
        
        return true
    end,
    onStop = function()
        print("[EventManager] Stopping race event")
        MP.SendChatMessage(-1, "[EVENT] Race event has ended!")
        
        -- Trigger stop race on all clients
        for _, playerID in ipairs(eventParticipants) do
            MP.TriggerClientEvent(playerID, "stopRace", "")
        end
        
        eventParticipants = {}
        return true
    end
}

-- Built-in event: Derby
local derbyEvent = {
    name = "derby",
    description = "Demolition derby event",
    onStart = function(params)
        print("[EventManager] Starting derby event")
        eventParticipants = {}
        
        local players = MP.GetPlayers()
        for id, name in pairs(players) do
            table.insert(eventParticipants, tonumber(id))
        end
        
        MP.SendChatMessage(-1, "[EVENT] Derby event has started!")
        MP.SendChatMessage(-1, "[EVENT] Last vehicle standing wins!")
        MP.SendChatMessage(-1, "[EVENT] " .. #eventParticipants .. " participants registered")
        
        return true
    end,
    onStop = function()
        print("[EventManager] Stopping derby event")
        MP.SendChatMessage(-1, "[EVENT] Derby event has ended!")
        eventParticipants = {}
        return true
    end
}

-- Built-in event: Free Roam
local freeRoamEvent = {
    name = "freeroam",
    description = "Free roam exploration event",
    onStart = function(params)
        print("[EventManager] Starting free roam event")
        MP.SendChatMessage(-1, "[EVENT] Free Roam event started - explore the map!")
        return true
    end,
    onStop = function()
        print("[EventManager] Stopping free roam event")
        MP.SendChatMessage(-1, "[EVENT] Free Roam event has ended!")
        return true
    end
}

-- Start an event
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
    else
        return false, "Failed to start event '" .. eventName .. "'"
    end
end

-- Stop the current event
local function stopEvent()
    if not activeEvent then
        return false, "No event is currently running"
    end
    
    local success = activeEvent.event.onStop()
    if success then
        local eventName = activeEvent.name
        activeEvent = nil
        return true, "Event '" .. eventName .. "' stopped successfully"
    else
        return false, "Failed to stop event"
    end
end

-- List all available events
local function listEvents()
    local eventList = {}
    for name, event in pairs(events) do
        table.insert(eventList, name .. " - " .. (event.description or "No description"))
    end
    return eventList
end

-- Handle chat commands
function onChatMessage(playerID, playerName, message)
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))
        
        -- /events command (available to all)
        if command == "events" or command == "listevents" then
            MP.SendChatMessage(playerID, "Available events:")
            local eventList = listEvents()
            for _, eventInfo in ipairs(eventList) do
                MP.SendChatMessage(playerID, "  - " .. eventInfo)
            end
            if activeEvent then
                MP.SendChatMessage(playerID, "Current event: " .. activeEvent.name)
            else
                MP.SendChatMessage(playerID, "No event currently running")
            end
            return 1
        end
        
        -- Admin-only commands
        if isAdmin(playerID) then
            -- /startevent command
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
            
            -- /stopevent command
            if command == "stopevent" then
                local success, msg = stopEvent()
                MP.SendChatMessage(playerID, msg)
                if success then
                    MP.SendChatMessage(-1, "[SERVER] Admin stopped the event")
                end
                return 1
            end
        else
            -- Non-admin tried to use admin command
            if string.match(command, "^startevent") or command == "stopevent" then
                MP.SendChatMessage(playerID, "You don't have permission to use this command")
                return 1
            end
        end
    end
    
    return 0
end

function onInit()
    print("[EventManager] Plugin loaded successfully!")
    
    -- Register built-in events
    RegisterEvent("race", raceEvent)
    RegisterEvent("derby", derbyEvent)
    RegisterEvent("freeroam", freeRoamEvent)
    
    print("[EventManager] Registered " .. eventCount .. " events")
    print("[EventManager] Use /events to list available events")
end

function onPlayerDisconnect(playerID)
    -- Remove player from event participants if they disconnect
    if activeEvent then
        for i, id in ipairs(eventParticipants) do
            if id == playerID then
                table.remove(eventParticipants, i)
                break
            end
        end
    end
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")

-- Export functions for other plugins to use (make RegisterEvent globally accessible)
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
