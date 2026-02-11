# Drift Event Plugin

A professional drift event system for BeamMP servers based on Formula Drift scoring criteria.

## Features

- **Timed Events**: Admin-configurable event duration
- **Professional Scoring System**: Based on real drift competitions
  - **Drift Time**: 40 points per second base
  - **Angle**: Up to 30 points based on slip angle
  - **Proximity**: Up to 20 points for proximity to objects/clipping points
  - **Speed**: Up to 10 points based on drift speed
- **Real-time Leaderboard**: Track rankings during active events
- **Automatic Event Management**: Timer automatically ends events
- **Player Statistics**: Track individual drift time and scores

## Installation

1. Copy the `DriftEvent` folder to your BeamMP server's `Resources/Server/` directory
2. Configure admin IDs in `main.lua` (see Configuration section)
3. Restart your BeamMP server

## Configuration

Edit the `admins` table in `main.lua` to add admin player IDs:

```lua
local admins = {
    "12345",    -- Replace with actual player IDs
    "67890"
}
```

### Scoring Configuration

You can adjust scoring weights in the `SCORING` table:

```lua
local SCORING = {
    DRIFT_TIME = 40,        -- Points per second of drifting
    ANGLE = 30,             -- Max points for drift angle
    PROXIMITY = 20,         -- Max points for proximity to objects
    SPEED = 10              -- Max points for speed
}
```

### Drift Detection Thresholds

Customize detection sensitivity:

```lua
local DRIFT_THRESHOLD = {
    MIN_ANGLE = 10,         -- Minimum slip angle to count as drifting (degrees)
    MIN_SPEED = 15,         -- Minimum speed to count as drift (m/s)
    MAX_SPEED = 100,        -- Maximum speed for scoring normalization
    PROXIMITY_RANGE = 5     -- Distance to objects for proximity bonus (meters)
}
```

## Commands

### Player Commands

- `/driftstatus` - Check if an event is running, time remaining, and your current score
- `/driftleaderboard` or `/driftlb` - View current top 5 rankings
- `/drifthelp` - Show available commands

### Admin Commands

- `/driftstart [seconds]` - Start a drift event with optional duration
  - Default: 300 seconds (5 minutes)
  - Minimum: 30 seconds
  - Maximum: 3600 seconds (1 hour)
  - Example: `/driftstart 600` (10 minute event)
- `/driftstop` - End the current event early and display final results

## How to Play

1. **Wait for Event Start**: An admin must start the event using `/driftstart`
2. **Start Drifting**: When the event is active, drift to earn points
3. **Scoring Criteria**:
   - **Maintain Drift**: Keep your car sideways to earn base points
   - **Increase Angle**: More aggressive angles = more points
   - **Get Close**: Drive near walls, objects, or clipping zones for proximity bonus
   - **Speed Matters**: Higher speed (while drifting) earns more points
4. **Check Progress**: Use `/driftstatus` to see your score or `/driftlb` to see rankings
5. **Event Ends**: When time expires, final leaderboard is displayed automatically

## Scoring System Explained

The scoring system is based on professional drift competitions like Formula Drift:

### Base Points (40 pts/sec)
- Awarded for every second spent drifting above minimum thresholds
- Requires minimum 10° slip angle and 15 m/s speed

### Angle Score (up to 30 pts/sec)
- Higher drift angles earn more points
- 90° angle = maximum 30 points per second
- Rewards aggressive, controlled drifting

### Proximity Score (up to 20 pts/sec)
- Earned when drifting close to objects (within 5 meters)
- Closer distance = higher score
- Simulates "clipping points" from real competitions

### Speed Score (up to 10 pts/sec)
- Higher speed while drifting earns bonus points
- Normalized between minimum (15 m/s) and maximum (100 m/s) speed
- Rewards fast, confident drifting

### Total Example
A player drifting at:
- 45° angle (50% of max angle) = 15 pts
- 60 m/s speed = ~7 pts
- 2 meters from wall = 12 pts
- Base drift time = 40 pts
- **Total: 74 points per second**

