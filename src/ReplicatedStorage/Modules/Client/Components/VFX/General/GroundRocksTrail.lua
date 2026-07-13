---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
local Cache = {}

return function(
	Enemy: Types.EnemyClass,
	Time: number,
	Slam: boolean?
): ()

	if Cache[Enemy] then
		
	end

	local EnemyModel = Enemy:GetModel()
	local CombatFolder = Assets.Effects.General.Combat
	local RockItems = Assets.Effects.General.Rocks:GetChildren()
	local Emitter = Effects:Create(CombatFolder.GroundTrail, Time + 1.5);
	Emitter:PivotTo(EnemyModel:GetPivot())

	local OriginTime = os.clock()
	local LastPosition = EnemyModel:GetPivot().Position + EnemyModel:GetPivot().LookVector*0.01
	local LastRockPostion = LastPosition
	local Connection; Connection = RunService.Heartbeat:Connect(function(Delta: number)
		if (os.clock() - OriginTime) > Time then
			Cache[Enemy] = nil
			Effects:Toggle(Emitter, false);
			Connection:Disconnect();


			return
		end

		local Distance = (EnemyModel:GetPivot().Position - LastPosition).Magnitude;

		if Distance <= 0.05 then
			Effects:Toggle(Emitter, false)
		else
			Effects:Toggle(Emitter, true)
		end

		LastPosition = EnemyModel:GetPivot().Position

		---
		local RockDistance = (EnemyModel:GetPivot().Position - LastRockPostion).Magnitude
		if RockDistance > 1.9 then
			LastRockPostion = EnemyModel:GetPivot().Position

			for i = -1, 1, 2 do
				local Wide = Effects:Random(1.85, 3.15) * i
				local Cast = Effects:CastMapRaycast((EnemyModel:GetPivot() * CFrame.new(Wide, 1, 0)).Position, vector.create(0, -15))

				if Cast then
					local RandomRock = RockItems[math.random(1, #RockItems)]:Clone();
					RandomRock.Size = Vector3.one * Effects:Random(.9, 1.65)
					RandomRock.Anchored = true
					RandomRock.CanCollide = false
					RandomRock.CFrame = CFrame.new(Cast.Position + Effects:RandomV3() * Effects:Random(0, .1), Effects:RandomV3())
					RandomRock.Color = Cast.Color
					RandomRock.Material = Cast.Material
					RandomRock.Parent = Effects:GetParent(script.Name)

					task.delay(1.75, function()
						Effects:Tween(RandomRock, { .25, 'Quad' }, {Size = Vector3.zero, Position = RandomRock.Position - Cast.Normal*RandomRock.Size.Y/2})
					end)
				end
			end
		end

		local GroundCast = Effects:CastMapRaycast(EnemyModel:GetPivot().Position, vector.create(0, -15))
		if GroundCast then
			Emitter:PivotTo(CFrame.lookAlong(GroundCast.Position + GroundCast.Normal * Emitter.Size.Y/2, EnemyModel:GetPivot().LookVector))
		end
	end)

	local FirstGroundCast = Effects:CastMapRaycast(EnemyModel:GetPivot().Position, vector.create(0, -15))
	if Slam and FirstGroundCast then
		local SlamEffect = Effects:Create(CombatFolder.GroundSlam, 3)
		SlamEffect:PivotTo(CFrame.lookAlong(FirstGroundCast.Position + FirstGroundCast.Normal * 0.2, FirstGroundCast.Normal))
		
		Effects:RecolorSmoke(FirstGroundCast, SlamEffect:GetDescendants())
		Effects:Emit(SlamEffect, true)
	end

	Cache[Enemy] = function()
		Connection:Disconnect()
		Effects:Toggle(Emitter, false)
		Effects:CleanUp(Emitter, 1.5)
	end
end
