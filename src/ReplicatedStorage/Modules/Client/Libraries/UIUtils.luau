local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Models = Assets.Characters

local UIUtils = {}

function UIUtils:CreateArtifactModel(Artifact_Name: string, SlotId: number, Parent: ViewportFrame, UUID: string?): boolean
    
    local ArtifactsFolder = Assets:FindFirstChild('Items'):FindFirstChild('Artifacts')
    local Target = ArtifactsFolder:FindFirstChild(Artifact_Name)

    if not Target then return false end

    local ClonedModel;
    if Target:IsA('Folder') then
        if Target:FindFirstChild(tostring(SlotId)) then
            ClonedModel = Target[tostring(SlotId)]:Clone()
        else
            local Children = Target:GetChildren()
            ClonedModel = Children[math.random(1, #Children)]
        end

    elseif Target:IsA('Model') then
        
        ClonedModel = Target:Clone()
    end
    
    if Target:HasTag('RandomColor') then
        --UUID and Random.new(tonumber(string.gsub(string.sub(UUID, 1, 10), '-', ''), 16)) or 
        local Random = Random.new(SlotId)

        for _, Descendant in Target:GetDescendants() do
            if Descendant:HasTag('Recolorable') then
                Descendant.Color = Color3.fromHSV(Random:NextInteger(0, 360) / 360, 170/255, 1)
            end
        end

    end

    Parent.WorldModel:ClearAllChildren()

    ClonedModel:PivotTo(CFrame.new())
    ClonedModel.Parent = Parent.WorldModel

    if Parent:FindFirstChild('Camera') then
        Parent.Camera:Destroy()
    end

    --
    local CamOffset = Target:GetAttribute('CameraOffset') or Vector3.new(0, 0, -5)
    local NewCamera = Instance.new("Camera")
    NewCamera.FieldOfView = 10
    NewCamera.CFrame = CFrame.new(CamOffset) * CFrame.Angles(0, math.pi, 0)
    NewCamera.Parent = Parent

    Parent.CurrentCamera = NewCamera

    return true
end

function UIUtils:CreateEnemyModel(EnemyName: string, Viewport: ViewportFrame)
    local Enemies = Models.Enemies
    local EnemyBaseModel = Enemies:FindFirstChild(EnemyName)

    if not EnemyBaseModel then
        EnemyBaseModel = Models.Agents.Template
    elseif EnemyBaseModel:IsA('Folder') then
        EnemyBaseModel = EnemyBaseModel:GetChildren()[math.random(1, #EnemyBaseModel:GetChildren())]
    end

    local Cloned = EnemyBaseModel:Clone();
    Cloned:PivotTo(CFrame.new())
    Cloned.Parent = Viewport:FindFirstChildOfClass("WorldModel");

    local NewCamera = Instance.new("Camera")
    NewCamera.CFrame = CFrame.new(0, 1.8, -220) * CFrame.Angles(0, math.pi, 0)
    NewCamera.FieldOfView = 1
    NewCamera.Parent = Viewport

    Viewport.CurrentCamera = NewCamera;

    return true;
end

return UIUtils