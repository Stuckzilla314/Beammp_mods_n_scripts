# Drift Event Quick Start Guide

## For Server Admins

### Initial Setup

1. **Add Your Admin ID**
   - Edit `main.lua`
   - Find the `admins` table
   - Add your player ID(s):
   ```lua
   local admins = {
       "YOUR_PLAYER_ID_HERE"
   }
   ```

2. **Restart Server**
   - The plugin will load automatically

### Running an Event

#### Basic Event (5 minutes)
```
/driftstart
```

#### Custom Duration
```
/driftstart 600    -- 10 minute event
/driftstart 120    -- 2 minute event
/driftstart 1800   -- 30 minute event
```

#### Stop Event Early
```
/driftstop
```

#### Check Event Status
```
/driftstatus
```

### Tips for Great Events

**Timing**
- 2-5 minutes: Quick competition
- 5-10 minutes: Standard event
- 15-30 minutes: Endurance challenge

**Before Starting**
- Announce the event in chat
- Give players time to prepare
- Choose appropriate track/location
- Consider clearing traffic

**During Event**
- Monitor leaderboard with `/driftlb`
- Watch for technical issues
- Keep chat positive and engaging

**After Event**
- Congratulate winners
- Share final leaderboard
- Consider running multiple rounds

## For Players

### Essential Commands

```
/drifthelp          -- Show all commands
/driftstatus        -- Check time & your score  
/driftlb            -- View top 5 rankings
```

### How to Score Points

1. **Start Drifting** - Get your car sideways (min 10° angle)
2. **Maintain Speed** - Keep above 15 m/s
3. **Increase Angle** - More sideways = more points
4. **Get Close** - Drift near walls/objects for bonus
5. **Go Fast** - Higher speed earns more

### Point Breakdown

- **40 pts/sec** - Base drift time
- **+30 pts/sec** - Angle bonus (max at 90°)
- **+20 pts/sec** - Proximity bonus (within 5m of objects)
- **+10 pts/sec** - Speed bonus (faster = better)
- **Max: 100 pts/sec** when drifting perfectly!

### Strategy

**Beginner**: Focus on maintaining long drifts
**Intermediate**: Add angle and speed
**Advanced**: Master proximity scoring near walls

## Example Event Flow

1. **Admin**: `/driftstart 300` (5 min event)
2. **Server**: "DRIFT EVENT STARTED! Duration: 05:00"
3. **Players**: Start drifting to earn points
4. **Players**: Use `/driftlb` to check rankings
5. **Auto**: Event ends after 5 minutes
6. **Server**: Shows final leaderboard with winner

## Troubleshooting

**"You don't have permission"**
- You're not configured as admin
- Check admin IDs in `main.lua`

**"Event already running"**
- Stop current event first: `/driftstop`
- Or wait for it to finish

**"No event is running"**
- Admin needs to start event: `/driftstart`

**Not earning points**
- Check if event is active: `/driftstatus`
- Ensure you're drifting (angle + speed)
- See README.md for technical details

## Configuration Examples

### Beginner-Friendly Settings
```lua
DRIFT_THRESHOLD = {
    MIN_ANGLE = 5,      -- Easier to trigger
    MIN_SPEED = 10,     -- Lower speed requirement
    ...
}
```

### Pro Competition Settings
```lua
DRIFT_THRESHOLD = {
    MIN_ANGLE = 15,     -- Requires good angle
    MIN_SPEED = 20,     -- Must be fast
    ...
}
```

### Proximity-Focused (Technical Tracks)
```lua
local SCORING = {
    DRIFT_TIME = 30,
    ANGLE = 25,
    PROXIMITY = 35,     -- Increased for tight courses
    SPEED = 10
}
```

### Speed-Focused (Open Tracks)
```lua
local SCORING = {
    DRIFT_TIME = 30,
    ANGLE = 25,
    PROXIMITY = 10,
    SPEED = 35          -- Increased for high-speed drift
}
```

## Advanced Usage

### Multiple Events
Run different event types:
- Sprint: 2 minutes, high intensity
- Standard: 5-10 minutes, balanced
- Endurance: 20-30 minutes, consistency test

### Tournament Format
1. Qualifying round (5 min) - Top 8 advance
2. Quarter finals (3 min) - 1v1 battles
3. Semi finals (3 min)
4. Final (5 min) - Winner takes all

### Practice Mode
- Run unlimited time event for practice
- Use `/driftstop` when done
- No official results

## Getting Player IDs

To find player IDs for admin configuration:

1. Player joins server
2. Check server console logs
3. Or use existing admin tools
4. Note the numeric ID (e.g., "12345")
5. Add to `admins` table in quotes

---

**Need Help?**
- Read full README.md for details
- Check BeamMP documentation
- Visit BeamMP Discord community
