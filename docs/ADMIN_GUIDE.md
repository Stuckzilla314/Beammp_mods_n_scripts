# Admin Guide - BeamMP Server Management

This guide covers all available admin commands and how to effectively manage your BeamMP server using the AdminTools and EventManager plugins.

## Table of Contents
1. [Setup](#setup)
2. [Admin Commands Reference](#admin-commands-reference)
3. [Event Management](#event-management)
4. [Common Admin Tasks](#common-admin-tasks)
5. [Best Practices](#best-practices)

## Setup

### 1. Installing Plugins

Copy the following plugins to your server's `Resources/Server/` directory:
- `AdminTools` - Required for admin commands
- `EventManager` - Required for event management
- `CustomEvents` - Optional, provides example events

### 2. Configuring Admins

Edit the `admins` table in each plugin's `main.lua` file:

```lua
local admins = {
    "12345",  -- Replace with actual player IDs
    "67890"
}
```

**Finding Player IDs:**
- Check the server console when players connect
- Player IDs are shown in connection messages
- Use the BeamMP server console to view current players

### 3. Server Restart

Restart your BeamMP server for the plugins to load.

## Admin Commands Reference

### General Commands

#### `/help`
Shows available commands for the current user.
- **Available to:** All players
- **Example:** `/help`

### Player Management Commands

#### `/kick [player_id]`
Kicks a player from the server.
- **Available to:** Admins only
- **Example:** `/kick 2`
- **Effect:** Immediately disconnects the player

#### `/announce [message]`
Sends a server-wide announcement.
- **Available to:** Admins only
- **Example:** `/announce Server restart in 5 minutes!`
- **Effect:** All players see the message prefixed with `[SERVER]`

### Teleportation Commands

#### `/tp [player_id]`
Teleports you to another player's location.
- **Available to:** Admins only
- **Example:** `/tp 1`
- **Notes:** Requires player position data to be available

#### `/tphere [player_id]`
Teleports a specific player to your location.
- **Available to:** Admins only
- **Example:** `/tphere 2`
- **Effect:** Brings the specified player to you

#### `/tpall`
Teleports all players to your location.
- **Available to:** Admins only
- **Example:** `/tpall`
- **Effect:** Brings all connected players to your position
- **Use cases:** Gathering players for events, meetings, or screenshots

### Vehicle Control Commands

#### `/freeze [player_id]`
Freezes a player's vehicle, preventing all movement.
- **Available to:** Admins only
- **Example:** `/freeze 3`
- **Use cases:** Stopping rule violations, pausing for discussions

#### `/unfreeze [player_id]`
Unfreezes a previously frozen vehicle.
- **Available to:** Admins only
- **Example:** `/unfreeze 3`

#### `/explode [player_id]`
Explodes a player's vehicle.
- **Available to:** Admins only
- **Example:** `/explode 1`
- **Warning:** This is destructive and will damage/destroy the vehicle
- **Use cases:** Punishment, fun events, removing stuck vehicles

#### `/resetvehicle [player_id]`
Resets a player's vehicle to its original state.
- **Available to:** Admins only
- **Example:** `/resetvehicle 2`
- **Use cases:** Fixing damaged vehicles, resetting after events

### Event Management Commands

#### `/events` or `/listevents`
Lists all available events and shows current running event.
- **Available to:** All players
- **Example:** `/events`

#### `/startevent [event_name]`
Starts a specific event.
- **Available to:** Admins only
- **Example:** `/startevent race`
- **Note:** Only one event can run at a time

#### `/stopevent`
Stops the currently running event.
- **Available to:** Admins only
- **Example:** `/stopevent`

## Event Management

### Built-in Events

#### Race Event
Standard BeamNG race event with all players participating.
```
/startevent race
```

#### Derby Event
Demolition derby where last vehicle standing wins.
```
/startevent derby
```

#### Free Roam Event
Free exploration event for casual play.
```
/startevent freeroam
```

### Custom Events (if CustomEvents plugin is installed)

#### Time Trial
Race against the clock (5-minute time limit).
```
/startevent timetrial
```

#### Tag
One player is "it" and must tag others.
```
/startevent tag
```
- Requires: Minimum 2 players

#### Convoy
Follow-the-leader event.
```
/startevent convoy
```
- Requires: Minimum 2 players

#### Police Chase
Cops vs robbers chase event.
```
/startevent policechase
```
- Requires: Minimum 2 players
- Players are randomly split into teams

#### Car Show
Vehicle showcase event.
```
/startevent carshow
```

## Common Admin Tasks

### Starting a Server Session

1. Connect to the server
2. Verify you have admin permissions: `/help` (should show admin commands)
3. Welcome players with announcements: `/announce Welcome to the server!`

### Managing Problem Players

1. **Warning:** Use announcements to warn the player
   ```
   /announce Player 2, please follow server rules
   ```

2. **Temporary action:** Freeze their vehicle
   ```
   /freeze 2
   ```

3. **Final action:** Kick the player
   ```
   /kick 2
   ```

### Organizing Events

1. **Announce the event:**
   ```
   /announce Race event starting in 2 minutes! Get ready!
   ```

2. **Gather players:**
   ```
   /tpall
   ```

3. **Start the event:**
   ```
   /startevent race
   ```

4. **End the event:**
   ```
   /stopevent
   ```

5. **Announce results:**
   ```
   /announce Thanks for participating! Winner was Player 3!
   ```

### Taking Screenshots/Videos

1. Gather all players: `/tpall`
2. Ask players to line up their vehicles
3. Use `/freeze [id]` on each player to prevent movement
4. Take your screenshot/video
5. Unfreeze all players when done

### Dealing with Stuck Vehicles

**Option 1 - Reset:**
```
/resetvehicle [player_id]
```

**Option 2 - Explode (more dramatic):**
```
/explode [player_id]
```
Then have the player respawn a new vehicle.

## Best Practices

### 1. Communication
- Always announce actions before taking them
- Give warnings before kicking players
- Explain event rules clearly
- Keep players informed about server restarts

### 2. Event Management
- Ensure enough players before starting competitive events
- Stop old events before starting new ones
- Announce event start/end clearly
- Thank players for participating

### 3. Fair Administration
- Apply rules consistently to all players
- Don't abuse teleport/vehicle commands for competitive advantage
- Give warnings before disciplinary actions
- Be respectful even when enforcing rules

### 4. Server Maintenance
- Announce server restarts in advance
- Use `/announce` for important information
- Regularly check for problem players
- Keep the server running smoothly

### 5. Using Vehicle Commands Responsibly
- Don't explode vehicles without reason
- Use freeze/unfreeze for organization, not punishment
- Reset vehicles when players are stuck or need help
- Always unfreeze vehicles after organizing events

## Tips and Tricks

### Quick Event Sequence
```
/announce Event starting in 1 minute!
(wait 30 seconds)
/announce 30 seconds until event!
(wait 30 seconds)
/tpall
/startevent race
```

### Managing Large Groups
When managing many players:
1. Use `/tpall` to gather everyone
2. Freeze players one by one as they arrive
3. Give instructions via `/announce`
4. Unfreeze everyone when ready
5. Start the event

### Emergency Server Control
If chaos erupts:
1. `/announce Please stop and listen`
2. Freeze problem players
3. Address the issue
4. Kick repeat offenders if necessary

### Custom Announcement Templates
```
/announce [RULES] No ramming, no blocking, have fun!
/announce [INFO] Type /help to see available commands
/announce [EVENT] Next event at the top of the hour!
/announce [RESTART] Server restart in 10 minutes - save your progress!
```

## Troubleshooting

### Commands not working
- Verify you're an admin (check `main.lua` files)
- Ensure player IDs are correct
- Check for typos in commands
- Restart the server if plugins aren't loading

### Teleportation not working
- Players must have spawned vehicles first
- Position data must be available
- Try having both players drive around first

### Events not starting
- Check minimum player requirements
- Ensure no other event is running (use `/stopevent` first)
- Verify event name is spelled correctly
- Check server console for errors

### Players not receiving messages
- Verify player IDs are correct and players are online
- Check that `MP.SendChatMessage` syntax is correct
- Ensure players haven't disabled chat

## Additional Resources

- [AdminTools README](../Resources/Server/AdminTools/README.md)
- [EventManager README](../Resources/Server/EventManager/README.md)
- [CustomEvents README](../Resources/Server/CustomEvents/README.md)
- [BeamMP Documentation](https://docs.beammp.com/)
- [BeamMP Scripting Wiki](https://wiki.beammp.com/en/Scripting)

---

**Remember:** With great power comes great responsibility. Use admin commands fairly and make the server fun for everyone!
