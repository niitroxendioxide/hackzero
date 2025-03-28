---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)


---
return function(Enemy: Types.EnemyClass)
	
	local Appearance = Enemy.__Appearance
	
	local Model = Appearance:GetModel() :: Model
	local At = Model:GetPivot()
	local Duplicate = Model:Clone()
	
	for _, BasePart in Duplicate:GetDescendants() do
		if BasePart:IsA('Shirt') or BasePart:IsA('Pants') then
			BasePart:Destroy()
			
			continue
		end
		
		if BasePart:IsA('BasePart') then
			BasePart:ClearAllChildren()
			BasePart.Anchored = true
			BasePart.CanCollide = false
			
			task.delay(.2, function()
				BasePart.Material = Enum.Material.Neon
				BasePart.Color = Color3.fromRGB(99, 187, 255)
				
				task.wait(0.05)
				Effects:Tween(BasePart, {Effects:Random(0.15, .35)}, {
					Size = Vector3.zero, 
					Position = BasePart.Position + Effects:RandomV3(),
					Orientation = BasePart.Orientation + Effects:RandomV3() * Effects:Random(70, 180),
				})
			end)
		end
	end
	
	Duplicate.Parent = workspace.World.Effects
	
	--
	local Highlight = Instance.new('Highlight')
	Highlight.Parent = Duplicate
	Highlight.FillColor = Color3.new(1,1,1)
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	
	Effects:Tween(Highlight, {.15}, {FillTransparency = 0, OutlineTransparency = 0})
	
	task.wait(.25)
	Highlight:Destroy()
	
	local DeathEffect = Effects:Create(Assets.Effects.General.Combat.Death, 2.5)
	DeathEffect:PivotTo(At)
	
	Effects:Emit(DeathEffect)
end
