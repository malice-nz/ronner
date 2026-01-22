--# Services #--
local Players			= game:GetService("Players")
local RunService		= game:GetService("RunService")
local UserInputService	= game:GetService("UserInputService")

--# Ronner #--
local Ronner	= {};
Ronner.__index	= Ronner;

local malice = function(Module)
	return loadstring(game:HttpGet(`https://git.malice.nz/{Module}.lua`))':3'
end;

--# Libraries #--
local Easing	= malice'Easing';
local Animate	= malice'Animate';
local Lucide	= malice'Lucide';
local Richie	= malice'Richie';

--# Configs #--
local VIEWPORT_OFFSET	= 20;
local TOAST_WIDTH		= 360;
local GAP				= 12;

--Ronner.CornerData	= {
--	[Enum.StartCorner.BottomRight]	= { Anchor = Vector2.new(1, 1), Position = UDim2.new(1, -VIEWPORT_OFFSET, 1, -VIEWPORT_OFFSET),	Direction = -1 },
--	[Enum.StartCorner.BottomLeft]	= { Anchor = Vector2.new(0, 1), Position = UDim2.new(0, VIEWPORT_OFFSET, 1, -VIEWPORT_OFFSET),	Direction = -1 },
--	[Enum.StartCorner.TopRight]		= { Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -VIEWPORT_OFFSET, 0, VIEWPORT_OFFSET),	Direction = 1 },
--	[Enum.StartCorner.TopLeft]		= { Anchor = Vector2.new(0, 0), Position = UDim2.new(0, VIEWPORT_OFFSET, 0, VIEWPORT_OFFSET),	Direction = 1 },
--}

Ronner.PositionData = {
	["bottom-right"]	= { Anchor = Vector2.new(1, 1),		Position = UDim2.new(1, -VIEWPORT_OFFSET, 1, -VIEWPORT_OFFSET),	Direction = -1 },
	["bottom-left"]		= { Anchor = Vector2.new(0, 1),		Position = UDim2.new(0, VIEWPORT_OFFSET, 1, -VIEWPORT_OFFSET),	Direction = -1 },
	["bottom-center"]	= { Anchor = Vector2.new(0.5, 1),	Position = UDim2.new(0.5, 0, 1, -VIEWPORT_OFFSET),				Direction = -1 },
	["top-right"]		= { Anchor = Vector2.new(1, 0),		Position = UDim2.new(1, -VIEWPORT_OFFSET, 0, VIEWPORT_OFFSET),	Direction = 1 },
	["top-left"]		= { Anchor = Vector2.new(0, 0),		Position = UDim2.new(0, VIEWPORT_OFFSET, 0, VIEWPORT_OFFSET),	Direction = 1 },
	["top-center"]		= { Anchor = Vector2.new(0.5, 0),	Position = UDim2.new(0.5, 0, 0, VIEWPORT_OFFSET),				Direction = 1 },
}

Ronner.Config	= {
	Position	= "bottom-right";

	MaxToasts		= 5;
	VisibleToasts	= 3;
	Gap				= GAP;
	DefaultDuration	= 8;

	DynamicDuration	= false;
	MinDuration		= 2;
	MaxDuration		= 7;

	Animation	= {
		Enter		= 0.4;
		Exit		= 0.2;
		Reposition	= 0.35;
		Stagger		= 0.012;
	};

	Width			= TOAST_WIDTH;
	BaseHeight		= 52;
	CornerRadius	= 8;

	CloseButton		= true;
	PauseOnHover	= true;

	SafeArea		= true;
	SafeAreaPadding	= { Top = 0, Bottom = 0, Left = 0, Right = 0 };

	Theme	= 'Dark';

	Colours = {
		Dark = {
			Background	= Color3.fromRGB(9, 9, 11);
			Foreground	= Color3.fromRGB(250, 250, 250);
			Border		= Color3.fromRGB(39, 39, 42);

			Muted			= Color3.fromRGB(161, 161, 170);
			MutedForeground	= Color3.fromRGB(113, 113, 122);

			Success	= Color3.fromRGB(74, 222, 128);
			Error	= Color3.fromRGB(248, 113, 113);
			Warning	= Color3.fromRGB(251, 191, 36);
			Info	= Color3.fromRGB(96, 165, 250);
			Loading	= Color3.fromRGB(161, 161, 170);
		},
		Light = {
			Background	= Color3.fromRGB(255, 255, 255);
			Foreground	= Color3.fromRGB(9, 9, 11);
			Border		= Color3.fromRGB(228, 228, 231);

			Muted			= Color3.fromRGB(113, 113, 122);
			MutedForeground	= Color3.fromRGB(82, 82, 91);

			Success	= Color3.fromRGB(22, 163, 74);
			Error	= Color3.fromRGB(220, 38, 38);
			Warning	= Color3.fromRGB(217, 119, 6);
			Info	= Color3.fromRGB(37, 99, 235);
			Loading	= Color3.fromRGB(113, 113, 122);
		}
	};

	Icons	= {
		Success	= Lucide('check');
		Error	= Lucide('x');
		Warning	= Lucide('alert-triangle');
		Info	= Lucide('info');
		Loading	= Lucide('loader');
		Close	= Lucide('x');
	}
};

