-- Discord: lordx997 | Roblox: TheRealRacion
-- ASTER ARCHERY | Main submission candidate. Review and rewrite explanations in your own words.
-- One cohesive server controller: clients request actions; this script owns time, trajectories and scores.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- WaitForChild tolerates replication/startup order without assuming other assets initialize first.
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

-- A separate folder gives every shot a cheap shared exclusion filter, including parked pool models.
local Projectiles = Instance.new("Folder")
Projectiles.Name = "ArcheryProjectiles"
Projectiles.Parent = Workspace

-- Reject NaN and infinity before normalization: either would poison CFrame math and the physics loop.
local function Finite(Number)
    return Number == Number and math.abs(Number) < 1e6
end

local function ValidDirection(Value)
    if typeof(Value) ~= "Vector3" then
        return false
    end
    return Finite(Value.X) and Finite(Value.Y) and Finite(Value.Z)
        and Value.Magnitude > 0.5 and Value.Magnitude < 1.5
end

local function GetArcher(Player)
    -- Resolve the current character for every action; a cached character becomes stale after respawn.
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Head = Character and Character:FindFirstChild("Head")
    local Tool = Character and Character:FindFirstChild("Aster Bow")
    if not Humanoid or Humanoid.Health <= 0 or not Head or not Tool or not Tool:IsA("Tool") then
        return nil
    end
    -- Range bounds prevent an equipped tool elsewhere in this existing place from running the demo.
    if (Head.Position - Spawn.Position).Magnitude > 260 then
        return nil
    end
    return Head, Character
end

local function SendState(Player, Session)
    -- Send only presentation data to its owner; connection handles and server rate limits stay private.
    Remote:FireClient(Player, "State", {
        score = Session.score,
        shots = Session.shots,
        hits = Session.hits,
        best = Session.best,
        streak = Session.streak,
        mode = Session.mode,
        endsAt = Session.endsAt,
        drawAt = Session.drawAt,
    })
end

local function CancelDraw(Player, Session, Reason)
    -- Clearing the timestamp makes a later Release harmless even if the client misses this reply.
    Session.drawAt = nil
    Remote:FireClient(Player, "Cancel", Reason)
end

-- The token bucket limits all client actions, including malformed messages, before expensive work.
local function ConsumeToken(Session, Time)
    -- Refill by elapsed time, not frame count, so clients receive the same allowance at any framerate.
    Session.tokens = math.min(12, Session.tokens + (Time - Session.tokenAt) * 8)
    Session.tokenAt = Time
    if Session.tokens < 1 then
        return false
    end
    Session.tokens -= 1
    return true
end

-- Reusing complete arrow models avoids allocating and destroying many replicated parts per shot.
for Index = 1, PoolSize do
    local Model = Assets.Arrow:Clone()
    Model.Name = "PooledArrow"
    Model:PivotTo(CFrame.new(0, -1000, 0))
    Model.Parent = Projectiles
    table.insert(FreeModels, Model)
    -- Yield in bounded batches so initialization does not monopolize Studio's simulation thread.
    if Index % 32 == 0 then
        task.wait()
    end
end

for _, Model in TargetsFolder:GetChildren() do
    local Face = Model:FindFirstChild("Hitbox")
    if Face and Face:IsA("BasePart") then
        TargetData[Face] = {
            model = Model,
            base = Model:GetPivot(), -- Preserve the original frame so sinusoidal movement never drifts.
            radius = Face:GetAttribute("Radius"),
            amplitude = Model:GetAttribute("Amplitude") or 0,
            frequency = Model:GetAttribute("Frequency") or 1,
            phase = Model:GetAttribute("Phase") or 0,
        }
    end
end

-- Object space removes world position and rotation, so scoring still works when a target moves.
local function RingScore(Result)
    -- This lookup only recognizes the authored scoring surface, never a client-provided target name.
    local Target = TargetData[Result.Instance]
    if not Target then
        return 0, "MISS"
    end
    local Point = Result.Instance.CFrame:PointToObjectSpace(Result.Position)
    local NormalizedRadius = Vector2.new(Point.X, Point.Y).Magnitude / Target.radius
    -- A square collision face surrounds circular artwork; reject corners and hits from behind it.
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
-- Methods live on one shared table rather than allocating closures for every projectile.
Arrow.__index = Arrow

