-- WelcomeMessage Plugin
-- Sends a welcome message to players when they join the server

function onPlayerJoin(playerID)
    local playerName = MP.GetPlayerName(playerID)
    
    -- Send welcome message to the joining player
    MP.SendChatMessage(playerID, "Welcome to the server, " .. playerName .. "!")
    
    -- Announce to all players
    MP.SendChatMessage(-1, playerName .. " has joined the server!")
    
    print("[WelcomeMessage] " .. playerName .. " (ID: " .. playerID .. ") joined the server")
end

function onPlayerDisconnect(playerID)
    local playerName = MP.GetPlayerName(playerID)
    
    -- Announce to all players
    MP.SendChatMessage(-1, playerName .. " has left the server!")
    
    print("[WelcomeMessage] " .. playerName .. " (ID: " .. playerID .. ") left the server")
end

function onInit()
    print("[WelcomeMessage] Plugin loaded successfully!")
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
