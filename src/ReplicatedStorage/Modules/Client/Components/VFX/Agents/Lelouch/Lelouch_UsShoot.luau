const _ReplicatedStorage = game:GetService("ReplicatedStorage")

const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")

return function(Caster: any, ...)
    const Model = Caster:GetModel();
    const Gun = Model:FindFirstChild("Gun")

    Effects:Emit(Gun)
end
