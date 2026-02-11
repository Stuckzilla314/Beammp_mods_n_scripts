# AdminTools Plugin

A comprehensive admin command system for BeamMP servers. Provides essential admin commands for server management, player control, and server moderation.

## Features

- Admin permission system based on player IDs
- Player management commands (kick, teleport)
- Vehicle control commands (freeze, explode, reset)
- Server announcements
- Permission checks to prevent unauthorized command use

## Installation

1. Copy the `AdminTools` folder to your BeamMP server's `Resources/Server/` directory
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

To find a player's ID, check the server console when they connect, or use the BeamMP server console.

## Available Commands

### For All Players
- `/help` - Shows available commands

### For Admins Only

#### Player Management
- `/kick [player_id]` - Kicks a player from the server
  - Example: `/kick 0`
- `/announce [message]` - Sends a server-wide announcement
  - Example: `/announce Server will restart in 5 minutes!`

#### Teleportation Commands
- `/tp [player_id]` - Teleport yourself to another player
  - Example: `/tp 1`
- `/tphere [player_id]` - Teleport a player to your location
  - Example: `/tphere 2`
- `/tpall` - Teleport all players to your location
  - Example: `/tpall`

#### Vehicle Control
- `/freeze [player_id]` - Freeze a player's vehicle (prevents movement)
  - Example: `/freeze 1`
- `/unfreeze [player_id]` - Unfreeze a player's vehicle
  - Example: `/unfreeze 1`
- `/explode [player_id]` - Explode a player's vehicle
  - Example: `/explode 1`
  - Note: This is destructive and will damage/destroy the vehicle
- `/resetvehicle [player_id]` - Reset a player's vehicle to original state
  - Example: `/resetvehicle 1`

## Notes

- Commands starting with `/` are intercepted and won't appear in chat
- Non-admin players attempting to use admin commands will receive a permission denied message
- All admin actions are visible to all players (server announcements)
- Teleportation requires player position data to be available
- Vehicle control commands trigger client-side events

## Client-Side Events

The following client events are triggered by admin commands:
- `freezeVehicle` - Freezes the player's vehicle
- `unfreezeVehicle` - Unfreezes the player's vehicle
- `explodeVehicle` - Explodes the player's vehicle
- `resetVehicle` - Resets the player's vehicle

These events can be handled by client-side Lua scripts if you want to customize their behavior.

## Troubleshooting

### Commands not working
- Verify your player ID is in the admins table
- Check the server console for error messages
- Make sure you're using the correct syntax for each command

### Teleportation not working
- Position tracking requires players to have spawned vehicles
- Position data is extracted from vehicle spawn data when available
- Try spawning a vehicle and moving around first
- Check server logs for position data errors
- Note: Position tracking may not be 100% accurate; consider it a best-effort feature
