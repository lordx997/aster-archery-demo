-- Discord: lordx997 | Roblox: TheRealRacion
-- The server checks shots, moves arrows, and keeps score.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Shared settings and models.
local Package = ReplicatedStorage:WaitForChild("AsterArchery")
local Remote = Package:WaitForChild("Action")
local Assets = Package:WaitForChild("Assets")
local Arena = Workspace:WaitForChild("AsterArchery")
local TargetsFolder = Arena:WaitForChild("Targets")
local Spawn = Arena:WaitForChild("RangeSpawn")
local Config = Package:WaitForChild("Config")
local ChargeTime = Config:GetAttribute("ChargeTime")
local MinSpeed = Config:GetAttribute("MinSpeed")
local MaxSpeed = Config:GetAttribute("MaxSpeed")
local Gravity = Vector3.new(0, -Config:GetAttribute("ArrowGravity"), 0)
local RoundSeconds = Config:GetAttribute("RoundSeconds")
local MuzzleRestOffset = Config:GetAttribute("MuzzleRestOffset") or Vector3.new(0.8, -0.45, -3.84)
local MuzzleDrawOffset = Config:GetAttribute("MuzzleDrawOffset") or Vector3.new(-0.18, 0, 0.72)
local Cooldown = 0.38
local SimulationStep = 1 / 120
local PoolSize = 64
local MaxEmbeddedPerPlayer = 12
local MaxEmbeddedTotal = 48
local Sessions = {}
local ActiveArrows = {}
local FreeModels = {}
local TargetData = {}
local HeartbeatAccumulator = 0
local StateAccumulator = 0

-- Keep arrows together so collision checks can ignore them.
local Projectiles = Instance.new("Folder")
Projectiles.Name = "ArcheryProjectiles"
Projectiles.Parent = Workspace

-- Reject invalid numbers before using them in movement calculations.
local function Finite(Number)
    return Number == Number and math.abs(Number) < 1e6
end

-- Check that the aim is a valid direction.
local function ValidDirection(Value)
    if typeof(Value) ~= "Vector3" then
        return false
    end
    return Finite(Value.X) and Finite(Value.Y) and Finite(Value.Z)
        and Value.Magnitude > 0.5 and Value.Magnitude < 1.5
end

local function GetArcher(Player)
    -- Get the current character because respawning replaces the old one.
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Head = Character and Character:FindFirstChild("Head")
    local Tool = Character and Character:FindFirstChild("Aster Bow")
    if not Humanoid or Humanoid.Health <= 0 or not Head or not Tool or not Tool:IsA("Tool") then
        return nil
    end
    -- Only allow shots near the archery range.
    if (Head.Position - Spawn.Position).Magnitude > 260 then
        return nil
    end
    return Head, Character
end

local function SendState(Player, Session)
    -- Send this player's score and round status to their HUD.
    Remote:FireClient(Player, "State", {
        Score = Session.Score,
        Shots = Session.Shots,
        Hits = Session.Hits,
        Best = Session.Best,
        Streak = Session.Streak,
        Mode = Session.Mode,
        EndsAt = Session.EndsAt,
        DrawAt = Session.DrawAt,
    })
end

local function CancelDraw(Player, Session, Reason)
    -- Clear the draw time so a cancelled shot cannot fire later.
    Session.DrawAt = nil
    Remote:FireClient(Player, "Cancel", Reason)
end

-- Limit requests so one player cannot overload the server.
local function ConsumeToken(Session, Time)
    -- Restore request allowance based on time, not frame rate.
    Session.Tokens = math.min(12, Session.Tokens + (Time - Session.TokenAt) * 8)
    Session.TokenAt = Time
    if Session.Tokens < 1 then
        return false
    end
    Session.Tokens -= 1
    return true
end

-- Reuse arrow models to avoid creating parts for every shot.
for Index = 1, PoolSize do
    local Model = Assets.Arrow:Clone()
    Model.Name = "PooledArrow"
    Model:PivotTo(CFrame.new(0, -1000, 0))
    Model.Parent = Projectiles
    table.insert(FreeModels, Model)
    -- Pause briefly while preparing the arrow pool to keep Studio responsive.
    if Index % 32 == 0 then
        task.wait()
    end
