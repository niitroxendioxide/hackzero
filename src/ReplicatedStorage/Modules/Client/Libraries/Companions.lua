local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types.Companions)
--

--
local Companions = {
    __Objs = {}
}

function Companions:Add(Obj: Types.ClientCompanionClass, Id: number)
    Companions.__Objs[Id] = Obj
end

function Companions:Get(Id: number): Types.ClientCompanionClass
    return Companions.__Objs[Id]
end

function Companions:GetCompanionsForPlayer(Player: Player)
    local List = {}

    for k, Object in Companions.__Objs do
        print(Object:IsOwner(Player), Object.__Owner_Id)

        if Object:IsOwner(Player) then
            table.insert(List, Object)
        end
    end

    return List
end

function Companions:Remove(Obj: Types.ClientCompanionClass)
    for k, Ex in Companions.__Objs do
        if Ex == Obj then
            Companions.__Objs[k] = nil
        end
    end
end

return Companions
