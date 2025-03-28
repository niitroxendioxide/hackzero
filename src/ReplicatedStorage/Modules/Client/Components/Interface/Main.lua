--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client

local Component = require(Client.Classes.Interface)
local Fusion = require(Client.Libraries.Fusion)
local Events = require(Client.Libraries.Events)
local CharacterLibrary = require(Client.Libraries.Characters)
local InterfaceStates = require(Client.Packages.InterfaceStates)

--
local peek = Fusion.peek
local Component = Component.new(script.Name, 'HUD', {
})

function Component:Init()
	local UserId = Player.UserId
	local Scope = self:GetScope()
	local Frame = self:GetFrame()
	
	--
	local Color = Scope:Value(Color3.fromRGB(104, 133, 152))
	
	local EnergySpring = Scope:Spring(InterfaceStates.Energy, 15, .8)
	local HealthSpring = Scope:Spring(InterfaceStates.Health, 30, .8)
	local ColorSpring = Scope:Spring(Color, 25, .8)

	--
	local Info = Frame.Info
	local Icons = Frame.Icons

	local Meters = Info:FindFirstChild('Meters') :: Component.Meter_Folder

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

	local function UpdateCharacters()
		local Characters = CharacterLibrary:GetCharacters(Player.UserId)
		if Characters == nil then return end
		
		local CurrentActiveCharacter, Active = CharacterLibrary:GetCurrent(Player.UserId)
		if not Active then return end
		
		local Next = Active + 1 > 3 and 1 or Active + 1
		local Prev = Active - 1 < 1 and 3 or Active - 1
		
		Icon_Positions[Active]:set(Active_Pos)
		Icon_Positions[Next]:set(Next_Pos)
		Icon_Positions[Prev]:set(Previous_Pos)
		Icon_Positions[Active + 3]:set(1)
		Icon_Positions[Next + 3]:set(.6)
		Icon_Positions[Prev + 3]:set(.6)

		--
		local Health, Max_Health = CurrentActiveCharacter:GetHealth()
		InterfaceStates.Health:set(Health)
		InterfaceStates.Max_Health:set(Max_Health)
		
		Info.CharacterName.Text = CurrentActiveCharacter.Name
	
		for _, Item in Icons:GetChildren() do
			local Number = tonumber(Item.Name, 10) :: number
			if not Characters[Number] then continue end
			
			local Character = Characters[Number].Name
			local Viewport = Item.Main :: ViewportFrame
			local BaseModel = ReplicatedStorage.Assets.Characters.Agents:FindFirstChild(Character)
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
	
	
	-- Changes
	Scope:Observer(InterfaceStates.Energy):onChange(function() 
		local Value = Fusion.peek(InterfaceStates.Energy)
		
		if Value > 60 then
			Color:set(Color3.fromRGB(51, 211, 255))
		else
			Color:set(Color3.fromRGB(104, 133, 152))
		end
	end)
	
	Scope:Observer(InterfaceStates.Characters):onChange(UpdateCharacters)
	
	UpdateCharacters()
	
	--
	table.insert(Scope, RunService.Heartbeat:Connect(function(delta: number)
		local EnergySize = math.clamp(peek(EnergySpring) / 100, 0, 1)
		local HealthSize = math.clamp(peek(HealthSpring) / peek(InterfaceStates.Max_Health), 0, 1)
		
		--
		
		Info.EnergyPercent.Text = math.floor(peek(InterfaceStates.Energy)).."%"
		Info.HealthCount.Text = math.floor(peek(InterfaceStates.Health)).."/"..math.floor(peek(InterfaceStates.Max_Health))
		
		local EnergyMain = Meters.Energy.Main
		local HealthMain = Meters.Health.Main
		
		EnergyMain.ImageColor3 = peek(ColorSpring)
		EnergyMain.UIGradient.Offset = Vector2.new(-0.8 + EnergySize, 0)
		HealthMain.UIGradient.Offset = Vector2.new(math.min(-0.8 + HealthSize, 0.2), 0)
		
		--
		for Index = 1, 3 do 
			local Spring_Value = Icon_Springs[Index]
			local Icon_Object = Icons[tostring(Index)]

			Icon_Object.IconScale.Scale = peek(Icon_Springs[Index + 3])
			Icon_Object.Position = peek(Spring_Value)
		end
	end))
end

return Component