end

for _, Model in TargetsFolder:GetChildren() do
    local Face = Model:FindFirstChild("Hitbox")
    if Face and Face:IsA("BasePart") then
        TargetData[Face] = {
            Model = Model,
            Base = Model:GetPivot(), -- Save the starting position so target movement does not drift.
            Radius = Face:GetAttribute("Radius"),
            Amplitude = Model:GetAttribute("Amplitude") or 0,
            Frequency = Model:GetAttribute("Frequency") or 1,
            Phase = Model:GetAttribute("Phase") or 0,
        }
    end
end

-- Measure hits relative to the target, even when it moves or rotates.
local function RingScore(Result)
    -- Only the server's known target faces can award points.
    local Target = TargetData[Result.Instance]
    if not Target then
        return 0, "MISS"
    end
    local Point = Result.Instance.CFrame:PointToObjectSpace(Result.Position)
    local NormalizedRadius = Vector2.new(Point.X, Point.Y).Magnitude / Target.Radius
    -- Ignore hits outside the circle or on the back of the target.
    if NormalizedRadius > 1 or Result.Normal:Dot(Result.Instance.CFrame.ZVector) < 0.6 then
        return 0, "OFF TARGET"
    end
    if NormalizedRadius <= 0.18 then
        return 10, "BULLSEYE"
    elseif NormalizedRadius <= 0.38 then
        return 8, "INNER RING"
    elseif NormalizedRadius <= 0.60 then
        return 6, "MIDDLE RING"
    elseif NormalizedRadius <= 0.80 then
        return 4, "OUTER RING"
    end
    return 2, "EDGE"
end

local Arrow = {}

Arrow.__index = Arrow

