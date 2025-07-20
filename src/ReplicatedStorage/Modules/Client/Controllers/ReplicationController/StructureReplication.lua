local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chests = require(ReplicatedStorage.Modules.Client.Libraries.Chests)
-- TODO: Add destructibles here too :v


--
local Controller = {}

function Controller:CreateChest(Buffer: buffer, Part: BasePart)
    local Id = buffer.readu16(Buffer, 1)

    print(Part, "on client")
    Chests:CreateWithBase(Part, Id)
end

return Controller
