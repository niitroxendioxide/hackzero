local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local TextCache = {}

return function(Text: string)
    local Frame = Effects:FromGui(Text)
	if not Frame then
        return;
	end

    if not TextCache[Text] then
        TextCache[Text] = {}
    end
    
    local DodgeTextobj: ImageLabel = Frame.text;
	if #TextCache[Text] > 0 then
		for _, tween in TextCache[Text] do
			tween:Cancel()
		end

		TextCache[Text] = {}
	end

	DodgeTextobj.ImageTransparency = 0.6
	DodgeTextobj.Scaler.Scale = 0.25
	TextCache[Text][#TextCache[Text] + 1] = Effects:Tween(DodgeTextobj, {0.375, 'Quad'}, {ImageTransparency = 1})
	TextCache[Text][#TextCache[Text] + 1] = Effects:Tween(DodgeTextobj.Scaler, {.25, 'Quad'}, {Scale = 1})
end
