# BeamMP Scripting Guide

This guide covers the basics of creating scripts (plugins) for BeamMP servers.

## Plugin Structure

Every plugin must be in its own folder under `Resources/Server/` and must have a `main.lua` file.

```
Resources/Server/
└── YourPlugin/
    └── main.lua
```

## Event System

BeamMP uses an event-driven architecture. You register functions to be called when specific events occur.

### Basic Event Registration

```lua
function onInit()
    print("Plugin loaded!")
end

MP.RegisterEvent("onInit", "onInit")
```

### Common Events

#### onInit
Called when the server starts or plugin is loaded.

```lua
function onInit()
    print("Server initialized")
end

MP.RegisterEvent("onInit", "onInit")
```

#### onPlayerConnect
Called when a player first connects (before fully joining).

```lua
function onPlayerConnect(playerID)
    print("Player " .. playerID .. " is connecting...")
end

MP.RegisterEvent("onPlayerConnect", "onPlayerConnect")
```

#### onPlayerJoin
Called when a player successfully joins the server.

```lua
function onPlayerJoin(playerID)
    local playerName = MP.GetPlayerName(playerID)
    print(playerName .. " joined!")
end

MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
```

#### onPlayerDisconnect
Called when a player disconnects.

```lua
function onPlayerDisconnect(playerID)
    local playerName = MP.GetPlayerName(playerID)
    print(playerName .. " left!")
end

MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
```

#### onChatMessage
Called when a player sends a chat message. Return 1 to cancel the message.

```lua
function onChatMessage(playerID, playerName, message)
    print("[Chat] " .. playerName .. ": " .. message)
    
    -- Filter bad words
    if message:lower():find("badword") then
        MP.SendChatMessage(playerID, "Please watch your language!")
        return 1  -- Cancel the message
    end
    
    return 0  -- Allow the message
end

MP.RegisterEvent("onChatMessage", "onChatMessage")
```

#### onVehicleSpawn
Called when a vehicle is spawned.

```lua
function onVehicleSpawn(playerID, vehicleID, vehicleData)
    print("Vehicle spawned by player " .. playerID)
end

MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
```

#### onVehicleDeleted
Called when a vehicle is deleted.

```lua
function onVehicleDeleted(playerID, vehicleID)
    print("Vehicle deleted")
end

MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
```

## API Functions

### Chat Functions

- `MP.SendChatMessage(playerID, message)` - Send a message to a player (-1 for all players)
- `MP.SendChatMessage(-1, message)` - Send to all players

### Player Functions

- `MP.GetPlayerName(playerID)` - Get player's name
- `MP.DropPlayer(playerID, reason)` - Kick a player
- `MP.GetPlayerCount()` - Get number of connected players
- `MP.GetPlayers()` - Get table of all player IDs

### Vehicle Functions

- `MP.RemoveVehicle(playerID, vehicleID)` - Remove a specific vehicle

## Best Practices

1. **Always validate input** - Check if player IDs and vehicle IDs are valid before using them
2. **Use descriptive function names** - Make your code easy to understand
3. **Add comments** - Explain what your code does, especially for complex logic
4. **Test thoroughly** - Always test your plugins on a development server first
5. **Handle errors** - Use `pcall()` for operations that might fail
6. **Log important events** - Use `print()` to log important events for debugging

## Example: Complete Plugin

```lua
-- ChatLogger Plugin
-- Logs all chat messages to a file

local logFile = "chatlogs.txt"

function onInit()
    print("[ChatLogger] Plugin loaded")
end

function onChatMessage(playerID, playerName, message)
    local timestamp = os.date("!%Y-%m-%d %H:%M:%S")  -- Use UTC time
    local logEntry = string.format("[%s] %s (ID: %d): %s\n", 
        timestamp, playerName, playerID, message)
    
    -- Write to log file
    local file = io.open(logFile, "a")
    if file then
        file:write(logEntry)
        file:close()
    end
    
    return 0  -- Don't cancel the message
end

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "onChatMessage")
```

## Resources

- [Official BeamMP Documentation](https://docs.beammp.com/)
- [BeamMP Wiki](https://wiki.beammp.com/en/Scripting)
- [BeamMP Discord](https://discord.gg/beammp)
- [Lua 5.3 Reference Manual](https://www.lua.org/manual/5.3/)

## Troubleshooting

### Plugin not loading
- Check that your plugin folder is in `Resources/Server/`
- Ensure you have a `main.lua` file
- Check the server console for error messages
- Verify your Lua syntax is correct

### Events not firing
- Make sure you registered the event with `MP.RegisterEvent()`
- Check that the function name in the registration matches the actual function name
- Verify the event name is spelled correctly

### Server crashes
- Check for infinite loops in your code
- Validate all input before using it
- Use `pcall()` for operations that might fail
- Check the server log for error messages
