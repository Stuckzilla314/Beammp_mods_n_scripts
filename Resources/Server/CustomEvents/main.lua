-- CustomEvents Plugin
-- Example custom events to extend the EventManager
-- This demonstrates how to create your own custom events

-- List of admin player IDs (should match EventManager)
local admins = {
    -- Example: "12345", "67890"
}

-- Time Trial Event
local timeTrialEvent = {
    name = "timetrial",
    description = "Time trial race - beat the clock!",
    startTime = nil,
    
    onStart = function(params)
        print("[CustomEvents] Starting time trial event")
        
        -- Get all players
        local players = MP.GetPlayers()
        local participantCount = 0
        
        for id, name in pairs(players) do
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
        
        -- Stop time trial on all clients
        local players = MP.GetPlayers()
        for id, name in pairs(players) do
            MP.TriggerClientEvent(tonumber(id), "stopTimeTrial", "")
        end
        
        timeTrialEvent.startTime = nil
        return true
    end
}

-- Tag Event
local tagEvent = {
    name = "tag",
    description = "Tag game - one player is 'it', tag others to make them 'it'",
    itPlayer = nil,
    
    onStart = function(params)
        print("[CustomEvents] Starting tag event")
        
        local players = MP.GetPlayers()
        local playerList = {}
        
        -- Get all player IDs
        for id, name in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        
        if #playerList < 2 then
            MP.SendChatMessage(-1, "[EVENT] Need at least 2 players for tag!")
            return false
        end
        
        -- Pick random player to be "it"
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

-- Convoy Event
local convoyEvent = {
    name = "convoy",
    description = "Follow the leader convoy event",
    leader = nil,
    
    onStart = function(params)
        print("[CustomEvents] Starting convoy event")
        
        local players = MP.GetPlayers()
        local playerList = {}
        
        for id, name in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        
        if #playerList < 2 then
            MP.SendChatMessage(-1, "[EVENT] Need at least 2 players for convoy!")
            return false
        end
        
        -- First player (lowest ID) is the leader
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

-- Police Chase Event
local policeChaseEvent = {
    name = "policechase",
    description = "Police chase - cops vs robbers",
    cops = {},
    robbers = {},
    
    onStart = function(params)
        print("[CustomEvents] Starting police chase event")
        
        local players = MP.GetPlayers()
        local playerList = {}
        
        for id, name in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        
        if #playerList < 2 then
            MP.SendChatMessage(-1, "[EVENT] Need at least 2 players for police chase!")
            return false
        end
        
        -- Split players into cops and robbers
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

-- Car Show Event
local carShowEvent = {
    name = "carshow",
    description = "Car show - show off your best vehicles",
    
    onStart = function(params)
        print("[CustomEvents] Starting car show event")
        
        MP.SendChatMessage(-1, "[EVENT] Car Show started!")
        MP.SendChatMessage(-1, "[EVENT] Show off your best vehicles!")
        MP.SendChatMessage(-1, "[EVENT] Park your vehicles in the designated area")
        
        local players = MP.GetPlayers()
        for id, name in pairs(players) do
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

-- Register all custom events when plugin loads
function onInit()
    print("[CustomEvents] Loading custom events...")
    
    -- Check if EventManager is available
    if not RegisterEvent then
        print("[CustomEvents] ERROR: EventManager not found!")
        print("[CustomEvents] Make sure EventManager plugin is installed in Resources/Server/EventManager")
        print("[CustomEvents] and that it loads before CustomEvents plugin")
        return
    end
    
    -- Register all custom events
    RegisterEvent("timetrial", timeTrialEvent)
    RegisterEvent("tag", tagEvent)
    RegisterEvent("convoy", convoyEvent)
    RegisterEvent("policechase", policeChaseEvent)
    RegisterEvent("carshow", carShowEvent)
    
    print("[CustomEvents] Registered 5 custom events:")
    print("[CustomEvents]   - timetrial: Time trial race event")
    print("[CustomEvents]   - tag: Tag game event")
    print("[CustomEvents]   - convoy: Follow the leader event")
    print("[CustomEvents]   - policechase: Cops vs robbers chase")
    print("[CustomEvents]   - carshow: Vehicle showcase event")
    print("[CustomEvents] Use /events to see all available events")
end

-- Register the onInit event
MP.RegisterEvent("onInit", "onInit")
