local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Companions = require(Shared.Database.Companions)
local CompanionTraits = require(Shared.Database.CompanionTraits)

return {
    FromCompanionCompressedObject = function(Obj)
        local Buffer = Obj[1]
        local Stats = Obj[2]
        local Rarities = Obj[3]

        local Id = buffer.readstring(Buffer, 7, buffer.len(Buffer) - 7)

        local Converted = {
            Id = Id,
            Name = Companions:GetFromId(buffer.readu8(Buffer, 0)),
            Level = buffer.readu8(Buffer, 1),
            Trait = CompanionTraits:GetFromId(buffer.readu8(Buffer, 2)),
            Experience = buffer.readf32(Buffer, 3),

            Stats = Stats,
            Rarities = Rarities,
        }

        return Converted
    end
}