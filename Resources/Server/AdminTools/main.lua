-- AdminTools Plugin
-- Comprehensive admin commands for server management

-- List of admin player IDs (add your admin IDs here)
local admins = {
    -- Example: "12345", "67890"
}

-- Store player positions for teleportation
local playerPositions = {}

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

-- Teleport a player's vehicle to a position
local function teleportPlayer(playerID, x, y, z)
    local data = "{"..x..","..y..","..z.."}"
    MP.TeleportVehicle(playerID, -1, data)  -- -1 means all vehicles of the player
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
                MP.SendChatMessage(playerID, "Admin Commands:")
                MP.SendChatMessage(playerID, "/kick [id] - Kick a player")
                MP.SendChatMessage(playerID, "/announce [msg] - Server announcement")
                MP.SendChatMessage(playerID, "/tp [id] - Teleport to player")
                MP.SendChatMessage(playerID, "/tphere [id] - Teleport player to you")
                MP.SendChatMessage(playerID, "/tpall - Teleport all players to you")
                MP.SendChatMessage(playerID, "/freeze [id] - Freeze player's vehicle")
                MP.SendChatMessage(playerID, "/unfreeze [id] - Unfreeze player's vehicle")
                MP.SendChatMessage(playerID, "/explode [id] - Explode player's vehicle")
                MP.SendChatMessage(playerID, "/resetvehicle [id] - Reset player's vehicle")
            end
            return 1 -- Cancel the message so it doesn't appear in chat
        end
        
        -- Admin-only commands
        if isAdmin(playerID) then
            -- /kick command
            if string.match(command, "^kick%s") or command == "kick" then
                local targetID = string.match(command, "kick%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) then
                        MP.DropPlayer(targetIDNum, "You have been kicked by an admin")
                        MP.SendChatMessage(-1, "Player " .. targetID .. " has been kicked")
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /kick [player_id]")
                end
                return 1
            end
            
            -- /announce command
            if string.match(command, "^announce%s") or command == "announce" then
                local announcement = string.match(command, "announce%s+(.+)")
                if announcement then
                    MP.SendChatMessage(-1, "[SERVER] " .. announcement)
                else
                    MP.SendChatMessage(playerID, "Usage: /announce [message]")
                end
                return 1
            end
            
            -- /tp command - teleport to another player
            if string.match(command, "^tp%s") or command == "tp" then
                local targetID = string.match(command, "tp%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) and playerPositions[targetIDNum] then
                        local pos = playerPositions[targetIDNum]
                        teleportPlayer(playerID, pos.x, pos.y, pos.z)
                        MP.SendChatMessage(playerID, "Teleported to player " .. targetID)
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found or no position data")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /tp [player_id]")
                end
                return 1
            end
            
            -- /tphere command - teleport player to admin
            if string.match(command, "^tphere%s") or command == "tphere" then
                local targetID = string.match(command, "tphere%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) and playerPositions[playerID] then
                        local pos = playerPositions[playerID]
                        teleportPlayer(targetIDNum, pos.x, pos.y, pos.z)
                        MP.SendChatMessage(playerID, "Teleported player " .. targetID .. " to you")
                        MP.SendChatMessage(targetIDNum, "You have been teleported by an admin")
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found or no position data")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /tphere [player_id]")
                end
                return 1
            end
            
            -- /tpall command - teleport all players to admin
            if command == "tpall" then
                if playerPositions[playerID] then
                    local pos = playerPositions[playerID]
                    local players = MP.GetPlayers()
                    local count = 0
                    for id, name in pairs(players) do
                        if tonumber(id) ~= playerID then
                            teleportPlayer(tonumber(id), pos.x, pos.y, pos.z)
                            MP.SendChatMessage(tonumber(id), "You have been teleported by an admin")
                            count = count + 1
                        end
                    end
                    MP.SendChatMessage(playerID, "Teleported " .. count .. " player(s) to you")
                    MP.SendChatMessage(-1, "[SERVER] All players have been teleported")
                else
                    MP.SendChatMessage(playerID, "Error: Unable to get your position")
                end
                return 1
            end
            
            -- /freeze command - freeze a player's vehicle
            if string.match(command, "^freeze%s") or command == "freeze" then
                local targetID = string.match(command, "freeze%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) then
                        MP.SendChatMessage(targetIDNum, "Your vehicle has been frozen by an admin")
                        MP.SendChatMessage(playerID, "Froze player " .. targetID .. "'s vehicle")
                        -- Send freeze command to client
                        MP.TriggerClientEvent(targetIDNum, "freezeVehicle", "")
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /freeze [player_id]")
                end
                return 1
            end
            
            -- /unfreeze command - unfreeze a player's vehicle
            if string.match(command, "^unfreeze%s") or command == "unfreeze" then
                local targetID = string.match(command, "unfreeze%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) then
                        MP.SendChatMessage(targetIDNum, "Your vehicle has been unfrozen")
                        MP.SendChatMessage(playerID, "Unfroze player " .. targetID .. "'s vehicle")
                        -- Send unfreeze command to client
                        MP.TriggerClientEvent(targetIDNum, "unfreezeVehicle", "")
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /unfreeze [player_id]")
                end
                return 1
            end
            
            -- /explode command - explode a player's vehicle
            if string.match(command, "^explode%s") or command == "explode" then
                local targetID = string.match(command, "explode%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) then
                        MP.SendChatMessage(-1, "[SERVER] Player " .. targetID .. "'s vehicle has been exploded!")
                        -- Send explode command to client
                        MP.TriggerClientEvent(targetIDNum, "explodeVehicle", "")
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /explode [player_id]")
                end
                return 1
            end
            
            -- /resetvehicle command - reset a player's vehicle
            if string.match(command, "^resetvehicle%s") or command == "resetvehicle" then
                local targetID = string.match(command, "resetvehicle%s+(%d+)")
                if targetID then
                    local targetIDNum = tonumber(targetID)
                    if targetIDNum and MP.GetPlayerName(targetIDNum) then
                        MP.SendChatMessage(targetIDNum, "Your vehicle has been reset by an admin")
                        MP.SendChatMessage(playerID, "Reset player " .. targetID .. "'s vehicle")
                        -- Send reset command to client
                        MP.TriggerClientEvent(targetIDNum, "resetVehicle", "")
                    else
                        MP.SendChatMessage(playerID, "Error: Player ID " .. targetID .. " not found")
                    end
                else
                    MP.SendChatMessage(playerID, "Usage: /resetvehicle [player_id]")
                end
                return 1
            end
        else
            -- Non-admin tried to use admin command
            local adminCommands = {"kick", "announce", "tp", "tphere", "tpall", "freeze", "unfreeze", "explode", "resetvehicle"}
            for _, cmd in ipairs(adminCommands) do
                if string.match(command, "^" .. cmd) then
                    MP.SendChatMessage(playerID, "You don't have permission to use this command")
                    return 1
                end
            end
        end
    end
    
    return 0 -- Allow normal messages
end

-- Track player positions when vehicles spawn or move
function onVehicleSpawn(playerID, vehicleID, vehicleData)
    -- Initialize position tracking for this player if not already done
    if not playerPositions[playerID] then
        playerPositions[playerID] = {x = 0, y = 0, z = 0}
    end
    
    -- Try to parse position from vehicle data
    -- Vehicle data format varies, this is a basic implementation
    -- Position updates will be more accurate with client-side position reporting
    if vehicleData and type(vehicleData) == "string" then
        local x, y, z = string.match(vehicleData, "\"pos\":%[([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%]")
        if x and y and z then
            playerPositions[playerID] = {
                x = tonumber(x),
                y = tonumber(y),
                z = tonumber(z)
            }
        end
    end
end

-- Remove position data when player disconnects
function onPlayerDisconnect(playerID)
    playerPositions[playerID] = nil
end

function onInit()
    print("[AdminTools] Plugin loaded successfully!")
    print("[AdminTools] " .. #admins .. " admin(s) configured")
    print("[AdminTools] Available admin commands: kick, announce, tp, tphere, tpall, freeze, unfreeze, explode, resetvehicle")
end

-- Register events
MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
