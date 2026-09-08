--!nonstrict
--[[
	@Roblox (modified)

	Roblox's DynamicThumbstick, adapted to render inside a frame authored in PlayerHUD
	(PlayerHUD.TouchControlFrame) instead of building and laying out its own frame.

	The frame passed to :Enable()/:Create() IS the thumbstick's canvas: its Size and Position are
	owned by the UI, never by this module. What the stick CAPTURES is bounded separately by
	GetTouchRegion, so a container-sized frame doesn't swallow the touches the camera needs.
--]]

--[[ Constants ]]--
local ZERO_VECTOR3 = Vector3.new(0,0,0)
local TOUCH_CONTROLS_SHEET = "rbxasset://textures/ui/Input/TouchControlsSheetV2.png"

local DYNAMIC_THUMBSTICK_ACTION_NAME = "DynamicThumbstickAction"
local DYNAMIC_THUMBSTICK_ACTION_PRIORITY = Enum.ContextActionPriority.High.Value

local MIDDLE_TRANSPARENCIES = {
	1 - 0.89,
	1 - 0.70,
	1 - 0.60,
	1 - 0.50,
	1 - 0.40,
	1 - 0.30,
	1 - 0.25
}
local NUM_MIDDLE_IMAGES = #MIDDLE_TRANSPARENCIES

-- The background fade tints thumbstickFrame.BackgroundTransparency. Roblox applied it to a
-- full-screen region where it reads as a vignette; on a stick-sized authored frame it reads as an
-- opaque box, so it stays off. Flip this back on only if the frame is made full-screen again.
local FADE_IN_OUT_BACKGROUND = false
local FADE_IN_OUT_MAX_ALPHA = 0.35

local FADE_IN_OUT_HALF_DURATION_DEFAULT = 0.3
local FADE_IN_OUT_BALANCE_DEFAULT = 0.5
local ThumbstickFadeTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- The authored frame decides where the stick is DRAWN. What it CAPTURES is bounded separately:
-- a touch the stick claims gets sunk through ContextActionService, which marks it
-- gameProcessedEvent, and Camera.lua's TouchMoved skips those. So a capture area covering the whole
-- screen means the camera can never be dragged.
--
-- Small authored frame -> capture its rect plus HIT_PADDING_PX.
-- Container-sized frame -> fall back to Roblox's stock region and leave the rest to the camera.
local HIT_PADDING_PX = 24
local MAX_CAPTURE_VIEWPORT_FRACTION = 0.5
local STOCK_REGION_POSITION = Vector2.new(0, 1/3)
local STOCK_REGION_SIZE = Vector2.new(0.4, 2/3)

-- Defaults, scaled x2 on tablet-sized viewports. Pixel values: independent of the frame's size.
local DEFAULT_THUMBSTICK_SIZE = 45
local DEFAULT_RING_SIZE = 20
local DEFAULT_MIDDLE_SIZE = 10
local DEFAULT_MIDDLE_SPACING = DEFAULT_MIDDLE_SIZE + 4
local RADIUS_OF_DEAD_ZONE = 2
local RADIUS_OF_MAX_SPEED = 20
local BIG_SCREEN_MIN_AXIS = 500

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

--[[ The Module ]]--
local BaseCharacterController = require(script.Parent:WaitForChild("BaseCharacterController"))
local DynamicThumbstick = setmetatable({}, BaseCharacterController)
DynamicThumbstick.__index = DynamicThumbstick

function DynamicThumbstick.new()
	local self = setmetatable(BaseCharacterController.new() :: any, DynamicThumbstick)

	self.moveTouchObject = nil
	self.moveTouchLockedIn = false
	self.moveTouchFirstChanged = false
	self.moveTouchStartPosition = nil

	self.startImage = nil
	self.endImage = nil
	self.middleImages = {}

	self.startImageFadeTween = nil
	self.endImageFadeTween = nil
	self.middleImageFadeTweens = {}

	self.isFirstTouch = true

	self.thumbstickFrame = nil

	self.onRenderSteppedConn = nil

	-- Assigned for real in ResizeThumbstick during :Create(). Seeded here so a DoMove that lands
	-- before Create (disabled stick, stray touch) compares against numbers instead of nil.
	self.thumbstickSize = DEFAULT_THUMBSTICK_SIZE
	self.thumbstickRingSize = DEFAULT_RING_SIZE
	self.middleSize = DEFAULT_MIDDLE_SIZE
	self.middleSpacing = DEFAULT_MIDDLE_SPACING
	self.radiusOfDeadZone = RADIUS_OF_DEAD_ZONE
	self.radiusOfMaxSpeed = RADIUS_OF_MAX_SPEED

	self.fadeInAndOutBalance = FADE_IN_OUT_BALANCE_DEFAULT
	self.fadeInAndOutHalfDuration = FADE_IN_OUT_HALF_DURATION_DEFAULT
	self.hasFadedBackgroundInPortrait = false
	self.hasFadedBackgroundInLandscape = false

	self.tweenInAlphaStart = nil
	self.tweenOutAlphaStart = nil

	return self
