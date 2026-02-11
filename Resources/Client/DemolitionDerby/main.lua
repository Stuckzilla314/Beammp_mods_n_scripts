-- DemolitionDerby Client-Side Script
-- Handles position tracking and feature disabling during events

local M = {}

-- Event state
local derbyActive = false
local positionCheckInterval = 1.0  -- Check position every second
local lastPositionCheck = 0

-- Feature states
local originalNodeGrabberEnabled = true
local originalTeleportEnabled = true

-- Get current vehicle position
local function getCurrentVehiclePosition()
    local vehicle = be:getPlayerVehicle(0)
    if vehicle then
        local pos = vehicle:getPosition()
        return pos
    end
    return nil
end

-- Send position to server
local function sendPositionToServer()
    local pos = getCurrentVehiclePosition()
    if pos then
        local posData = string.format("%.2f,%.2f,%.2f", pos.x, pos.y, pos.z)
        MP.TriggerServerEvent("DerbyPositionUpdate", posData)
    end
end

-- Disable features during derby
local function disableFeatures()
    derbyActive = true
    
    -- Disable node grabber
    if scenetree.NodeGrabber then
        originalNodeGrabberEnabled = scenetree.NodeGrabber:isEnabled()
        scenetree.NodeGrabber:setEnabled(false)
    end
    
    -- Note: Teleport and reset are handled server-side
    -- We just track the state here for UI purposes
    
    print("[DemolitionDerby] Features disabled - Derby is active!")
end

-- Enable features after derby
local function enableFeatures()
    derbyActive = false
    
    -- Re-enable node grabber
    if scenetree.NodeGrabber then
        scenetree.NodeGrabber:setEnabled(originalNodeGrabberEnabled)
    end
    
    print("[DemolitionDerby] Features enabled - Derby ended")
end

-- Reset vehicle
local function resetVehicle()
    local vehicle = be:getPlayerVehicle(0)
    if vehicle then
        vehicle:reset()
    end
end

-- Update function called periodically
local function onUpdate(dt)
    if not derbyActive then
        return
    end
    
    lastPositionCheck = lastPositionCheck + dt
    
    if lastPositionCheck >= positionCheckInterval then
        lastPositionCheck = 0
        sendPositionToServer()
    end
end

-- Event handlers
local function onDerbyDisableFeatures(data)
    disableFeatures()
end

local function onDerbyEnableFeatures(data)
    enableFeatures()
end

local function onDerbyRequestPosition(data)
    sendPositionToServer()
end

local function onDerbyResetVehicle(data)
    resetVehicle()
end

-- Register client event handlers
MP.RegisterEvent("DerbyDisableFeatures", onDerbyDisableFeatures)
MP.RegisterEvent("DerbyEnableFeatures", onDerbyEnableFeatures)
MP.RegisterEvent("DerbyRequestPosition", onDerbyRequestPosition)
MP.RegisterEvent("DerbyResetVehicle", onDerbyResetVehicle)

-- Register update function
MP.RegisterEvent("onUpdate", onUpdate)

return M
