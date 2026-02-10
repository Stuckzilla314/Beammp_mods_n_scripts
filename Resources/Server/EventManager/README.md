# EventManager Plugin

A comprehensive event management framework for BeamMP servers. Allows admins to start and manage custom events and built-in BeamNG events like races.

## Features

- Event registration system for custom events
- Built-in events (race, derby, freeroam)
- Admin commands to start/stop events
- Event participant tracking
- Extensible framework for creating custom events

## Installation

1. Copy the `EventManager` folder to your BeamMP server's `Resources/Server/` directory
2. Edit `main.lua` and add your admin player IDs to the `admins` table
3. Restart your BeamMP server

## Configuration

Open `main.lua` and find the admins table:

```lua
local admins = {
    "12345",  -- Replace with actual player IDs
    "67890"
}
```

## Available Commands

### For All Players
- `/events` or `/listevents` - List all available events and show current running event

### For Admins Only
- `/startevent [event_name]` - Start an event
  - Example: `/startevent race`
  - Example: `/startevent derby`
- `/stopevent` - Stop the currently running event

## Built-in Events

### Race
A standard BeamNG race event.
- **Command:** `/startevent race`
- **Description:** Standard racing event with checkpoints
- **Client Event:** Triggers `startRace` event on all clients

### Derby
Demolition derby event where last vehicle standing wins.
- **Command:** `/startevent derby`
- **Description:** Last vehicle standing wins
- **Participants:** All connected players

### Free Roam
Free exploration event.
- **Command:** `/startevent freeroam`
- **Description:** Free roam exploration of the map
- **Participants:** All players

## Creating Custom Events

You can create custom events by registering them in your plugin or in a separate plugin file.

### Event Structure

```lua
local myCustomEvent = {
    name = "myevent",
    description = "Description of my event",
    onStart = function(params)
        -- Code to run when event starts
        -- params contains optional parameters passed from command
        MP.SendChatMessage(-1, "[EVENT] My custom event started!")
        
        -- Return true if successful, false otherwise
        return true
    end,
    onStop = function()
        -- Code to run when event stops
        MP.SendChatMessage(-1, "[EVENT] My custom event stopped!")
        
        -- Return true if successful, false otherwise
        return true
    end
}

-- Register the event
RegisterEvent("myevent", myCustomEvent)
```

### Example: Custom Time Trial Event

```lua
local timeTrialEvent = {
    name = "timetrial",
    description = "Time trial race event",
    onStart = function(params)
        print("[EventManager] Starting time trial event")
        
        -- Get all players
        local players = MP.GetPlayers()
        local participantCount = 0
        
        for id, name in pairs(players) do
            participantCount = participantCount + 1
            MP.SendChatMessage(tonumber(id), "[EVENT] Time trial started! Beat the clock!")
        end
        
        MP.SendChatMessage(-1, "[EVENT] Time Trial event started with " .. participantCount .. " participants")
        
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Time Trial event ended!")
        return true
    end
}

-- Register in your plugin's onInit function
RegisterEvent("timetrial", timeTrialEvent)
```

### Example: Custom Tag Event

```lua
local tagEvent = {
    name = "tag",
    description = "Tag game - one player is 'it'",
    onStart = function(params)
        local players = MP.GetPlayers()
        local playerList = {}
        
        -- Get all player IDs
        for id, name in pairs(players) do
            table.insert(playerList, tonumber(id))
        end
        
        if #playerList < 2 then
            return false  -- Need at least 2 players
        end
        
        -- Pick random player to be "it"
        math.randomseed(os.time())
        local itPlayer = playerList[math.random(#playerList)]
        
        MP.SendChatMessage(-1, "[EVENT] Tag game started!")
        MP.SendChatMessage(itPlayer, "You are IT! Tag other players!")
        
        for _, id in ipairs(playerList) do
            if id ~= itPlayer then
                MP.SendChatMessage(id, "Don't get tagged!")
            end
        end
        
        return true
    end,
    onStop = function()
        MP.SendChatMessage(-1, "[EVENT] Tag game ended!")
        return true
    end
}

RegisterEvent("tag", tagEvent)
```

## Creating a Separate Custom Events Plugin

You can create a separate plugin for your custom events:

1. Create a new folder in `Resources/Server/` (e.g., `CustomEvents`)
2. Create a `main.lua` file with your custom events
3. The EventManager plugin must be loaded before your custom events plugin

Example structure:
```
Resources/Server/
├── EventManager/
│   └── main.lua
└── CustomEvents/
    └── main.lua
```

Example `CustomEvents/main.lua`:
```lua
function onInit()
    print("[CustomEvents] Loading custom events...")
    
    -- Define your custom event
    local myEvent = {
        name = "myevent",
        description = "My custom event",
        onStart = function(params)
            MP.SendChatMessage(-1, "[EVENT] Custom event started!")
            return true
        end,
        onStop = function()
            MP.SendChatMessage(-1, "[EVENT] Custom event stopped!")
            return true
        end
    }
    
    -- Register with EventManager
    -- Note: This requires EventManager to expose the RegisterEvent function
    if RegisterEvent then
        RegisterEvent("myevent", myEvent)
        print("[CustomEvents] Registered myevent")
    else
        print("[CustomEvents] ERROR: EventManager not found!")
    end
end

MP.RegisterEvent("onInit", "onInit")
```

## Event Lifecycle

1. **Event Registration** - Events are registered during plugin initialization
2. **Event Start** - Admin uses `/startevent [name]` command
3. **Event Running** - The event's `onStart` function executes
4. **Event Stop** - Admin uses `/stopevent` or event stops naturally
5. **Event Cleanup** - The event's `onStop` function executes

## Best Practices

1. **Validate Players** - Always check if players exist before sending them messages
2. **Handle Disconnects** - The framework automatically removes disconnected players from participants
3. **Return Status** - Always return true/false from onStart and onStop functions
4. **Error Messages** - Provide clear error messages to admins
5. **Event Conflicts** - Only one event can run at a time; stop existing events before starting new ones
6. **Test Thoroughly** - Test your custom events with multiple players

## Troubleshooting

### Event not starting
- Check that the event name is correct (case-sensitive)
- Verify the event is registered (check server logs)
- Ensure no other event is currently running

### Event not stopping
- Check server logs for errors in the onStop function
- Use the server console to manually stop if needed

### Custom events not working
- Ensure EventManager plugin is loaded first
- Check that RegisterEvent function is available
- Verify your event structure matches the required format

## Client-Side Integration

Events can trigger client-side actions:

```lua
-- In event's onStart function
for _, playerID in ipairs(participants) do
    MP.TriggerClientEvent(playerID, "customEventStart", "event_data")
end
```

Create corresponding client-side Lua scripts to handle these events.

## Notes

- Only one event can run at a time
- Events are automatically cleaned up when players disconnect
- Admin permissions are required to start/stop events
- All players can view available events with `/events`