end

-- Note: Overrides base class GetIsJumping with get-and-clear behavior to do a single jump
-- rather than sustained jumping. This is only to preserve the current behavior through the refactor.
function DynamicThumbstick:GetIsJumping()
	local wasJumping = self.isJumping
	self.isJumping = false
	return wasJumping
end

function DynamicThumbstick:Enable(enable: boolean?, uiParentFrame: GuiObject?): boolean
	if enable == nil then return false end			-- If nil, return false (invalid argument)
	enable = enable and true or false				-- Force anything non-nil to boolean before comparison

	if enable then
		if not uiParentFrame then
			warn("[DynamicThumbstick] Enable(true) needs the frame to bind to")
			return false
		end

		-- Re-Create on a *different* frame, not just a missing one: PlayerHUD is rebuilt on respawn
		-- when ResetOnSpawn is set, which leaves the previously adopted frame orphaned.
		if self.thumbstickFrame ~= uiParentFrame then
			self:Create(uiParentFrame)
		end

		if not self.enabled then
			self:BindContextActions()
		end
	else
		if self.enabled then
			self:UnbindContextActions()
			self:OnInputEnded() -- Cleanup
		end
	end

	self.enabled = enable

	if self.thumbstickFrame then
		self.thumbstickFrame.Visible = enable
	end

	return true
end

-- Was called OnMoveTouchEnded in previous version
function DynamicThumbstick:OnInputEnded()
	self.moveTouchObject = nil
	self.moveVector = ZERO_VECTOR3
	self:FadeThumbstick(false)
end

function DynamicThumbstick:FadeThumbstick(visible: boolean?)
	if not visible and self.moveTouchObject then
		return
	end
	if self.isFirstTouch then return end
	if not self.startImage or not self.endImage then return end

	if self.startImageFadeTween then
		self.startImageFadeTween:Cancel()
	end
	if self.endImageFadeTween then
		self.endImageFadeTween:Cancel()
	end
	for i = 1, #self.middleImages do
		if self.middleImageFadeTweens[i] then
			self.middleImageFadeTweens[i]:Cancel()
		end
	end

	if visible then
		self.startImageFadeTween = TweenService:Create(self.startImage, ThumbstickFadeTweenInfo, { ImageTransparency = 0 })
		self.startImageFadeTween:Play()

		self.endImageFadeTween = TweenService:Create(self.endImage, ThumbstickFadeTweenInfo, { ImageTransparency = 0.2 })
		self.endImageFadeTween:Play()

		for i = 1, #self.middleImages do
			self.middleImageFadeTweens[i] = TweenService:Create(self.middleImages[i], ThumbstickFadeTweenInfo, { ImageTransparency = MIDDLE_TRANSPARENCIES[i] })
			self.middleImageFadeTweens[i]:Play()
		end
	else
		self.startImageFadeTween = TweenService:Create(self.startImage, ThumbstickFadeTweenInfo, { ImageTransparency = 1 })
		self.startImageFadeTween:Play()

		self.endImageFadeTween = TweenService:Create(self.endImage, ThumbstickFadeTweenInfo, { ImageTransparency = 1 })
		self.endImageFadeTween:Play()

		for i = 1, #self.middleImages do
			self.middleImageFadeTweens[i] = TweenService:Create(self.middleImages[i], ThumbstickFadeTweenInfo, { ImageTransparency = 1 })
			self.middleImageFadeTweens[i]:Play()
		end
	end
end

