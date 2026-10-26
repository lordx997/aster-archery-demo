-- Run once in Studio edit mode to recreate the latest UI from this place.
-- Do not install this file as a running game script.
assert(not game:GetService("RunService"):IsRunning(), "Stop play mode first")
assert(not game.StarterGui:FindFirstChild("AsterHUD"), "AsterHUD already exists; edit it in StarterGui")
local Objects = {}
local function Make(Class, Name, Parent, Properties)
    local Object = Instance.new(Class)
    Object.Name = Name
    for Property, Value in Properties do
        Object[Property] = Value
    end
    Object.Parent = Parent
    return Object
end

-- AsterHUD
Objects[1] = Make("ScreenGui", "AsterHUD", nil, {
    Enabled = true, ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Global, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
    ClipToDeviceSafeArea = true, SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension,
})
Objects[1]:SetAttribute("UIVersion", 2)

-- ScorePanel
Objects[2] = Make("Frame", "ScorePanel", Objects[1], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 24, 0, 70), Size = UDim2.new(0, 322, 0, 186),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.0823529437, 0.145098045, 0.149019614), BackgroundTransparency = 0.07000000029802322,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[3] = Make("UICorner", "Corner", Objects[2], {
    CornerRadius = UDim.new(0, 10),
})


-- Responsive
Objects[4] = Make("UIScale", "Responsive", Objects[2], {
    Scale = 1,
})


-- Brand
Objects[5] = Make("TextLabel", "Brand", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 20, 0, 15), Size = UDim2.new(0, 282, 0, 24),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "ASTER  /  ARCHERY CLUB",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 14,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Mode
Objects[6] = Make("TextLabel", "Mode", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 20, 0, 45), Size = UDim2.new(0, 170, 0, 18),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "FREE PRACTICE",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 10,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Time
Objects[7] = Make("TextLabel", "Time", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 202, 0, 45), Size = UDim2.new(0, 100, 0, 18),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "NO TIMER",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 11,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Right,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Score
Objects[8] = Make("TextLabel", "Score", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 20, 0, 65), Size = UDim2.new(0, 130, 0, 54),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "000",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 42,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- ScoreCaption
Objects[9] = Make("TextLabel", "ScoreCaption", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 22, 0, 119), Size = UDim2.new(0, 130, 0, 18),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "POINTS",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 9,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Accuracy
Objects[10] = Make("TextLabel", "Accuracy", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 174, 0, 80), Size = UDim2.new(0, 100, 0, 30),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "—",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 23,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- AccuracyCaption
Objects[11] = Make("TextLabel", "AccuracyCaption", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 174, 0, 112), Size = UDim2.new(0, 110, 0, 18),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "ACCURACY",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 9,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Stats
Objects[12] = Make("TextLabel", "Stats", Objects[2], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 20, 0, 153), Size = UDim2.new(0, 284, 0, 20),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "0 SHOTS   /   0 STREAK   /   BEST 0",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 10,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Challenge
Objects[13] = Make("TextButton", "Challenge", Objects[1], {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 72), Size = UDim2.new(0, 190, 0, 42),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = true,
    Selectable = true, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "NEW CHALLENGE  [R]",
    TextColor3 = Color3.new(0.0823529437, 0.145098045, 0.149019614), TextTransparency = 0, TextSize = 12,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1, AutoButtonColor = true,
    Modal = false, Selected = false, Style = Enum.ButtonStyle.Custom,
})


-- Corner
Objects[14] = Make("UICorner", "Corner", Objects[13], {
    CornerRadius = UDim.new(0, 7),
})


-- Responsive
Objects[15] = Make("UIScale", "Responsive", Objects[13], {
    Scale = 1,
})


