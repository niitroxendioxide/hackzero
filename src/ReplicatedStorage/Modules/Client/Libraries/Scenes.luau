--[[
	Client side of SceneService: the posed models an event shows before anyone walks into it,
	pooled per event and slot. An enemy or recruit spawned for a slot `Take`s its model
	instead of making a new one; whatever nobody takes is `Clear`ed by the server.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client

local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local AnimLibrary = require(Client.Libraries.Animation)

--
type Posed = {Model: any, Track: AnimationTrack?}

local Scenes = {
	__Pool = {} :: {[string]: {[number]: Posed}},
}

--- `"Characters.Recruits.Namekian"` -> ReplicatedStorage.Assets.Characters.Recruits.Namekian.
local function FindAsset(Src: string): Instance?
	local Object: Instance? = ReplicatedStorage.Assets

	for _, Name in string.split(Src, '.') do
		Object = Object and Object:FindFirstChild(Name)
	end

	--- A folder of variants, like the character folders, picks one.
	if Object and Object:IsA('Folder') then
		local Variants = Object:GetChildren()
		Object = Variants[math.random(1, math.max(#Variants, 1))]
	end

	return Object
end

local function GetFolder(): Folder
	local Entities = workspace.World.Entities
	local Folder = Entities:FindFirstChild('Scenes')

	if not Folder then
		Folder = Instance.new('Folder')
		Folder.Name = 'Scenes'
		Folder.Parent = Entities
	end

	return Folder :: Folder
end

--- Only the root: anchoring the limbs too would freeze the pose the animation puts them in.
local function SetAnchored(Model: Model, State: boolean)
	local Root = Model:FindFirstChild('HumanoidRootPart') or Model.PrimaryPart

	if Root and Root:IsA('BasePart') then
		Root.Anchored = State
	end
end

--- Put up the slots of `Event`. Slots it already shows are left alone, the server may send twice.
function Scenes:Set(Event: string, Entries: {{Slot: number, Src: string, Animation: string?, CFrame: CFrame}})
	local Pool = Scenes.__Pool[Event] or {}
	Scenes.__Pool[Event] = Pool

	for _, Entry in Entries do
		if Pool[Entry.Slot] then
			continue
		end

		--- A Model (a posed character) or a BasePart (an effect: particles, lights, sounds inside it).
		local Asset = FindAsset(Entry.Src)
		if not Asset or not (Asset:IsA('Model') or Asset:IsA('BasePart')) then
			warn(`Scenes: no model or part at Assets.{Entry.Src}`)

			continue
		end

		print(Entry)
		local Model = Asset:Clone()

		if Model:IsA('Model') then
			SetAnchored(Model, true)
			Model:PivotTo(Entry.CFrame)
		else
			Model.Anchored = true
			Model.CFrame = Entry.CFrame
		end

		Model.Parent = GetFolder()

		local Track = nil
		if Entry.Animation and Model:IsA('Model') then
			Track = AnimLibrary:Play(Model, AnimLibrary:GetAnim(Entry.Animation), 0, 1, 1)

			if Track then
				Track.Looped = true
			else
				warn(`Scenes: no animation at Animations.{Entry.Animation}`)
			end
		end

		Pool[Entry.Slot] = {Model = Model, Track = Track, Type = Entry.Type}
	end
end

--[[
	Hand the model of a slot over to the entity spawned for it: its pose is stopped and it is
	unanchored, ready for an Appearance to take. Nil when this client never had it (joined
	after the scene was used), the entity then makes its own model as usual.
]]
function Scenes:Take(Link: {Event: string, Slot: number}?): Model?
	local Pool = Link and Scenes.__Pool[Link.Event]
	local Posed = Pool and Pool[Link.Slot]
	if not Posed or not Posed.Model:IsA('Model') then
		return nil
	end

	Pool[Link.Slot] = nil

	if Posed.Track then
		Posed.Track:Stop(0.2)
	end

	SetAnchored(Posed.Model, false)

	return Posed.Model
end

function Scenes:Clear(Event: string, Slots: {number})
	local Pool = Scenes.__Pool[Event]
	if not Pool then
		return
	end

	for _, Slot in Slots do
		local Posed = Pool[Slot]
		Pool[Slot] = nil

		if Posed and Posed.Type ~= "Effect" then
			Posed.Model:Destroy()
		end

		if Posed.Type == "Effect" then
			Effects:Toggle(Posed.Model, false)
			Effects:CleanUp(Posed.Model, 5)
			if Posed.Model:IsA('BasePart') then
				Posed.Model.Transparency = 1;
			end
		end
	end
end

return Scenes
