local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes

local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('Wristband')

ArtifactObject:OnEffectProcess(function(Effect, Data)
	if Effect == 'Physical' then
		print('Wristband equipped')
	end
end)

return ArtifactObject
