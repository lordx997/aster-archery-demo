-- Aster Archery presentation and input. Scoring and projectile simulation remain on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Player = Players.LocalPlayer
local Package = ReplicatedStorage:WaitForChild("AsterArchery")
local Remote = Package:WaitForChild("Action")
local Assets = Package:WaitForChild("Assets")
local Config = Package:WaitForChild("Config")
local ChargeTime = Config:GetAttribute("ChargeTime")
local MinSpeed = Config:GetAttribute("MinSpeed")
local MaxSpeed = Config:GetAttribute("MaxSpeed")
local Gravity = Vector3.new(0, -Config:GetAttribute("ArrowGravity"), 0)
local BowScale = 0.8
local MuzzleRestOffset = Config:GetAttribute("MuzzleRestOffset") or Vector3.new(0.8, -0.45, -3.84)
local MuzzleDrawOffset = Config:GetAttribute("MuzzleDrawOffset") or Vector3.new(-0.18, 0, 0.72)
local Camera = workspace.CurrentCamera
local Equipped = false
local Drawing = false
local DrawStarted = 0
local LastRelease = -math.huge
local ViewBow, ViewArrow, CurrentTool
local ToolConnections = {}
local ToolParts = {}
local ToolBeams = {}
local SavedCameraMode, SavedMouseIcon, SavedFov
local NoticeGeneration = 0
local Recoil = 0
local PreviewAccumulator = 0
local PreviewDistance = nil
local State = { score = 0, shots = 0, hits = 0, best = 0, streak = 0, mode = "Practice", endsAt = 0 }
local Cream = Color3.fromRGB(245, 235, 211)
local Mint = Color3.fromRGB(139, 226, 194)
local Dark = Color3.fromRGB(21, 37, 38)

local function Make(Class, Name, Parent, Properties)
    local Instance = Instance.new(Class)
    Instance.Name = Name
    for Key, Value in Properties do
        Instance[Key] = Value
    end
    Instance.Parent = Parent
    return Instance
end

local function Round(Object, Pixels)
    Make("UICorner", "Corner", Object, { CornerRadius = UDim.new(0, Pixels) })
end

-- Allocate the guide once. Its local geometry is excluded from both aiming and collision queries.
local Preview = Make("Folder", "ArcheryAimPreview", workspace, {})
local function PreviewPart(Name)
    return Make("Part", Name, Preview, {
        Size = Vector3.one * 0.1, Transparency = 1, Anchored = true,
        CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
    })
end
local PreviewStart = PreviewPart("CurveStart")
local PreviewEnd = PreviewPart("CurveEnd")
local StartAttachment = Make("Attachment", "Tangent", PreviewStart, {})
local EndAttachment = Make("Attachment", "Tangent", PreviewEnd, {})
local PathBeam = Make("Beam", "PredictedArc", PreviewStart, {
    Attachment0 = StartAttachment, Attachment1 = EndAttachment,
    Width0 = 0.025, Width1 = 0.065, FaceCamera = true, Segments = 40,
    Color = ColorSequence.new(Mint), Transparency = NumberSequence.new(0.15, 0.45),
    LightEmission = 0.8, LightInfluence = 0, Enabled = false,
})
local LandingPoint = PreviewPart("LandingPoint")
local LandingGui = Make("BillboardGui", "LandingMarker", LandingPoint, {
    Size = UDim2.fromOffset(28, 28), AlwaysOnTop = false, Enabled = false,
})
local LandingRing = Make("Frame", "Ring", LandingGui, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 1,
})
Round(LandingRing, 100)
local RingStroke = Make("UIStroke", "Outline", LandingRing, { Color = Mint, Thickness = 2 })
local LandingDot = Make("Frame", "Center", LandingRing, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Mint, BorderSizePixel = 0,
})
Round(LandingDot, 4)
local PathDots = {}
for Index = 1, 16 do
    local Dot = PreviewPart("PathDot" .. Index)
    Dot.Shape = Enum.PartType.Ball
    Dot.Size = Vector3.one * 0.10
    Dot.Material = Enum.Material.Neon
    Dot.Color = Mint
    table.insert(PathDots, Dot)
