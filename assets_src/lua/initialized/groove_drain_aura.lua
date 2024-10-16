local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local OldDrainAura = require "verbs/groove_drain_aura"


local Drain = GrooveVerb:new()

function Drain:init()
    OldDrainAura.execute = Drain.execute
    OldDrainAura.getSplashTargets = Drain.getSplashTargets
end

local maxDrainAmount = { 30, 0 }
local drainRadius = { 3, 0 }
local armyDrain = { 0, 30 }
local tierUsed

function Drain:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, drainRadius[tier], "all")
    return targets
end


function Drain:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    tierUsed = tier

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local targets = Wargroove.getTargetsInRange(targetPos, drainRadius[tier], "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("darkmercia/darkmerciaGroove", targetPos)
    Wargroove.waitTime(2.4)
    if tier == 1 then
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, drainRadius[tier], "fx/groove/darkmercia_groove_fx", "idle", "behind_units", {x = 12, y = 12})
    else
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, drainRadius[tier], "fx/groove/darkmercia_groove_fx_2", "idle", "behind_units", {x = 12, y = 12})
    end

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    local healthDrained = 0

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
            healthDrained = healthDrained + math.min(u.health, maxDrainAmount[tier])

            u:setHealth(u.health - maxDrainAmount[tier], unit.id)
            Wargroove.updateUnit(u)
            Wargroove.spawnPaletteSwappedMapAnimation(pos, 0, "fx/drain_unit")
            Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", pos)
            Wargroove.waitTime(0.2)
        end
    end

    if tier == 2 then
        local allUnits = Wargroove.getAllUnitIds()
        for _, id in ipairs(allUnits) do
            local u = Wargroove.getUnitById(id)
            if not u.unitClass.isStructure and Wargroove.areEnemies(unit.playerId, u.playerId) then
                healthDrained = healthDrained + math.min(u.health, armyDrain[tier])

                u:setHealth(u.health - armyDrain[tier], unit.id)
                Wargroove.updateUnit(u)
                Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/aoe_leech_unit", "idle", "over_units")
            end
        end

        Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", unit.pos)
    end

    unit:setHealth(unit.health + healthDrained, unit.id)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)

    Wargroove.waitTime(0.6)
end

return Drain
