---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Settings = require(ReplicatedStorage.Modules.Client.Packages.Settings)
local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum)

local Key = ColorSequenceKeypoint.new
local Sequence = ColorSequence.new
local White = Color3.new(1, 1, 1)

local Gradients = {
	['Fire'] = {Color3.fromRGB(255, 149, 0), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.new(1))}},

	['Ice'] = {Color3.fromRGB(164, 231, 255), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(28, 96, 255))}},

	['Water'] = {Color3.fromRGB(164, 231, 255), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(28, 96, 255))}},

	['Wind'] = {Color3.fromRGB(211, 255, 214), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(94, 255, 69))}},

	['Energy'] = {White, Sequence{Key(0, Color3.fromRGB(7, 52, 255)), Key(1, Color3.new(1))}},

	['Physical'] = {Color3.fromRGB(255, 227, 128), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.fromRGB(255, 77, 17))}},

	['Default'] = {White, Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.new())}},

	['Enemy'] = {Color3.new(1), Sequence{Key(0, White), Key(0.5, White), Key(1, Color3.new())}},

	['Earth'] = {Color3.fromRGB(156, 129, 110), Sequence{Key(0, White), Key(.415, White), Key(1, Color3.fromRGB(57, 9, 0))}},

	['Weak'] = {White, Sequence{Key(0, White), Key(1, Color3.new())}},

	['Shatter'] = {White, Sequence{Key(0, Color3.fromRGB(143, 236, 255)), Key(1, White)}}
}

local INDICATOR_LIMIT = 3
local Threads = {}
local Counter = {}

---
return function(At: Vector3 | Types.EnemyClass | CFrame, Data: Types.EffectAnyData)
	if typeof(At) == 'nil' then return end

	local Parent = Effects:GetParent('Indicator')
	local Indicator = typeof(At) == 'table' and Parent:FindFirstChild(At:GetId()..'indicatorobj') or nil
	local ClearThread: thread = nil
	local NumberToString = tostring(Data.Number)..(Data.Critical and '!' or '')
	local Multiple_Indicators_Setting = not Settings:Get("Multiple_Indicators", "QOL")

	if Multiple_Indicators_Setting and Indicator and Threads[Indicator] then
		local Previous = Indicator:GetAttribute('Total')
		local NewTotal = Data.Number + Previous
		NumberToString = tostring(NewTotal)..(Data.Critical and '!' or '')
		Indicator:SetAttribute('Total', NewTotal)

		for _, Thread in Threads[Indicator] do
			task.cancel(Thread)
		end

		for _, Object: Instance | TextLabel in Indicator.Holder.Main:GetChildren() do
			if Object:IsA("TextLabel") then
				local Text = Object.Text

				if Text == '!' and not Data.Critical then
					Object:Destroy()
				end
			end
		end

		ClearThread = Effects:CleanUp(Indicator, 10)
	else
		if typeof(At) == 'table' then
			Counter[At] = (Counter[At] or 0) + 1

			if Counter[At] >= INDICATOR_LIMIT and Indicator then
				if Threads[Indicator] then
					for _, Thread in Threads[Indicator] do
						task.cancel(Thread)
					end
				end

				for _, Object in Indicator.Holder.Main:GetChildren() do
					if not Object:IsA("TextLabel") then
						continue
					end

					Effects:Tween(Object, {.15, 'Back', 'In'}, {Size = UDim2.fromScale(0, .39)})
				end

				Effects:CleanUp(Indicator, 0.3)
				Counter[At] -= 1

			end
		end

		Indicator, ClearThread = Effects:Create(Assets.Interface.Combat.DamageIndicator, 10)
		Indicator:SetAttribute('Total', Data.Number)
	end

	local Affliction = Data.Affliction or 'Default'
	local Burst = Data.Burst
	if typeof(Affliction) == 'number' then
		Affliction = GameEnum.KeyLookup(GameEnum.Afflictions, Affliction) or 'Default'
	end

	local Color = Gradients[Affliction] or Gradients.Default

	if Burst then
		Indicator.Holder.Size = UDim2.fromScale(9, 9)

		Effects:Tween(Indicator.Holder, {.6, 'Back', 'Out'}, {Size = UDim2.fromScale(7, 3)})
	end

	if typeof(At) == 'table' and At.GetPivot then
		Indicator.Position = At:GetModel():GetPivot().Position
		Indicator.Name = At:GetId()..'indicatorobj'

		Effects:Tween(Indicator, {.4, 'Back'}, {Position = Indicator.Position + Effects:RandomV3() * Effects:Random(0.8, 1.3)})
	else
		Indicator.Position = typeof(At) == 'Vector3' and At or (At :: CFrame).Position
	end

	-- for all threads
	if not Threads[Indicator] then
		Threads[Indicator] = {}
	end

	table.insert(Threads[Indicator], ClearThread)
	table.insert(Threads[Indicator], task.delay(10, function()
		if typeof(At) == 'table' then
			Counter[At] -= 1
		end
	end))

	for i = 1, #NumberToString do
		local Number = string.sub(NumberToString, i, i)
		local X_Size = tonumber(Number) == nil and 0.07 or 0.1

		local Exists = Indicator.Holder.Main:FindFirstChild(tostring(i))
		local Object = Exists or Assets.Interface.Combat.DamageNumber:Clone()
		Object.Name = i
		Object.Text = Number
		Object.TextColor3 = Color[1]:Lerp(White, Burst and 0.15 or 0)
		Object.UIGradient.Color = Color[2]
		Object.ZIndex = #NumberToString - i
		Object.Size = UDim2.fromScale(0, .39)
		Object.Parent = Indicator.Holder.Main

		--Object.UIStroke.Thickness = ScreenUtil:GetStrokeSize(Object.UIStroke.Thickness)
		if Data.Critical or Burst then
			Object.UIStroke.Color = White
			Effects:Tween(Object.UIStroke, {.3}, {Color = Color3.new(0)})
		end

		local Scale = Instance.new('UIScale')
		Scale.Parent = Object

		Effects:Tween(Scale, {.25, 'Back', 'Out'}, {Scale = 1.85 + (Burst and 0.5 or 0)})
		task.delay(.2, function()
			Effects:Tween(Scale, {.15, 'Quad', 'InOut'}, {Scale = 1 + (Burst and 0.5 or 0)})
		end)

		Effects:Tween(Object, {.25, 'Back'}, {Size = UDim2.fromScale(X_Size, .39)})

		table.insert(Threads[Indicator], task.delay((Data.VanishTime or .75) + (Burst and 0.5 or 0), function()
			Effects:Tween(Object, {.15, 'Back', 'In'}, {Size = UDim2.fromScale(0, .39)})
		end))

		task.wait(1/30)
	end
end
