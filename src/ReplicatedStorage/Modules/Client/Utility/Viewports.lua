--> by @juaniitrox (niitroxen) on 14/11/2023, v1.02;

local RunService = game:GetService('RunService');
local HttpService = game:GetService('HttpService');
local TweenService = game:GetService('TweenService');
local Players = game:GetService('Players');

-->
local OsClock = os.clock;
local CharacterClasses = {'Accessory', 'Shirt', 'Pants', 'BodyColors', 'Humanoid'};
local Errors = {
	InvalidInstance = 'Incorrect type of instance given (%s). Can only track BaseParts, Models or Characters',
	RootNotFound = 'WorldModel \"Root\" not found under viewportframe: %s',
	NotDescendantOfWorkspace = 'Object: %s is not a descendant of workspace.',
};
local ViewportManager = {};
ViewportManager.__index = ViewportManager;

type Ease = ('Linear' | 'Sine' | 'Quad' | 'Cubic' | 'Quart' | 'Quint' | 'Circular' | 'Exponential' | 'Elastic' | 'Bounce' | 'Back')?

type FadeInfo = {
	Time: number?,
	Ease: Ease?,
	StopTracking: boolean?
};

type ViewportParameters = {
	Object: BasePart | Model,

	ModelParent: Model?,
	RenderedProperties: {string}?,
	Parent: (ScreenGui | Frame | ViewportFrame)?,
	GetModelDescendants: boolean?,
	ZIndex: number?,
	Framerate: number?,

	RenderPriority: (Enum.RenderPriority | number)?,
	Blacklist: {Instance}?,
}

export type ViewportInstance = {
	Object: BasePart | Model,
	RenderPriority: (Enum.RenderPriority | number),

	RenderedProperties: {string},
	Parent: (ScreenGui | Frame | ViewportFrame)?,
	GetModelDescendants: boolean?,
	ZIndex: number?,
	Framerate: number?,

	Update: (self: ViewportInstance, Delta: number) -> nil,
	Start: (self: ViewportInstance) -> nil,
	Stop: (self: ViewportInstance) -> nil,
	Destroy: (self: ViewportInstance, FadeOptions: FadeInfo?) -> nil,
	PlayFade: (self: ViewportInstance, FadeOptions: FadeInfo) -> nil,
	PlayOnce: (self: ViewportInstance, FadeOptions: FadeInfo) -> nil,
	AddConnection: (self: ViewportInstance, Object: BasePart, Reference: BasePart) -> nil,

	_model_parent: Model?,
	_viewportobject: Model?,
	_renderframe: ViewportFrame?,
	_connections: {string}?,
	_active: boolean,
	_connection_id: string,
	_blacklist: {Instance}?,
};


-------> Create a new model to track the given instance, requires only an Object to track.
	-- returns a ViewportInstance.
	-- use :Start() to start the tracking of said object
	-- use :Stop() to stop the tracking of said object,
function ViewportManager.new(Data: ViewportParameters): ViewportInstance
	if not(Data) or not(Data.Object) then
		error(Errors.InvalidInstance:format(Data and Data.Object or 'nil'))
	end

	local self = setmetatable(Data, ViewportManager);
	self.RenderPriority = self.RenderPriority or Enum.RenderPriority.Camera.Value + 1
	self.RenderedProperties = self.RenderedProperties or {'CFrame'}
	self._blacklist = Data.Blacklist or {}
	self._model_parent = Data.ModelParent

	if typeof(self.RenderPriority) == 'EnumItem' then
		self.RenderPriority = self.RenderPriority.Value;
	end

	self.Object.Destroying:Once(function()
		self:Destroy();
	end)

	return self :: ViewportInstance;
end





-------> Called by the ViewportManager internally to update a basepart
function ViewportManager:Update(Object: BasePart, Reference: BasePart) --> @ delta: number isn't needed btw
	if not(self._renderframe) or not(self._renderframe:FindFirstChild('Root')) then
		warn(Errors.RootNotFound:format(tostring(self._renderframe)))
		return;
	end

	for i = 1, #self.RenderedProperties do
		local Property = self.RenderedProperties[i]
		--[[local HasProperty = pcall(function()
			return Reference[Property] ~= nil;
		end)]]

		Object[Property] = Reference[Property];
	end
end





