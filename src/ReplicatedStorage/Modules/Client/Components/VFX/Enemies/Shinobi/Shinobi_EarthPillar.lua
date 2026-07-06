---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)

---
return function(At: vector)
	--
	local ShinobiAssets = Assets.Effects.Enemies.Shinobi
	local GroundCast = Effects:CastMapRaycast(At, vector.create(0, -100))
	if not GroundCast then
		return;
	end

	local NewPart = Instance.new('Part')
	NewPart.Material = Enum.Material.Basalt;
	NewPart.Size = Vector3.new(6, 6, 0)
	NewPart.Anchored = true
	NewPart.CanCollide = false
	NewPart.Color = GroundCast.Color;
	NewPart.CFrame = CFrame.lookAlong(GroundCast.Position - GroundCast.Normal, GroundCast.Normal)
	NewPart.Parent = workspace.World.Effects;

	local PillarVFX = Effects:Create(ShinobiAssets.Pillar, 3)
	PillarVFX.CFrame = NewPart.CFrame * CFrame.new(0, 0, -(PillarVFX.Size.Z/2 + .6))
	Effects:Emit(PillarVFX, true)
	Effects:RecolorSmoke(GroundCast, PillarVFX:GetDescendants())

	GroundCast.Material = Enum.Material.Basalt
	Effects:CreateRocks(GroundCast, vector.create(3.75, 1.75, 3.75) / 1.6, {7, 10}, {5, 7}, {15, 35}, Effects:GetParent(script.Name), .65)

	Effects:Tween(NewPart, {0.2, 'Back'}, {CFrame = NewPart.CFrame * CFrame.new(0, 0, -4.5), Size = vector.create(4, 4, 9)})

	task.delay(.5, function()
		Effects:Tween(NewPart, {0.45, 'Back', 'In'}, {CFrame = NewPart.CFrame * CFrame.new(0, 0, 4.5), Size = vector.create(2, 2, 0)})
		Effects:CleanUp(NewPart, 0.45)
	end)
end