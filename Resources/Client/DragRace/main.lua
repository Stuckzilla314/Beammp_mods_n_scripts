-- DragRace Client-Side Script
-- Sends position updates and locks vehicles during countdown

local M = {}

local dragActive = false
local lockActive = false
local positionInterval = 0.2
local positionTimer = 0

local function getCurrentVehicle()
    return be:getPlayerVehicle(0)
end

local function sendPositionToServer()
    local vehicle = getCurrentVehicle()
    if not vehicle then return end

    local pos = vehicle:getPosition()
    local posData = string.format("%.2f,%.2f,%.2f", pos.x, pos.y, pos.z)
    MP.TriggerServerEvent("DragPositionUpdate", posData)
end

local function applyLock()
    local vehicle = getCurrentVehicle()
    if not vehicle then return end

    -- Apply brakes and parking brake to prevent forward movement while still allowing revs
    vehicle:queueLuaCommand("input.event('brake', 1, 0)")
    vehicle:queueLuaCommand("input.event('parkingbrake', 1, 0)")
end

local function releaseLock()
    local vehicle = getCurrentVehicle()
    if not vehicle then return end

    vehicle:queueLuaCommand("input.event('brake', 0, 0)")
    vehicle:queueLuaCommand("input.event('parkingbrake', 0, 0)")
end

function M.onUpdate(dt)
    if dragActive then
        positionTimer = positionTimer + dt
        if positionTimer >= positionInterval then
            positionTimer = 0
            sendPositionToServer()
        end
    end

    if lockActive then
        applyLock()
    end
end

local function onDragSetActive(data)
    dragActive = true
end

local function onDragSetInactive(data)
    dragActive = false
    lockActive = false
    releaseLock()
end

local function onDragLock(data)
    lockActive = true
    applyLock()
end

local function onDragUnlock(data)
    lockActive = false
    releaseLock()
end

MP.RegisterEvent("DragSetActive", onDragSetActive)
MP.RegisterEvent("DragSetInactive", onDragSetInactive)
MP.RegisterEvent("DragLock", onDragLock)
MP.RegisterEvent("DragUnlock", onDragUnlock)

return M
