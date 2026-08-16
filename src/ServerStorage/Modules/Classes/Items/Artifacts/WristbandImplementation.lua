local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes

local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('Wristband')

ArtifactObject:OnHitProcess("After", function(Data, PieceCount)
	if PieceCount < 4 then return end

end)

return ArtifactObject
