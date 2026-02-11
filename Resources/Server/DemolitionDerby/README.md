# Demolition Derby Plugin

A competitive demolition derby event system for BeamMP servers.

## Features

- **Admin-controlled events**: Only administrators can start and stop derby events
- **Automatic elimination**: Players are eliminated if their vehicle is stationary for 5 seconds
- **Winner announcement**: Automatically announces the winner when only one player remains
- **Feature restrictions during event**:
  - Vehicle reset disabled
  - Teleportation disabled
  - Node grabber disabled
- **Automatic vehicle reset**: All vehicles are reset after the event ends

## Installation

1. Copy the `DemolitionDerby` folder to your BeamMP server's `Resources/Server/` directory
2. Copy the client-side `DemolitionDerby` folder to your BeamMP server's `Resources/Client/` directory
3. Configure admin IDs in the `main.lua` file (see Configuration section)
4. Restart your BeamMP server

## Configuration

Edit `/Resources/Server/DemolitionDerby/main.lua` and add your admin player IDs to the `admins` table:

```lua
local admins = {
    "12345",  -- Replace with actual player IDs
    "67890"
}
```

You can also adjust these settings:

```lua
local STATIONARY_THRESHOLD = 5.0  -- Seconds a car must be stationary to be eliminated
local STATIONARY_DISTANCE = 2.0   -- Distance threshold in meters
local CHECK_INTERVAL = 1.0        -- How often to check positions (seconds)
```

## Commands

### `/startderby`
**Permission**: Admin only  
**Description**: Starts a demolition derby event with all currently connected players

**Requirements**:
- At least 2 players must be connected
- No event can be currently running

### `/stopderby`
**Permission**: Admin only  
**Description**: Immediately stops the current derby event (for emergencies)

## How It Works

1. Admin runs `/startderby` command
2. All connected players are automatically entered into the event
3. Players must keep moving - staying stationary for 5 seconds results in elimination
4. When only one player remains active, they are declared the winner
5. All vehicles are automatically reset after the event ends
6. Restrictions are lifted and normal gameplay resumes

## Game Rules

- **Movement Required**: Keep your vehicle moving! If you stay in roughly the same spot for 5 seconds, you're eliminated
- **No Resets**: Vehicle resets are disabled during the event
- **No Teleporting**: Teleportation is disabled during the event  
- **No Node Grabber**: The node grabber tool is disabled during the event
- **Last One Standing**: The last player with a moving vehicle wins

## Troubleshooting

### Event won't start
- Make sure at least 2 players are connected
- Verify that no other event is currently running
- Check that you have admin permissions

### Players not being eliminated
- Ensure the client-side script is properly installed
- Check server console for errors
- Verify the STATIONARY_THRESHOLD and STATIONARY_DISTANCE settings

### Features not being disabled
- Make sure the client-side script is in `Resources/Client/DemolitionDerby/`
- Restart the server to ensure scripts are loaded
- Check client console for errors

## Notes

- The plugin uses client-server communication to track vehicle positions
- All players automatically participate when an event starts
- Disconnecting during an event counts as elimination
- The event automatically ends if only 0 or 1 players remain

## Version

1.0.0

## License

This script is provided as-is for BeamMP servers. Feel free to modify and distribute.
