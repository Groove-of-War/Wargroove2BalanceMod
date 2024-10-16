local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"
local OldDFireCraze = require "verbs/groove_fire_craze"


local FireCraze = GrooveVerb:new()

function FireCraze:init()
    OldDFireCraze.execute = FireCraze.execute
    OldDFireCraze.preExecute = FireCraze.preExecute
    OldDFireCraze.canExecuteWithTarget = FireCraze.canExecuteWithTarget
    OldDFireCraze.getSplashTargets = FireCraze.getSplashTargets
    OldDFireCraze.getMaximumRange = FireCraze.getMaximumRange
end



local maxDamage = {0.5, 0.75}
local maxRange = {5, 5}
local maxTargets = {3, 5}
local burn = {false, true}
FireCraze.selectedLocations = {}

function FireCraze:selectedLocationsContains(pos)
    for i, selectedPos in pairs(FireCraze.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
            return true
        end
    end
    return false
end

function FireCraze:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return maxRange[tier]
end

function FireCraze:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    local targets = Wargroove.getTargetsInRange(targetPos, maxRange[tier], "all")
    return targets
end

function FireCraze:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    if FireCraze:selectedLocationsContains(targetPos) then
        return false
    end

    local unitThere = Wargroove.getUnitAt(targetPos)
    return unitThere and Wargroove.areEnemies(unitThere.playerId, unit.playerId) and (not unitThere.unitClass.isStructure) and unitThere.canBeAttacked and (unitThere.unitClass.isAttackable)
end

function FireCraze:preExecute(unit, targetPos, strParam, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    FireCraze.selectedLocations = {}

    local allTargets = FireCraze:getSplashTargets(unit, endPos, endPos)
    local enemyTargets = {}
    for i, target in ipairs(allTargets) do
        if FireCraze:canExecuteWithTarget(unit, endPos, target, strParam) then
            table.insert(enemyTargets, target)
        end
    end

    for i=1,maxTargets[tier] do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            FireCraze.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            Wargroove.waitFrame()
            return false, ""
        end

        Wargroove.displayTarget(target)
        table.insert(FireCraze.selectedLocations, target)
        if (#enemyTargets) == (#FireCraze.selectedLocations) then
            break
        end
    end

    local result = ""
    for i, target in ipairs(FireCraze.selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #FireCraze.selectedLocations then
            result = result .. ";"
        end
    end

    FireCraze.selectedLocations = {}
    Wargroove.waitFrame()
    Wargroove.clearDisplayTargets()
    Wargroove.waitFrame()

    return true, result
end


function FireCraze:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, maxRange[tier], "all")

    -- Pick random x targets from table
    local finalTargets = {}
    local targetPositions = self:parseTargets(strParam)
    for i, pos in pairs(targetPositions) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            table.insert(finalTargets, u)
        end
    end

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playMapSound("nadia/nadiaGroove", unit.pos)
    if tier == 2 then
        Wargroove.playUnitAnimation(unit.id, "groove2")
    else
        Wargroove.playUnitAnimation(unit.id, "groove")
    end
    Wargroove.waitTime(1.25)
    Wargroove.playGrooveEffect()

    -- Visual bomb effect
    -- Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/nadia/nadia_area_explosion", "idle", "behind_units", { x = 12, y = 12 })
    Wargroove.waitTime(0.35)

    -- Do burn effect on randomized targets
    for i, u in ipairs(finalTargets) do
        local damage = Combat:getGrooveAttackerDamage(unit, u, "average", unit.pos, u.pos, path, nil) * maxDamage[tier]
        u:setHealth(u.health - damage, unit.id)
        Wargroove.updateUnit(u)
        Wargroove.playUnitAnimation(u.id, "hit")
        
        local isBurning = Wargroove.getUnitState(u, "burning")

        Wargroove.playMapSound("nadia/nadiaGrooveHit", u.pos)
        Wargroove.spawnMapAnimation(u.pos, 1, "units/commanders/nadia/nadia_burn_fx_front", "idle", "over_units", {x = 13, y = 16})
        Wargroove.spawnMapAnimation(u.pos, 1, "units/commanders/nadia/nadia_burn_fx_back", "idle", "units", {x = 13, y = 16})

        -- We prevent double burns
        if (isBurning == nil or isBurning == "false") and burn[tier] == true then
            Wargroove.setUnitState(u, "burning", "true")
            Wargroove.updateUnit(u)

            local startingState = {}
            local unitId = {key = "unitId", value = u.id}
            table.insert(startingState, unitId)
            Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "burn", false, "", startingState)

            Wargroove.displayBuffVisualEffect(u.id, u.playerId, "units/commanders/nadia/nadia_constant_burn_fx_back", "spawn", 1.0, nil, "units", {x = 0, y = -1}, false, false)
            Wargroove.displayBuffVisualEffect(u.id, u.playerId, "units/commanders/nadia/nadia_constant_burn_fx_front", "spawn", 1.0, nil, "over_units", {x = 0, y = 3}, false, false)
        end
    end

    Wargroove.waitTime(1.0);
    Wargroove.clearBuffVisualEffect(unit.id)

    Wargroove.waitTime(1.0)
end

return FireCraze