function DynamicThumbstick:FadeThumbstickFrame(fadeDuration: number, fadeRatio: number)
	self.fadeInAndOutHalfDuration = fadeDuration * 0.5
	self.fadeInAndOutBalance = fadeRatio
	self.tweenInAlphaStart = tick()
end

-- InputObject.Position is viewport-absolute (it includes the top-bar inset), while
-- GuiObject.AbsolutePosition excludes that inset unless the ScreenGui sets IgnoreGuiInset.
-- Every place that mixes the two goes through here so the hit test and the visuals stay together.
function DynamicThumbstick:GetFrameOrigin(): Vector2
	if not self.thumbstickFrame then
		return Vector2.zero
	end

	local screenGui = self.thumbstickFrame:FindFirstAncestorWhichIsA("ScreenGui")
	local inset = (screenGui and not screenGui.IgnoreGuiInset) and GuiService:GetGuiInset() or Vector2.zero

	return self.thumbstickFrame.AbsolutePosition + inset
end

--- Viewport-space rect (top-left, bottom-right) in which a touch starts a stick drag.
--- Everything outside it is passed straight through, so the camera keeps those touches.
function DynamicThumbstick:GetTouchRegion(): (Vector2, Vector2)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1, 1)

	local topLeft = viewport * STOCK_REGION_POSITION
	local size = viewport * STOCK_REGION_SIZE

	if self.thumbstickFrame then
		local padding = Vector2.new(HIT_PADDING_PX, HIT_PADDING_PX)
		local frameTopLeft = self:GetFrameOrigin() - padding
		local frameSize = self.thumbstickFrame.AbsoluteSize + (padding * 2)

		local viewportArea = viewport.X * viewport.Y
		local coversViewport = viewportArea <= 0
			or ((frameSize.X * frameSize.Y) / viewportArea) > MAX_CAPTURE_VIEWPORT_FRACTION

		if not coversViewport then
			topLeft = frameTopLeft
			size = frameSize
		end
	end

	return topLeft, topLeft + size
end

function DynamicThumbstick:InputInFrame(inputObject: InputObject)
	local frameCornerTopLeft: Vector2, frameCornerBottomRight: Vector2 = self:GetTouchRegion()
	local inputPosition = inputObject.Position
	if inputPosition.X >= frameCornerTopLeft.X and inputPosition.Y >= frameCornerTopLeft.Y then
		if inputPosition.X <= frameCornerBottomRight.X and inputPosition.Y <= frameCornerBottomRight.Y then
			return true
		end
	end
	return false
end

function DynamicThumbstick:DoFadeInBackground()
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local hasFadedBackgroundInOrientation = false

	-- only fade in/out the background once per orientation
	if playerGui then
		if playerGui.CurrentScreenOrientation == Enum.ScreenOrientation.LandscapeLeft or
			playerGui.CurrentScreenOrientation == Enum.ScreenOrientation.LandscapeRight then
				hasFadedBackgroundInOrientation = self.hasFadedBackgroundInLandscape
				self.hasFadedBackgroundInLandscape = true
		elseif playerGui.CurrentScreenOrientation == Enum.ScreenOrientation.Portrait then
				hasFadedBackgroundInOrientation = self.hasFadedBackgroundInPortrait
				self.hasFadedBackgroundInPortrait = true
		end
	end

	if not hasFadedBackgroundInOrientation then
		self.fadeInAndOutHalfDuration = FADE_IN_OUT_HALF_DURATION_DEFAULT
		self.fadeInAndOutBalance = FADE_IN_OUT_BALANCE_DEFAULT
		self.tweenInAlphaStart = tick()
	end
end

function DynamicThumbstick:DoMove(direction: Vector3)
	local currentMoveVector: Vector3 = direction

	-- Scaled Radial Dead Zone
	local inputAxisMagnitude: number = currentMoveVector.Magnitude
	if inputAxisMagnitude < self.radiusOfDeadZone then
		currentMoveVector = ZERO_VECTOR3
	else
		currentMoveVector = currentMoveVector.Unit*(
			1 - math.max(0, (self.radiusOfMaxSpeed - currentMoveVector.Magnitude)/self.radiusOfMaxSpeed)
		)
		currentMoveVector = Vector3.new(currentMoveVector.X, 0, currentMoveVector.Y)
	end

	self.moveVector = currentMoveVector