local function TrimEmbedded(Player)
    local Owned, Total = {}, {}
    for _, Arrow in ActiveArrows do
        if Arrow.StuckAt and not Arrow.Released then
            table.insert(Total, Arrow)
            if Arrow.Player == Player then
                table.insert(Owned, Arrow)
            end
        end
    end
    local function OldestFirst(A, B)
        return A.StuckAt < B.StuckAt
    end
    table.sort(Owned, OldestFirst)
    table.sort(Total, OldestFirst)
    -- Keep the latest twelve landed arrows for each player.
    for Index = 1, math.max(0, #Owned - MaxEmbeddedPerPlayer) do
        Owned[Index]:Release()
    end
    local Count = 0
    for _, Arrow in Total do
        if not Arrow.Released then
            Count += 1
        end
    end
    for _, Arrow in Total do
        if Count <= MaxEmbeddedTotal then
            break
        end
        if not Arrow.Released then
            Arrow:Release()
            Count -= 1
        end
    end
end

function Arrow.new(Player, Session, Origin, Velocity, Params)
    local Model = table.remove(FreeModels)
    if not Model then
        return nil
    end
    local Self = setmetatable({}, Arrow)
    Self.Model = Model
    Self.Player = Player
    Self.SessionId = Session.Id
    Self.Pos = Origin
    Self.Vel = Velocity
    Self.Params = Params
    Self.Age = 0
    Self.Dist = 0
    Self.StuckPart = nil
    Self.StuckAt = nil
    Self.Released = false
    Model:PivotTo(CFrame.lookAt(Origin, Origin + Velocity)) -- The arrow model points along its local -Z axis.
    -- Clear the old trail so a reused arrow does not leave a long streak.
    Model.Shaft.FlightTrail:Clear()
    Model.Shaft.FlightTrail.Enabled = true
    Model:SetAttribute("FlightState", "Flying")
    Model:SetAttribute("ArcherUserId", Player.UserId)
    Model:SetAttribute("ImpactPosition", nil)
    return Self
end

function Arrow.Release(Self)
    -- Return each arrow to the pool only once.
    if Self.Released then
        return
    end
    Self.Released = true
    Self.Model.Shaft.FlightTrail.Enabled = false
    Self.Model:SetAttribute("FlightState", "Pooled")
    Self.Model:SetAttribute("ImpactPosition", nil)
    Self.Model:PivotTo(CFrame.new(0, -1000, 0))
    table.insert(FreeModels, Self.Model)
end

function Arrow.Resolve(Self, Result)
    local Session = Sessions[Self.Player]
    if not Session or Session.Id ~= Self.SessionId then
        return
    end
    -- Ignore arrows from an earlier round.
    local Time = Workspace:GetServerTimeNow()
    if Session.Mode == "Complete" or (Session.Mode == "Challenge" and Time >= Session.EndsAt) then
        return
    end
    local Points, Label = 0, "MISS"
    if Result then
        Points, Label = RingScore(Result)
    end
    if Points > 0 then
        Session.Hits += 1
        Session.Streak += 1
        Session.Score += Points
    else
        -- A miss ends the streak but keeps the points already earned.
        Session.Streak = 0
    end
    Remote:FireClient(Self.Player, "Impact", {
        Points = Points,
        Label = Label,
        Pos = Result and Result.Position or Self.Pos,
        Dist = math.floor(Self.Dist),
    })
    SendState(Self.Player, Session)
end

function Arrow.Stick(Self, Result, Time)
    Self:Resolve(Result)
    Self.Model.Shaft.FlightTrail.Enabled = false
    local Direction = Self.Vel.Unit
    -- Move the tip slightly into the surface so the arrow looks stuck.
    local Frame = CFrame.lookAt(Result.Position + Direction * 0.12, Result.Position + Direction)
    Self.Model:PivotTo(Frame)
    Self.StuckPart = Result.Instance
    -- Save the hit position relative to the part so the arrow follows it.
    if Result.Instance:IsA("BasePart") and not Result.Instance:IsA("Terrain") then
        Self.StuckOffset = Result.Instance.CFrame:ToObjectSpace(Frame)
    end
    Self.StuckFrame = Frame
    Self.StuckAt = Time
    Self.Model:SetAttribute("FlightState", "Embedded")
    Self.Model:SetAttribute("ImpactPosition", Result.Position)
    TrimEmbedded(Self.Player)
end

function Arrow.FollowSurface(Self)
    if not Self.StuckPart:IsDescendantOf(Workspace) then
        Self:Release()
        return
    end
    local Frame = Self.StuckOffset and Self.StuckPart.CFrame * Self.StuckOffset or Self.StuckFrame
    -- Only reposition the arrow when the surface moves.
    if Frame ~= Self.StuckFrame then
        Self.Model:PivotTo(Frame)
        Self.StuckFrame = Frame
    end
end

function Arrow.Step(Self, DeltaTime, Time)
    Self.Age += DeltaTime
    -- Apply gravity in small steps to follow the arrow's curved path.
    local Displacement = Self.Vel * DeltaTime + Gravity * (0.5 * DeltaTime * DeltaTime)
    local Result = Workspace:Spherecast(Self.Pos, 0.07, Displacement, Self.Params)
    -- Check the whole step so fast arrows do not skip thin targets.
    Self.Dist += Result and Result.Distance or Displacement.Magnitude
    if Result then
        -- Use the velocity at impact to set the arrow's angle.
        local Fraction = math.clamp(Result.Distance / Displacement.Magnitude, 0, 1)
        Self.Vel += Gravity * (DeltaTime * Fraction)
        Self:Stick(Result, Time)
        return
    end
    Self.Pos += Displacement
    Self.Vel += Gravity * DeltaTime
    Self.Model:PivotTo(CFrame.lookAt(Self.Pos, Self.Pos + Self.Vel))
    if Self.Age >= 5 or Self.Dist >= 500 or Self.Pos.Y < Spawn.Position.Y - 50 then
        -- Recycle arrows that fly too long, too far, or below the range.
        Self:Resolve(nil)
        Self:Release()
    end
end

local function BeginChallenge(Player, Session, Time)
    if Time - Session.LastRestart < 2 then
        return
    end
    Session.LastRestart = Time
    for _, Arrow in ActiveArrows do
        if Arrow.Player == Player then
            Arrow:Release()
        end
    end
    Session.Id += 1
    Session.DrawAt = nil
    Session.Score = 0
    Session.Hits = 0
    Session.Shots = 0
    Session.Streak = 0
    Session.Mode = "Challenge"
    Session.EndsAt = Time + RoundSeconds
    Remote:FireClient(Player, "Round", string.format("Challenge started — %d seconds. Every ring counts.", RoundSeconds))
    SendState(Player, Session)
end

local function FireArrow(Player, Session, Direction, Time)
    local Started = Session.DrawAt
    -- Clear the draw so the same release cannot fire twice.
    Session.DrawAt = nil
    if not Started or not ValidDirection(Direction) or Time - Session.LastShot < Cooldown then
        Remote:FireClient(Player, "Cancel", "Shot cancelled")
        return
    end
    local Head, Character = GetArcher(Player)
    if not Head or Time - Started < 0.08 then
        Remote:FireClient(Player, "Cancel", "Hold to draw the bow")
        return
    end
    Direction = Direction.Unit
    local Power = math.clamp((Time - Started) / ChargeTime, 0, 1)
    -- Limit charge to the bow's maximum speed.
    local Speed = MinSpeed + (MaxSpeed - MinSpeed) * Power
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { Character, Projectiles }
    Params.IgnoreWater = true
    local AimFrame = CFrame.lookAt(Head.Position, Head.Position + Direction)
    local Origin = AimFrame:PointToWorldSpace(MuzzleRestOffset + MuzzleDrawOffset * Power)
    -- The server chooses the arrow's start position and power.
    local Obstruction = Workspace:Raycast(Head.Position, Origin - Head.Position, Params)
    -- Block shots when a wall is between the player and the arrow tip.
    if Obstruction then
        Remote:FireClient(Player, "Cancel", "Step back from the obstacle")
        return
    end
    local Arrow = Arrow.new(Player, Session, Origin, Direction * Speed, Params)
    if not Arrow then
        Remote:FireClient(Player, "Cancel", "Range busy — try again")
        return
    end
    Session.LastShot = Time
    -- Only count shots that actually fire.
    Session.Shots += 1
    table.insert(ActiveArrows, Arrow)
    Remote:FireClient(Player, "Shot", { Power = Power, Speed = Speed })
    SendState(Player, Session)
end

Remote.OnServerEvent:Connect(function(Player, Action, Payload)
    -- Use the player Roblox supplies, not a name sent by the client.
    local Session = Sessions[Player]
    local Time = Workspace:GetServerTimeNow()
    if not Session or not ConsumeToken(Session, Time) then
        return
    end
    if Action == "Sync" then
        -- Send the current score when the HUD is ready.
        SendState(Player, Session)
        return
    elseif Action == "Cancel" then
        Session.DrawAt = nil
        return
    end
    if not GetArcher(Player) then
        CancelDraw(Player, Session, "Equip your bow at the range")
        return
    end
    if Action == "Challenge" then
        BeginChallenge(Player, Session, Time)
        return
    end
    if Session.Mode == "Complete" or (Session.Mode == "Challenge" and Time >= Session.EndsAt) then
        CancelDraw(Player, Session, "Press R or NEW CHALLENGE to play again")
        return
    end
    if Action == "Begin" then
        if not Session.DrawAt and Time - Session.LastShot >= Cooldown then
            Session.DrawAt = Time
            Remote:FireClient(Player, "Draw", Time)
        else
            Remote:FireClient(Player, "Cancel", "Bow recovering")
        end
    elseif Action == "Release" then
        FireArrow(Player, Session, Payload, Time)
    end
end)

local function PrepareCharacter(Player, Character)
    local Session = Sessions[Player]
    if not Session then
        return
    end
    Session.DrawAt = nil
    if Session.DeathConnection then
        Session.DeathConnection:Disconnect()
    end
    local Root = Character:WaitForChild("HumanoidRootPart", 10)
    local Humanoid = Character:WaitForChild("Humanoid", 10)
    if not Root or not Humanoid or Player.Character ~= Character or Sessions[Player] ~= Session then
        return
    end
    Character:PivotTo(Spawn.CFrame + Vector3.new(0, 4, 0))
    Session.DeathConnection = Humanoid.Died:Connect(function()
        CancelDraw(Player, Session, "Respawning at the range")
    end)
end

local function AddPlayer(Player)
    -- Scores last for this server session and are not saved between visits.
    local Session = {
        Id = 0, Score = 0, Shots = 0, Hits = 0, Best = 0, Streak = 0,
        Mode = "Practice", EndsAt = 0, DrawAt = nil,
        LastShot = -math.huge, LastRestart = -math.huge,
        Tokens = 12, TokenAt = Workspace:GetServerTimeNow(),
    }
    Sessions[Player] = Session
    Player.RespawnLocation = Spawn
    Session.CharacterConnection = Player.CharacterAdded:Connect(function(Character)
        PrepareCharacter(Player, Character)
    end)
    if Player.Character then
        task.spawn(PrepareCharacter, Player, Player.Character)
    end
end

Players.PlayerAdded:Connect(AddPlayer)
Players.PlayerRemoving:Connect(function(Player)
    local Session = Sessions[Player]
    if Session then
        Session.CharacterConnection:Disconnect()
        if Session.DeathConnection then
            Session.DeathConnection:Disconnect()
        end
    end
    Sessions[Player] = nil
    -- Recycle a player's arrows when they leave.
    for _, Arrow in ActiveArrows do
        if Arrow.Player == Player then
            Arrow:Release()
        end
    end
end)
for _, Player in Players:GetPlayers() do
    AddPlayer(Player)
end

RunService.Heartbeat:Connect(function(DeltaTime)
    local Time = Workspace:GetServerTimeNow()
    for _, Target in TargetData do
        if Target.Amplitude > 0 then
            local Offset = math.sin(Time * Target.Frequency + Target.Phase) * Target.Amplitude
            -- Move each target left and right from its starting position.
            Target.Model:PivotTo(Target.Base * CFrame.new(Offset, 0, 0))
        end
    end
    for _, Projectile in ActiveArrows do
        if Projectile.StuckAt and not Projectile.Released then
            Projectile:FollowSurface()
        end
    end
    -- Limit catch-up steps after lag so one frame does not do too much work.
    HeartbeatAccumulator = math.min(HeartbeatAccumulator + DeltaTime, SimulationStep * 12)
    while HeartbeatAccumulator >= SimulationStep do
        HeartbeatAccumulator -= SimulationStep
        for Index = #ActiveArrows, 1, -1 do
            local Arrow = ActiveArrows[Index]
            if not Arrow.Released and not Arrow.StuckAt then
                Arrow:Step(SimulationStep, Time)
            end
            if Arrow.Released then
                -- Replace a removed entry with the last arrow to avoid shifting the list.
                ActiveArrows[Index] = ActiveArrows[#ActiveArrows]
                ActiveArrows[#ActiveArrows] = nil
            end
        end
    end
    StateAccumulator += DeltaTime
    if StateAccumulator < 0.25 then
        return
    end
    StateAccumulator = 0
    for Player, Session in Sessions do
        if Session.DrawAt and (Time - Session.DrawAt > 8 or not GetArcher(Player)) then
            CancelDraw(Player, Session, "Draw cancelled")
        end
        if Session.Mode == "Challenge" and Time >= Session.EndsAt then
            -- End the round once and stop accepting extra points.
            Session.Mode = "Complete"
            Session.DrawAt = nil
            Session.Best = math.max(Session.Best, Session.Score)
            Remote:FireClient(Player, "Round", string.format("Round complete — %d points. Press R to retry.", Session.Score))
            SendState(Player, Session)
        end
    end
end)

print("[AsterArchery] Server ready: pooled ballistic arrows, server-owned charge and scoring.")
