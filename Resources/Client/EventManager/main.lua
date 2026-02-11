-- EventManager Client-Side Script
-- Renders translucent race gate bubbles when set by admins

local M = {}

local raceGateStart = nil
local raceGateEnd = nil

local function parseGate(data)
    local x, y, z, r = string.match(data or "", "([^,]+),([^,]+),([^,]+),([^,]+)")
    if not x or not y or not z or not r then
        return nil
    end
    return {
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z),
        r = tonumber(r)
    }
end

local function drawGate(gate, color)
    if not gate then return end
    if not debugDrawer or not ColorF then return end

    local pos = vec3(gate.x, gate.y, gate.z)
    debugDrawer:drawSphere(pos, gate.r, color)
end

function M.onUpdate(dt)
    if raceGateStart then
        drawGate(raceGateStart, ColorF(0, 0.7, 1, 0.35))
    end
    if raceGateEnd then
        drawGate(raceGateEnd, ColorF(0.2, 1, 0.2, 0.35))
    end
end

local function onRaceGateSetStart(data)
    raceGateStart = parseGate(data)
end

local function onRaceGateSetEnd(data)
    raceGateEnd = parseGate(data)
end

local function onRaceGateClear(data)
    raceGateStart = nil
    raceGateEnd = nil
end

local function onRaceOrient(data)
    local dx, dy = string.match(data or "", "([^,]+),([^,]+)")
    if not dx or not dy then return end
    local dir = vec3(tonumber(dx), tonumber(dy), 0)
    if dir:length() < 0.001 then return end

    local vehicle = be:getPlayerVehicle(0)
    if not vehicle then return end

    local rot = quatFromDir(dir, vec3(0, 0, 1))
    local pos = vehicle:getPosition()

    if vehicle.setPositionRotation then
        vehicle:setPositionRotation(pos, rot)
    elseif vehicle.setRotation then
        vehicle:setRotation(rot)
    end
end

MP.RegisterEvent("RaceGateSetStart", onRaceGateSetStart)
MP.RegisterEvent("RaceGateSetEnd", onRaceGateSetEnd)
MP.RegisterEvent("RaceGateClear", onRaceGateClear)
MP.RegisterEvent("RaceOrient", onRaceOrient)

return M
