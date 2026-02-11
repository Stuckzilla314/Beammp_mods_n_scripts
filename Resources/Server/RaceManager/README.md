# RaceManager Plugin

A comprehensive race management system for BeamMP servers featuring start/end gates, countdown timers, vehicle freeze during countdown, and real-time leaderboards.

## Features

- **Start and End Gates**: Define race tracks by setting start and end gate positions (primarily for reference)
- **Countdown System**: Manual 3-second countdown before race starts
- **Vehicle Freeze Notification**: Sends messages to players during countdown asking them not to move
- **Leaderboard**: Tracks participants and their finish times
- **Manual Finish Recording**: Admin can record finish times when racers cross the finish line
- **Multiple Race States**: Manages race progression through idle, countdown, racing, and finished states

## Commands

### Player Commands

- `/race` or `/race help` - Display available commands
- `/race join` - Join the current race (before it starts)
- `/race leave` - Leave the current race
- `/race leaderboard` - Display the current leaderboard

### Admin Commands

- `/race setstart x,y,z[,radius]` - Set the start gate position
  - Example: `/race setstart 100,50,200` (uses default 15m radius)
  - Example: `/race setstart 100,50,200,20` (uses 20m radius)
  
- `/race setend x,y,z[,radius]` - Set the finish line position
  - Example: `/race setend 500,50,250` (uses default 15m radius)
  - Example: `/race setend 500,50,250,25` (uses 25m radius)
  
- `/race start` - Start the race countdown
- `/race countdown` - Progress the countdown by 1 second (use 3 times: 3, 2, 1, then race starts)
- `/race finish [playerName] [time]` - Record a player's finish time
  - Example: `/race finish Player1 45.23`
- `/race stop` - Stop and reset the current race

## Setup

1. **Add Admins**: Edit the `admins` table in `main.lua` to add admin player IDs:
   ```lua
   local admins = {
       "12345",  -- Replace with actual admin IDs
       "67890"
   }
   ```

2. **Configure Gates**: Admins must set up start and end gates before starting a race
   - Use `/race setstart x,y,z` to set the starting position
   - Use `/race setend x,y,z` to set the finish line position
   - Optional: Add a 4th parameter to customize gate radius (default is 15 meters)

3. **Start a Race**:
   - Players use `/race join` to enter the race
   - Admin uses `/race start` to begin countdown
   - Admin uses `/race countdown` three times (for 3, 2, 1)
   - After third countdown, race begins automatically
   - Admin uses `/race finish [playerName] [time]` to record each finish
     - Time should be measured from race start
   - View results with `/race leaderboard`

## How It Works

### Race States

1. **Idle**: No race in progress, players can join
2. **Countdown**: Admin-controlled 3-step countdown (3, 2, 1), players notified not to move
3. **Racing**: Race in progress, admin records finishes
4. **Finished**: All racers have finished, final results displayed (automatically transitions when all finish)

### Leaderboard System

The leaderboard displays:

1. **Finished**: Shows players who completed the race, ordered by finish position with times
2. **Racing**: Shows active racers who haven't finished yet

Note: Since BeamMP doesn't provide automatic real-time vehicle position tracking, finish times must be recorded manually by an admin using the `/race finish` command.

### Vehicle Freeze

During the countdown phase, the system sends messages to all players asking them not to move their vehicles. This is an honor system - players are expected to wait until "GO!" is announced. BeamMP does not provide server-side vehicle control APIs to enforce this automatically.

## Example Race Setup

```
Admin: /race setstart 100,200,300
Server: Race start gate has been set!

Admin: /race setend 900,200,350
Server: Race finish line has been set!

Player1: /race join
Server: Player1 joined the race!

Player2: /race join
Server: Player2 joined the race!

Admin: /race start
Server: ========================================
Server: RACE STARTING!
Server: ========================================
Server: COUNTDOWN: 3...

Admin: /race countdown
Server: COUNTDOWN: 2...
Server: FREEZE! Don't move until GO!

Admin: /race countdown
Server: COUNTDOWN: 1...
Server: FREEZE! Don't move until GO!

Admin: /race countdown
Server: ========================================
Server: GO! GO! GO!
Server: ========================================

[Players race to finish line - admin watches]

Admin: /race finish Player1 45.23
Server: Player1 finished in position #1! Time: 45.23s

Admin: /race finish Player2 47.89
Server: Player2 finished in position #2! Time: 47.89s

Server: ========================================
Server: RACE FINISHED!
Server: ========================================

Player1: /race leaderboard
Server: ======== LEADERBOARD ========
Server: --- FINISHED ---
Server: 1. Player1 - 45.23s
Server: 2. Player2 - 47.89s
Server: ============================
```

## Configuration

Edit these values in `main.lua` to customize behavior:

- `GATE_RADIUS`: Default radius for gates (default: 15 meters)
- `countdownMax`: Countdown duration in steps (default: 3)

## Notes

- Start and end gates are defined for reference purposes and to mark the race course
- The countdown is progressed manually by an admin using `/race countdown` command
- Players are asked not to move during countdown (honor system)
- Finish times must be recorded manually by admins using `/race finish [player] [time]`
- Leaderboard can be checked at any time during the race with `/race leaderboard`
- If a player disconnects during a race, they are automatically removed from participants
- Race can be stopped at any time by an admin using `/race stop`

## Limitations & Future Enhancements

This implementation provides core race functionality within BeamMP's API constraints:

**Current Limitations:**
- Vehicle freezing is notification-based (honor system), not enforced
- Position tracking and finish detection require manual admin input
- Countdown must be manually progressed

**Why These Limitations:**
BeamMP's server-side Lua API doesn't provide:
- Real-time vehicle position updates to the server
- Server-side vehicle control (freezing/unfreezing)
- Automated timer/tick events

**Possible Future Enhancements:**
- Client-side mod to send position updates to server
- Visual gate markers in the game world
- Support for multiple concurrent races
- Race templates/presets for different tracks
- Spectator mode
- Automated timing with client-side integration
