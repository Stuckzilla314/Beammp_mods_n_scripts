# Drift Event - Developer Integration Guide

This guide is for developers who want to integrate actual vehicle telemetry with the Drift Event scoring system.

## Overview

The Drift Event plugin provides a complete scoring framework, but requires vehicle data to calculate scores in real-time. This guide explains how to integrate vehicle telemetry data.

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Client-Side    │         │   BeamMP Server  │         │  Drift Event    │
│  Vehicle Data   │ ──────> │   (Networking)   │ ──────> │     Scoring     │
│  Collection     │         │                  │         │     System      │
└─────────────────┘         └──────────────────┘         └─────────────────┘
```

## Required Data Points

For accurate drift scoring, the following data is needed for each player's vehicle:

### 1. Slip Angle (degrees)
- **Definition:** Angle between vehicle heading and velocity vector
- **Range:** 0° (straight) to 90° (full sideways)
- **Used for:** Angle scoring component

### 2. Vehicle Speed (m/s)
- **Definition:** Magnitude of velocity vector
- **Range:** 0 to 150+ m/s
- **Used for:** Speed scoring and drift detection threshold

### 3. Position (x, y, z)
- **Definition:** 3D coordinates in world space
- **Used for:** Proximity calculations to objects/walls

### 4. Heading Direction (degrees)
- **Definition:** Direction vehicle is facing
- **Used for:** Calculating slip angle

### 5. Velocity Vector (x, y, z)
- **Definition:** Direction and speed of movement
- **Used for:** Calculating slip angle and speed

## Integration Methods

### Method 1: Client-Side Mod (Recommended)

Create a client-side mod that monitors vehicle data and sends it to the server.

#### Client-Side Code (Lua)

```lua
-- Client/DriftTelemetry/main.lua

local updateInterval = 0.1  -- Update every 100ms
local lastUpdate = 0

local function sendVehicleTelemetry()
    local vehicle = be:getPlayerVehicle(0)
    if not vehicle then return end
    
    -- Get vehicle data
    local position = vehicle:getPosition()
    local velocity = vehicle:getVelocity()
    local rotation = vehicle:getRotation()
    
    -- Calculate slip angle
    local heading = math.atan2(rotation.y, rotation.x)
    local velocityAngle = math.atan2(velocity.y, velocity.x)
    local slipAngle = math.abs(heading - velocityAngle) * (180 / math.pi)
    
    -- Normalize to 0-90 degrees
    if slipAngle > 90 then
        slipAngle = 180 - slipAngle
    end
    
    -- Calculate speed
    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    
    -- Find nearest object (simplified - use proper distance check)
    local nearestDistance = 999
    -- TODO: Implement proper proximity detection
    
    -- Send to server
    local data = {
        slipAngle = slipAngle,
        speed = speed,
        position = {x = position.x, y = position.y, z = position.z},
        proximity = nearestDistance
    }
    
    -- Send via BeamMP network event
    TriggerServerEvent("DriftTelemetry", data)
end

