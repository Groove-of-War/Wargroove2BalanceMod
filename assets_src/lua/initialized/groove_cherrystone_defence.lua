local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local OldCherrystoneDefence = require "verbs/groove_cherrystone_defence"

local CherrystoneDefence = GrooveVerb:new()

function CherrystoneDefence:init()
    OldCherrystoneDefence.execute = CherrystoneDefence.execute
end

local spawnIds = {"crystal", "crystal_tier_two" }
local allyModifiers = { "", "emeric_range_boost" }
local allyRange = { 0, 3 }


function CherrystoneDefence:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    print("Executing groove with tier "..tier)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)
        
    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("emeric/emericGroove", targetPos)
    Wargroove.waitTime(1.3)
    Wargroove.playGrooveEffect()
    Wargroove.spawnUnit(unit.playerId, targetPos, spawnIds[tier], false, "spawn")

    coroutine.yield()

    if tier == 2 then
        for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, allyRange[tier], "unit")) do
            local u = Wargroove.getUnitAt(pos)
             if Wargroove.areAllies(u.playerId, unit.playerId) and u.id ~= unit.id and #u.unitClass.weapons > 0 and u.unitClass.weapons[1].maxRange > 1 and Wargroove.isInList(u.unitClassId, Wargroove.getTroopUnitClasses()) then
                 Wargroove.spawnMapAnimation(pos, 0, "fx/groove/inspire_unit")
                
                local modifier = allyModifiers[tier]
                if modifier ~= "" then
                    Wargroove.pushUnitClassModifier(u.id, modifier)
                    Wargroove.setUnitState(u, "emeric_range_boost", "true")
                end
                
                Wargroove.updateUnit(u)
            end
        end
    end

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)

    Wargroove.waitTime(1.2)
end

return CherrystoneDefence