end

local function HidePreview()
    PathBeam.Enabled = false
    LandingGui.Enabled = false
    PreviewDistance = nil
    for _, Dot in PathDots do
        Dot.Transparency = 1
    end
end

local function GetAim(Power)
    local Character = Player.Character
    local Head = Character and Character:FindFirstChild("Head")
    if not Head then
        return nil
    end
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { Character, Camera, Preview, workspace:FindFirstChild("ArcheryProjectiles") }
    Params.IgnoreWater = true
    local Ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local Hit = workspace:Raycast(Ray.Origin, Ray.Direction * 500, Params)
    local AimPoint = Hit and Hit.Position or Ray.Origin + Ray.Direction * 500
    local Offset = AimPoint - Head.Position
    if Offset.Magnitude < 0.1 then
        return nil
    end
    local Direction = Offset.Unit
    local MuzzleOffset = MuzzleRestOffset + MuzzleDrawOffset * Power
    local Origin = Head.Position
    -- Reconcile the offset bow tip with the center-camera aim point; the server derives the same origin.
    for _ = 1, 4 do
        Origin = CFrame.lookAt(Head.Position, Head.Position + Direction):PointToWorldSpace(MuzzleOffset)
        local AimOffset = AimPoint - Origin
        if AimOffset.Magnitude < 0.1 or AimOffset:Dot(Direction) <= 0 then
            return nil
        end
        Direction = AimOffset.Unit
    end
    Origin = CFrame.lookAt(Head.Position, Head.Position + Direction):PointToWorldSpace(MuzzleOffset)
    if workspace:Raycast(Head.Position, Origin - Head.Position, Params) then
        return nil
    end
    return Origin, Direction, Params
end