## Leaderboard Display

When an event ends, the top 10 players are shown with:
- Rank (with medals for top 3: 🥇🥈🥉)
- Player name
- Total score
- Total drift time

Example:
```
=================================
DRIFT EVENT FINISHED!
=================================
FINAL LEADERBOARD:
🥇 #1: ProDrifter - 25840 points (350.2s drift)
🥈 #2: SlideKing - 18320 points (298.5s drift)
🥉 #3: AngleGod - 15670 points (245.1s drift)
#4: DriftMaster - 12450 points (210.8s drift)
...
=================================
```

## Implementation Notes

### Current Limitations

This plugin provides the complete scoring framework and event management system. However, **actual drift detection requires vehicle telemetry data** which is not directly exposed by the base BeamMP Lua API.

For full functionality, you would need to implement one of these solutions:

1. **Client-Side Mod**: Create a client-side mod that:
   - Monitors vehicle slip angle, speed, and position
   - Sends telemetry data to server via network events
   - Server receives and processes this data

2. **Vehicle Data Parsing**: Parse BeamMP's vehicle data packets to extract:
   - Slip angle (difference between heading and velocity direction)
   - Speed (velocity magnitude)
   - Position (for proximity calculations)

3. **Alternative Scoring**: Modify the scoring system to use available data:
   - Player position changes
   - Chat-based point awards
   - Manual scoring by admins

### Integration Points

The main.lua file includes detailed comments showing where to integrate vehicle data. The key function to call when telemetry is received is:

```lua
-- When you receive vehicle telemetry data, call this function:
updatePlayerDrift(playerID, isDrifting, slipAngle, speed, proximity)

-- Example integration with custom telemetry event:
function onDriftTelemetry(playerID, data)
    if not driftEvent.active then return end
    
    local isDrifting = (data.slipAngle >= DRIFT_THRESHOLD.MIN_ANGLE and 
                       data.speed >= DRIFT_THRESHOLD.MIN_SPEED)
    updatePlayerDrift(playerID, isDrifting, data.slipAngle, data.speed, data.proximity)
end

MP.RegisterEvent("DriftTelemetry", "onDriftTelemetry")
```

See INTEGRATION.md for complete implementation examples.

## Troubleshooting

### Event won't start
- Verify you have admin permissions
- Check that no event is currently running
- Ensure duration is between 30 and 3600 seconds

### Not earning points
- Confirm event is active using `/driftstatus`
- Check vehicle telemetry integration (see Implementation Notes)
- Verify drift detection thresholds are configured correctly

### Commands not working
- Ensure plugin is loaded (check server console)
- Verify command syntax (use `/drifthelp`)
- Check for typos in command names

## Best Practices

1. **Event Duration**: 
   - Short events (2-5 min) for quick competitions
   - Long events (10-30 min) for endurance challenges
   
2. **Track Selection**:
   - Choose tracks with walls and obstacles for proximity scoring
   - Technical tracks reward skilled drifters
   - Wide-open tracks favor high-speed drifting

3. **Admin Management**:
   - Announce events in advance
   - Give players time to practice before starting
   - Consider running multiple rounds with different durations

4. **Server Settings**:
   - Disable traffic for cleaner drifting
   - Consider specific drift-focused maps
   - Set up spawn points near drift zones

## Future Enhancements

Potential improvements for future versions:

- Multiple drift zones with different point multipliers
- Combo system for sustained drifts
- Penalties for wall contacts or spins
- Custom clipping points per track
- Replay system for top runs
- Team-based drift battles
- Seasonal championships with cumulative points
- Integration with economy systems for rewards

## Credits

Scoring system based on professional drift competitions including:
- Formula Drift (USA)
- D1 Grand Prix (Japan)
- Drift Masters European Championship

## Support

For issues, suggestions, or contributions:
- Check the main repository README
- Review BeamMP documentation
- Join the BeamMP Discord community

## Version History

- **v1.0** - Initial release
  - Event management system
  - Professional scoring algorithm
  - Leaderboard tracking
  - Admin commands
  - Player statistics

