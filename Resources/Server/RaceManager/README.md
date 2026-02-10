# RaceManager Plugin

A comprehensive race management system for BeamMP servers featuring start/end gates, countdown timers, vehicle freeze during countdown, and real-time leaderboards.

## Features

- **Start and End Gates**: Define race tracks by setting start and end gate positions
- **Countdown System**: 3-second countdown before race starts
- **Vehicle Freeze**: Prevents vehicle movement during countdown to ensure fair starts
- **Live Leaderboard**: Tracks which racers are closest to the finish line during the race
- **Finish Times**: Records and displays finish times and positions when racers cross the finish line
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
   - After 3-second countdown, race begins
   - Players race to the finish line
   - Leaderboard shows live standings and finish times

## How It Works

### Race States

1. **Idle**: No race in progress, players can join
2. **Countdown**: 3-second countdown, vehicles are frozen
3. **Racing**: Race in progress, leaderboard updates in real-time
4. **Finished**: All racers have finished, final results displayed

### Leaderboard System

The leaderboard has two sections:

1. **Finished**: Shows players who completed the race, ordered by finish position with times
2. **Racing**: Shows active racers ordered by distance to finish line (closest first)

### Vehicle Freeze

During the countdown phase, the system notifies all players not to move their vehicles. This ensures all racers start at the same time when the countdown reaches zero.

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
Server: Get to the start gate now!
Server: ========================================
Server: Race starts in 3...
Server: Race starts in 2...
Server: Race starts in 1...
Server: ========================================
Server: GO! GO! GO!
Server: ========================================

[Players race to finish line]

Server: Player1 finished in position #1! Time: 45.23s
Server: Player2 finished in position #2! Time: 47.89s

Server: ========================================
Server: RACE FINISHED!
Server: ========================================
Server: ======== LEADERBOARD ========
Server: --- FINISHED ---
Server: 1. Player1 - 45.23s
Server: 2. Player2 - 47.89s
Server: ============================
```

## Configuration

Edit these values in `main.lua` to customize behavior:

- `GATE_RADIUS`: Default radius for gates (default: 15 meters)
- `UPDATE_INTERVAL`: How often to update race state (default: 0.1 seconds)
- `countdownMax`: Countdown duration in seconds (default: 3)

## Notes

- Players must be within the start gate radius when the race starts
- The system tracks distance to the end gate in real-time during the race
- Leaderboard can be checked at any time during the race with `/race leaderboard`
- If a player disconnects during a race, they are automatically removed from participants
- Race can be stopped at any time by an admin using `/race stop`

## Technical Details

### Position Format

Positions are specified as comma-separated values: `x,y,z[,radius]`
- `x`, `y`, `z`: 3D coordinates in the game world
- `radius`: (optional) Gate detection radius in meters

### Distance Calculation

The system uses 3D Euclidean distance to calculate:
- Whether vehicles are within gate boundaries
- Distance to finish line for leaderboard ordering

### Limitations

This implementation provides the core race functionality. For production use, you may want to add:
- Client-side vehicle position synchronization
- Visual gate markers in the game world
- Support for multiple concurrent races
- Race templates/presets for different tracks
- Spectator mode
- Anti-cheat mechanisms