local function UpdatePreview(Power)
    local Origin, Direction, Params = GetAim(Power)
    if not Origin then
        HidePreview()
        return
    end
    local Velocity = Direction * (MinSpeed + (MaxSpeed - MinSpeed) * Power)
    local Position = Origin
    local CurrentVelocity = Velocity
    local Elapsed = 0
    local Distance = 0
    local Impact = nil
    local Step = 1 / 120
    -- Use the server's swept-sphere step. Stop at the first surface; moving targets may move before arrival.
    for _ = 1, 600 do
        local Displacement = CurrentVelocity * Step + Gravity * (0.5 * Step * Step)
        Impact = workspace:Spherecast(Position, 0.07, Displacement, Params)
        if Impact then
            Elapsed += Step * math.clamp(Impact.Distance / Displacement.Magnitude, 0, 1)
            Distance += Impact.Distance
            break
        end
        Position += Displacement
        CurrentVelocity += Gravity * Step
        Elapsed += Step
        Distance += Displacement.Magnitude
        if Distance >= 500 then
            break
        end
    end
    local Endpoint = Origin + Velocity * Elapsed + Gravity * (0.5 * Elapsed * Elapsed)
    local EndVelocity = Velocity + Gravity * Elapsed
    -- A quadratic ballistic arc is represented exactly by these cubic Bezier tangent lengths.
    PreviewStart.CFrame = CFrame.lookAt(Origin, Origin + Velocity) * CFrame.Angles(0, math.pi / 2, 0)
    PreviewEnd.CFrame = CFrame.lookAt(Endpoint, Endpoint + EndVelocity) * CFrame.Angles(0, math.pi / 2, 0)
    PathBeam.CurveSize0 = Velocity.Magnitude * Elapsed / 3
    PathBeam.CurveSize1 = EndVelocity.Magnitude * Elapsed / 3
    PathBeam.Enabled = true
    PreviewDistance = math.floor(Distance)
    local Color = Impact and Impact.Instance:GetAttribute("Radius") and Mint or Cream
    PathBeam.Color = ColorSequence.new(Mint, Color)
    for Index, Dot in PathDots do
        local Time = Elapsed * Index / (#PathDots + 1)
        Dot.Position = Origin + Velocity * Time + Gravity * (0.5 * Time * Time)
        Dot.Transparency = 0.15 + Index / #PathDots * 0.35
        Dot.Color = Color
    end
    LandingGui.Enabled = Impact ~= nil
    if Impact then
        LandingPoint.Position = Impact.Position + Impact.Normal * 0.09
        RingStroke.Color = Color
        LandingDot.BackgroundColor3 = Color
    end
    -- Inspectable local attributes make prediction-versus-impact checks possible without test remotes.
    Preview:SetAttribute("PredictedPosition", Impact and Impact.Position or Endpoint)
    Preview:SetAttribute("Power", Power)
end

local function Text(Parent, Name, Content, Size, Position, Dimensions, Color)
    return Make("TextLabel", Name, Parent, {
        Text = Content, Font = Enum.Font.GothamMedium, TextSize = Size,
        Position = Position, Size = Dimensions, TextColor3 = Color or Cream,
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
    })
end

local Gui = Make("ScreenGui", "AsterHUD", Player:WaitForChild("PlayerGui"), {
    ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20,
})
local Panel = Make("Frame", "ScorePanel", Gui, {
    Position = UDim2.fromOffset(24, 70), Size = UDim2.fromOffset(322, 186),
    BackgroundColor3 = Dark, BackgroundTransparency = 0.07, BorderSizePixel = 0,
})
Round(Panel, 10)
local PanelScale = Make("UIScale", "Responsive", Panel, { Scale = 1 })
Text(Panel, "Brand", "ASTER  /  ARCHERY CLUB", 14, UDim2.fromOffset(20, 15), UDim2.fromOffset(282, 24), Mint)
local ModeLabel = Text(Panel, "Mode", "FREE PRACTICE", 10, UDim2.fromOffset(20, 45), UDim2.fromOffset(170, 18))
local TimerLabel = Text(Panel, "Time", "NO TIMER", 11, UDim2.fromOffset(202, 45), UDim2.fromOffset(100, 18), Mint)
TimerLabel.TextXAlignment = Enum.TextXAlignment.Right
local ScoreLabel = Text(Panel, "Score", "000", 42, UDim2.fromOffset(20, 65), UDim2.fromOffset(130, 54))
Text(Panel, "ScoreCaption", "POINTS", 9, UDim2.fromOffset(22, 119), UDim2.fromOffset(130, 18), Mint)
local AccuracyLabel = Text(Panel, "Accuracy", "—", 23, UDim2.fromOffset(174, 80), UDim2.fromOffset(100, 30))
Text(Panel, "AccuracyCaption", "ACCURACY", 9, UDim2.fromOffset(174, 112), UDim2.fromOffset(110, 18), Mint)
local SmallStats = Text(Panel, "Stats", "0 SHOTS   /   0 STREAK   /   BEST 0", 10, UDim2.fromOffset(20, 153), UDim2.fromOffset(284, 20))
local Challenge = Make("TextButton", "Challenge", Gui, {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 72), Size = UDim2.fromOffset(190, 42),
    BackgroundColor3 = Mint, TextColor3 = Dark, Text = "NEW CHALLENGE  [R]", TextSize = 12,
    Font = Enum.Font.GothamBold, BorderSizePixel = 0, AutoButtonColor = true,
})
Round(Challenge, 7)
local ChallengeScale = Make("UIScale", "Responsive", Challenge, { Scale = 1 })
local Reticle = Make("Frame", "Reticle", Gui, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false,
})
local CrossParts = {}
for Index, Info in {
    { 19, 0, 2, 10 }, { 19, 30, 2, 10 }, { 0, 19, 10, 2 }, { 30, 19, 10, 2 },
} do
    CrossParts[Index] = Make("Frame", "Tick" .. Index, Reticle, {
        Position = UDim2.fromOffset(Info[1], Info[2]), Size = UDim2.fromOffset(Info[3], Info[4]),
        BackgroundColor3 = Cream, BorderSizePixel = 0,
    })
end
local Dot = Make("Frame", "Center", Reticle, { Position = UDim2.fromOffset(18, 18),
    Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Mint, BorderSizePixel = 0 })
