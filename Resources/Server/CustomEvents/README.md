# CustomEvents Plugin

Example custom events that extend the EventManager framework. This plugin demonstrates how to create your own custom events for your BeamMP server.

## Features

This plugin includes 5 example custom events:
- **Time Trial** - Race against the clock
- **Tag** - Classic tag game where one player is "it"
- **Convoy** - Follow-the-leader event
- **Police Chase** - Cops vs robbers chase event
- **Car Show** - Vehicle showcase event

## Installation

1. **Prerequisite:** Install the EventManager plugin first
2. Copy the `CustomEvents` folder to your BeamMP server's `Resources/Server/` directory
3. Restart your BeamMP server

## Requirements

- EventManager plugin must be installed and loaded before CustomEvents
- At least 2 players required for most events (tag, convoy, police chase)

## Available Custom Events

### Time Trial
Start a time trial race where players race against the clock.

**Command:** `/startevent timetrial`

**Features:**
- All players participate automatically
- 5-minute time limit announced
- Triggers client-side `startTimeTrial` event

### Tag
Classic tag game where one player is "it" and must tag others.

**Command:** `/startevent tag`

**Features:**
- Random player selected as "it"
- Requires minimum 2 players
- Players notified who is "it"

### Convoy
Follow-the-leader event where players form a convoy.

**Command:** `/startevent convoy`

**Features:**
- Player with lowest ID becomes leader
- Other players must follow the leader
- Requires minimum 2 players

### Police Chase
Cops vs robbers chase event with team assignment.

**Command:** `/startevent policechase`

**Features:**
- Players randomly split into cops and robbers
- Approximately 50/50 team split
- Requires minimum 2 players
- Teams announced in chat

### Car Show
Showcase event where players display their vehicles.

**Command:** `/startevent carshow`

**Features:**
- Freeform event for showing off vehicles
- All players can participate
- No competitive element

## How to Use

1. Admin starts event: `/startevent [event_name]`
2. Event begins and players are notified
3. Players participate according to event rules
4. Admin stops event: `/stopevent`

## Creating Your Own Custom Events

You can add your own events by following this pattern:

```lua
local myCustomEvent = {
    name = "myevent",
    description = "Description of my event",
    
    onStart = function(params)
        -- Code to run when event starts
        print("[CustomEvents] Starting my custom event")
        
        -- Get all players
        local players = MP.GetPlayers()
        for id, name in pairs(players) do
            MP.SendChatMessage(tonumber(id), "[EVENT] My event started!")
        end
        
        -- Return true if successful
        return true
    end,
    
    onStop = function()
        -- Code to run when event stops
        MP.SendChatMessage(-1, "[EVENT] My event ended!")
        
        -- Return true if successful
        return true
    end
}

-- Register in onInit function
function onInit()
    -- ... existing code ...
    RegisterEvent("myevent", myCustomEvent)
    print("[CustomEvents] Registered myevent")
end
```

## Event Best Practices

1. **Always validate player count** - Check if enough players are connected
2. **Return true/false appropriately** - Return false if event can't start
3. **Clean up on stop** - Reset any event-specific variables
4. **Communicate clearly** - Send chat messages to inform players
5. **Handle edge cases** - What if a player disconnects during the event?

## Customization

You can modify any of the included events to suit your server:

- Change team ratios in Police Chase
- Adjust time limits in Time Trial
- Add scoring systems
- Integrate with other plugins
- Add custom vehicle restrictions

## Client-Side Integration

Some events trigger client-side events:
- `startTimeTrial` - Triggered when time trial starts
- `stopTimeTrial` - Triggered when time trial ends

You can create client-side Lua scripts to handle these events and add visual effects, timers, or other enhancements.

## Example: Adding a Scoring System

```lua
local driftEvent = {
    name = "drift",
    description = "Drift competition",
    scores = {},
    
    onStart = function(params)
        driftEvent.scores = {}
        
        local players = MP.GetPlayers()
        for id, name in pairs(players) do
            driftEvent.scores[tonumber(id)] = 0
            MP.SendChatMessage(tonumber(id), "[EVENT] Drift competition! Show us your best drifts!")
        end
        
        MP.SendChatMessage(-1, "[EVENT] Drift competition started!")
        return true
    end,
    
    onStop = function()
        -- Announce winner
        local winner = nil
        local highScore = 0
        
        for id, score in pairs(driftEvent.scores) do
            if score > highScore then
                highScore = score
                winner = id
            end
        end
        
        if winner then
            MP.SendChatMessage(-1, "[EVENT] Winner: Player " .. winner .. " with " .. highScore .. " points!")
        end
        
        MP.SendChatMessage(-1, "[EVENT] Drift competition ended!")
        driftEvent.scores = {}
        return true
    end
}
```

## Troubleshooting

### Events not registering
- Ensure EventManager plugin is installed
- Check that EventManager loads before CustomEvents
- Verify no syntax errors in your custom event definitions

### Event won't start
- Check minimum player requirements
- Verify event name is correct (case-sensitive)
- Look for error messages in server console

### Players not receiving notifications
- Verify `MP.SendChatMessage` is being called
- Check that player IDs are valid numbers
- Ensure players are actually connected

## Notes

- Events are examples and can be modified
- Some events work better with more players
- Client-side scripts can enhance these events
- Consider server performance with complex events