local function TrimEmbedded(Player)
    local Owned, Total = {}, {}
    for _, Arrow in ActiveArrows do
        if Arrow.stuckAt and not Arrow.released then
            table.insert(Total, Arrow)
            if Arrow.player == Player then
                table.insert(Owned, Arrow)
            end
        end
    end
    local function OldestFirst(A, B)
        return A.stuckAt < B.stuckAt
    end
    table.sort(Owned, OldestFirst)
    table.sort(Total, OldestFirst)
    -- Keep landed arrows until their owner starts another round or replaces the oldest of twelve.
    for Index = 1, math.max(0, #Owned - MaxEmbeddedPerPlayer) do
        Owned[Index]:Release()
    end
    local Count = 0
    for _, Arrow in Total do
        if not Arrow.released then
            Count += 1
        end
    end
    for _, Arrow in Total do
        if Count <= MaxEmbeddedTotal then
            break
        end
        if not Arrow.released then
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
    Self.model = Model
    Self.player = Player
    Self.sessionId = Session.id
    Self.position = Origin
    Self.velocity = Velocity
    Self.params = Params
    Self.age = 0
    Self.distance = 0
    Self.stuckPart = nil
    Self.stuckAt = nil
    Self.released = false
    Model:PivotTo(CFrame.lookAt(Origin, Origin + Velocity)) -- Local -Z is the authored arrow direction.
    -- Clear the old trail before enabling it, otherwise reusing a model can draw a streak across space.
    Model.Shaft.FlightTrail:Clear()
    Model.Shaft.FlightTrail.Enabled = true
    Model:SetAttribute("FlightState", "Flying")
    Model:SetAttribute("ArcherUserId", Player.UserId)
    Model:SetAttribute("ImpactPosition", nil)
    return Self
end

function Arrow.Release(Self)
    -- Idempotence prevents disconnect cleanup and the simulation loop from returning a model twice.
    if Self.released then
        return
    end
    Self.released = true
    Self.model.Shaft.FlightTrail.Enabled = false
    Self.model:SetAttribute("FlightState", "Pooled")
    Self.model:SetAttribute("ImpactPosition", nil)
    Self.model:PivotTo(CFrame.new(0, -1000, 0))
    table.insert(FreeModels, Self.model)
end

function Arrow.Resolve(Self, Result)
    local Session = Sessions[Self.player]
    if not Session or Session.id ~= Self.sessionId then
        return
    end
    -- Session IDs prevent an arrow fired before restart from scoring in the next challenge.
    local Time = Workspace:GetServerTimeNow()
    if Session.mode == "Complete" or (Session.mode == "Challenge" and Time >= Session.endsAt) then
        return
    end
    local Points, Label = 0, "MISS"
    if Result then
        Points, Label = RingScore(Result)
    end
    if Points > 0 then
        Session.hits += 1
        Session.streak += 1
        Session.score += Points
    else
        -- A miss resets consistency but does not remove points already earned on earlier shots.
        Session.streak = 0
    end
    Remote:FireClient(Self.player, "Impact", {
        points = Points,
        label = Label,
        position = Result and Result.Position or Self.position,
        distance = math.floor(Self.distance),
    })
    SendState(Self.player, Session)
end

function Arrow.Stick(Self, Result, Time)
    Self:Resolve(Result)
    Self.model.Shaft.FlightTrail.Enabled = false
    local Direction = Self.velocity.Unit
    -- The model pivot is the arrow tip. A small inset embeds the tip without burying the shaft.
    local Frame = CFrame.lookAt(Result.Position + Direction * 0.12, Result.Position + Direction)
    Self.model:PivotTo(Frame)
    Self.stuckPart = Result.Instance
    -- Store a local offset rather than a world position, keeping embedded arrows attached to movers.
    if Result.Instance:IsA("BasePart") and not Result.Instance:IsA("Terrain") then
        Self.stuckOffset = Result.Instance.CFrame:ToObjectSpace(Frame)
    end
    Self.stuckFrame = Frame
    Self.stuckAt = Time
    Self.model:SetAttribute("FlightState", "Embedded")
    Self.model:SetAttribute("ImpactPosition", Result.Position)
    TrimEmbedded(Self.player)
end

function Arrow.FollowSurface(Self)
    if not Self.stuckPart:IsDescendantOf(Workspace) then
        Self:Release()
        return
    end
    local Frame = Self.stuckOffset and Self.stuckPart.CFrame * Self.stuckOffset or Self.stuckFrame
    -- Static impacts need no repeated transforms; moving attachments update once per Heartbeat.
    if Frame ~= Self.stuckFrame then
        Self.model:PivotTo(Frame)
        Self.stuckFrame = Frame
    end
end

function Arrow.Step(Self, DeltaTime, Time)
    Self.age += DeltaTime
    -- Constant acceleration gives the exact segment endpoint; small steps limit chord error.
    local Displacement = Self.velocity * DeltaTime + Gravity * (0.5 * DeltaTime * DeltaTime)
    local Result = Workspace:Spherecast(Self.position, 0.07, Displacement, Self.params)
    -- Sweeping the entire traveled segment prevents fast arrows tunneling through a thin target.
    Self.distance += Result and Result.Distance or Displacement.Magnitude
    if Result then
        -- Orient the embedded shaft along velocity at the collision time, rather than the prior step.
        local Fraction = math.clamp(Result.Distance / Displacement.Magnitude, 0, 1)
        Self.velocity += Gravity * (DeltaTime * Fraction)
        Self:Stick(Result, Time)
        return
    end
    Self.position += Displacement
    Self.velocity += Gravity * DeltaTime
    Self.model:PivotTo(CFrame.lookAt(Self.position, Self.position + Self.velocity))
    if Self.age >= 5 or Self.distance >= 500 or Self.position.Y < Spawn.Position.Y - 50 then
        -- Time, distance and height bounds reclaim missed arrows even when they never touch geometry.
        Self:Resolve(nil)
        Self:Release()
    end
end

local function BeginChallenge(Player, Session, Time)
    if Time - Session.lastRestart < 2 then
        return
    end
    Session.lastRestart = Time
    for _, Arrow in ActiveArrows do
        if Arrow.player == Player then
            Arrow:Release()
        end
    end
    Session.id += 1
    Session.drawAt = nil
    Session.score = 0
    Session.hits = 0
    Session.shots = 0
    Session.streak = 0
    Session.mode = "Challenge"
    Session.endsAt = Time + RoundSeconds
    Remote:FireClient(Player, "Round", string.format("Challenge started — %d seconds. Every ring counts.", RoundSeconds))
    SendState(Player, Session)
end

local function FireArrow(Player, Session, Direction, Time)
    local Started = Session.drawAt
    -- Consume the draw once before validation: replaying the same Release cannot create another shot.
    Session.drawAt = nil
    if not Started or not ValidDirection(Direction) or Time - Session.lastShot < Cooldown then
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
    -- Clamp power so holding indefinitely cannot exceed the same maximum launch speed as a normal shot.
    local Speed = MinSpeed + (MaxSpeed - MinSpeed) * Power
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { Character, Projectiles }
    Params.IgnoreWater = true
    local AimFrame = CFrame.lookAt(Head.Position, Head.Position + Direction)
    local Origin = AimFrame:PointToWorldSpace(MuzzleRestOffset + MuzzleDrawOffset * Power)
    -- Both spawn point and power come from server state; the client only supplies its aim direction.
    local Obstruction = Workspace:Raycast(Head.Position, Origin - Head.Position, Params)
    -- The short muzzle offset must also be clear; otherwise shooting beside a wall could bypass it.
    if Obstruction then
        Remote:FireClient(Player, "Cancel", "Step back from the obstacle")
        return
    end
    local Arrow = Arrow.new(Player, Session, Origin, Direction * Speed, Params)
    if not Arrow then
        Remote:FireClient(Player, "Cancel", "Range busy — try again")
        return
    end
    Session.lastShot = Time
    -- Count only accepted launches, keeping accuracy consistent when a request is rejected.
    Session.shots += 1
    table.insert(ActiveArrows, Arrow)
    Remote:FireClient(Player, "Shot", { power = Power, speed = Speed })
    SendState(Player, Session)
end

Remote.OnServerEvent:Connect(function(Player, Action, Payload)
    -- Roblox supplies player from the connection; a client cannot name another archer in the payload.
    local Session = Sessions[Player]
    local Time = Workspace:GetServerTimeNow()
    if not Session or not ConsumeToken(Session, Time) then
        return
    end
    if Action == "Sync" then
        -- A newly loaded HUD requests state explicitly because PlayerAdded can precede its listener.
        SendState(Player, Session)
        return
    elseif Action == "Cancel" then
        Session.drawAt = nil
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
    if Session.mode == "Complete" or (Session.mode == "Challenge" and Time >= Session.endsAt) then
        CancelDraw(Player, Session, "Press R or NEW CHALLENGE to play again")
        return
    end
    if Action == "Begin" then
        if not Session.drawAt and Time - Session.lastShot >= Cooldown then
            Session.drawAt = Time
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
    Session.drawAt = nil
    if Session.deathConnection then
        Session.deathConnection:Disconnect()
    end
    local Root = Character:WaitForChild("HumanoidRootPart", 10)
    local Humanoid = Character:WaitForChild("Humanoid", 10)
    if not Root or not Humanoid or Player.Character ~= Character or Sessions[Player] ~= Session then
        return
    end
    Character:PivotTo(Spawn.CFrame + Vector3.new(0, 4, 0))
    Session.deathConnection = Humanoid.Died:Connect(function()
        CancelDraw(Player, Session, "Respawning at the range")
    end)
end

local function AddPlayer(Player)
    -- Scores are per-server-session only. The demo deliberately makes no persistence promise.
    local Session = {
        id = 0, score = 0, shots = 0, hits = 0, best = 0, streak = 0,
        mode = "Practice", endsAt = 0, drawAt = nil,
        lastShot = -math.huge, lastRestart = -math.huge,
        tokens = 12, tokenAt = Workspace:GetServerTimeNow(),
    }
    Sessions[Player] = Session
    Player.RespawnLocation = Spawn
    Session.characterConnection = Player.CharacterAdded:Connect(function(Character)
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
        Session.characterConnection:Disconnect()
        if Session.deathConnection then
            Session.deathConnection:Disconnect()
        end
    end
    Sessions[Player] = nil
    -- Release departing players' arrows immediately rather than retaining their Player reference.
    for _, Arrow in ActiveArrows do
        if Arrow.player == Player then
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
        if Target.amplitude > 0 then
            local Offset = math.sin(Time * Target.frequency + Target.phase) * Target.amplitude
            -- Multiplying by the base CFrame expresses motion along each target's own horizontal axis.
            Target.model:PivotTo(Target.base * CFrame.new(Offset, 0, 0))
        end
    end
    for _, Projectile in ActiveArrows do
        if Projectile.stuckAt and not Projectile.released then
            Projectile:FollowSurface()
        end
    end
    -- Bound catch-up work after a lag spike. One loop owns every projectile instead of per-arrow tasks.
    HeartbeatAccumulator = math.min(HeartbeatAccumulator + DeltaTime, SimulationStep * 12)
    while HeartbeatAccumulator >= SimulationStep do
        HeartbeatAccumulator -= SimulationStep
        for Index = #ActiveArrows, 1, -1 do
            local Arrow = ActiveArrows[Index]
            if not Arrow.released and not Arrow.stuckAt then
                Arrow:Step(SimulationStep, Time)
            end
            if Arrow.released then
                -- Swap removal is O(1); reverse iteration ensures no unprocessed arrow is skipped.
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
        if Session.drawAt and (Time - Session.drawAt > 8 or not GetArcher(Player)) then
            CancelDraw(Player, Session, "Draw cancelled")
        end
        if Session.mode == "Challenge" and Time >= Session.endsAt then
            -- Transition once to Complete; remaining projectiles cannot extend the scoring window.
            Session.mode = "Complete"
            Session.drawAt = nil
            Session.best = math.max(Session.best, Session.score)
            Remote:FireClient(Player, "Round", string.format("Round complete — %d points. Press R to retry.", Session.score))
            SendState(Player, Session)
        end
    end
end)

print("[AsterArchery] Server ready: pooled ballistic arrows, server-owned charge and scoring.")