Round(Dot, 4)
local ChargePanel = Make("Frame", "ChargePanel", Gui, {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -60),
    Size = UDim2.fromOffset(280, 76), BackgroundColor3 = Dark, BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
})
Round(ChargePanel, 8)
local ChargeLabel = Text(ChargePanel, "ChargeLabel", "HOLD CLICK TO DRAW", 11, UDim2.fromOffset(16, 8), UDim2.fromOffset(248, 22))
ChargeLabel.TextXAlignment = Enum.TextXAlignment.Center
local Track = Make("Frame", "Track", ChargePanel, { Position = UDim2.fromOffset(16, 37),
    Size = UDim2.fromOffset(248, 5), BackgroundColor3 = Color3.fromRGB(58, 77, 74), BorderSizePixel = 0 })
Round(Track, 3)
local Fill = Make("Frame", "Fill", Track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Mint, BorderSizePixel = 0 })
Round(Fill, 3)
local Hint = Text(ChargePanel, "Hint", "Release to shoot  ·  Q to cancel", 9, UDim2.fromOffset(12, 47), UDim2.fromOffset(256, 20))
Hint.TextXAlignment = Enum.TextXAlignment.Center
local Notice = Text(Gui, "Notice", "Equip your bow to begin", 15, UDim2.new(0.5, 0, 0.28, 0), UDim2.new(0.8, 0, 0, 55))
Notice.AnchorPoint = Vector2.new(0.5, 0)
Notice.TextXAlignment = Enum.TextXAlignment.Center
Notice.TextWrapped = true
Notice.TextStrokeTransparency = 0.5

local function Notify(Message, Color)
    NoticeGeneration += 1
    local Generation = NoticeGeneration
    Notice.Text = Message
    Notice.TextColor3 = Color or Cream
    task.delay(3.5, function()
        if Generation == NoticeGeneration then
            Notice.Text = ""
        end
    end)
end

local function Cancel()
    if Drawing then
        Remote:FireServer("Cancel")
    end
    Drawing = false
    HidePreview()
end

local function Begin()
    if not Equipped or Drawing or UserInputService:GetFocusedTextBox() or os.clock() - LastRelease < 0.4 then
        return
    end
    if State.mode == "Complete" then
        Notify("Start a new challenge to keep shooting")
        return
    end
    Drawing = true
    DrawStarted = workspace:GetServerTimeNow()
    Remote:FireServer("Begin")
end

local function Release()
    if not Drawing then
        return
    end
    Drawing = false
    HidePreview()
    LastRelease = os.clock()
    local Power = math.clamp((workspace:GetServerTimeNow() - DrawStarted) / ChargeTime, 0, 1)
    local _, Direction = GetAim(Power)
    if Direction then
        Remote:FireServer("Release", Direction)
    else
        Remote:FireServer("Cancel")
    end
end

local function StartChallenge()
    Cancel()
    Remote:FireServer("Challenge")
end
Challenge.Activated:Connect(StartChallenge)
UserInputService.InputBegan:Connect(function(Input, Processed)
    if Processed then
        return
    end
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Begin()
    elseif Input.KeyCode == Enum.KeyCode.R or Input.KeyCode == Enum.KeyCode.ButtonY then
        StartChallenge()
    elseif Input.KeyCode == Enum.KeyCode.Q or Input.KeyCode == Enum.KeyCode.ButtonB then
        Cancel()
    end
end)
UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Release()
    end
