---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)

local Key = ColorSequenceKeypoint.new
local Sequence = ColorSequence.new
local White = Color3.new(1, 1, 1)

local Gradients = {
	['Fire'] = {Color3.fromRGB(255, 149, 0), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.new(1))}},
		
	['Ice'] = {Color3.fromRGB(164, 231, 255), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(28, 96, 255))}},
	
	['Wind'] = {Color3.fromRGB(211, 255, 214), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(94, 255, 69))}},
	
	['Energy'] = {White, Sequence{Key(0, Color3.fromRGB(7, 52, 255)), Key(1, Color3.new(1))}},
	
	['Physical'] = {Color3.fromRGB(255, 227, 128), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(255, 77, 17))}},
	
	['Default'] = {White, Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.new())}},
	
	['Enemy'] = {Color3.new(1), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.new())}},
	
	['Earth'] = {Color3.fromRGB(156, 129, 110), Sequence{Key(0, White), Key(.415, White), Key(1, Color3.fromRGB(57, 9, 0))}},
	
	['Weak'] = {White, Sequence{Key(0, White), Key(1, Color3.new())}},
	
	['Shatter'] = {White, Sequence{Key(0, Color3.fromRGB(143, 236, 255)), Key(1, White)}}
}

---
return function(At: Vector3 | Types.EnemyClass, Data: {})
	if typeof(At) == 'nil' then return end
	
	local Indicator = Effects:Create(Assets.Interface.Combat.DamageIndicator, 10)
	local NumberToString = tostring(Data.Number)..(Data.Critical and '!' or '')
	local Affliction = Data.Affliction or 'Default'
	local Burst = Data.Burst
	
	if typeof(Affliction) == 'number' then
		Affliction = GameEnum.KeyLookup(GameEnum.Afflictions, Affliction) or 'Default'
	end
	
	if typeof(At) == 'table' and At.GetPivot then
		Indicator.Position = At:GetPivot().Position
		
		Effects:Tween(Indicator, {.4, 'Back'}, {Position = Indicator.Position + Effects:RandomV3() * Effects:Random(0.8, 1.3)})
	else
		Indicator.Position = typeof(At) == 'Vector3' and At or At.Position
	end
	
	local Color = Gradients[Affliction] or Gradients.Default
	
	if Burst then
		Indicator.Holder.Size = UDim2.fromScale(10, 5)
		
		Effects:Tween(Indicator.Holder, {.5}, {Size = UDim2.fromScale(7, 3)})
	end
	
	
	for i = 1, #NumberToString do
		local Number = string.sub(NumberToString, i, i)
		local X_Size = tonumber(Number) == nil and 0.07 or 0.1
		
		local Object = Assets.Interface.Combat.DamageNumber:Clone()
		Object.Name = i
		Object.Text = Number
		Object.TextColor3 = Color[1]:Lerp(White, Burst and 0.15 or 0)
		Object.UIGradient.Color = Color[2]
		Object.ZIndex = #NumberToString - i
		Object.Size = UDim2.fromScale(0, .39)
		Object.Parent = Indicator.Holder.Main
		
		if Data.Critical or Burst then
			Object.UIStroke.Color = White
			Effects:Tween(Object.UIStroke, {.3}, {Color = Color3.new(0)})
		end
		
		local Scale = Instance.new('UIScale')
		Scale.Parent = Object
		
		Effects:Tween(Scale, {.25, 'Back', 'Out'}, {Scale = 1.5 + (Burst and 0.5 or 0)})
		task.delay(.2, function()
			Effects:Tween(Scale, {.15, 'Quad', 'InOut'}, {Scale = 1 + (Burst and 0.5 or 0)})
		end)
		
		Effects:Tween(Object, {.25, 'Back'}, {Size = UDim2.fromScale(X_Size, .39)})
		
		
		task.delay((Data.VanishTime or .75) + (Burst and 0.5 or 0), function()
			Effects:Tween(Object, {.3, 'Back', 'In'}, {Size = UDim2.fromScale(0, .39)})
		end)
		
		task.wait(1/20)
	end
end