-------> Starts tracking and updating the bodyparts
function ViewportManager:Start(PlayedOnce: boolean?)
	if self._active then
		return;
	end

	if not(self.Object:IsDescendantOf(workspace)) then
		error(Errors.NotDescendantOfWorkspace:format(tostring(self.Object)));

		return
	end

	local Client = Players.LocalPlayer;
	local ParentGui = self.Parent;

	self._active = true;
	self._connection_id = HttpService:GenerateGUID(false);

	if not(self.Parent) then
		ParentGui = Client.PlayerGui:FindFirstChild('ViewportManagerScreenGUI') or Instance.new('ScreenGui')
		ParentGui.Name = 'ViewportManagerScreenGUI';
		ParentGui.IgnoreGuiInset = true;
		ParentGui.Parent = Client.PlayerGui;

		ParentGui.Destroying:Once(function()
			self:Destroy();
		end)
	end

	-- >> Create render frame
	self._renderframe = Instance.new('ViewportFrame');
	self._renderframe.Size = UDim2.fromScale(1, 1);
	self._renderframe.BackgroundTransparency = 1;
	self._renderframe.LightDirection = Vector3.new(1, -1, -1);
	self._renderframe.Ambient = Color3.fromRGB(138, 138, 138);
	self._renderframe.LightColor = Color3.new(1, 1, 1);
	self._renderframe.CurrentCamera = workspace.CurrentCamera;
	self._renderframe.Name = `VFM{self._connection_id}`;
	self._renderframe.Parent = ParentGui;
	self._renderframe.ZIndex = self.ZIndex or self._renderframe.ZIndex;

	if not(self._renderframe:FindFirstChildOfClass('WorldModel')) then
		local WorldModel = Instance.new('WorldModel');
		WorldModel.Parent = self._renderframe;
		WorldModel.Name = 'Root';
	else
		local Root = self._renderframe:FindFirstChildOfClass('WorldModel');
		Root.Name = 'Root';
	end

	self._connections = {};

	--[[if self._viewportobject then
		self._viewportobject:Destroy()
	end]]

	self._viewportobject = Instance.new('Model');
	self._viewportobject.Parent = self._model_parent or self._renderframe.Root;
	self._viewportobject.Name = ''

	if self.Object:IsA('Model') then
		local IsCharacter = self.Object:FindFirstChild('Humanoid');
		local Parts = self.Object:GetChildren();

		local AddObjects; AddObjects = function(List, Parent: Model?)
			for _, Child: BasePart | Model in List do
				if self.GetModelDescendants and Child:IsA('Model') and not(table.find(self._blacklist, Child)) then
					local SubModel = Instance.new('Model');
					SubModel.Name, SubModel.Parent = Child.Name, self._viewportobject;
					AddObjects(Child:GetChildren(), SubModel);
				end

				if Child:IsA('BasePart') then
					local Cloned = Child:Clone();
					Cloned.CFrame = Child.CFrame;
					Cloned.Anchored = true;
					Cloned.Parent = Parent or self._viewportobject;

					self:AddConnection(Cloned, Child, PlayedOnce);
				end
			end
		end

		AddObjects(Parts);

		if IsCharacter then
			IsCharacter.Died:Once(function()
				self:Destroy()
			end)

			for _, Detail in Parts do
				if table.find(CharacterClasses, Detail.ClassName) then
					local Required = Detail:Clone();
					Required.Parent = self._viewportobject;

					if Detail:IsA('Accessory') and Detail:FindFirstChild('Handle') then
						local BasePart = Detail.Handle;
						local Object = Required.Handle;

						self:AddConnection(Object, BasePart, PlayedOnce);
					end
				end
			end
		end
	elseif self.Object:IsA('BasePart') then
		local Cloned = self.Object:Clone();
		Cloned.CFrame = self.Object.CFrame;
		Cloned.Anchored = true;
		Cloned.Parent = self._viewportobject;

		self:AddConnection(Cloned, self.Object, PlayedOnce);
	end
end





-------> Save a connection on it's connection table/cache, will be deleted upon calling:
	-- :Stop(),
	-- :Destroy()
	-- :PlayFade({StopTracking = true})
function ViewportManager:AddConnection(Object: BasePart, Reference: BasePart, PlayedOnce: boolean?)
	if PlayedOnce then
		self:Update(Object, Reference);

		return;
	end

	local LastFrameUpdate = OsClock();
	local subId = `{HttpService:GenerateGUID(false):sub(1, 7)}{self._connection_id}`;
	RunService:BindToRenderStep(subId, self.RenderPriority, function(Delta)
		if not(Object) or not(Reference) then
			local idx = table.find(self._connections, subId);
			if idx then
				RunService:UnbindFromRenderStep(subId);
				table.remove(self._connections, idx)
			end

			return
		end

		if self.Framerate and (OsClock() - LastFrameUpdate) < 1/self.Framerate then
			return;
		end

		LastFrameUpdate = OsClock();
		self:Update(Object, Reference);
	end)

	table.insert(self._connections, subId);
end

----> Plays the viewport manager for 1 frame and instantly stops playback, fading away the effect.
	-- Useful for afterimages
function ViewportManager:PlayOnce(FadeOptions: FadeInfo)
	if not(FadeOptions) then
		return;
	end

	self:Start(true);
	task.spawn(self.PlayFade, self, FadeOptions);
end



----> Fades away the render frame for the viewport instance
function ViewportManager:PlayFade(Fade: FadeInfo)
	if not(Fade) or not(self._renderframe) then
		return;
	end

	if Fade.StopTracking then
		self:Stop();
	end

	local Time = Fade.Time or 0.5;
	local Ease = Fade.Ease or 'Linear';
	local Frame = self._renderframe;
	if Fade.StopTracking then
		self._renderframe = nil;
	end

    if Enum.EasingStyle:FromName(Ease) == nil then
        return
    end

    local Easing = Enum.EasingStyle[Ease]
	local Info = TweenInfo.new(Time, Easing);
	local Tween = TweenService:Create(Frame, Info, {ImageTransparency = 1});
	Tween:Play();

	Tween.Completed:Wait();
	Tween:Destroy();

	Frame:Destroy();
end

----> Deletes the Viewport instance
function ViewportManager:Destroy(Fade: FadeInfo)
	if not(self._active) then
		return;
	end

	self:PlayFade(Fade);

	self:Stop();

	if self._renderframe then
		self._renderframe:Destroy();
	end

	for k in self do
		self[k] = nil;
	end

	self = nil;
end

----> Stops all active tracking of the viewportinstance
function ViewportManager:Stop()
	self._active = false;

	if self._connections then
		for _, connection_id in self._connections do
			RunService:UnbindFromRenderStep(connection_id)
		end

		self._connections = nil;
	end
end

----> Returns the Viewportframe used by the current ViewportInstance to render models
function ViewportManager:GetViewportFrame(): ViewportFrame?
	return self._renderframe
end

----> Updates the rendered frame z index
function ViewportManager:SwitchZIndex(NewValue: number?)
	local RenderFrame = self:GetViewportFrame();
	if not(RenderFrame) then
		return;
	end

	self.ZIndex = NewValue or 1;

	RenderFrame.ZIndex = self.ZIndex;
end

return ViewportManager;