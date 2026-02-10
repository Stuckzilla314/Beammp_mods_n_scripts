# AdminTools Plugin

A basic admin command system for BeamMP servers. Provides essential admin commands for server management.

## Features

- Admin permission system based on player IDs
- `/help` command for all players
- `/kick [id]` command for admins
- `/announce [message]` command for admins
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
- `/kick [player_id]` - Kicks a player from the server
  - Example: `/kick 0`
- `/announce [message]` - Sends a server-wide announcement
  - Example: `/announce Server will restart in 5 minutes!`

## Notes

- Commands starting with `/` are intercepted and won't appear in chat
- Non-admin players attempting to use admin commands will receive a permission denied message
- All admin actions are visible to all players
