local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local InterfaceAssets = ReplicatedStorage.Assets.Interface

local Places = require(ReplicatedStorage.Modules.Shared.Places)
local EffectUtil = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local AgentTypes = require(Shared.Types.Agents)
local ComponentClass = require(Client.Classes.Interface)
local Fusion = require(Client.Libraries.Fusion)
local CharacterLibrary = require(Client.Libraries.Characters)
local InterfaceStates = require(Client.Packages.InterfaceStates)
local CharacterDatabase = require(Shared.Database.Characters)

-- STATICS
local FULL_COLOR = Color3.fromRGB(51, 211, 255);
local NOT_COLOR = Color3.fromRGB(134, 148, 152);

--
local peek = Fusion.peek
local Component = ComponentClass.new(script.Name, 'HUD', {
})

local Handlers = {}

--
local function ReplicationId(): number
	return Player:GetAttribute("ReplicationId") :: number
end

local function GetEnergyNeededById(Id: number): number
	local Agent = CharacterLibrary:GetAgent(ReplicationId(), Id) :: AgentTypes.AgentClass
	if Agent == nil then return 0 end

	local CharacterInfo = CharacterDatabase:GetMovesetData(Agent.Name) -- Agent.Name
	if not CharacterInfo.Special or not CharacterInfo.Special.Base or not CharacterInfo.Special.Base.Required_Energy then
		return 100
	end

	return CharacterInfo.Special.Base.Required_Energy :: number
end


--
function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("Main", true)

	return Main;
end

