--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Animations = ReplicatedStorage.Assets.Animations
local Characters = Animations.Characters
local General = Animations.General

--
local AnimationLibrary = {}

function AnimationLibrary:GetAnim(Directory: string)
	local Split = string.split(Directory, '.')
	local Object = Animations

	for i = 1, #Split - 1 do
		Object = Object[Split[i]]
	end

	return Object[Split[#Split]]
end

function AnimationLibrary:GetMovementAnim(Character: string, TrackName: string)
	local MovementDirectory = General

	if Characters:FindFirstChild(Character) and Characters:FindFirstChild(Character):FindFirstChild('Movement') then
		MovementDirectory = Characters:FindFirstChild(Character)
	end

	if not MovementDirectory:FindFirstChild('Movement') then
		warn('Directory doesn\'t have movement tracks')

		return;
	end

	local Track =  MovementDirectory:FindFirstChild('Movement'):FindFirstChild(TrackName) or General.Movement:FindFirstChild(TrackName)
	if Track == nil then return end

	if Track:IsA('Folder') then
		local Children = Track:GetChildren()
		return Children[math.random(1, #Children)]
	end

	return Track;
end

function AnimationLibrary:Load(Character: Model, Track: Animation)
	local Animator = AnimationLibrary:GetAnimator(Character)
	print(typeof(Character))
	local LoadedTrack = Animator:LoadAnimation(Track)

	return LoadedTrack
end

function AnimationLibrary:Play(Character: Model, TrackName: Animation, ...)
	if not TrackName then
		return
	end

	local Track = AnimationLibrary:Load(Character, TrackName)
	Track:Play(...)

	Track.Stopped:Once(function()
		Track:Destroy()
	end)

	return Track
end

function AnimationLibrary:GetTracks(Character: Model): {AnimationTrack}
	local Animator = AnimationLibrary:GetAnimator(Character)

	return Animator:GetPlayingAnimationTracks()
end

function AnimationLibrary:GetAnimator(Character: Model): Animator
	local Humanoid = Character:FindFirstChild('Humanoid') :: Humanoid
	local Animator = Humanoid:FindFirstChild('Animator') :: Animator

	if Animator == nil then
		Animator = Instance.new('Animator')
		Animator.Parent = Humanoid
	end

	return Animator
end

return AnimationLibrary