end


function DynamicThumbstick:LayoutMiddleImages(startPos: Vector3, endPos: Vector3)
	local startDist = (self.thumbstickSize / 2) + self.middleSize
	local vector = endPos - startPos
	local distAvailable = vector.Magnitude - (self.thumbstickRingSize / 2) - self.middleSize
	local direction = vector.Unit

	local distNeeded = self.middleSpacing * NUM_MIDDLE_IMAGES
	local spacing = self.middleSpacing

	if distNeeded < distAvailable then
		spacing = distAvailable / NUM_MIDDLE_IMAGES
	end

	for i = 1, NUM_MIDDLE_IMAGES do
		local image = self.middleImages[i]
		local distWithout = startDist + (spacing * (i - 2))
		local currentDist = startDist + (spacing * (i - 1))

		if distWithout < distAvailable then
			local pos = endPos - direction * currentDist
			local exposedFraction = math.clamp(1 - ((currentDist - distAvailable) / spacing), 0, 1)

			image.Visible = true
			image.Position = UDim2.new(0, pos.X, 0, pos.Y)
			image.Size = UDim2.new(0, self.middleSize * exposedFraction, 0, self.middleSize * exposedFraction)
		else
			image.Visible = false
		end
	end
end

function DynamicThumbstick:MoveStick(pos)
	local frameOrigin = self:GetFrameOrigin()
	local vector2StartPosition = Vector2.new(self.moveTouchStartPosition.X, self.moveTouchStartPosition.Y)
	local startPos = vector2StartPosition - frameOrigin
	local endPos = Vector2.new(pos.X, pos.Y) - frameOrigin
	self.endImage.Position = UDim2.new(0, endPos.X, 0, endPos.Y)
	self:LayoutMiddleImages(startPos, endPos)
end

