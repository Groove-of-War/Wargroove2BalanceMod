local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local OldSplashJump = require "verbs/groove_splash_jump"


local SplashJump = GrooveVerb:new()

function SplashJump:init()
    OldSplashJump.getMaximumRange = SplashJump.getMaximumRange
    OldSplashJump.generateOrders = SplashJump.generateOrders
end

local jumpRange = {6, 9}

function SplashJump:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return jumpRange[tier]
end

function SplashJump:generateOrders(unitId, canMove)
    local orders = {}
    
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)    
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        if Wargroove.canStandAt("soldier", pos) then
            local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, jumpRange[tier], "empty")
            for j, target in pairs(targets) do
                if self:canSeeTarget(target) and Wargroove.canStandAt("soldier", target) then
                    orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = target}
                end
            end
        end
    end

    return orders
end


return SplashJump
