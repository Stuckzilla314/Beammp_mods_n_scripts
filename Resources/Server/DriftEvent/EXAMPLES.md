# Drift Event System - Usage Examples

This document provides practical examples for using the Drift Event plugin.

## Table of Contents
- [Basic Usage](#basic-usage)
- [Admin Examples](#admin-examples)
- [Player Examples](#player-examples)
- [Event Scenarios](#event-scenarios)
- [Scoring Examples](#scoring-examples)
- [Configuration Examples](#configuration-examples)

## Basic Usage

### Starting Your First Event

1. **Simple 5-minute event:**
   ```
   Admin: /driftstart
   Server: DRIFT EVENT STARTED! Duration: 05:00
   ```

2. **Custom 10-minute event:**
   ```
   Admin: /driftstart 600
   Server: DRIFT EVENT STARTED! Duration: 10:00
   ```

3. **Players join and drift:**
   ```
   Player1: /driftstatus
   Server: Drift event is active! Time remaining: 04:23
   Server: Your score: 1250 points (42.5s drift)
   ```

4. **Check rankings:**
   ```
   Player1: /driftlb
   Server: === CURRENT LEADERBOARD ===
   Server: #1: ProDrifter - 3450 pts
   Server: #2: Player1 - 1250 pts
   Server: #3: SlideKing - 980 pts
   ```

5. **Event ends automatically:**
   ```
   Server: DRIFT EVENT FINISHED!
   Server: FINAL LEADERBOARD:
   Server: 🥇 #1: ProDrifter - 15840 points (210.3s drift)
   Server: 🥈 #2: SlideKing - 12320 points (185.5s drift)
   Server: 🥉 #3: Player1 - 8670 points (142.1s drift)
   ```

## Admin Examples

### Event Management

**Start event with different durations:**
```
/driftstart 120    -- 2 minute sprint
/driftstart 300    -- 5 minute standard (default)
/driftstart 600    -- 10 minute challenge
/driftstart 1800   -- 30 minute endurance
```

**Stop event early:**
```
Admin: /driftstop
Server: DRIFT EVENT FINISHED!
[Shows final leaderboard...]
```

**Check event status:**
```
Admin: /driftstatus
Server: Drift event is active!
Server: Time remaining: 03:45
Server: Your score: 0 points (0.0s drift)
```

### Error Handling

**Event already running:**
```
Admin: /driftstart 300
Server: Drift event is already running!
```

**Invalid duration:**
```
Admin: /driftstart 10
Server: Duration must be at least 30 seconds

Admin: /driftstart 5000
Server: Duration cannot exceed 1 hour (3600 seconds)
```

**No event to stop:**
```
Admin: /driftstop
Server: No drift event is currently running
```

## Player Examples

### During Active Event

**Check your score:**
```
Player: /driftstatus
Server: Drift event is active!
Server: Time remaining: 02:15
Server: Your score: 5240 points (68.3s drift)
```

**View leaderboard:**
```
Player: /driftleaderboard
Server: === CURRENT LEADERBOARD ===
Server: #1: DriftKing - 8450 pts
Server: #2: AngleGod - 6320 pts
Server: #3: You - 5240 pts
Server: #4: Novice - 2180 pts
Server: #5: Learning - 1050 pts
```

**Get help:**
```
Player: /drifthelp
Server: === DRIFT EVENT COMMANDS ===
Server: /driftstatus - Check event status and your score
Server: /driftleaderboard (or /driftlb) - Show current rankings
Server: /drifthelp - Show this help message
```

### When No Event Running

```
Player: /driftstatus
Server: No drift event is currently running

Player: /driftlb
Server: No drift event is currently running
```

### Player Joins During Event

```
[Player joins server]
Server: Welcome to the server, NewPlayer!
Server: A drift event is currently running!
Server: Time remaining: 04:30
Server: Type /drifthelp for commands
```

## Event Scenarios

### Scenario 1: Quick Competition

**Setup:**
- 2-minute event
- 5 players
- Goal: Fast, intense competition

**Timeline:**
```
00:00 - Admin: /driftstart 120
00:00 - Server: DRIFT EVENT STARTED! Duration: 02:00
00:15 - Player1: /driftlb (checks standings)
00:30 - Player2 takes lead
01:00 - Player3: /driftstatus (checks progress)
01:30 - Final push, players maximize points
02:00 - Event ends automatically
02:00 - Server shows final leaderboard
```

**Results:**
```
🥇 #1: SpeedDemon - 4520 points (98.2s drift)
🥈 #2: QuickSlide - 4230 points (95.1s drift)
🥉 #3: FastDrift - 3890 points (89.4s drift)
```

### Scenario 2: Endurance Challenge

**Setup:**
- 30-minute event
- 10 players
- Goal: Consistency over time

**Timeline:**
```
00:00 - Admin: /driftstart 1800
00:00 - Server: DRIFT EVENT STARTED! Duration: 30:00
05:00 - Players settle into rhythm
10:00 - Some players ahead, others catching up
15:00 - Halfway point, admin reminds players
20:00 - Final 10 minutes, intensity increases
25:00 - Last push for points
30:00 - Event ends, comprehensive leaderboard shown
```

**Results:**
```
🥇 #1: Consistent - 52380 points (1245.8s drift)
🥈 #2: Steady - 48920 points (1189.3s drift)
🥉 #3: Marathon - 45670 points (1092.7s drift)
```

### Scenario 3: Multiple Rounds

**Tournament Format:**

**Round 1 - Qualifying (5 min):**
```
Admin: /driftstart 300
[All 16 players compete]
[Top 8 advance]
```

**Round 2 - Quarter Finals (3 min):**
```
Admin: /driftstart 180
[8 players compete]
[Top 4 advance]
```

**Round 3 - Semi Finals (3 min):**
```
Admin: /driftstart 180
[4 players compete]
[Top 2 advance]
```

**Round 4 - Final (5 min):**
```
Admin: /driftstart 300
[2 players compete]
[Winner crowned]
```

## Scoring Examples

### Example 1: Beginner Drifter

**Situation:**
- 15° drift angle (low)
- 20 m/s speed (moderate)
- 10m from objects (no proximity bonus)

**Points per second:**
- Base: 40 pts
- Angle: 15° / 90° × 30 = 5 pts
- Speed: ~3 pts
- Proximity: 0 pts
- **Total: 48 pts/sec**

**After 60 seconds:**
- Total score: 2,880 points
- Drift time: 60 seconds

### Example 2: Intermediate Drifter

**Situation:**
- 45° drift angle (moderate)
- 50 m/s speed (high)
- 3m from wall (proximity bonus)

**Points per second:**
- Base: 40 pts
- Angle: 45° / 90° × 30 = 15 pts
- Speed: ~8 pts
- Proximity: (1 - 3/5) × 20 = 8 pts
- **Total: 71 pts/sec**

**After 120 seconds:**
- Total score: 8,520 points
- Drift time: 120 seconds

### Example 3: Professional Drifter

**Situation:**
- 70° drift angle (aggressive)
- 80 m/s speed (very high)
- 1m from wall (very close)

**Points per second:**
- Base: 40 pts
- Angle: 70° / 90° × 30 = 23 pts
- Speed: ~10 pts
- Proximity: (1 - 1/5) × 20 = 16 pts
- **Total: 89 pts/sec**

**After 180 seconds:**
- Total score: 16,020 points
- Drift time: 180 seconds

### Example 4: Perfect Drift

**Situation:**
- 90° drift angle (maximum)
- 100 m/s speed (maximum)
- 0.5m from wall (extremely close)

**Points per second:**
- Base: 40 pts
- Angle: 90° / 90° × 30 = 30 pts
- Speed: 10 pts
- Proximity: (1 - 0.5/5) × 20 = 18 pts
- **Total: 98 pts/sec**

**After 300 seconds (5 min event):**
- Total score: 29,400 points
- Drift time: 300 seconds
- **Winner!**

## Configuration Examples

### Configuration 1: Beginner Server

**Purpose:** Make drifting easier for new players

```lua
-- In main.lua:

local SCORING = {
    DRIFT_TIME = 50,        -- Higher base reward
    ANGLE = 20,             -- Less emphasis on angle
    PROXIMITY = 15,         -- Less emphasis on proximity
    SPEED = 15              -- Reward speed more
}

local DRIFT_THRESHOLD = {
    MIN_ANGLE = 5,          -- Very low threshold
    MIN_SPEED = 10,         -- Lower speed needed
    MAX_SPEED = 80,         -- Lower max for normalization
    PROXIMITY_RANGE = 8     -- Larger proximity range
}
```

**Effect:** Players can score points more easily

### Configuration 2: Pro Competition

**Purpose:** Reward skilled, aggressive drifting

```lua
-- In main.lua:

local SCORING = {
    DRIFT_TIME = 30,        -- Lower base
    ANGLE = 35,             -- High angle reward
    PROXIMITY = 25,         -- High proximity reward
    SPEED = 10              -- Keep speed bonus
}

local DRIFT_THRESHOLD = {
    MIN_ANGLE = 20,         -- High threshold
    MIN_SPEED = 25,         -- Must be fast
    MAX_SPEED = 120,        -- Higher max speed
    PROXIMITY_RANGE = 3     -- Very tight proximity
}
```

**Effect:** Only skilled drifters with good angle and proximity score well

### Configuration 3: Speed Focus

**Purpose:** Reward high-speed drifting

```lua
-- In main.lua:

local SCORING = {
    DRIFT_TIME = 30,
    ANGLE = 20,
    PROXIMITY = 10,
    SPEED = 40              -- Very high speed reward
}

local DRIFT_THRESHOLD = {
    MIN_ANGLE = 10,
    MIN_SPEED = 30,         -- Must be very fast
    MAX_SPEED = 150,        -- Very high max
    PROXIMITY_RANGE = 5
}
```

**Effect:** Fast drifters dominate

### Configuration 4: Technical Track

**Purpose:** Reward precision and proximity

```lua
-- In main.lua:

local SCORING = {
    DRIFT_TIME = 25,
    ANGLE = 25,
    PROXIMITY = 40,         -- Very high proximity reward
    SPEED = 10
}

local DRIFT_THRESHOLD = {
    MIN_ANGLE = 15,
    MIN_SPEED = 15,
    MAX_SPEED = 100,
    PROXIMITY_RANGE = 4     -- Tight proximity range
}
```

**Effect:** Precision near walls/objects is key

## Tips and Strategies

### For Players

1. **Consistency over perfection:** Maintaining a constant drift is better than short perfect drifts
2. **Find your line:** Practice finding walls/objects to drift near for proximity bonus
3. **Speed matters:** Don't drift too slowly - maintain momentum
4. **Check progress:** Use `/driftstatus` to track your improvement
5. **Study leaders:** Watch top players to learn techniques

### For Admins

1. **Warm-up time:** Give players 5-10 minutes to practice before starting event
2. **Clear communication:** Announce event start time in advance
3. **Fair duration:** Match event length to server population and track
4. **Multiple rounds:** Consider running several shorter events vs one long one
5. **Mix it up:** Vary event duration and track selection
6. **Encourage newcomers:** Run beginner-friendly events periodically

## Troubleshooting Examples

### Players Not Scoring

**Symptom:**
```
Player: /driftstatus
Server: Your score: 0 points (0.0s drift)
```

**Possible causes:**
1. Not drifting hard enough (angle < 10°)
2. Going too slow (speed < 15 m/s)
3. Vehicle telemetry not working (see README technical notes)

**Solutions:**
- Increase drift angle
- Maintain higher speed
- Check server vehicle data integration

### Leaderboard Not Updating

**Symptom:**
- Same scores shown repeatedly
- Real-time updates not working

**Cause:**
- Vehicle data not being received by server

**Solution:**
- See README.md Implementation Notes section
- Implement vehicle telemetry system

### Event Won't Start

**Symptom:**
```
Admin: /driftstart 300
Server: You don't have permission to use this command
```

**Solution:**
1. Check admin IDs in `main.lua`
2. Ensure your player ID is in the admins table
3. Restart server after configuration change

---

**For more information:**
- See [README.md](README.md) for detailed documentation
- See [QUICK_START.md](QUICK_START.md) for quick reference
- Check BeamMP documentation for server setup