function DynamicThumbstick:BindContextActions()
	local function inputBegan(inputObject)
		if self.moveTouchObject then
			return Enum.ContextActionResult.Pass
		end

		if not self:InputInFrame(inputObject) then
			return Enum.ContextActionResult.Pass
		end

		if self.isFirstTouch then
			self.isFirstTouch = false
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0)
			TweenService:Create(self.startImage, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)}):Play()
			TweenService:Create(
				self.endImage,
				tweenInfo,
				{Size = UDim2.new(0, self.thumbstickSize, 0, self.thumbstickSize), ImageColor3 = Color3.new(0,0,0)}
			):Play()
		end

		self.moveTouchLockedIn = false
		self.moveTouchObject = inputObject
		self.moveTouchStartPosition = inputObject.Position
		self.moveTouchFirstChanged = true

		if FADE_IN_OUT_BACKGROUND then
			self:DoFadeInBackground()
		end

		return Enum.ContextActionResult.Pass
	end

	local function inputChanged(inputObject: InputObject)
		if inputObject == self.moveTouchObject then
			if self.moveTouchFirstChanged then
				self.moveTouchFirstChanged = false

				local frameOrigin = self:GetFrameOrigin()
				local startPosVec2 = Vector2.new(
					inputObject.Position.X - frameOrigin.X,
					inputObject.Position.Y - frameOrigin.Y
				)
				self.startImage.Visible = true
				self.startImage.Position = UDim2.new(0, startPosVec2.X, 0, startPosVec2.Y)
				self.endImage.Visible = true
				self.endImage.Position = self.startImage.Position

				self:FadeThumbstick(true)
				self:MoveStick(inputObject.Position)
			end

			self.moveTouchLockedIn = true

			local direction = Vector2.new(
				inputObject.Position.X - self.moveTouchStartPosition.X,
				inputObject.Position.Y - self.moveTouchStartPosition.Y
			)
			if math.abs(direction.X) > 0 or math.abs(direction.Y) > 0 then
				self:DoMove(direction)
				self:MoveStick(inputObject.Position)
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	local function inputEnded(inputObject)
		if inputObject == self.moveTouchObject then
			self:OnInputEnded()
			if self.moveTouchLockedIn then
				return Enum.ContextActionResult.Sink
			end
		end
		return Enum.ContextActionResult.Pass
	end

	local function handleInput(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			return inputBegan(inputObject)
		elseif inputState == Enum.UserInputState.Change then
			if inputObject == self.moveTouchObject then
				return Enum.ContextActionResult.Sink
			else
				return Enum.ContextActionResult.Pass
			end
		elseif inputState == Enum.UserInputState.End then
			return inputEnded(inputObject)
		elseif inputState == Enum.UserInputState.Cancel then
			self:OnInputEnded()
		end
	end

	ContextActionService:BindActionAtPriority(
		DYNAMIC_THUMBSTICK_ACTION_NAME,
		handleInput,
		false,
		DYNAMIC_THUMBSTICK_ACTION_PRIORITY,
		Enum.UserInputType.Touch)

	self.TouchMovedCon = UserInputService.TouchMoved:Connect(function(inputObject: InputObject, _gameProcessedEvent: boolean)
		inputChanged(inputObject)
	end)
end

function DynamicThumbstick:UnbindContextActions()
	ContextActionService:UnbindAction(DYNAMIC_THUMBSTICK_ACTION_NAME)

	if self.TouchMovedCon then
		self.TouchMovedCon:Disconnect()
		self.TouchMovedCon = nil
	end
end

-- Tears down everything :Create() made, WITHOUT destroying the frame itself: the frame is authored
-- in PlayerHUD and owned by the UI, not by this module.
function DynamicThumbstick:DestroyVisuals()
	if self.startImage then
		self.startImage:Destroy()
		self.startImage = nil
	end
	if self.endImage then
		self.endImage:Destroy()
		self.endImage = nil
	end
	for _, image in self.middleImages do
		image:Destroy()
	end
	table.clear(self.middleImages)

	self.startImageFadeTween = nil
	self.endImageFadeTween = nil
	self.middleImageFadeTweens = {}

	local Connections = {
		"onRenderSteppedConn",
		"absoluteSizeChangedConn",
		"viewportSizeChangedConn",
		"onTouchEndedConn",
		"menuOpenedConn",
	}

	for _, Key in Connections do
		if self[Key] then
			self[Key]:Disconnect()
			self[Key] = nil
		end
	end
end

--- Adopts `parentFrame` as the thumbstick itself. Its Size/Position/styling stay untouched.
function DynamicThumbstick:Create(parentFrame: GuiObject)
	self:DestroyVisuals()

	self.thumbstickFrame = parentFrame
	self.thumbstickFrame.Active = false

	-- Visuals are brand new, so the touch state that drives them has to start over too: without
	-- this, a re-adopted frame keeps isFirstTouch = false and the resting ring never shrinks.
	self.isFirstTouch = true
	self.moveTouchObject = nil
	self.moveTouchLockedIn = false
	self.moveTouchFirstChanged = false
	self.moveVector = ZERO_VECTOR3

	self.startImage = Instance.new("ImageLabel")
	self.startImage.Name = "ThumbstickStart"
	self.startImage.Visible = true
	self.startImage.BackgroundTransparency = 1
	self.startImage.Image = TOUCH_CONTROLS_SHEET
	self.startImage.ImageRectOffset = Vector2.new(1,1)
	self.startImage.ImageRectSize = Vector2.new(144, 144)
	self.startImage.ImageColor3 = Color3.new(0, 0, 0)
	self.startImage.AnchorPoint = Vector2.new(0.5, 0.5)
	self.startImage.ZIndex = 10
	self.startImage.Parent = self.thumbstickFrame

	self.endImage = Instance.new("ImageLabel")
	self.endImage.Name = "ThumbstickEnd"
	self.endImage.Visible = true
	self.endImage.BackgroundTransparency = 1
	self.endImage.Image = TOUCH_CONTROLS_SHEET
	self.endImage.ImageRectOffset = Vector2.new(1,1)
	self.endImage.ImageRectSize =  Vector2.new(144, 144)
	self.endImage.AnchorPoint = Vector2.new(0.5, 0.5)
	self.endImage.ZIndex = 10
	self.endImage.Parent = self.thumbstickFrame

	for i = 1, NUM_MIDDLE_IMAGES do
		self.middleImages[i] = Instance.new("ImageLabel")
		self.middleImages[i].Name = "ThumbstickMiddle"
		self.middleImages[i].Visible = false
		self.middleImages[i].BackgroundTransparency = 1
		self.middleImages[i].Image = TOUCH_CONTROLS_SHEET
		self.middleImages[i].ImageRectOffset = Vector2.new(1,1)
		self.middleImages[i].ImageRectSize = Vector2.new(144, 144)
		self.middleImages[i].ImageTransparency = MIDDLE_TRANSPARENCIES[i]
		self.middleImages[i].AnchorPoint = Vector2.new(0.5, 0.5)
		self.middleImages[i].ZIndex = 9
		self.middleImages[i].Parent = self.thumbstickFrame
	end

	local function ResizeThumbstick()
		-- Sized off the viewport, not the frame: the ">500" test asks "is this a tablet?", and the
		-- authored frame is stick-sized, so measuring it would answer "no" on every device.
		local camera = workspace.CurrentCamera
		local screenSize = camera and camera.ViewportSize or Vector2.new(1, 1)
		local isBigScreen = math.min(screenSize.X, screenSize.Y) > BIG_SCREEN_MIN_AXIS
		local scale = isBigScreen and 2 or 1

		self.thumbstickSize = DEFAULT_THUMBSTICK_SIZE * scale
		self.thumbstickRingSize = DEFAULT_RING_SIZE * scale
		self.middleSize = DEFAULT_MIDDLE_SIZE * scale
		self.middleSpacing = DEFAULT_MIDDLE_SPACING * scale
		self.radiusOfDeadZone = RADIUS_OF_DEAD_ZONE * scale
		self.radiusOfMaxSpeed = RADIUS_OF_MAX_SPEED * scale

		-- Rest at the centre of whatever it actually captures, in frame-local pixels. For a
		-- stick-sized frame that IS the frame's centre; for a container it's the stock region's,
		-- so the ring sits where the touches are rather than mid-screen.
		local regionTopLeft, regionBottomRight = self:GetTouchRegion()
		local restPosition = ((regionTopLeft + regionBottomRight) / 2) - self:GetFrameOrigin()

		self.startImage.Position = UDim2.fromOffset(restPosition.X, restPosition.Y)
		self.startImage.Size = UDim2.new(0, self.thumbstickRingSize * 3.7, 0, self.thumbstickRingSize * 3.7)

		self.endImage.Position = self.startImage.Position
		self.endImage.Size = UDim2.new(0, self.thumbstickSize * 0.8, 0, self.thumbstickSize * 0.8)
	end

	ResizeThumbstick()
	self.absoluteSizeChangedConn = parentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeThumbstick)

	if workspace.CurrentCamera then
		self.viewportSizeChangedConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ResizeThumbstick)
	end

	self.moveTouchStartPosition = nil

	if FADE_IN_OUT_BACKGROUND then
		self.onRenderSteppedConn = RunService.RenderStepped:Connect(function()
			if self.tweenInAlphaStart ~= nil then
				local delta = tick() - self.tweenInAlphaStart
				local fadeInTime = (self.fadeInAndOutHalfDuration * 2 * self.fadeInAndOutBalance)
				self.thumbstickFrame.BackgroundTransparency = 1 - FADE_IN_OUT_MAX_ALPHA*math.min(delta/fadeInTime, 1)
				if delta > fadeInTime then
					self.tweenOutAlphaStart = tick()
					self.tweenInAlphaStart = nil
				end
			elseif self.tweenOutAlphaStart ~= nil then
				local delta = tick() - self.tweenOutAlphaStart
				local fadeOutTime = (self.fadeInAndOutHalfDuration * 2) - (self.fadeInAndOutHalfDuration * 2 * self.fadeInAndOutBalance)
				self.thumbstickFrame.BackgroundTransparency = 1 - FADE_IN_OUT_MAX_ALPHA + FADE_IN_OUT_MAX_ALPHA*math.min(delta/fadeOutTime, 1)
				if delta > fadeOutTime  then
					self.tweenOutAlphaStart = nil
				end
			end
		end)
	end

	self.onTouchEndedConn = UserInputService.TouchEnded:Connect(function(inputObject: InputObject)
		if inputObject == self.moveTouchObject then
			self:OnInputEnded()
		end
	end)

	self.menuOpenedConn = GuiService.MenuOpened:Connect(function()
		if self.moveTouchObject then
			self:OnInputEnded()
		end
	end)
end

return DynamicThumbstick
