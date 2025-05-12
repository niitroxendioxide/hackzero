--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local Artifacts = {
	__Stored = {} :: Types.Artifact_Data,
	__Ids = {},
}

function Artifacts:Init()
	for _, ArtifactModule in script:GetChildren() do
		local Success, Artifact_Data = pcall(require, ArtifactModule)

		if Success then
			Artifacts.__Stored[ArtifactModule.Name] = table.freeze(Artifact_Data)

			table.insert(Artifacts.__Ids, ArtifactModule.Name)
		else
			warn('Error on character data for:', ArtifactModule.Name)
		end
	end
end

function Artifacts:GetArtifactData(Name: string): Types.Artifact_Data
	local SavedData = Artifacts.__Stored[Name]

	return SavedData
end

function Artifacts:GetTwoPieceEffect(Name: string)
	local ArtifactData = Artifacts:GetArtifactData(Name)
	
	return {
		Effect = ArtifactData.Piece_Effects,
		Description = ArtifactData.Piece_Descriptions,
	}
end

function Artifacts:Verify(Name: string): boolean
	return Artifacts:GetArtifactData(Name) ~= nil
end

function Artifacts:GetIdFor(Name: string): number?
	return table.find(Artifacts.__Ids, Name)
end

function Artifacts:GetFromId(Id: number): string
	return Artifacts.__Ids[Id]
end

return Artifacts
