local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes

local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('Wristband')

ArtifactObject:OnEffectProcess(function(Data, PieceCount: number)
	if Data.Element == 'Physical' then

	end
end)

ArtifactObject:OnHitProcess("After", function()

end)

return ArtifactObject
