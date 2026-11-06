---
local ReplicatedStorage = game:GetService('ReplicatedStorage')



local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

const EnemyOverheadGui = require("@game/ReplicatedStorage/Modules/Client/Libraries/EnemyStatusIndicator")

const HighlightColor = Color3.fromRGB(37, 255, 33);
const MidHighlightTr = 1.6;

const function TweenHighlight(Model)
	const Highlight = Instance.new("Highlight")
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.Parent = Model;
	
	Highlight.FillColor = Color3.new(1,1,1)
	Highlight.OutlineColor = Color3.fromRGB(234, 0, 255)
	Highlight.FillTransparency = 30;
	Highlight.OutlineTransparency = 0;
	
	Effects:Tween(Highlight, {0.45, 'Linear'}, {FillTransparency = MidHighlightTr, FillColor = HighlightColor})
	Effects:Tween(Highlight, {0.7, 'Quad'}, {OutlineTransparency = 0.999})
	task.delay(0.45, function()
		Effects:Tween(Highlight, {0.5, 'Quad'}, {FillTransparency = 1, FillColor = Color3.new(1,1,1)})
		Effects:CleanUp(Highlight, 0.5)
	end)
	
end

---
return function(EnemyObject: Types.ClientEnemy, IsCorrupted: boolean): ()
    warn("Spawning enemy automatically turns it into corrupt spaw, fix later.")
    IsCorrupted = true --

    if IsCorrupted then
        const AuraEffect = Effects:Create(Assets.Effects.Enemies.SpawnEnemy, 5)
        AuraEffect:PivotTo(EnemyObject:GetPivot())

        task.delay(0.15, function()
            EnemyObject:SetVisible(true)

            task.wait(0.15)

            TweenHighlight(EnemyObject:GetModel())
            
            task.wait(0.1)
            Effects:Toggle(AuraEffect, false)

            task.wait(0.45)
            EnemyOverheadGui:AddIndicator(EnemyObject:GetId(), EnemyObject)
        end)
    else
        EnemyOverheadGui:AddIndicator(EnemyObject:GetId(), EnemyObject)
    end

end