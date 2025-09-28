local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Companions)
local Signal = require(Shared.Utility.Signal)
local Sequence = require(Shared.Utility.Sequence)

local Damage = require(ServerStorage.Modules.Libraries.Damage)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local AttackClass = {}
AttackClass.__index = AttackClass

function AttackClass.new(): Types.ServerCompanionAttack
    local self = setmetatable({}, AttackClass)
    self.__Cache = {}
    self.__Sequences = {}

    self.Finished = Signal.new()

    return self
end

function AttackClass.Run(self: Types.ServerCompanionAttack, CompanionObject: Types.CompanionClass)
    print("Running attack for companion: ", CompanionObject.__Key)
end

function AttackClass.Save(self: Types.ServerCompanionAttack, CompanionObject: Types.CompanionClass, Key: string, Value: any)
    if not self.__Cache[CompanionObject] then
        self.__Cache[CompanionObject] = {}
    end

    self.__Cache[CompanionObject][Key] = Value
end

function AttackClass.Get(self: Types.ServerCompanionAttack, CompanionObject: Types.CompanionClass, Key: string): any
    if not self.__Cache[CompanionObject] then
        return nil
    end

    return self.__Cache[CompanionObject][Key]
end

function AttackClass.FromData(self: Types.ServerCompanionAttack, Key: number)
    
end

function AttackClass.Sequence(self: Types.ServerCompanionAttack, CompanionObject: Types.CompanionClass, Frames: {})
    if self.__Sequences[CompanionObject] then
        self.__Sequences[CompanionObject]:Destroy()
    end

    --
    local Sequence = Sequence.new(Frames)

    Sequence:Start()

    self.__Sequences[CompanionObject] = Sequence

    return Sequence
end

function AttackClass.Cancel(self: Types.ServerCompanionAttack)
    
end

function AttackClass.Hit(self: Types.ServerCompanionAttack, Caster: Types.CompanionClass, Target: any, Data)
    local Validated, Dealt_Damage = Damage:Deal(Caster, Target, Data)
    if not Validated then
        return;
    end

    Replicator:DisplayDamage(Target, Dealt_Damage, false, Data.Affliction)
end

return AttackClass