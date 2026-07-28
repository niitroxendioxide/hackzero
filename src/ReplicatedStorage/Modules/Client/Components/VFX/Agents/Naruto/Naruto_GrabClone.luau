---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService("HttpService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AnimLib = require(Client.Libraries.Animation)
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)
local EffectLibrary = require(Client.Libraries.Effects)

---
local Cache = {}

return function(Caster: Types.AgentClass, EnemyId: number, Time: number): ()
    local EnemyObject = Enemies:GetEnemy(EnemyId)
    if not EnemyObject then
        return;
    end

    local EnemyModel = EnemyObject:GetModel()
    local BaseModel = Caster:GetModel()
    if not EnemyModel or not BaseModel then
        return
    end

    if Cache[EnemyObject] then
        Cache[EnemyObject]()
        Cache[EnemyObject] = nil
    end

    Time = Time or 3

    ---
    local CloneId = HttpService:GenerateGUID()
    local NewLocation = BaseModel:GetPivot():ToObjectSpace(EnemyModel:GetPivot() * CFrame.new(0, 0.325, 1.3))
    local CloneAnimation = AnimLib:GetAnim("Characters.Naruto.Abilities.Ultimate.Clone")
    local TargetAnimation = AnimLib:GetAnim("Characters.Naruto.Abilities.Ultimate.Enemy")

    AnimLib:Play(EnemyModel, TargetAnimation, 0, 1, 1)

    EffectLibrary:Play("Naruto_CloneControl", CloneId, Caster, Time, {{NewLocation, 0}}, {
        Object = CloneAnimation,
        Speed = 1,
        Weight = 1,
    })

    local Clock = os.clock()
    local Thread = task.spawn(function()
        while (os.clock() - Clock) < Time do
            if EnemyObject:IsGrabbed() then
                Cache[EnemyObject]()
                return
            end

            task.wait()
        end

        Cache[EnemyObject] = nil
    end)

    Cache[EnemyObject] = function()
        if Thread and Thread ~= coroutine.running() then
            task.cancel(Thread)
        end

        EffectLibrary:Play("Naruto_CloneControl", CloneId, true)
    end
end