local function onUpdate(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate >= updateInterval then
        lastUpdate = 0
        sendVehicleTelemetry()
    end
end

-- Register update hook
-- (Exact method depends on BeamNG.drive modding API)
```

#### Server-Side Integration

```lua
-- In DriftEvent/main.lua, add this function:

function onDriftTelemetry(playerID, data)
    if not driftEvent.active then
        return
    end
    
    -- Extract data
    local slipAngle = data.slipAngle or 0
    local speed = data.speed or 0
    local proximity = data.proximity or 999
    
    -- Determine if drifting
    local isDrifting = (slipAngle >= DRIFT_THRESHOLD.MIN_ANGLE and 
                       speed >= DRIFT_THRESHOLD.MIN_SPEED)
    
    -- Update player stats
    updatePlayerDrift(playerID, isDrifting, slipAngle, speed, proximity)
end

-- Register the event handler
MP.RegisterEvent("DriftTelemetry", "onDriftTelemetry")
```

### Method 2: Vehicle Data Parsing

Parse BeamMP's native vehicle data packets.

```lua
-- In DriftEvent/main.lua

function onVehicleData(playerID, vehicleID, data)
    if not driftEvent.active then
        return
    end
    
    -- Parse data packet (format depends on BeamMP version)
    local parsedData = parseVehicleData(data)
    
    if parsedData then
        local slipAngle = calculateSlipAngle(parsedData)
        local speed = calculateSpeed(parsedData)
        local proximity = calculateProximity(parsedData)
        local isDrifting = detectDrift(parsedData)
        
        updatePlayerDrift(playerID, isDrifting, slipAngle, speed, proximity)
    end
end

-- Helper functions
local function parseVehicleData(data)
    -- Implementation depends on BeamMP's data format
    -- Return table with: position, velocity, rotation
    return nil  -- Placeholder
end

local function calculateSlipAngle(data)
    -- Extract heading from rotation
    local heading = math.atan2(data.rotation.y, data.rotation.x)
    
    -- Extract velocity direction
    local velocityAngle = math.atan2(data.velocity.y, data.velocity.x)
    
    -- Calculate slip angle
    local slipAngle = math.abs(heading - velocityAngle) * (180 / math.pi)
    
    -- Normalize to 0-90 degrees
    if slipAngle > 90 then
        slipAngle = 180 - slipAngle
    end
    
    return slipAngle
end

local function calculateSpeed(data)
    -- Calculate magnitude of velocity vector
    return math.sqrt(
        data.velocity.x^2 + 
        data.velocity.y^2 + 
        data.velocity.z^2
    )
end

local function calculateProximity(data)
    -- Find distance to nearest object/wall
    -- This requires map data or raycasting
    
    -- Simplified example using predefined clipping points
    local minDistance = 999
    for _, clipPoint in ipairs(clippingPoints) do
        local dx = data.position.x - clipPoint.x
        local dy = data.position.y - clipPoint.y
        local dz = data.position.z - clipPoint.z
        local distance = math.sqrt(dx^2 + dy^2 + dz^2)
        
        if distance < minDistance then
            minDistance = distance
        end
    end
    
    return minDistance
end

local function detectDrift(data)
    local slipAngle = calculateSlipAngle(data)
    local speed = calculateSpeed(data)
    
    return (slipAngle >= DRIFT_THRESHOLD.MIN_ANGLE and 
            speed >= DRIFT_THRESHOLD.MIN_SPEED)
end

-- Register event
MP.RegisterEvent("onVehicleData", "onVehicleData")
```

### Method 3: Timer-Based Updates

Use BeamMP's timer system to periodically check vehicle states.

```lua
-- In DriftEvent/main.lua

local function updateAllPlayerDrifts()
    if not driftEvent.active then
        return
    end
    
    for playerID, _ in pairs(playerStats) do
        -- Get player's primary vehicle
        local vehicleData = getPlayerVehicleData(playerID)
        
        if vehicleData then
            local slipAngle = calculateSlipAngle(vehicleData)
            local speed = calculateSpeed(vehicleData)
            local proximity = calculateProximity(vehicleData)
            local isDrifting = detectDrift(vehicleData)
            
            updatePlayerDrift(playerID, isDrifting, slipAngle, speed, proximity)
        end
    end
end

-- Set up timer (BeamMP timer API)
MP.CreateTimer(updateAllPlayerDrifts, 100)  -- 100ms interval
```

## Proximity Detection Strategies

### Strategy 1: Predefined Clipping Points

Define specific points on the track for proximity scoring.

```lua
-- Track-specific clipping points
local clippingPoints = {
    {x = 100, y = 200, z = 0, name = "Turn 1 Inside"},
    {x = 150, y = 250, z = 0, name = "Turn 1 Outside"},
    {x = 200, y = 300, z = 0, name = "Turn 2 Apex"},
    -- Add more points...
}

local function findNearestClippingPoint(position)
    local minDistance = 999
    local nearestPoint = nil
    
    for _, point in ipairs(clippingPoints) do
        local dx = position.x - point.x
        local dy = position.y - point.y
        local dz = position.z - point.z
        local distance = math.sqrt(dx^2 + dy^2 + dz^2)
        
        if distance < minDistance then
            minDistance = distance
            nearestPoint = point
        end
    end
    
    return minDistance, nearestPoint
end
```

### Strategy 2: Raycast to Objects

Use raycasting to find distance to nearest solid object.

```lua
local function castProximityRays(position, heading)
    -- Cast rays perpendicular to vehicle direction
    local rayLength = 10  -- meters
    
    -- Calculate perpendicular directions
    local leftDir = {
        x = -math.sin(heading),
        y = math.cos(heading),
        z = 0
    }
    
    local rightDir = {
        x = math.sin(heading),
        y = -math.cos(heading),
        z = 0
    }
    
    -- Cast rays (requires BeamNG/BeamMP raycast API)
    local leftHit = castRay(position, leftDir, rayLength)
    local rightHit = castRay(position, rightDir, rayLength)
    
    -- Return closest hit
    local minDistance = math.min(
        leftHit and leftHit.distance or 999,
        rightHit and rightHit.distance or 999
    )
    
    return minDistance
end
```

### Strategy 3: Zone-Based Detection

Define drift zones with boundaries.

```lua
local driftZones = {
    {
        name = "Hairpin Zone",
        bounds = {
            minX = 90, maxX = 160,
            minY = 190, maxY = 260,
            minZ = -5, maxZ = 5
        },
        walls = {
            {x = 100, y = 200, z = 0},  -- Inside wall
            {x = 150, y = 250, z = 0}   -- Outside wall
        }
    },
    -- Add more zones...
}

local function getZoneProximity(position)
    -- Find which zone player is in
    for _, zone in ipairs(driftZones) do
        if isInZone(position, zone.bounds) then
            -- Find nearest wall in this zone
            local minDist = 999
            for _, wall in ipairs(zone.walls) do
                local dist = distance(position, wall)
                if dist < minDist then
                    minDist = dist
                end
            end
            return minDist
        end
    end
    
    return 999  -- Not in any drift zone
end
```

## Testing Your Integration

### Test 1: Verify Data Collection

```lua
-- Add debug logging
function onDriftTelemetry(playerID, data)
    print(string.format(
        "[DriftEvent] P%d: Angle=%.1f Speed=%.1f Proximity=%.1f",
        playerID, data.slipAngle, data.speed, data.proximity
    ))
    -- ... rest of function
end
```

### Test 2: Validate Scoring

```lua
-- Test scoring calculation
local function testScoring()
    -- Test case 1: Moderate drift
    local score1 = calculateDriftScore(45, 50, 3)
    print("Test 1 (45°, 50m/s, 3m): " .. score1 .. " pts")
    
    -- Test case 2: Aggressive drift
    local score2 = calculateDriftScore(70, 80, 1)
    print("Test 2 (70°, 80m/s, 1m): " .. score2 .. " pts")
    
    -- Test case 3: Perfect drift
    local score3 = calculateDriftScore(90, 100, 0.5)
    print("Test 3 (90°, 100m/s, 0.5m): " .. score3 .. " pts")
end
```

### Test 3: Monitor Update Rate

```lua
local updateCount = 0
local lastPrintTime = os.time()

function onDriftTelemetry(playerID, data)
    updateCount = updateCount + 1
    
    local now = os.time()
    if now - lastPrintTime >= 5 then
        print(string.format(
            "[DriftEvent] Updates per second: %.1f",
            updateCount / 5
        ))
        updateCount = 0
        lastPrintTime = now
    end
    
    -- ... rest of function
end
```

## Performance Considerations

### Optimization Tips

1. **Update Rate:** Don't update more than 10-20 times per second per player
   ```lua
   local UPDATE_INTERVAL = 0.1  -- 100ms = 10 updates/sec
   ```

2. **Proximity Checks:** Cache clipping point distances
   ```lua
   local proximityCache = {}
   local CACHE_DURATION = 0.5  -- Cache for 500ms
   ```

3. **Player Count:** Scale update frequency based on player count
   ```lua
   local function getUpdateInterval()
       local playerCount = MP.GetPlayerCount()
       if playerCount > 20 then
           return 0.2  -- 5 updates/sec
       else
           return 0.1  -- 10 updates/sec
       end
   end
   ```

4. **Active Players Only:** Only update players who are actively drifting
   ```lua
   if speed < DRIFT_THRESHOLD.MIN_SPEED then
       return  -- Skip update for stationary vehicles
   end
   ```

## Example: Complete Integration

Here's a complete example combining all components:

```lua
-- Complete integration example

-- At top of main.lua, add:
local telemetryCache = {}

function onDriftTelemetry(playerID, data)
    if not driftEvent.active then
        return
    end
    
    -- Validate data
    if not data or not data.slipAngle or not data.speed then
        return
    end
    
    -- Cache the telemetry
    telemetryCache[playerID] = {
        slipAngle = data.slipAngle,
        speed = data.speed,
        proximity = data.proximity or 999,
        timestamp = os.time()
    }
end

-- Update scores every second using cached data
local lastScoreUpdate = os.time()
function onTick()
    local currentTime = os.time()
    
    if currentTime - lastScoreUpdate >= 1 then
        lastScoreUpdate = currentTime
        
        -- Update all player scores
        for playerID, cachedData in pairs(telemetryCache) do
            -- Check if data is fresh (within 2 seconds)
            if currentTime - cachedData.timestamp <= 2 then
                local isDrifting = (
                    cachedData.slipAngle >= DRIFT_THRESHOLD.MIN_ANGLE and
                    cachedData.speed >= DRIFT_THRESHOLD.MIN_SPEED
                )
                
                updatePlayerDrift(
                    playerID,
                    isDrifting,
                    cachedData.slipAngle,
                    cachedData.speed,
                    cachedData.proximity
                )
            end
        end
        
        -- Check event timer
        checkEventTimer()
    end
end

-- Register events
MP.RegisterEvent("DriftTelemetry", "onDriftTelemetry")

-- Note: BeamMP timer creation varies by version.
-- Check your BeamMP documentation for the correct timer API.
-- Example alternatives:
-- MP.CreateTimer(onTick, 1000)              -- Some versions
-- MP.RegisterEvent("onTick", "onTick")      -- If onTick event exists
-- Or implement as periodic event from client
```

## Resources

- [BeamMP Lua API Documentation](https://docs.beammp.com/)
- [BeamNG.drive Modding Documentation](https://documentation.beamng.com/)
- [Lua 5.3 Reference Manual](https://www.lua.org/manual/5.3/)

## Support

For questions about integration:
1. Check BeamMP Discord #modding channel
2. Review BeamMP example plugins
3. Study existing telemetry mods

---

**Note:** The exact implementation details depend on your BeamMP server version and available APIs. Consult the latest BeamMP documentation for specific function names and data formats.