function Component:Init()
	local Scope = self:GetScope()
	local Frame = self:GetFrame()

	if not Places:CanFight() then
		return
	end

	for _, MeterHandler: ModuleScript in script:GetChildren() do
		Handlers[MeterHandler.Name] = require(MeterHandler)
	end

	--
	local Color = Scope:Value(Color3.fromRGB(104, 133, 152))

	local EnergySprings = {
		Scope:Spring(InterfaceStates.Energy[1], 15, .8),
		Scope:Spring(InterfaceStates.Energy[2], 15, .8),
		Scope:Spring(InterfaceStates.Energy[3], 15, .8),
	}
	local HealthSprings = {
		Scope:Spring(InterfaceStates.Health[1], 30, .8),
		Scope:Spring(InterfaceStates.Health[2], 30, .8),
		Scope:Spring(InterfaceStates.Health[3], 30, .8),
	}
	local ColorSpring = Scope:Spring(Color, 25, .8)

	--
	local Info = Frame.Info
	local Icons = Frame.Icons

	local Meters = Info:FindFirstChild('Meters') :: ComponentClass.Meter_Folder
	local EffectsFrame = Info:FindFirstChild('EffectsList')

	-- Privates
	local Active_Pos = UDim2.fromScale(-0.05, 0.898)
	local Next_Pos = UDim2.fromScale(-0.05, 0.33)
	local Previous_Pos = UDim2.fromScale(-0.05, -0.03)

	local Icon_Positions = {
		Scope:Value(Active_Pos),
		Scope:Value(Next_Pos),
		Scope:Value(Previous_Pos),
		Scope:Value(1),
		Scope:Value(.6),
		Scope:Value(.6),
	}

	local Icon_Springs = {
		Scope:Spring(Icon_Positions[1], 25, .8),
		Scope:Spring(Icon_Positions[2], 25, .8),
		Scope:Spring(Icon_Positions[3], 25, .8),
		Scope:Spring(Icon_Positions[4], 20, .7),
		Scope:Spring(Icon_Positions[5], 20, .7),
		Scope:Spring(Icon_Positions[6], 20, .7)
	}

	local function CleanUpEffectIcons()
		for _, EffectObj in EffectsFrame:GetChildren() do
			if EffectObj:IsA("Frame") then
				EffectObj:Destroy()
			end
		end
	end

	local function AddEffectIcon(AgentName: string, Effect: {Id: number, Time: number?, Created: number})

		--
		local Object = InterfaceAssets.Combat.Effects.EffectObj:Clone()
		Object.Name = AgentName..Effect.Id
		Object.Timer.Visible = Effect.Time ~= nil
		Object.Parent = EffectsFrame


		if Effect.Time then
			local TimeLeft = Effect.Time - (os.clock() - Effect.Created)
			local Size = UDim2.fromScale(1, TimeLeft / Effect.Time)
			Object.Timer.Fill.Size = Size
			EffectUtil:Tween(Object.Timer.Fill, {TimeLeft}, {Size = UDim2.fromScale(1, 0)})
		end
	end

	local function RemoveEffectIcon(Id: string)
		local Object = EffectsFrame:FindFirstChild(Id)
		if Object then
			Object.Name = '__destroying'
			EffectUtil:Tween(Object.UIScale, {.2, 'Quad'}, {Scale = 0})
			EffectUtil:CleanUp(Object, .2)

			Object:Destroy()
		end
	end

	local function UpdateCharacters()
		local Characters = CharacterLibrary:GetCharacters(ReplicationId())
		if Characters == nil then return end

		local CurrentActiveCharacter, Active = CharacterLibrary:GetCurrent(ReplicationId())
		if not Active or not CurrentActiveCharacter then return end

		local Next = Active + 1 > 3 and 1 or Active + 1
		local Prev = Active - 1 < 1 and 3 or Active - 1

		Icon_Positions[Active]:set(Active_Pos)
		Icon_Positions[Next]:set(Next_Pos)
		Icon_Positions[Prev]:set(Previous_Pos)
		Icon_Positions[Active + 3]:set(1)
		Icon_Positions[Next + 3]:set(.6)
		Icon_Positions[Prev + 3]:set(.6)

		--
		CleanUpEffectIcons()
		for _, Effect in CurrentActiveCharacter.__Status.__Effects do
			AddEffectIcon(CurrentActiveCharacter.Name, Effect)
		end

		--
		local Data = CharacterDatabase:GetCharacterData((CurrentActiveCharacter :: AgentTypes.AgentClass).Name)
		Info.CharacterName.Text = Data.Nickname

		for _, Item in Icons:GetChildren() do
			local Number = tonumber(Item.Name, 10) :: number
			if not Characters[Number] then continue end

			local Assets: Folder = ReplicatedStorage:WaitForChild("Assets") :: Folder & { Characters: Folder }
			local CharacterFolder = Assets:FindFirstChild("Characters") :: Folder & { Agents: Folder };
			local Character = Characters[Number].Name
			local Viewport = Item.Main :: ViewportFrame
			local BaseModel = CharacterFolder.Agents:FindFirstChild(Character) :: Model
			if not BaseModel then continue end

			local Camera = (Viewport:FindFirstChild('Camera') or Instance.new('Camera')) :: Camera
			Camera.FieldOfView = 1
			Camera.Parent = Viewport
			Camera.CFrame = CFrame.new(-0.33, 1.75, -215) * CFrame.Angles(0, math.pi, 0)

			Viewport.CurrentCamera = Camera

			local Model = BaseModel:Clone()
			Model:PivotTo(CFrame.new())
			Model.Parent = Viewport:FindFirstChild('WorldModel')
		end
	end

	InterfaceStates.EffectAdded:Connect(function(AgentId: number, EffectObj)
		local Agent, ActiveAgentId = CharacterLibrary:GetCurrent(ReplicationId())

		--print(AgentId, ActiveAgentId)
		if AgentId == ActiveAgentId and Agent then
			AddEffectIcon(Agent.Name, EffectObj)
		end
	end)

	InterfaceStates.EffectRemoved:Connect(function(AgentId: number, Id: number)
		local AgentObj = CharacterLibrary:GetAgent(ReplicationId(), AgentId)
		if not AgentObj then
			return
		end

		RemoveEffectIcon(AgentObj.Name..Id)
	end)

	-- Changes
	Scope:Observer(InterfaceStates.Characters):onChange(UpdateCharacters)

	UpdateCharacters()

	--
	table.insert(Scope, RunService.Heartbeat:Connect(function(_: number)
		local CurrentAgent, CurrentId = CharacterLibrary:GetCurrent(ReplicationId())
		local CurrentEnergySpring = EnergySprings[CurrentId :: number]

		if not CurrentEnergySpring or not CurrentAgent or not CurrentId then
			return;
		end

		local HealthValue, Max_Health = CurrentAgent:GetHealth()
		local EnergySize = math.clamp(peek(CurrentEnergySpring) / 100, 0, 1)
		local HealthSize = math.clamp(peek(HealthSprings[CurrentId]), 0, 1)

		--
		local Needed_Energy = GetEnergyNeededById(CurrentId :: number)
		if peek(CurrentEnergySpring) > Needed_Energy then
			Color:set(FULL_COLOR)
		else
			Color:set(NOT_COLOR)
		end

		Info.EnergyPercent.Text = math.floor(peek(InterfaceStates.Energy[CurrentId])).."%"
		Info.HealthCount.Text = `{math.floor(HealthValue)} / {math.floor(Max_Health)}`

		local EnergyMain = Meters.Energy.Main
		local HealthMain = Meters.Health.Main

		EnergyMain.ImageColor3 = peek(ColorSpring)
		EnergyMain.UIGradient.Offset = Vector2.new(-0.8 + EnergySize, 0)
		HealthMain.UIGradient.Offset = Vector2.new(math.min(-0.8 + HealthSize, 0.2), 0)

		--
		for Index = 1, 3 do
			local Spring_Value = Icon_Springs[Index]
			local Icon_Object = Icons[tostring(Index)]
			local Energy_Size = peek(InterfaceStates.Energy[Index])
			local Health_Size = peek(HealthSprings[Index])
			local Icon_Scale = peek(Icon_Springs[Index + 3])
			local Light = Color3.fromRGB(330, 330, 330)

			if Health_Size <= 0 then
				Energy_Size = 0
				Light = Color3.new()
			end


			--
			local TransparencyMod = (Icon_Scale - 0.6) / 0.4

			Icon_Object.Main.LightColor = Light;
			Icon_Object.Info.GroupTransparency = TransparencyMod
			Icon_Object.Info.Meters.Health.Fill.Size = UDim2.fromScale(Health_Size, 1)
			Icon_Object.Info.Meters.Energy.Fill.Size = UDim2.fromScale(Energy_Size / 100, 1)
			Icon_Object.Info.Meters.Energy.Fill.BackgroundColor3 = (Energy_Size >= GetEnergyNeededById(Index)) and FULL_COLOR or NOT_COLOR
			Icon_Object.IconScale.Scale = Icon_Scale
			Icon_Object.Position = peek(Spring_Value)
		end
	end))
end

function Component:UpdateAgentMeter(Id: number, MeterName: string, Amount: number)
	local CharacterPassiveMeterHandler = Handlers[MeterName]
	if not CharacterPassiveMeterHandler then
		return
	end

	local Frame = self:GetFrame()
	local Icons = Frame.Icons

	CharacterPassiveMeterHandler:Update(Icons[tostring(Id)], Amount)
end

return Component
