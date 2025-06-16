local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client


local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Effects = require(Shared.Utility.Effects)
local Icons = require(Shared.Database.Icons)
local AgentData = require(Shared.Database.Characters)
local LocalData = require(Client.Libraries.LocalData)

--
local DEFAULT_DESCRIPTIONS = {
    Basic_Attack = 'Agent\'s default attack.',
    Ultimate = 'Agent\'s ultimate attack',
    Special = 'Agent\'s special attack',
}

--
local SkillComponent = {
    __Agent = '',
    __Skill = '',
    __Connection = nil,
}

type MainFrame = Frame & {
    List: Frame,
    Stats: Frame & {
        UIScale: UIScale,
        Level: TextLabel,
        Desc: TextLabel,
        Upgrade: Frame & {Button: TextButton}
    }
}

function SkillComponent:UpdateSkills(MainFrame: MainFrame, Agent: string)
    if SkillComponent.__Agent == Agent then
        return
    end

    --
    SkillComponent:ShowInformation(MainFrame, nil)

    SkillComponent.__Agent = Agent

    local AgentInfo = LocalData:GetAgent(Agent)

    for SkillName in DEFAULT_DESCRIPTIONS do
        local Icon = Icons.Skills[SkillName];

        if SkillName == 'Ultimate' then
            Icon = Icons.Skills.Ultimates[Agent]
        end

        local SkillObject = MainFrame.List:FindFirstChild(SkillName)
        if not SkillObject then
            SkillObject = Assets.Interface.Agents.Skills.SkillFrame:Clone()
            SkillObject.Parent = MainFrame.List
        end

        local SkillLvl = AgentInfo.Skills[SkillName]
        SkillObject.Level.Level.Text = `{SkillLvl} / 20`

        SkillObject.Icon.Image = Icons.PREFIX .. (Icon or 0)
        SkillObject.Name = SkillName

        --
        SkillObject.Button.MouseButton1Click:Connect(function()
            SkillComponent:ShowInformation(MainFrame, SkillName)
        end)
    end
end

function SkillComponent:ShowInformation(MainFrame: MainFrame, Skill: string?)
    if SkillComponent.__Agent == nil then
        return
    end

    local StatsTab = MainFrame.Stats
    local AgentSkills = LocalData:GetAgent(SkillComponent.__Agent)
    local AgentMovesetData = AgentData:GetMovesetData(SkillComponent.__Agent);
    local SkillData = AgentMovesetData[Skill] or {}

    if (not Skill or not AgentMovesetData or not SkillData or not AgentSkills) or SkillComponent.__Skill == Skill then
        SkillComponent.__Skill = nil
        Effects:Tween(StatsTab.UIScale, {.3, 'Cubic', 'In'}, {Scale = 0})

        return
    end

    StatsTab.Visible = true

    SkillComponent.__Skill = Skill

    Effects:Tween(StatsTab.UIScale, {.25, 'Back'}, {Scale = 1})

    --
    local Description = SkillData.Description or DEFAULT_DESCRIPTIONS[Skill]

    StatsTab.Desc.Text = Description
    StatsTab.Level.Text = `<b>Lvl.</b> {AgentSkills.Skills[Skill]} / 20`

    --
    if not SkillComponent.__Connection then
        SkillComponent.__Connection = StatsTab.Upgrade.Button.MouseButton1Click:Connect(function()
            Network:Fire('UpdateAgent', GameEnum.AgentEvent.UpgradeAgentSkill, {
                SkillComponent.__Agent,
                SkillComponent.__Skill,
            })
        end)
    end
end

function SkillComponent:UpdateSkillLevels(MainFrame: MainFrame, Agent: string)
    local AgentInfo = LocalData:GetAgent(Agent)

    for SkillName in DEFAULT_DESCRIPTIONS do
        local SkillObject = MainFrame.List:FindFirstChild(SkillName)
        if not SkillObject then continue end

        local SkillLvl = AgentInfo.Skills[SkillName]
        SkillObject.Level.Level.Text = `{SkillLvl} / 20`

        if SkillComponent.__Skill == SkillName then
            MainFrame.Stats.Level.Text = `<b>Lvl.</b> {SkillLvl} / 20`
        end
    end

end

return SkillComponent