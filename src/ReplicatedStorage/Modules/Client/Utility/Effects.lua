--
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

--
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CameraShaker = require(script.Parent.Libraries.CameraShaker)

-- Private
local function CleanUp(object: any)
	local t = typeof(object)
	if t == "function" then
		return object()
	elseif t == "thread" then
		return task.cancel(object)
	end
	if t == "Instance" then
		return object:Destroy()
	elseif t == "RBXScriptConnection" then
		return object:Disconnect()
	elseif t == "table" then
		if typeof(object.Destroy) == "function" then
			return object:Destroy()
		elseif typeof(object.Disconnect) == "function" then
			return object:Disconnect()
		end
	end
end


--
local Util = {}

function Util:Emit(Root: Instance | BasePart | Attachment, Delay: number)
	local WorldSpeed = workspace.World.Data:GetAttribute('WorldSpeed')

	task.delay((Delay or 0)/WorldSpeed, function()
		if not(Root) then
			return
		end

		local GraphicSettigns = UserSettings().GameSettings.SavedQualityLevel.Value
		for k, Particle in Root:GetDescendants() do
			if Particle:IsA('ParticleEmitter') then
				task.delay((Particle:GetAttribute('EmitDelay') or 0)/WorldSpeed, function()
					--
					local Default = (Particle:GetAttribute('EmitCount') or 0)		
					if Default < 1 then
						return
					end
					Particle:Emit(math.max(Default, 1))
				end)
			end
		end
	end)
end

function Util:CleanUp(Item: any, Time: number)
	local Speed = math.clamp(workspace.World.Data:GetAttribute('WorldSpeed'), 0, 1)
	if Time == nil then 
		Time = 0 
	end

	task.delay(Time/Speed, CleanUp, Item)
end

function Util:Tween(Object: Instance, Info: UtilTweenInfo, Goals: GoalsType)
	if typeof(Object) == 'nil' then
		return {}
	end

	local DestroyAfterTween = false;
	if Goals.Destroy then
		DestroyAfterTween = true
		Goals.Destroy = nil
	end

	local Tween = TweenService:Create(Object, TweenInfo.new(
		Info[1] or 0.5,
		Enum.EasingStyle[Info[2] or 'Linear'],
		Enum.EasingDirection[Info[3] or 'Out'],
		Info[4] or 0,
		Info[5] or false,
		Info[6] or 0), Goals)

	Tween:Play()

	Tween.Completed:Connect(function()
		Tween:Destroy()

		if DestroyAfterTween then
			Object:Destroy()
		end
	end)

	return Tween
end

function Util:ForBodyParts(Character: Model, Function: (BodyPart: BasePart) -> any)

	for _, Part in Util.BodyParts do
		local PartExists = Character:FindFirstChild(Part)
		if PartExists and PartExists:IsA('BasePart') then
			local PlayerBodyPart: BasePart = PartExists

			Function(PlayerBodyPart);
		end
	end
end

function Util:EraseObjectsWithTag(Object: Instance | Attachment | BasePart, Tag: string, Time: number)
	for _, v in Object:GetDescendants() do
		if v:HasTag(Tag) then
			if v:IsA('ParticleEmitter') then
				v.Enabled = false
			end

			Util:CleanUp(v, Time)
		end
	end
end

function Util:GetSurface(Position: Vector3, Direction: (Vector3 | number)?): RaycastResult?
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.World.Map}
	Params.FilterType = Enum.RaycastFilterType.Include

	Direction = (typeof(Direction) == 'number' and Direction * Vector3.yAxis) or Direction
	Position = typeof(Position) == 'CFrame' and Position.Position or Position

	local Cast = workspace:Raycast(Position, Direction, Params)

	return Cast
end

function Util:Toggle(Root: Instance, State: boolean)
	for k, Particle in Root:GetDescendants() do
		if Particle:IsA('ParticleEmitter') then
			Particle.Enabled = State
		end
	end
end

function Util:ComputeQuad(...)
	local Result = function(t, p0, p1, p2)
		return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
	end

	return Result(...)
end

function Util:ComputeCubic(...)
	local step = function(t, p0: number, p1: number, p2: number, p3: number)
		return p0*(1 - t)^3+3*p1*(1 - t)^2*t+3*p2*(1-t)*t^2+p3*t^3
	end

	return step(...)
end

function Util:ShakeCamera(Preset: string)
	if not(Util:GetSetting('CameraShake')) then
		return
	end

	local NewCamShake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(shakeCf)
		Camera.CFrame = Camera.CFrame * shakeCf
	end)

	NewCamShake:Start()
	NewCamShake:Shake(CameraShaker.Presets[Preset]);
end

function Util:SustainedShake(Preset: string)
	if not(Util:GetSetting('CameraShake')) then
		return
	end

	local Status = LocalPlayer.Character:WaitForChild('Status');
	if Status:HasTag('InSkillTree') then
		return;
	end

	local NewCamShake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(shakeCf)
		Camera.CFrame = Camera.CFrame * shakeCf
	end)

	NewCamShake:Start();
	NewCamShake:ShakeSustain(CameraShaker.Presets[Preset]);

	return NewCamShake
end

function Util:GetSetting()
	warn('Setting not implemented')
	
	return true
end

return Util