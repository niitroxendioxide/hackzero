---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)


---
return function(
	Caster: Types.ClientAgent
): ()
	const LuffyAssets = Assets.Effects.Agents.Luffy
	const CasterModel = Caster:GetModel();

	const BazookaVFX = Effects:Create(LuffyAssets.BazookaPlay, 500)
	BazookaVFX:PivotTo(CasterModel:GetPivot() * CFrame.new(0, 0, -10.5))

	const RaycastGround = Effects:CastMapRaycast(CasterModel:GetPivot(), vector.create(0, -25, 0))
	if RaycastGround then
		Effects:RecolorSmoke(RaycastGround, BazookaVFX:GetDescendants())
	end

	Effects:Emit(BazookaVFX, true)

	const Aura = Instance.new("Highlight");
	Aura.DepthMode = Enum.HighlightDepthMode.Occluded;
	Aura.FillColor = Color3.fromRGB(255, 255, 255)
	Aura.FillTransparency = 1.8
	Aura.Parent = CasterModel;
	Aura.OutlineTransparency = 0.99

	Effects:CleanUp(Aura, 0.35)
	Effects:Tween(Aura, { .35, 'Quad' }, {FillTransparency = 1})
end
