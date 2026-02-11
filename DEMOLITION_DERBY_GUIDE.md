# Demolition Derby Quick Start Guide

## Installation

1. **Copy Server Plugin**
   ```bash
   cp -r Resources/Server/30_DemolitionDerby /path/to/beammp-server/Resources/Server/
   ```

2. **Copy Client Mod**
   ```bash
   cp -r Resources/Client/DemolitionDerby /path/to/beammp-server/Resources/Client/
   ```

3. **Configure Admins**
   - Edit `Resources/Server/30_DemolitionDerby/main.lua`
   - Add your player IDs to the `admins` table (find IDs in server console when you connect)

4. **Restart Server**

## Usage

### For Admins

1. **Start Event**: `/startderby`
   - Requires at least 2 players connected
   - All connected players automatically participate

2. **Stop Event**: `/stopderby`
   - Emergency stop if needed

3. **Check Status**: `/derbystatus`
   - See if event is running and how many players remain

### For Players

- **Get Help**: `/derbyhelp`
- **Check Status**: `/derbystatus`
- **Stay Moving!** If you're stationary for 5 seconds, you're out

## Game Rules

1. Keep your vehicle moving at all times
2. If you stay in one spot for 5 seconds, you're eliminated
3. Last player with a moving vehicle wins
4. During the event:
   - Cannot reset your vehicle
   - Cannot use node grabber
   - Disconnecting counts as elimination

## Configuration Options

Edit `Resources/Server/30_DemolitionDerby/main.lua` to adjust:

```lua
local STATIONARY_THRESHOLD = 5.0  -- Seconds before elimination (default: 5)
local STATIONARY_DISTANCE = 2.0   -- Movement threshold in meters (default: 2)
local CHECK_INTERVAL = 1.0        -- Position check frequency (default: 1)
```

## Troubleshooting

### Event won't start
- Check at least 2 players are connected
- Verify you're in the admins list
- Ensure no event is already running

### Players not eliminated
- Check client script is installed in Resources/Client/
- Verify server console for errors
- Restart server to reload scripts

### Features not disabled
- Ensure client script is properly installed
- Check client console (F11) for errors
- Some features may not work if BeamNG/BeamMP objects unavailable

## Support

Check the full README in `Resources/Server/30_DemolitionDerby/README.md` for detailed information.
