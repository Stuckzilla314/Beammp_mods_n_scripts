-- AdminTools Plugin
-- Basic admin commands for server management

-- List of admin player IDs (add your admin IDs here)
local admins = {
    -- Example: "12345", "67890"
}

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

-- Handle chat commands
function onChatMessage(playerID, playerName, message)
    -- Check for admin commands
    if string.sub(message, 1, 1) == "/" then
        local command = string.lower(string.sub(message, 2))
        
        -- /help command (available to all)
        if command == "help" then
            MP.SendChatMessage(playerID, "Available commands:")
            MP.SendChatMessage(playerID, "/help - Show this help message")
            if isAdmin(playerID) then
                MP.SendChatMessage(playerID, "/kick [id] - Kick a player")
                MP.SendChatMessage(playerID, "/announce [message] - Send server announcement")
            end
            return 1 -- Cancel the message so it doesn't appear in chat
        end
        
        -- Admin-only commands
        if isAdmin(playerID) then
            -- /kick command
            if string.sub(command, 1, 4) == "kick" then
                local targetID = string.match(command, "kick%s+(%d+)")
                if targetID then
                    MP.DropPlayer(tonumber(targetID), "You have been kicked by an admin")
                    MP.SendChatMessage(-1, "Player " .. targetID .. " has been kicked")
                else
                    MP.SendChatMessage(playerID, "Usage: /kick [player_id]")
                end
                return 1
            end
            
            -- /announce command
            if string.sub(command, 1, 8) == "announce" then
                local announcement = string.match(command, "announce%s+(.+)")
                if announcement then
                    MP.SendChatMessage(-1, "[SERVER] " .. announcement)
                else
                    MP.SendChatMessage(playerID, "Usage: /announce [message]")
                end
                return 1
            end
        else
            -- Non-admin tried to use admin command
            if command == "kick" or command == "announce" then
                MP.SendChatMessage(playerID, "You don't have permission to use this command")
                return 1
            end
        end
    end
    
    return 0 -- Allow normal messages
end

function onInit()
    print("[AdminTools] Plugin loaded successfully!")
    print("[AdminTools] " .. #admins .. " admin(s) configured")
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
