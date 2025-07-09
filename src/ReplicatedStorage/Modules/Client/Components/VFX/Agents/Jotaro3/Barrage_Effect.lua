---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)

local Rng = Random.new()

--local ArmCache = {}

---
return function(Caster: Types.AgentClass): ()
    local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
    if not StandModel then
        return
    end

    if not Caster:HasTag('Barraging') then
        return
    end

    local Offset = CFrame.new(0, 0, -1)
    local Effect = Effects:Create(Assets.Effects.Agents.Jotaro3.BarrageEffect, 10)
    Effect.CFrame = StandModel:GetPivot() * Offset

    --[[local LocalCache = {}
    for i = #LocalCache, #LocalCache-4, -1 do
        table.remove(LocalCache, #LocalCache)
    end]] -- use later for armcache

    local Arms = {}
    local ForNextSpawn = os.clock()
    local LoopActive = true

    while Caster:HasTag('Barraging') do
        local _ = task.wait()
        if not StandModel:IsDescendantOf(workspace) then
            break
        end

        --
        Effect.CFrame = StandModel:GetPivot() * Offset

        if (os.clock() - ForNextSpawn) > 0.1 and #Arms < 10 then
            ForNextSpawn = os.clock()

            local Sign = Rng:NextInteger(0, 1) == 1 and 1 or -1
            local Side = CFrame.new(Rng:NextNumber(0.25, 0.5) * Sign, Rng:NextNumber(-1, 1), 1)
            local End = CFrame.new(Side.X * 0.1, 0, -Rng:NextNumber(4, 6))
            local Angle = math.atan2(Side.Y, Side.X);

            local ArmModel = Assets.Effects.Agents.Jotaro3.BarrageArm:Clone()
            ArmModel:PivotTo(StandModel:GetPivot() * CFrame.new(Side.X, Side.Y, 0) * CFrame.Angles(0, 0, Angle))
            ArmModel.Parent = workspace

            local Data = {
                ArmModel,
                Side,
                End,
                CFrame.new(math.sign(Side.X) * Rng:NextNumber(3, 6), math.sign(Side.Y) * Rng:NextNumber(0, 3), End.Z/2),
                0,
                Rng:NextNumber(0.17, .3)
            }

            local function UpdateArm(Delta)
                local StartOffset, EndOffset, MiddleOffset = Data[2], Data[3], Data[4]

                Data[5] += Delta
                local AlphaTime = Data[5] / Data[6]
                if AlphaTime > 1 then
                    if not LoopActive then
                        Data[1]:Destroy()
                        Data[#Data]:Disconnect();

                        return
                    end

                    local Sign = Rng:NextInteger(0, 1) == 1 and 1 or -1
                    local Side = CFrame.new(Rng:NextNumber(0.25, 0.5) * Sign, Rng:NextNumber(-1, 1), 2)
                    local End = CFrame.new(Side.X * 0.1, 0,  -Rng:NextNumber(4, 6))
                    local Mid = CFrame.new(math.sign(Side.X) * Rng:NextNumber(3, 6), math.sign(Side.Y) * Rng:NextNumber(0, 3), End.Z/2)

                    Angle = math.atan2(Side.Y, Side.X);
                    Data[2], Data[3], Data[4] = Side, End, Mid

                    Data[5] = 0
                    Data[6] = Rng:NextNumber(0.17, 0.3)

                    return
                end

                local Origin = (StandModel:GetPivot() * StartOffset).Position
                local Middle = (StandModel:GetPivot() * MiddleOffset).Position
                local End = (StandModel:GetPivot() * EndOffset).Position

                local Cur = Effects:Quad(Origin, Middle, End, AlphaTime)
                local Next = Effects:Quad(Origin, Middle, End, AlphaTime + 1 / 100)

                Data[1]:PivotTo(CFrame.lookAt(Cur, Next) * CFrame.Angles(0, 0, Angle))
            end

            Data[#Data + 1] = RunService.Heartbeat:Connect(UpdateArm)

            table.insert(Arms, Data)
        end
    end

    LoopActive = false

    Effects:Toggle(Effect, false)
end