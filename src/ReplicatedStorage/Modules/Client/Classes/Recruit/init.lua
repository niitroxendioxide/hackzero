--[[
	@class ClientRecruit

	A recruit as the client sees it, visuals only: every decision is the server's. Between
	packets it keeps walking along the last heading it was sent, with the same
	RecruitMovement the server runs so the guess lands close. Every snap pulls it back onto
	the server's position: smoothly when the guess was close, instantly when it was not.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Statics = require(Shared.Database.Statics)
local GameEnum = require(Shared.GameEnum)
local Math = require(Shared.Utility.Math)
local SharedEffects = require(Shared.Utility.Effects)
local Types = require(Shared.Types.Recruits)
local RecruitsDatabase = require(Shared.Database.Recruits)
local MovementClass = require(Shared.Classes.Recruit.RecruitMovement)
local AppearanceClass = require(Client.Classes.Appearance)
local Effects = require(Client.Libraries.Effects)
local Prompts = require(Client.Libraries.Prompts)
local InterfaceController = require(Client.Controllers.InterfaceController)
local RecruitHealth = require(Client.Components.Interface.Combat.RecruitHealth)
local Scenes = require(Client.Libraries.Scenes)
local Characters = require(Client.Libraries.Characters)
local AnimatorClass = require(script.Animator)

--
-- How fast an ally turns to keep its eyes on the local player.
local LOOK_RATE = 4

local function CreateAnchor(At: CFrame, Id: number): BasePart
	local Entities = workspace.World.Entities
	local Parent = Entities:FindFirstChild('Recruits') or Instance.new('Folder')
	Parent.Name = 'Recruits'
	Parent.Parent = Entities

	local Part = Instance.new('Part')
	Part.Name = 'Recruit' .. Id
	Part.CFrame = At
	Part.Size = Vector3.one * 2
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.Transparency = 1
	Part.Parent = Parent

	return Part
end

--- Brief white flash on the model, the hit equivalent of the Death effect's highlight.
local function Flash(Model: Model)
	local Highlight = Instance.new('Highlight')
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillColor = Color3.new(1, 1, 1)
	Highlight.FillTransparency = 0.2
	Highlight.OutlineTransparency = 1
	Highlight.Parent = Model

	SharedEffects:Tween(Highlight, {0.25}, {FillTransparency = 1})
	SharedEffects:CleanUp(Highlight, 0.3)
end

--
local ClientRecruit = {}
ClientRecruit.__index = ClientRecruit
ClientRecruit.__tostring = function()
	return 'ClientRecruitClass'
end

--[[
	@param Id      Id the server knows it by.
	@param Name    Its kind out of `Database/Recruits`.
	@param At      Where the server has it.
	@param Visuals What to draw it as, resolved server side so mission overrides show up.
]]
function ClientRecruit.new(Id: number, Name: string, At: CFrame, Visuals: {Model: string?, Display_Name: string?, Height: number?, Scene: {Event: string, Slot: number}?, Talk: string?}?): Types.ClientRecruitClass
	local Data = RecruitsDatabase:GetData(Name)
	local Drawn = Visuals or {}
	local Model = Drawn.Model or Data.Model

	local self = setmetatable({}, ClientRecruit)
	self.Name = Name

	self.__Id = Id
	self.__Owner_Id = 0
	self.__State = 'Idle'
	self.__Shield = Data.Stats.Shield
	self.__Max_Shield = Data.Stats.Shield
	self.__Display_Name = Drawn.Display_Name or Data.Display_Name
	self.__Talk = Drawn.Talk
	self.__Prompt = nil
	self.__Movement = MovementClass.new(At, Data.Stats.Walk_Speed, Drawn.Height or Data.Appearance.Height)
	self.__Correction = Vector3.zero
	self.__Anchor = CreateAnchor(At, Id)
	self.__Ally = Data.Ally == true
	self.__Facing = At.LookVector

	--- Seeded off the id, so a model folder with variants gives every client the same pick.
	--- Spawned for a scene slot: it becomes the posed model already standing there.
	self.__Appearance = AppearanceClass.new(Scenes:Take(Drawn.Scene) or Model, 'Recruits', false, Random.new(Id))
	self.__Animator = AnimatorClass.new(self, Model)
	self.__Connection = nil

	return self
end

function ClientRecruit.Init(self: Types.ClientRecruitClass)
	if self.__Connection then
		return
	end

	local Model = self.__Appearance:GetModel()
	Model:PivotTo(self.__Anchor.CFrame)

	self.__Appearance:JoinTo(self.__Anchor)
	self.__Animator:Init()

	self:SetShield(self.__Shield, self.__Max_Shield)

	self.__Connection = RunService.PreRender:Connect(function(Delta: number)
		self:Update(Delta)
	end)
end

function ClientRecruit.Update(self: Types.ClientRecruitClass, Delta: number)
	self.__Movement:Update(Delta)

	--- Bleed the correction out rather than jumping onto the server's position.
	self.__Correction *= 1 - Math:SmoothAlpha(Statics.Replication_Correction_Rate, Delta)
	if self.__Correction.Magnitude < 0.01 then
		self.__Correction = Vector3.zero
	end

	local Pivot = self:GetPivot()

	--- An ally standing still keeps turning to watch the local player, only on this screen.
	local Agent = if self.__Ally and not self:IsMoving() then Characters:GetCurrent() else nil
	if Agent then
		local Toward = Agent:GetPivot().Position - Pivot.Position
		Toward = Vector3.new(Toward.X, 0, Toward.Z)

		if Toward.Magnitude > 1e-3 then
			local Facing = self.__Facing:Lerp(Toward.Unit, Math:SmoothAlpha(LOOK_RATE, Delta))
			self.__Facing = if Facing.Magnitude > 0.05 then Facing.Unit else Toward.Unit
			self.__Anchor.CFrame = CFrame.lookAlong(Pivot.Position, self.__Facing)

			return
		end
	end

	self.__Facing = Pivot.LookVector
	self.__Anchor.CFrame = Pivot
end

function ClientRecruit.Move(self: Types.ClientRecruitClass, Direction: Vector3, Speed: number)
	self.__Movement:Move(Direction, Speed)
end

function ClientRecruit.Sync(self: Types.ClientRecruitClass, At: CFrame, Teleport: boolean?)
	local Rendered = self.__Movement.__Position + self.__Correction
	local Distance = (At.Position - Rendered).Magnitude

	if Teleport or Distance >= Statics.Replication_Snap_Distance then
		self.__Correction = Vector3.zero
		self.__Movement:PivotTo(At)
		self.__Anchor.CFrame = self:GetPivot()

		--- The model is pulled onto the anchor by physics, which would drag it across the map.
		self.__Appearance:GetModel():PivotTo(self.__Anchor.CFrame)

		return
	end

	if Distance <= Statics.Replication_Ignore_Distance then
		return
	end

	--- Take the server's position but keep drawing it where it was, Update eases the gap away.
	self.__Movement:PivotTo(At)
	self.__Correction = Rendered - At.Position
end

function ClientRecruit.DisplayHit(self: Types.ClientRecruitClass, Hits: number, Shield: number)
	self:SetShield(Shield, self.__Max_Shield)

	self.__Animator:Hit()

	local Model = self.__Appearance:GetModel()
	Flash(Model)

	--- At a position rather than the recruit itself: Indicator reuses per-id objects, and ids are shared with enemies.
	Effects:Play('Indicator', Model:GetPivot().Position, {Text = `-{Hits}`, Affliction = 'Enemy'})
end

--- Shield is its hp, shown through the RecruitHealth component.
function ClientRecruit.SetShield(self: Types.ClientRecruitClass, Shield: number, Max: number)
	self.__Shield = Shield
	self.__Max_Shield = Max

	RecruitHealth:Update(self, Max, Shield)
end

function ClientRecruit.SetOwner(self: Types.ClientRecruitClass, OwnerId: number)
	self.__Owner_Id = OwnerId
end

function ClientRecruit.SetState(self: Types.ClientRecruitClass, State: Types.RecruitState)
	self.__State = State

	--- Won the fight and has something to say: put a Talk prompt on it.
	if State == 'Celebrating' and self.__Talk and not self.__Prompt then
		local Model = self.__Appearance:GetModel()
		local Root = Model:FindFirstChild('HumanoidRootPart') or Model.PrimaryPart

		if Root then
			local Prompt = Prompts:CreatePromptOnPart(Root, 0, 'Talk', self.__Display_Name, 10)

			Prompt.Triggered:Connect(function()
				InterfaceController:GetComponent('Dialogue'):ShowDialogue({Speaker = self.__Display_Name, Text = self.__Talk, NextDialogue = 3}, false)
			end)

			self.__Prompt = Prompt
		end
	end
end

function ClientRecruit.IsOwner(self: Types.ClientRecruitClass, Player: Player): boolean
	return self.__Owner_Id ~= 0 and self.__Owner_Id == (Player:GetAttribute('ReplicationId') :: number)
end

function ClientRecruit.IsMoving(self: Types.ClientRecruitClass): boolean
	return self.__Movement:IsMoving()
end

function ClientRecruit.GetId(self: Types.ClientRecruitClass): number
	return self.__Id
end

function ClientRecruit.GetState(self: Types.ClientRecruitClass): Types.RecruitState
	return self.__State
end

function ClientRecruit.GetPivot(self: Types.ClientRecruitClass): CFrame
	return self.__Movement:GetPivot() + self.__Correction
end

function ClientRecruit.GetModel(self: Types.ClientRecruitClass): Model
	return self.__Appearance:GetModel()
end

--- @param Reason `GameEnum.EntityRemoveReason`, a defeat plays the Death effect.
function ClientRecruit.Destroy(self: Types.ClientRecruitClass, Reason: number?)
	if self.__Connection then
		self.__Connection:Disconnect()
		self.__Connection = nil
	end

	RecruitHealth:Remove(self)

	--- Death clones the model before anything yields, so destroying it right after is safe.
	if Reason == GameEnum.EntityRemoveReason.Defeated then
		Effects:Play('Death', self)
	elseif Reason == GameEnum.EntityRemoveReason.Vanished then
		self.__Appearance:SetVisible(false)

		task.delay(0.45, function()
			self.__Animator:Destroy()
			self.__Appearance:Destroy()
			self.__Anchor:Destroy()
		end)

		return
	end

	self.__Animator:Destroy()

	self.__Appearance:Destroy()
	self.__Anchor:Destroy()
end

return ClientRecruit