--# Variables #--
local ScreenGui		= nil;
local Container		= nil;
local HoverArea		= nil;
local MouseTracker	= nil;
local KeyboardConn	= nil;

local Toasts		= {};
local Heights		= {};

local IsExpanded	= false;

local ToastId		= 0;
local HoverCount	= 0;

local function GetSafeAreaOffset(Position)
	if not Ronner.Config.SafeArea then
		return 0, 0
	end

	local Padding = Ronner.Config.SafeAreaPadding
	local PosData = Ronner.GetPositionData(Position)
	local XOffset, YOffset = 0, 0

	if PosData.Direction == -1 then
		YOffset = -Padding.Bottom
	else
		YOffset = Padding.Top
	end

	return XOffset, YOffset
end;

--# Getter Functions #--
function Ronner.GetThemeData(Theme)
	return Ronner.Config.Colours[Theme or Ronner.Config.Theme] or Ronner.Config.Colours.Dark
end;

function Ronner.GetPositionData(Position)
	local Pos = Position or Ronner.Config.Position

	if type(Pos) == "string" then
		return Ronner.PositionData[Pos] or Ronner.PositionData["bottom-right"]
		--else
		--	return Ronner.CornerData[Pos] or Ronner.CornerData[Enum.StartCorner.BottomRight]
	end
end;

