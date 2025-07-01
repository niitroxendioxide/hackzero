--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Inputs = require(Client.Libraries.Inputs)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local CutsceneLibrary = require(Client.Libraries.Cutscenes)
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local InterfaceController = require(Client.Controllers.InterfaceController)
--local Replicator = require(Client.Libraries.Replicator)

--local GameEnum = require(Shared.GameEnum)

--
local Controller = {
	__Abilities = {"Basic_Attack", "Dodge", "Swap_Forth", "Swap_Back", "Ultimate", "Special"},
	__State = false,
}

function Controller:Init()
	if not Places:CanFight() then
		return;
	end

	Movesets:Init()

	--
	Network:On("Cutscene", function(Type: number, CutscenName: string)
		if Type == GameEnum.CutsceneStatus.Received then
			CutsceneLibrary:Start(CutscenName)
		end
	end)

	--
	for _, Key in Controller.__Abilities do
		Inputs:Bind(Key, {
			Release = true,
			Callback = function(State: 'Begin' | 'End')
				Controller:HandleInput(Key, State)
			end,
		})
	end
end

function Controller:RequestCutscene()
	
end


function Controller:SetCombatState(State: boolean, Key: number?)
	Controller.__State = State
end

function Controller:GetCurrentCharacter()
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local CurrentAgent = Characters:GetCurrent(UserId)

	return CurrentAgent
end

function Controller:HandleInput(Key: string, State: string)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))
	local CurrentAgent = Characters:GetCurrent(UserId)

	if (CurrentAgent == nil) or not(Controller.__State) or not CurrentAgent:IsAlive() then
		return
	end

	if string.match(Key, "Swap") and not CurrentAgent:CanSwitch() then
		return
	end

	local Success;
	if State == 'Begin' then
		Success = CharacterMoveset:Begin(Key, CurrentAgent)
	else
		Success = CharacterMoveset:Release(Key, CurrentAgent)
	end

	--
	if Success then
		local SkillInfo = CharacterMoveset:GetInfoForSkill(Key)

		if string.match(Key, 'Swap') then
			SkillInfo = {Base = {Cooldown = .25}}
			Key = "Swap_Forth"
		end

		if SkillInfo.Base and SkillInfo.Base.Cooldown then
			local Moveset = InterfaceController:GetComponent("Moveset")

			Moveset:PlayCooldown(Key, SkillInfo.Base.Cooldown)
		end
	end

	if Key == 'Dodge' then
		for _, Character in Characters:GetCharacters(UserId) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end
end

return Controller