---
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local _Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local LibVFX = require(Client.Libraries.Effects)

---
return function(
	EnemyId: number,
	Caster: Types.ClientAgent
): ()
	local EnemyObj = Enemies:GetEnemy(EnemyId)
	local Model = EnemyObj:GetModel();

	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(62, 31, 31)
	Highlight.OutlineColor = Color3.new(1, 0, 0)
	Highlight.FillTransparency = -12
	Highlight.OutlineTransparency = -25;
	Highlight.Parent = Model;

	Effects:CleanUp(Highlight, 1 / 5)

	task.wait(1 / 30)

	if Caster.__Player_Assigned == Players.LocalPlayer then
		local CC = Instance.new("ColorCorrectionEffect")
		CC.Contrast = -4;
		CC.Saturation = -1;
		CC.Parent = Lighting;
	
		Effects:CleanUp(CC, 1 / 10)
	end
	
	---
	LibVFX:Play("Hit", EnemyObj, { Emitter = 'BlackFlashHit', HitstopTime = 1 / 10, Weld = true })
end