function Ronner.CalculateDuration(Message, Description)
	if not Ronner.Config.DynamicDuration then
		return Ronner.Config.DefaultDuration
	end

	local TotalLength = (Message and #Message or 0) + (Description and #Description or 0)
	local Duration = TotalLength * 0.05

	return math.clamp(Duration, Ronner.Config.MinDuration, Ronner.Config.MaxDuration)
end;

--# Helper Functions #--
local function IsTop()
	return Ronner.GetPositionData().Direction == 1;	
end;

local function GetExpandedOffset(Index)
	local Offset = 0
	for I = 1, Index - 1 do
		local Toast = Toasts[I]
		local H = Toast and Heights[Toast.Id]
		if(H) then
			Offset = Offset + H + Ronner.Config.Gap
		end
	end
	return Offset
end
local function GetTotalStackHeight()
	if(#Toasts == 0) then return Ronner.Config.BaseHeight end;

	if(IsExpanded) then
		local Total = 0
		for I, T in ipairs(Toasts) do
			if(I <= Ronner.Config.MaxToasts) then
				Total = Total + (Heights[T.Id] or Ronner.Config.BaseHeight) + Ronner.Config.Gap
			end
		end
		return Total - Ronner.Config.Gap
	else
		local FrontHeight	= Heights[Toasts[1] and Toasts[1].Id] or Ronner.Config.BaseHeight
		local PeekHeight	= math.min(#Toasts - 1, Ronner.Config.VisibleToasts - 1) * 8
		return FrontHeight + PeekHeight + 8
	end
end

local function UpdateHoverArea()
	if(not HoverArea or #Toasts == 0) then return end;

	local TotalHeight	= GetTotalStackHeight() + 20
	local TargetSize	= UDim2.new(1, 20, 0, TotalHeight)

	Animate.To(HoverArea, { Size = TargetSize }, 0.25, Easing.Emphasised)
end

local function UpdateToastPositions(Anim)
	local Duration	= Anim and Ronner.Config.Animation.Reposition or 0
	local Dir		= Ronner.GetPositionData().Direction

	for I, ToastData in ipairs(Toasts) do
		if(ToastData.Frame and not ToastData.Removed) then
			local Index		= I - 1
			local IsVisible	= Index < Ronner.Config.VisibleToasts

			local Scale, YOffset, Opacity

			if(IsExpanded) then
				Scale	= 1
				YOffset	= GetExpandedOffset(I) * Dir
				Opacity	= 1
			else
				Scale	= math.max(1 - (Index * 0.03), 0.94)
				YOffset	= (Index * 8) * Dir
				Opacity	= IsVisible and math.max(1 - (Index * 0.15), 0.55) or 0
			end

			ToastData.Frame.ZIndex = 100 - Index

			if(Anim and Duration > 0) then
				local Delay = Index * Ronner.Config.Animation.Stagger
				task.delay(Delay, function()
					if(ToastData.Frame and ToastData.Frame.Parent) then
						Animate.To(ToastData.Frame, {
							Position			= UDim2.new(0.5, 0, IsTop() and 0 or 1, YOffset),
							GroupTransparency	= 1 - Opacity,
						}, Duration, Easing.EaseEnter)

						if(ToastData.ScaleFrame) then
							Animate.To(ToastData.ScaleFrame, {
								Size = UDim2.new(Scale, 0, 1, 0),
							}, Duration, Easing.EaseEnter)
						end
					end
				end)
			else
				ToastData.Frame.Position			= UDim2.new(0.5, 0, IsTop() and 0 or 1, YOffset)
				ToastData.Frame.GroupTransparency	= 1 - Opacity
				if(ToastData.ScaleFrame) then
					ToastData.ScaleFrame.Size = UDim2.new(Scale, 0, 1, 0)
				end
			end
		end
	end

	UpdateHoverArea()
end

local function Expand()
	if(IsExpanded or #Toasts == 0) then return end;
	IsExpanded = true
	UpdateToastPositions(true)

	for _, T in ipairs(Toasts) do
		if(T.PauseTimer) then T.PauseTimer() end;
	end
end

local function Collapse()
	if(not IsExpanded) then return end;
	IsExpanded = false
	UpdateToastPositions(true)

	for _, T in ipairs(Toasts) do
		if(T.ResumeTimer) then T.ResumeTimer() end;
	end
end
local function IsMouseInArea()
	if(not Container) then return false end;

	local Mouse		= Players.LocalPlayer:GetMouse()
	local MousePos	= Vector2.new(Mouse.X, Mouse.Y)

	if(HoverArea) then
		local AbsPos	= HoverArea.AbsolutePosition
		local AbsSize	= HoverArea.AbsoluteSize

		local InBounds = MousePos.X >= AbsPos.X - 10
			and MousePos.X <= AbsPos.X + AbsSize.X + 10
			and MousePos.Y >= AbsPos.Y - 10
			and MousePos.Y <= AbsPos.Y + AbsSize.Y + 10

		return InBounds
	end

	return false
end

local function MouseMove()
	local IsInArea = IsMouseInArea()

	if(IsInArea and not IsExpanded and #Toasts > 0) then
		Expand()
	elseif(not IsInArea and IsExpanded) then
		Collapse()
	end
end

function Ronner.Init(CustomConfig)
	if(CustomConfig) then
		for K, V in pairs(CustomConfig) do
			if(type(V) == "table" and type(Ronner.Config[K]) == "table") then
				for SK, SV in pairs(V) do
					Ronner.Config[K][SK] = SV
				end
			else
				Ronner.Config[K] = V
			end
		end
	end

	if(ScreenGui) then ScreenGui:Destroy() end;
	if(MouseTracker) then MouseTracker:Disconnect() end;

	ScreenGui						= Instance.new("ScreenGui")
	ScreenGui.Name					= "🤤"
	ScreenGui.ResetOnSpawn			= false
	ScreenGui.IgnoreGuiInset		= true
	ScreenGui.ZIndexBehavior		= Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder			= 999
	ScreenGui.Parent				= gethui()

	local PosData = Ronner.GetPositionData()
	local SafeX, SafeY = GetSafeAreaOffset()
	local AdjustedPos = UDim2.new(
		PosData.Position.X.Scale, 
		PosData.Position.X.Offset + SafeX,
		PosData.Position.Y.Scale,
		PosData.Position.Y.Offset + SafeY
	)

	Container							= Instance.new("Frame")
	Container.Name						= "Container"
	Container.BackgroundTransparency	= 1
	Container.Size						= UDim2.new(0, Ronner.Config.Width, 0, 600)
	Container.Position					= AdjustedPos
	Container.AnchorPoint				= PosData.Anchor
	Container.ClipsDescendants			= false
	Container.Parent					= ScreenGui

	HoverArea							= Instance.new("Frame")
	HoverArea.Name						= "HoverArea"
	HoverArea.BackgroundTransparency	= 1
	HoverArea.Size						= UDim2.new(1, 20, 0, Ronner.Config.BaseHeight + 20)
	HoverArea.Position					= IsTop() and UDim2.new(0.5, 0, 0, -10) or UDim2.new(0.5, 0, 1, 10)
	HoverArea.AnchorPoint				= IsTop() and Vector2.new(0.5, 0) or Vector2.new(0.5, 1)
	HoverArea.Parent					= Container

	MouseTracker = RunService.RenderStepped:Connect(function()
		if(#Toasts > 0) then
			MouseMove()
		end
	end)

	return Ronner
end;

--# Toast Creation #--
local function CreateToastElement(Id, Message, Options)
	Options = Options or {}
	local ToastType		= Options.Type or "default"
	local Description	= Options.Description
	local Action		= Options.Action
	local Duration		= (Options.Duration or Ronner.Config.DefaultDuration) * 1000
	local Dismissible	= Options.Dismissible or false

	local Colours = Ronner.GetThemeData()

	local ToastHeight = Ronner.Config.BaseHeight
	if(Description) then ToastHeight = ToastHeight + 16 end;
	if(Action) then ToastHeight = ToastHeight + 6 end;

	Heights[Id] = ToastHeight

	local Wrapper						= Instance.new("CanvasGroup")
	Wrapper.Name						= "Toast_" .. Id
	Wrapper.Size						= UDim2.new(1, 0, 0, ToastHeight)
	Wrapper.Position					= UDim2.new(0.5, 0, IsTop() and 0 or 1, 0)
	Wrapper.AnchorPoint					= Vector2.new(0.5, IsTop() and 0 or 1)
	Wrapper.BackgroundTransparency		= 1
	Wrapper.GroupTransparency			= 1
	Wrapper.ZIndex						= 100

	local ScaleFrame					= Instance.new("Frame")
	ScaleFrame.Name						= "Scale"
	ScaleFrame.Size						= UDim2.new(1, 0, 1, 0)
	ScaleFrame.Position					= UDim2.new(0.5, 0, 0.5, 0)
	ScaleFrame.AnchorPoint				= Vector2.new(0.5, 0.5)
	ScaleFrame.BackgroundTransparency	= 1
	ScaleFrame.Parent					= Wrapper

	local Card							= Instance.new("Frame")
	Card.Name							= "Card"
	Card.Size							= UDim2.new(1, 0, 1, 0)
	Card.Position						= UDim2.new(0.5, 0, 0.5, 0)
	Card.AnchorPoint					= Vector2.new(0.5, 0.5)
	Card.BackgroundColor3				= Colours.Background
	Card.BorderSizePixel				= 0
	Card.ZIndex							= 2
	Card.Parent							= ScaleFrame

	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, Ronner.Config.CornerRadius)

	local Content						= Instance.new("Frame")
	Content.Name						= "Content"
	Content.Size						= UDim2.new(1, 0, 1, 0)
	Content.BackgroundTransparency		= 1
	Content.ZIndex						= 3
	Content.Parent						= Card

	local Padding			= Instance.new("UIPadding", Content)
	Padding.PaddingTop		= UDim.new(0, 12)
	Padding.PaddingBottom	= UDim.new(0, 12)
	Padding.PaddingLeft		= UDim.new(0, 14)
	Padding.PaddingRight	= UDim.new(0, 14)

	local Layout					= Instance.new("UIListLayout", Content)
	Layout.SortOrder				= Enum.SortOrder.LayoutOrder
	Layout.FillDirection			= Enum.FillDirection.Horizontal
	Layout.VerticalAlignment		= Enum.VerticalAlignment.Center
	Layout.Padding					= UDim.new(0, 10)

	if(ToastType ~= "default") then
		local IconImage						= Instance.new("ImageLabel")
		IconImage.Name						= "Icon"
		IconImage.Size						= UDim2.new(0, 16, 0, 16)
		IconImage.BackgroundTransparency	= 1
		IconImage.Image						= Ronner.Config.Icons[ToastType:sub(1,1):upper()..ToastType:sub(2)] or ""
		IconImage.ImageColor3				= Colours[ToastType:sub(1,1):upper()..ToastType:sub(2)] or Colours.Foreground
		IconImage.ScaleType					= Enum.ScaleType.Fit
		IconImage.LayoutOrder				= 1
		IconImage.Parent					= Content

		if(ToastType == "loading") then
			task.spawn(function()
				local StartTime = tick()
				while(IconImage and IconImage.Parent) do
					local Elapsed = tick() - StartTime
					IconImage.Rotation = (Elapsed * 180) % 360
					IconImage.ImageTransparency = 0.3 + math.sin(Elapsed * 3) * 0.2
					task.wait()
				end
			end)
		end
	end

	local HasCloseBtn	= Ronner.Config.CloseButton and Dismissible
	local HasAction		= Action ~= nil
	local RightPadding	= (HasCloseBtn and 26 or 0) + (HasAction and 65 or 0)

	local TextFrame						= Instance.new("Frame")
	TextFrame.Name						= "Text"
	TextFrame.Size						= UDim2.new(1, -RightPadding - (ToastType ~= "default" and 26 or 0), 1, 0)
	TextFrame.BackgroundTransparency	= 1
	TextFrame.LayoutOrder				= 2
	TextFrame.Parent					= Content

	local TextLayout					= Instance.new("UIListLayout", TextFrame)
	TextLayout.SortOrder				= Enum.SortOrder.LayoutOrder
	TextLayout.VerticalAlignment		= Enum.VerticalAlignment.Center
	TextLayout.Padding					= UDim.new(0, 2)

	local RichieColours = {
		border		= Colours.Border,
		background	= Colours.Background,
		muted		= Colours.Muted,
		warning		= Colours.Warning,
	}

	if(Message and Message ~= "") then
		local TitleRich = Richie.Render(TextFrame, Message, Colours.Foreground, Colours.Muted, 13, Enum.Font.GothamMedium, RichieColours)
		if(TitleRich) then
			TitleRich.LayoutOrder = 1
		else
			local Title						= Instance.new("TextLabel")
			Title.Name						= "Title"
			Title.Size						= UDim2.new(1, 0, 0, 16)
			Title.BackgroundTransparency	= 1
			Title.Text						= Message
			Title.TextColor3				= Colours.Foreground
			Title.TextSize					= 13
			Title.Font						= Enum.Font.GothamMedium
			Title.TextXAlignment			= Enum.TextXAlignment.Left
			Title.TextTruncate				= Enum.TextTruncate.AtEnd
			Title.LayoutOrder				= 1
			Title.Parent					= TextFrame
		end
	end

	if(Description) then
		local DescRich = Richie.Render(TextFrame, Description, Colours.Muted, Colours.MutedForeground, 12, Enum.Font.Gotham, RichieColours)
		if(DescRich) then
			DescRich.LayoutOrder = 2
		else
			local Desc						= Instance.new("TextLabel")
			Desc.Name						= "Description"
			Desc.Size						= UDim2.new(1, 0, 0, 14)
			Desc.BackgroundTransparency		= 1
			Desc.Text						= Description
			Desc.TextColor3					= Colours.Muted
			Desc.TextSize					= 12
			Desc.Font						= Enum.Font.Gotham
			Desc.TextXAlignment				= Enum.TextXAlignment.Left
			Desc.TextTruncate				= Enum.TextTruncate.AtEnd
			Desc.LayoutOrder				= 2
			Desc.Parent						= TextFrame
		end
	end

	if(Action and Action.Label) then
		local ActionBtn						= Instance.new("TextButton")
		ActionBtn.Name						= "Action"
		ActionBtn.Size						= UDim2.new(0, 0, 0, 26)
		ActionBtn.AutomaticSize				= Enum.AutomaticSize.X
		ActionBtn.BackgroundColor3			= Colours.Foreground
		ActionBtn.BackgroundTransparency	= 1
		ActionBtn.Text						= ""
		ActionBtn.AutoButtonColor			= false
		ActionBtn.LayoutOrder				= 3
		ActionBtn.Parent					= Content

		local ActionPadding			= Instance.new("UIPadding", ActionBtn)
		ActionPadding.PaddingLeft	= UDim.new(0, 10)
		ActionPadding.PaddingRight	= UDim.new(0, 10)

		local ActionText					= Instance.new("TextLabel", ActionBtn)
		ActionText.Size						= UDim2.new(1, 0, 1, 0)
		ActionText.BackgroundTransparency	= 1
		ActionText.Text						= Action.Label
		ActionText.TextColor3				= Colours.Foreground
		ActionText.TextSize					= 12
		ActionText.Font						= Enum.Font.GothamMedium

		local Underline						= Instance.new("Frame")
		Underline.Name						= "Underline"
		Underline.Size						= UDim2.new(0, 0, 0, 1)
		Underline.Position					= UDim2.new(0.5, 0, 1, -2)
		Underline.AnchorPoint				= Vector2.new(0.5, 0)
		Underline.BackgroundColor3			= Colours.Foreground
		Underline.BackgroundTransparency	= 0.5
		Underline.BorderSizePixel			= 0
		Underline.Parent					= ActionBtn

		ActionBtn.MouseEnter:Connect(function()
			Animate.To(Underline, { Size = UDim2.new(1, -20, 0, 1) }, 0.2, Easing.Emphasised)
		end)

		ActionBtn.MouseLeave:Connect(function()
			Animate.To(Underline, { Size = UDim2.new(0, 0, 0, 1) }, 0.15, Easing.EmphasisedAccelerate)
		end)

		ActionBtn.MouseButton1Click:Connect(function()
			if(Action.OnClick) then Action.OnClick() end;
			Ronner.Dismiss(Id)
		end)
	end

	if(HasCloseBtn) then
		local CloseBtn						= Instance.new("ImageButton")
		CloseBtn.Name						= "Close"
		CloseBtn.Size						= UDim2.new(0, 20, 0, 20)
		CloseBtn.Position					= UDim2.new(1, -8, 0.5, 0)
		CloseBtn.AnchorPoint				= Vector2.new(1, 0.5)
		CloseBtn.BackgroundTransparency		= 1
		CloseBtn.Image						= Ronner.Config.Icons.Close
		CloseBtn.ImageColor3				= Colours.Muted
		CloseBtn.ImageTransparency			= 0.6
		CloseBtn.ScaleType					= Enum.ScaleType.Fit
		CloseBtn.AutoButtonColor			= false
		CloseBtn.ZIndex						= 4
		CloseBtn.Parent						= Card

		CloseBtn.MouseEnter:Connect(function()
			Animate.To(CloseBtn, { ImageTransparency = 0 }, 0.12, Easing.Standard)
		end)

		CloseBtn.MouseLeave:Connect(function()
			Animate.To(CloseBtn, { ImageTransparency = 0.6 }, 0.12, Easing.Standard)
		end)

		CloseBtn.MouseButton1Click:Connect(function()
			Ronner.Dismiss(Id)
		end)
	end

	return Wrapper, ScaleFrame, Duration, ToastHeight
end

--# Timer #--
local function CreateTimer(Duration, OnComplete)
	local RemainingTime	= Duration
	local IsPaused		= false
	local StartTime		= tick()
	local TimerThread	= nil

	local Timer = {}

	function Timer.Pause()
		if(IsPaused) then return end;
		IsPaused = true
		RemainingTime = RemainingTime - ((tick() - StartTime) * 1000)
		if(TimerThread) then
			task.cancel(TimerThread)
			TimerThread = nil
		end
	end

	function Timer.Resume()
		if(not IsPaused) then return end;
		IsPaused = false
		StartTime = tick()

		TimerThread = task.delay(RemainingTime / 1000, function()
			if(not IsPaused) then
				OnComplete()
			end
		end)
	end

	TimerThread = task.delay(Duration / 1000, function()
		if(not IsPaused) then
			OnComplete()
		end
	end)

	return Timer
end

--# Toast #--
function Ronner.Toast(MessageOrOptions, Options)
	if(not Container) then
		Ronner.Init()
	end

	local Message = nil
	local Opts = Options or {}

	if(type(MessageOrOptions) == "table") then
		Opts = MessageOrOptions
		Message = Opts.Title
	else
		Message = MessageOrOptions
	end

	-- Calculate dynamic duration if not specified
	if not Opts.Duration then
		Opts.Duration = Ronner.CalculateDuration(Message, Opts.Description)
	end

	ToastId = ToastId + 1
	local Id = ToastId

	while(#Toasts >= Ronner.Config.MaxToasts) do
		local Oldest = table.remove(Toasts)
		if(Oldest and Oldest.Frame) then
			Animate.To(Oldest.Frame, { GroupTransparency = 1 }, Ronner.Config.Animation.Exit, Easing.EmphasisedAccelerate)
			task.delay(Ronner.Config.Animation.Exit, function()
				if(Oldest.Frame) then Oldest.Frame:Destroy() end;
			end)
			Heights[Oldest.Id] = nil
		end
	end

	local Frame, ScaleFrame, Duration, Height = CreateToastElement(Id, Message, Opts)
	Frame.Parent = Container

	local ToastData = {
		Id			= Id,
		Frame		= Frame,
		ScaleFrame	= ScaleFrame,
		Height		= Height,
		Removed		= false,
	}

	table.insert(Toasts, 1, ToastData)

	local Dir = Ronner.GetPositionData().Direction
	local StartOffset = -40 * Dir
	Frame.Position = UDim2.new(0.5, 0, IsTop() and 0 or 1, StartOffset)
	ScaleFrame.Size = UDim2.new(0.97, 0, 1, 0)

	task.defer(function()
		Animate.To(Frame, { GroupTransparency = 0 }, Ronner.Config.Animation.Enter * 0.6, Easing.StandardDecelerate)
		Animate.To(Frame, { Position = UDim2.new(0.5, 0, IsTop() and 0 or 1, 0) }, Ronner.Config.Animation.Enter, Easing.EaseEnter)
		Animate.To(ScaleFrame, { Size = UDim2.new(1, 0, 1, 0) }, Ronner.Config.Animation.Enter * 0.8, Easing.EmphasisedDecelerate)

		task.delay(0.04, function()
			UpdateToastPositions(true)
		end)
	end)

	if(Duration > 0 and Duration ~= math.huge) then
		local Timer = CreateTimer(Duration, function()
			if(not ToastData.Removed) then
				Ronner.Dismiss(Id)
			end
		end)

		ToastData.PauseTimer	= Timer.Pause
		ToastData.ResumeTimer	= Timer.Resume

		if(IsExpanded) then
			Timer.Pause()
		end
	end

	return Id
end

--# Dismiss #--
function Ronner.Dismiss(Id)
	for I, T in ipairs(Toasts) do
		if(T.Id == Id and not T.Removed) then
			T.Removed = true

			local Dir = Ronner.GetPositionData().Direction
			local ExitOffset = -20 * Dir

			Animate.To(T.Frame, {
				GroupTransparency	= 1,
				Position			= UDim2.new(0.5, 0, IsTop() and 0 or 1, ExitOffset)
			}, Ronner.Config.Animation.Exit, Easing.EmphasisedAccelerate)

			if(T.ScaleFrame) then
				Animate.To(T.ScaleFrame, {
					Size = UDim2.new(0.98, 0, 1, 0)
				}, Ronner.Config.Animation.Exit, Easing.EmphasisedAccelerate)
			end

			table.remove(Toasts, I)

			task.delay(Ronner.Config.Animation.Exit, function()
				if(T.Frame) then T.Frame:Destroy() end;
			end)

			task.delay(0.04, function()
				UpdateToastPositions(true)
			end)

			Heights[Id] = nil
			break
		end
	end
end

--# Dismiss All #--
function Ronner.DismissAll()
	local ToastsToRemove = {}
	for _, T in ipairs(Toasts) do
		table.insert(ToastsToRemove, T)
		T.Removed = true
	end

	for I, T in ipairs(ToastsToRemove) do
		task.delay((I - 1) * 0.03, function()
			Animate.To(T.Frame, { GroupTransparency = 1 }, Ronner.Config.Animation.Exit * 0.8, Easing.EmphasisedAccelerate)
			task.delay(Ronner.Config.Animation.Exit, function()
				if(T.Frame) then T.Frame:Destroy() end;
			end)
		end)
		Heights[T.Id] = nil
	end

	Toasts = {}
	UpdateHoverArea()
end

function Ronner.Promise(PromiseFunc, Messages, Options)
	local Id = Ronner.Loading(Messages.Loading or "Loading...", Options)

	task.spawn(function()
		local Success, Result = pcall(PromiseFunc)
		Ronner.Dismiss(Id)

		if(Success) then
			Ronner.Success(Messages.Success or "Success!", Options)
		else
			Ronner.Error(Messages.Error or "Something went wrong", Options)
		end
	end)

	return Id
end
--# Update Toast #--
function Ronner.Update(Id, Options)
	for _, T in ipairs(Toasts) do
		if T.Id == Id and not T.Removed then
			local TextFrame = T.Frame:FindFirstChild("Scale")
				and T.Frame.Scale:FindFirstChild("Card")
				and T.Frame.Scale.Card:FindFirstChild("Content")
				and T.Frame.Scale.Card.Content:FindFirstChild("Text")

			if TextFrame then
				local Title = TextFrame:FindFirstChild("Title")
				if Title and Options.Message then
					Title.Text = Options.Message
				end

				local Desc = TextFrame:FindFirstChild("Description")
				if Desc and Options.Description then
					Desc.Text = Options.Description
				end
			end

			if Options.Type then
				local IconFrame = T.Frame.Scale.Card.Content:FindFirstChild("Icon")
				if IconFrame then
					local Colours = Ronner.GetThemeData()
					IconFrame.Image = Ronner.Config.Icons[Options.Type:sub(1,1):upper()..Options.Type:sub(2)] or ""
					IconFrame.ImageColor3 = Colours[Options.Type:sub(1,1):upper()..Options.Type:sub(2)] or Colours.Foreground
				end
			end
			break
		end
	end
end

--# Theme Toggle #--
function Ronner.SetTheme(Theme)
	Ronner.Config.Theme = Theme
end

--# Configure #--
function Ronner.Configure(Options)
	for K, V in pairs(Options) do
		if type(V) == "table" and type(Ronner.Config[K]) == "table" then
			for SK, SV in pairs(V) do
				Ronner.Config[K][SK] = SV
			end
		else
			Ronner.Config[K] = V
		end
	end
end

--# Destroy #--
function Ronner.Destroy()
	if MouseTracker then
		MouseTracker:Disconnect()
		MouseTracker = nil
	end
	if KeyboardConn then
		KeyboardConn:Disconnect()
		KeyboardConn = nil
	end
	if ScreenGui then
		ScreenGui:Destroy()
		ScreenGui = nil
	end
	Container = nil
	HoverArea = nil
	Toasts = {}
	Heights = {}
end

return Ronner
