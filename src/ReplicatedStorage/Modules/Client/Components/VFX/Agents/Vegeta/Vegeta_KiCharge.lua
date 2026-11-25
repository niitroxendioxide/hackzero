---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

const Cache = {}
const MAX_CHARGE_TIME = 0.7;

---
return function(
	Caster: Types.ClientAgent
): ()
	if Cache[Caster] then
		return;
	end

	if Caster.__Player_Assigned == Players.LocalPlayer then
		Effects:ShakeCamera("Hit")
	end

	const VegetaAssets = Assets.Effects.Agents.Vegeta
	const CasterModel = Caster:GetModel();

	const Effect = Effects:Create(VegetaAssets.ChargingAura, 500)
	Effect:PivotTo(CasterModel:GetPivot())
	Effects:Weld(Effect.PrimaryPart, CasterModel.PrimaryPart)

	const RaycastGround = Effects:CastMapRaycast(CasterModel:GetPivot(), vector.create(0, -25, 0))
	if RaycastGround then
		Effects:CreateRocks(RaycastGround, vector.create(1.95, 0.75, 1.95), {11, 14}, {6, 11}, {-13, 13})
	end

	const Aura = Instance.new("Highlight");
	Aura.DepthMode = Enum.HighlightDepthMode.Occluded;
	Aura.FillColor = Color3.fromRGB(255, 92, 92)
	Aura.OutlineColor = Color3.fromRGB(97, 147, 255)
	Aura.FillTransparency = 1
	Aura.Parent = CasterModel;
	Aura.OutlineTransparency = 0.99

	Cache[Caster] = task.spawn(function()
		const Start = os.clock();
		while Caster:HasTag("HoldingKiCharge") do
			const Current = math.clamp((os.clock() - Start) / MAX_CHARGE_TIME, 0, 1)
			const Value = TweenService:GetValue(Current, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			Aura.FillTransparency = math.lerp(1, 1.5, Value)
			Aura.OutlineTransparency = math.lerp(0.99, 0, Value)

			task.wait()
		end

		const InstaDelete = Effect:FindFirstChild("MainAura", true);
		if InstaDelete then InstaDelete:Destroy() end

		Effects:Toggle(Effect, false)
		Effects:CleanUp(Effect, 1.25)
		Effects:Tween(Aura, { 0.25 }, {OutlineTransparency = 0.99, FillTransparency = 1})
		Effects:CleanUp(Aura, 0.25)

		if Cache[Caster] ~= coroutine.running() then
			task.cancel(Cache[Caster])
		end

		Cache[Caster] = nil;
	end)
end
