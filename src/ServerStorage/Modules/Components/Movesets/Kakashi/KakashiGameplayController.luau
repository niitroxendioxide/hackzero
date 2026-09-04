--[[
    @service
    Shared state for Kakashi's moveset: the 'Lightning' charge meter, Lightning Mode, and Paralyze.
    Every Kakashi ability talks to this instead of duplicating the logic, the same way
    SasukeGameplayController / MikuGameplayController do for their characters.

    This module has no SetData, so the moveset loader (Kakashi/init.lua) skips it and it never
    gets registered as a skill.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

---
local Shared = ReplicatedStorage.Modules.Shared
local Libraries = ServerStorage.Modules.Libraries

local Types = require(Shared.Types.Agents)
local EnemyDatabase = require(Shared.Database.Enemies)
local Replicator = require(Libraries.Replicator)

---
const METER_NAME = 'Lightning';
const LIGHTNING_MODE_TIME = 20;
const PARALYZE_STAT = 'Affliction_Resistance';
const PARALYZE_TAG = 'Paralyzed';
const PARALYZE_TIME = 2.5;
const PARALYZE_RESISTANCE_SHRED = -0.15;
const DAZE_SHRED_RESISTANCE_TAG = "KkResShred";
const DAZE_SHRED_RESISTANCE_STAT = "Daze_Resistance";
const DAZE_SHRED_RESISTANCE_VAL = -0.05;

---
local Kakashi = {
    __Lightning_Mode = {},
    __Mode_Threads = {},
}

--[[ # Lightning charges ]]

--[[
    Add Lightning charges, capped by the meter's Max (6). Charges are not gained while
    Lightning Mode is already running - the mode consumes the meter.
]]
function Kakashi:AddCharge(Caster: Types.ServerAgentClass, Amount: number?)
    if Kakashi:IsLightningMode(Caster) then
        return
    end

    Caster:UpdateMeter(METER_NAME, Amount or 1)
end

--[[ Whether the meter is full and the mode can be entered. ]]
function Kakashi:IsReady(Caster: Types.ServerAgentClass): boolean
    if Kakashi:IsLightningMode(Caster) then
        return false
    end

    const _Value, Percent = Caster:GetMeter(METER_NAME)

    return Percent >= 1
end

function Kakashi:IsLightningMode(Caster: Types.ServerAgentClass): boolean
    return Kakashi.__Lightning_Mode[Caster] == true
end

function Kakashi:EnterLightningMode(Caster: Types.ServerAgentClass, Time: number?)
    if not Kakashi:IsReady(Caster) then
        return false
    end

    const Duration = Time or LIGHTNING_MODE_TIME

    Kakashi.__Lightning_Mode[Caster] = true
    Caster:AddTag('LightningMode', Duration, true)

    Replicator:Effect('Kakashi_LightningMode', {Caster, Duration, true}, true)

    if Kakashi.__Mode_Threads[Caster] then
        task.cancel(Kakashi.__Mode_Threads[Caster])
    end

    Kakashi.__Mode_Threads[Caster] = task.delay(Duration, function()
        Kakashi:ExitLightningMode(Caster)
    end)

    return true
end

function Kakashi:ExitLightningMode(Caster: Types.ServerAgentClass)
    if not Kakashi:IsLightningMode(Caster) then
        return
    end

    Kakashi.__Lightning_Mode[Caster] = nil
    Kakashi.__Mode_Threads[Caster] = nil

    Caster:UpdateMeter(METER_NAME, -99)
    Caster:RemoveTag('LightningMode')

    Replicator:Effect('Kakashi_LightningMode', {Caster, 0, false}, true)
end

--[[ # Paralyze ]]
function Kakashi:IsBoss(Enemy: Types.Enemy): boolean
    const Data = EnemyDatabase:GetEnemyData(Enemy.__Name)

    return (Data ~= nil and (Data.EnemyTier == "Boss" or Data.Is_Boss == true))
end

function Kakashi:IsParalyzed(Enemy: Types.Enemy): boolean
    return Enemy:GetEffect(PARALYZE_TAG) ~= nil
end

--[[
    Paralyze a target: non-boss enemies get their current action interrupted outright (TrueStun
    cannot be broken out of), bosses only take the debuff. Both get the resistance shred.

    @param Time how long the paralysis lasts, defaults to 2.5s
]]
function Kakashi:Paralyze(Enemy: Types.Enemy, Time: number?, _Caster: Types.ServerAgentClass?)
    if tostring(Enemy) ~= 'EnemyClass' then
        return
    end

    if Kakashi:IsParalyzed(Enemy) then
        return
    end

    const Duration = Time or PARALYZE_TIME

    if not Kakashi:IsBoss(Enemy) then
        Enemy:ApplyTrueStun(Duration)
    end

    Enemy:AddEffect({
        Tag = PARALYZE_TAG,
        Type = PARALYZE_STAT,
        Value = PARALYZE_RESISTANCE_SHRED,
        Time = Duration,
    })

    Replicator:Effect('Kakashi_Paralyze', {Enemy:GetId(), Duration}, true)
end

--[[
    Apply a stat shred to a target - used by the Lightning Mode Quick Assist dogs (electric buildup)
    and by the Lightning Mode basics (daze resistance).

    @param Data {Tag, Type?, Value, Time} - Type defaults to Critical_Defense, matching Frostbite.
]]
function Kakashi:ShredResistance(Enemy: Types.Enemy, Time: number)
    if tostring(Enemy) ~= 'EnemyClass' then
        return
    end

    if Enemy:GetEffect(DAZE_SHRED_RESISTANCE_TAG) then
        Enemy:RemoveEffect(DAZE_SHRED_RESISTANCE_TAG)
    end

    Enemy:AddEffect({
        Tag = DAZE_SHRED_RESISTANCE_TAG,
        Type = DAZE_SHRED_RESISTANCE_STAT,
        Value = DAZE_SHRED_RESISTANCE_VAL,
        Time = Time,
    })
end

return Kakashi
