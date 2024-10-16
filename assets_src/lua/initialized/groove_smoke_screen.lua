local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local OldSmokeScreen = require "verbs/groove_smoke_screen"

local SmokeScreen = GrooveVerb:new()

function SmokeScreen:init()
    OldSmokeScreen.getMaximumRange = SmokeScreen.getMaximumRange
end

local smokeRange = {2, 12}

function SmokeScreen:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return smokeRange[tier]
end

return SmokeScreen