end)
UserInputService.WindowFocusReleased:Connect(Cancel)
ContextActionService:BindAction("AsterDraw", function(_, InputState)
    if not Equipped then
        return Enum.ContextActionResult.Pass
    end
    if InputState == Enum.UserInputState.Begin then
        Begin()
    elseif InputState == Enum.UserInputState.End then
        Release()
    elseif InputState == Enum.UserInputState.Cancel then
        Cancel()
    end
    return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("AsterDraw", "DRAW")
ContextActionService:SetPosition("AsterDraw", UDim2.new(1, -140, 1, -210))

local function Unequip()
    Cancel()
    Equipped = false
    Reticle.Visible = false
    for Beam, Enabled in ToolBeams do
        if Beam.Parent then
            Beam.Enabled = Enabled
        end
    end
    table.clear(ToolBeams)
    if ViewBow then
        ViewBow:Destroy()
        ViewBow = nil
    end
    if ViewArrow then
        ViewArrow:Destroy()
        ViewArrow = nil
    end
    if SavedCameraMode then
        Player.CameraMode = SavedCameraMode
        UserInputService.MouseIconEnabled = SavedMouseIcon
        Camera.FieldOfView = SavedFov
        SavedCameraMode = nil
    end
    local Button = ContextActionService:GetButton("AsterDraw")
    if Button then
        Button.Visible = false
    end
end

local function Equip(Tool)
    if Equipped then
        return
    end
    CurrentTool = Tool
    table.clear(ToolParts)
    for _, Object in Tool:GetDescendants() do
        if Object:IsA("BasePart") then
            table.insert(ToolParts, Object)
        elseif Object:IsA("Beam") then
            ToolBeams[Object] = Object.Enabled
            Object.Enabled = false
        end
    end
    Equipped = true
    SavedCameraMode = Player.CameraMode
    SavedMouseIcon = UserInputService.MouseIconEnabled
    SavedFov = Camera.FieldOfView
    Player.CameraMode = Enum.CameraMode.LockFirstPerson
    UserInputService.MouseIconEnabled = false
    ViewBow = Assets.BowView:Clone()
    ViewBow:ScaleTo(BowScale)
    ViewBow.Parent = Camera
    ViewArrow = Assets.Arrow:Clone()
    ViewArrow:ScaleTo(BowScale)
    ViewArrow.Parent = Camera
    Reticle.Visible = true
    local Button = ContextActionService:GetButton("AsterDraw")
    if Button then
        Button.Visible = true
    end
    Notify("Aim above the target to compensate for arrow drop", Mint)
    Remote:FireServer("Sync")
end

local function BindCharacter(Character)
    Unequip()
    for _, Connection in ToolConnections do
        Connection:Disconnect()
    end
    table.clear(ToolConnections)
    local Humanoid = Character:WaitForChild("Humanoid", 10)
    local Backpack = Player:WaitForChild("Backpack")
    local Tool = Character:FindFirstChild("Aster Bow") or Backpack:WaitForChild("Aster Bow", 10)
    if not Humanoid or not Tool or Player.Character ~= Character then
        return
    end
    table.insert(ToolConnections, Tool.Equipped:Connect(function()
        Equip(Tool)
    end))
    table.insert(ToolConnections, Tool.Unequipped:Connect(Unequip))
    table.insert(ToolConnections, Humanoid.Died:Connect(Unequip))
    Humanoid:EquipTool(Tool)
    if Tool.Parent == Character then
        Equip(Tool)
    end
end

Remote.OnClientEvent:Connect(function(Action, Payload)
    if Action == "State" then
        State = Payload
        ScoreLabel.Text = string.format("%03d", State.score)
        local Accuracy = State.shots > 0 and math.floor(State.hits / State.shots * 100) or nil
        AccuracyLabel.Text = Accuracy and (Accuracy .. "%") or "—"
        SmallStats.Text = string.format("%d SHOTS   /   %d STREAK   /   BEST %d", State.shots, State.streak, State.best)
        ModeLabel.Text = State.mode == "Practice" and "FREE PRACTICE" or string.upper(State.mode)
    elseif Action == "Draw" then
        if Drawing then
            DrawStarted = Payload
        end
    elseif Action == "Cancel" then
        Drawing = false
        HidePreview()
        Notify(Payload)
    elseif Action == "Shot" then
        Recoil = 1
    elseif Action == "Round" then
        Drawing = false
        HidePreview()
        Notify(Payload, Mint)
    elseif Action == "Impact" then
        Notify(string.format("%s  +%d  /  %d studs", Payload.label, Payload.points, Payload.distance), Payload.points > 0 and Mint or Cream)
        if Payload.points > 0 then
            local Anchor = Make("Part", "LocalImpact", Camera, { Size = Vector3.one * 0.1,
                Position = Payload.position, Anchored = true, CanCollide = false, CanTouch = false,
                CanQuery = false, Transparency = 1 })
            local Popup = Make("BillboardGui", "Points", Anchor, { Size = UDim2.fromOffset(130, 65),
                StudsOffset = Vector3.new(0, 1, 0), AlwaysOnTop = true })
            local Label = Text(Popup, "Score", "+" .. Payload.points, 28, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Mint)
            Label.TextXAlignment = Enum.TextXAlignment.Center
            Label.TextStrokeTransparency = 0.4
            TweenService:Create(Popup, TweenInfo.new(0.9), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
            TweenService:Create(Label, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
            Debris:AddItem(Anchor, 1)
        end
    end
end)

RunService:BindToRenderStep("AsterBowView", Enum.RenderPriority.Camera.Value + 1, function(DeltaTime)
    Camera = workspace.CurrentCamera
    local Scale = math.clamp(Camera.ViewportSize.X / 1000, 0.66, 1)
    PanelScale.Scale = Scale
    ChallengeScale.Scale = Scale
    local Remaining = math.max(0, State.endsAt - workspace:GetServerTimeNow())
    TimerLabel.Text = State.mode == "Practice" and "NO TIMER" or string.format("%02d:%02d", math.floor(Remaining / 60), math.floor(Remaining % 60))
    if not Equipped or not ViewBow then
        ChargeLabel.Text = "EQUIP YOUR BOW [1]"
        Fill.Size = UDim2.fromScale(0, 1)
        return
    end
    local Power = Drawing and math.clamp((workspace:GetServerTimeNow() - DrawStarted) / ChargeTime, 0, 1) or 0
    Fill.Size = UDim2.fromScale(Power, 1)
    ChargeLabel.Text = Drawing and string.format("DRAW POWER  %d%%", math.floor(Power * 100))
        or (UserInputService.TouchEnabled and "HOLD DRAW TO CHARGE" or "HOLD CLICK / RT TO DRAW")
    Hint.Text = UserInputService.TouchEnabled and "Release DRAW to shoot  ·  Aim with camera" or "Release to shoot  ·  Q / B to cancel"
    Recoil = math.max(0, Recoil - DeltaTime * 5)
    local DesiredFov = SavedFov - Power * 6 + Recoil * 2
    Camera.FieldOfView += (DesiredFov - Camera.FieldOfView) * (1 - math.exp(-DeltaTime * 12))
    local Sway = math.sin(os.clock() * 1.7) * 0.012
    -- No roll or draw-dependent rotation: the grip stays vertical and the arrow stays on its rest.
    local Frame = Camera.CFrame * CFrame.new(MuzzleRestOffset.X + MuzzleDrawOffset.X * Power,
        MuzzleRestOffset.Y + Sway, MuzzleRestOffset.Z + 2.05 * BowScale + Recoil * 0.12)
    -- Reverse the bow horizontally; its string now faces the archer while the arrow still faces forward.
    ViewBow:PivotTo(Frame * CFrame.Angles(0, math.pi, 0))
    local NockPosition = Vector3.new(0, 0, (-0.65 - Power * 0.9) * BowScale)
    ViewBow.Handle.Nock.Position = NockPosition
    local ArrowPosition = ViewBow.Handle.Nock.WorldPosition - Frame.ZVector * (2.7 * BowScale)
    ViewArrow:PivotTo(CFrame.new(ArrowPosition) * Frame.Rotation)
    PreviewAccumulator += DeltaTime
    if Drawing and PreviewAccumulator >= 1 / 20 then
        PreviewAccumulator = 0
        UpdatePreview(Power)
    elseif not Drawing then
        HidePreview()
    end
    if Drawing and PreviewDistance then
        Hint.Text = string.format("TRAJECTORY  %d STUDS  ·  Release to shoot", PreviewDistance)
    end
    -- Hide only this client's held mesh; other players still see the physical welded bow.
    for _, Object in ToolParts do
        Object.LocalTransparencyModifier = 1
    end
    for _, Tick in CrossParts do
        Tick.BackgroundColor3 = Power >= 1 and Mint or Cream
    end
end)

Player.CharacterAdded:Connect(function(Character)
    task.spawn(BindCharacter, Character)
end)
if Player.Character then
    task.spawn(BindCharacter, Player.Character)
end
Remote:FireServer("Sync")