-- Reticle
Objects[16] = Make("Frame", "Reticle", Objects[1], {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 40, 0, 40),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = false, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Tick1
Objects[17] = Make("Frame", "Tick1", Objects[16], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 19, 0, 0), Size = UDim2.new(0, 2, 0, 10),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Tick2
Objects[18] = Make("Frame", "Tick2", Objects[16], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 19, 0, 30), Size = UDim2.new(0, 2, 0, 10),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Tick3
Objects[19] = Make("Frame", "Tick3", Objects[16], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 19), Size = UDim2.new(0, 10, 0, 2),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Tick4
Objects[20] = Make("Frame", "Tick4", Objects[16], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 30, 0, 19), Size = UDim2.new(0, 10, 0, 2),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Center
Objects[21] = Make("Frame", "Center", Objects[16], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 18, 0, 18), Size = UDim2.new(0, 4, 0, 4),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[22] = Make("UICorner", "Corner", Objects[21], {
    CornerRadius = UDim.new(0, 4),
})


-- ChargePanel
Objects[23] = Make("Frame", "ChargePanel", Objects[1], {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -60), Size = UDim2.new(0, 280, 0, 76),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.0823529437, 0.145098045, 0.149019614), BackgroundTransparency = 0.15000000596046448,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[24] = Make("UICorner", "Corner", Objects[23], {
    CornerRadius = UDim.new(0, 8),
})


-- ChargeLabel
Objects[25] = Make("TextLabel", "ChargeLabel", Objects[23], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(0, 248, 0, 22),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "HOLD CLICK TO DRAW",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 11,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Track
Objects[26] = Make("Frame", "Track", Objects[23], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 16, 0, 37), Size = UDim2.new(0, 248, 0, 5),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.227450982, 0.301960796, 0.290196091), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[27] = Make("UICorner", "Corner", Objects[26], {
    CornerRadius = UDim.new(0, 3),
})


-- Fill
Objects[28] = Make("Frame", "Fill", Objects[26], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[29] = Make("UICorner", "Corner", Objects[28], {
    CornerRadius = UDim.new(0, 3),
})


-- Hint
Objects[30] = Make("TextLabel", "Hint", Objects[23], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 12, 0, 47), Size = UDim2.new(0, 256, 0, 20),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "Release to shoot  ·  Q to cancel",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 9,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Notice
Objects[31] = Make("TextLabel", "Notice", Objects[1], {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.280000001, 0), Size = UDim2.new(0.800000012, 0, 0, 55),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "Equip your bow to begin",
    TextColor3 = Color3.new(0.960784316, 0.921568632, 0.827450991), TextTransparency = 0, TextSize = 15,
    TextScaled = false, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.5,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- LandingMarker
Objects[32] = Make("BillboardGui", "LandingMarker", Objects[1], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 28, 0, 28),
    StudsOffset = Vector3.new(0, 0, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = false, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Ring
Objects[33] = Make("Frame", "Ring", Objects[32], {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.800000012, 0, 0.800000012, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[34] = Make("UICorner", "Corner", Objects[33], {
    CornerRadius = UDim.new(0, 100),
})


-- Outline
Objects[35] = Make("UIStroke", "Outline", Objects[33], {
    Color = Color3.new(0.545098066, 0.886274517, 0.760784328), Thickness = 2, Transparency = 0,
    Enabled = true, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round,
})


-- Center
Objects[36] = Make("Frame", "Center", Objects[33], {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 4, 0, 4),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY,
})


-- Corner
Objects[37] = Make("UICorner", "Corner", Objects[36], {
    CornerRadius = UDim.new(0, 4),
})


-- DrawButton
Objects[38] = Make("TextButton", "DrawButton", Objects[1], {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -40, 1, -150), Size = UDim2.new(0, 96, 0, 64),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), BackgroundTransparency = 0,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 0, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = true,
    Selectable = true, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "DRAW",
    TextColor3 = Color3.new(0.0823529437, 0.145098045, 0.149019614), TextTransparency = 0, TextSize = 18,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1, AutoButtonColor = true,
    Modal = false, Selected = false, Style = Enum.ButtonStyle.Custom,
})


-- Corner
Objects[39] = Make("UICorner", "Corner", Objects[38], {
    CornerRadius = UDim.new(0, 12),
})


-- PointPopups
Objects[40] = Make("Folder", "PointPopups", Objects[1], {
})


-- Points1
Objects[41] = Make("BillboardGui", "Points1", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[42] = Make("TextLabel", "Score", Objects[41], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points2
Objects[43] = Make("BillboardGui", "Points2", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[44] = Make("TextLabel", "Score", Objects[43], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points3
Objects[45] = Make("BillboardGui", "Points3", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[46] = Make("TextLabel", "Score", Objects[45], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points4
Objects[47] = Make("BillboardGui", "Points4", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[48] = Make("TextLabel", "Score", Objects[47], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points5
Objects[49] = Make("BillboardGui", "Points5", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[50] = Make("TextLabel", "Score", Objects[49], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points6
Objects[51] = Make("BillboardGui", "Points6", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[52] = Make("TextLabel", "Score", Objects[51], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points7
Objects[53] = Make("BillboardGui", "Points7", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[54] = Make("TextLabel", "Score", Objects[53], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})


-- Points8
Objects[55] = Make("BillboardGui", "Points8", Objects[40], {
    Enabled = false, ResetOnSpawn = true, Size = UDim2.new(0, 130, 0, 65),
    StudsOffset = Vector3.new(0, 1, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
    ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = true, LightInfluence = 0,
    Brightness = 1, MaxDistance = math.huge, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    ClipsDescendants = false,
})


-- Score
Objects[56] = Make("TextLabel", "Score", Objects[55], {
    AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.new(0.639215708, 0.635294139, 0.647058845), BackgroundTransparency = 1,
    BorderColor3 = Color3.new(0.105882354, 0.164705887, 0.20784314), BorderSizePixel = 1, BorderMode = Enum.BorderMode.Outline,
    Visible = true, ZIndex = 1, LayoutOrder = 0,
    Rotation = 0, ClipsDescendants = false, Active = false,
    Selectable = false, SizeConstraint = Enum.SizeConstraint.RelativeXY, Text = "+10",
    TextColor3 = Color3.new(0.545098066, 0.886274517, 0.760784328), TextTransparency = 0, TextSize = 28,
    TextScaled = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4000000059604645,
    RichText = false, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal), LineHeight = 1,
    TextTruncate = Enum.TextTruncate.None, MaxVisibleGraphemes = -1,
})

Objects[1].Parent = game:GetService("StarterGui")
return Objects[1]
