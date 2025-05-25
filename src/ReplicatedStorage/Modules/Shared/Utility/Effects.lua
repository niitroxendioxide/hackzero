--
local TweenService = game:GetService('TweenService')

--
local EffectUtil = {}

local Random_Number = Random.new()
local World = require(script.Parent.Parent.World)
local Effects_Folder = workspace:WaitForChild('World'):WaitForChild('Effects')

export type TweenGoals = {
	Size: (Vector3 | UDim2)?,
	CFrame: CFrame?,
	Position: (Vector3 | UDim2)?,
	Orientation: Vector3?,
	Transparency: number?,
	Brightness: number?,
	Range: number?,
	[string]: any?,
}

function EffectUtil:Tween(Object: Instance, Info: {number | string}, Goals: TweenGoals)
	--
	local Time, Ease, Direction = Info[1] :: number, (Info[2] or 'Linear') :: string, (Info[3] or 'Out') :: string;
	local NewInfo = typeof(Info) == 'TweenInfo' and Info or TweenInfo.new(
		Time,
		Enum.EasingStyle[Ease] :: Enum.EasingStyle,
		Enum.EasingDirection[Direction] :: Enum.EasingDirection
	)

	--
	local Tween = TweenService:Create(Object, NewInfo, Goals)
	Tween:Play()

	Tween.Completed:Once(function()
		Tween:Destroy()
	end)

	return Tween
end

function EffectUtil:CleanUp(Object: any, Time: number)
	task.delay(Time, function()
		local typeOf = typeof(Object)

		if typeOf == 'Instance' or (typeOf == 'table' and Object.Destroy) then
			Object:Destroy()
		elseif typeOf == 'RBXScriptConnection' then
			Object:Disconnect()
		elseif typeOf == 'function' then
			Object()
		elseif typeOf == 'thread' and (coroutine.running() ~= Object) then
			task.cancel(Object)
		end
	end)
end

function EffectUtil:SetRandomSeed(n: number)
	Random_Number = Random.new(n)
end

function EffectUtil:Random(min: number, max: number): (number)
	return Random_Number:NextNumber(min, max)
end

function EffectUtil:RandomInt(min: number, max: number): (number)
	return Random_Number:NextInteger(min, max)
end

function EffectUtil:RandomV3(): Vector3
	return Random_Number:NextUnitVector()
end

function EffectUtil:Create<T>(Asset: T & Instance, Time: number?)
	local Dir = string.split(debug.info(2, 's'), '.')
	local Name = Dir[#Dir]

	if not Effects_Folder:FindFirstChild(Name) then
		local New_Folder = Instance.new('Folder')
		New_Folder.Name = Name
		New_Folder.Parent = Effects_Folder
	end

	local Cloned = (Asset :: Instance):Clone()
	Cloned.Parent = Effects_Folder:FindFirstChild(Name)

	EffectUtil:CleanUp(Cloned, Time or 10)

	return Cloned :: T
end

function EffectUtil:Emit(Asset: Instance, Light: boolean?): ()
	local WorldSpeed = World:GetSpeed() :: number

	local GraphicSettings = UserSettings().GameSettings.SavedQualityLevel.Value
	for _, Objects in Asset:GetDescendants() do
		if Objects:IsA('ParticleEmitter') then

			local Delay = Objects:GetAttribute('EmitDelay') or 0
			task.delay( Delay / WorldSpeed, function()
				local CorrectedAmount = math.ceil(Objects:GetAttribute('EmitCount') * (GraphicSettings / 10))

				Objects:Emit(CorrectedAmount)
			end)
		elseif Objects:IsA('PointLight') and Light then
			EffectUtil:Tween(Objects, {.5 / WorldSpeed}, {Brightness = 0})
		end
	end
end

function EffectUtil:Weld(Object: BasePart, Welded: BasePart)
	local Weld = Instance.new('WeldConstraint')
	Weld.Part0 = Object
	Weld.Part1 = Welded
	Weld.Parent = Object
	
	return Weld
end

function EffectUtil:GetParent(Name: string?): Instance
	local WorldFolder = workspace:FindFirstChild("World"):: Folder

	if Name then
		return WorldFolder.Effects:FindFirstChild(Name) or WorldFolder.Effects;
	end

	return WorldFolder.Effects
end

function EffectUtil:Toggle(Object: Instance, State: boolean, Filter: ((Object: ParticleEmitter | Beam | Instance) -> (boolean))?)
	for _, Child in Object:GetDescendants() do
		if not (Child:IsA('ParticleEmitter') or Child:IsA('Beam')) then
			continue
		end

		if Filter and Filter(Object) or Filter == nil then
			Child.Enabled = State
		end
	end

end

return EffectUtil
