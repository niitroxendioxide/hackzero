local ArtifactClass = require("../../Classes/Artifact")

local ArtifactObject = ArtifactClass.new('Wristband')

ArtifactObject:OnEffectProcess(function(Effect, Data)
	if Effect == 'Physical' then
		print('Wristband equipped')
	end
end)

return ArtifactObject
