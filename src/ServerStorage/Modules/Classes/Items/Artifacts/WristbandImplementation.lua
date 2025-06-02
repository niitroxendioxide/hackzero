local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes

local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('Wristband')

ArtifactObject:OnEffectProcess(function(Data, PieceCount: number)
	print('Wristband equipped', PieceCount)
	if Data.Element == 'Physical' then

	end
end)

ArtifactObject:OnHitProcess("After", function()
	print("after damage")
end)

return ArtifactObject
