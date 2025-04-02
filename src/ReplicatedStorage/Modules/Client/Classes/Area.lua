--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local Signal = require(Shared.Utility.Signal)

--
local AreaClass = {}
AreaClass.__index = AreaClass

function AreaClass.new(InstanceList: {Instance} | Instance)
    local self = setmetatable({} :: Types.ClientAreaClass, AreaClass)
    self.__IsInside = false;
    self.__AreaInstances = InstanceList;

    self.OnEnter = Signal.new();
    self.OnLeave = Signal.new();

    return self;
end

function AreaClass.Init(self: Types.ClientAreaClass): ()
    local Character = Player.Character or Player.CharacterAdded:Wait()

    print("Area inited")
    self.__Params = OverlapParams.new()
    self.__Params.FilterDescendantsInstances = {Character}
    self.__Params.FilterType = Enum.RaycastFilterType.Include

    self.__Loop = RunService.Heartbeat:Connect(function()
        self:__GetPartsInInstances()
    end)

end

function AreaClass.Destroy(self: Types.ClientAreaClass)
    if self.__Loop then
        self.__Loop:Disconnect()
    end

end

function AreaClass.__IsPartInPlayer(self, BodyPart: BasePart)
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()

    return  BodyPart:IsDescendantOf(Character)
end

function AreaClass.__GetPartsInInstances(self: Types.ClientAreaClass)
    local List = typeof(self.__AreaInstances) == "table" and self.__AreaInstances or {self.__AreaInstances}

    local Detected = false;
    for _, Part in List do
        local PartList = workspace:GetPartsInPart(Part, self.__Params)

        for _, BP in PartList do
            if self:__IsPartInPlayer(BP) then
                if not(self.__IsInside) then
                    self.OnEnter:Fire()
                end

                Detected = true;
                self.__IsInside = true;
            end
        end
    end

    if not (Detected) and self.__IsInside then
        self.OnLeave:Fire()
    end

    self.__IsInside = Detected;
end

return AreaClass
