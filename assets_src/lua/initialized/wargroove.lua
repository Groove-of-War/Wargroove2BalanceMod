local Wargroove = {}
local OldWargroove = require "wargroove/wargroove"

function Wargroove:init()
    OldWargroove.getTroopUnitClasses = Wargroove.getTroopUnitClasses
end

function Wargroove.getTroopUnitClasses()
    return { "villager", "soldier", "dog", "spearman", "mage", "archer", "merman", "griffin_walking", "thief", "rifleman", "frog"  }
end


return Wargroove
