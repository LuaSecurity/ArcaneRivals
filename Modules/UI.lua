local UI = {}
UI.__index = UI

-- Pre-fetch Services and Functions
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Localize Math and Methods
local _v2 = Vector2.new
local _v3 = Vector3.new
local _cfLookAt = CFrame.lookAt
local _mathAtan2 = math.atan2
local _mathCos = math.cos
local _mathSin = math.sin
local _mathFloor = math.floor
local _mathAbs = math.abs
local _mathClamp = math.clamp

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local DrawingAPIClass = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaSecurity/ArcaneRivals/refs/heads/main/Modules/Drawing.lua"))()
local DrawingHandler = DrawingAPIClass.new()

function UI.new(title)
    local self = setmetatable({}, UI)
    
    self.Window = Library:CreateWindow({
        Title = title or "Arcane",
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })

    self.Tabs = {}
    self.ESP_Cache = {}
    
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    
    return self
end

function UI:CreateTab(name)
    if self.Tabs[name] then return self.Tabs[name] end
    local tab = self.Window:AddTab(name)
    self.Tabs[name] = tab
    return tab
end

local function IsSameTeam(player)
    if not (player and LocalPlayer) then return false end
    local myTeam = LocalPlayer:GetAttribute("TeamID")
    local theirTeam = player:GetAttribute("TeamID")
    return myTeam ~= nil and theirTeam ~= nil and myTeam == theirTeam
end

function UI:SetupVisuals()
    local VisualsTab = self:CreateTab("Visuals")
    
    local EspGroup = VisualsTab:AddLeftGroupbox("ESP Main")
    EspGroup:AddToggle("Esp_Enabled", { Text = "Enabled", Default = false })
    EspGroup:AddToggle("Esp_TeamCheck", { Text = "Team Check", Default = true })
    EspGroup:AddToggle("Esp_DistLimitEnabled", { Text = "Use Distance Limit", Default = false })
    EspGroup:AddSlider("Esp_MaxDist", { Text = "Max Distance", Default = 500, Min = 100, Max = 5000, Rounding = 0 })
    EspGroup:AddDivider()
    EspGroup:AddToggle("Esp_Box", { Text = "Box" }):AddColorPicker("BoxColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_BoxFill", { Text = "Box Fill" }):AddColorPicker("BoxFillColor", { Default = Color3.new(1, 0, 0), Transparency = 0.5 })
    EspGroup:AddToggle("Esp_Name", { Text = "Name" }):AddColorPicker("NameColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_Distance", { Text = "Distance" }):AddColorPicker("DistanceColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_HealthBar", { Text = "Health Bar" })
    EspGroup:AddToggle("Esp_Skeleton", { Text = "Skeleton" }):AddColorPicker("SkeletonColor", { Default = Color3.new(1,1,1) })
    
    local ChamsGroup = VisualsTab:AddLeftGroupbox("Chams")
    ChamsGroup:AddToggle("Chams_Enabled", { Text = "Enabled" })
    ChamsGroup:AddToggle("Chams_Fill", { Text = "Fill" }):AddColorPicker("ChamsFillColor", { Default = Color3.fromRGB(150, 0, 0), Transparency = 0.5 })
    ChamsGroup:AddToggle("Chams_Outline", { Text = "Outline" }):AddColorPicker("ChamsOutlineColor", { Default = Color3.fromRGB(255, 0, 0), Transparency = 0 })
    ChamsGroup:AddToggle("Chams_Occluded", { Text = "Visible Check", Default = true })

    local TracerGroup = VisualsTab:AddRightGroupbox("Bullet Effects")
    TracerGroup:AddToggle("CustomTracers", { Text = "Bullet Tracers" })
    TracerGroup:AddLabel("Tracer Color"):AddColorPicker("Tracer_Color", { Default = Color3.fromRGB(255, 255, 255) })
    TracerGroup:AddSlider("Tracer_Thickness", { Text = "Thickness", Default = 0.03, Min = 0.01, Max = 0.5, Rounding = 3 })
    TracerGroup:AddSlider("Tracer_Duration", { Text = "Lifetime (s)", Default = 1.5, Min = 0.1, Max = 5, Rounding = 1 })

    local MiscVisuals = VisualsTab:AddRightGroupbox("Visuals Extras")
    MiscVisuals:AddToggle("Esp_Tracers", { Text = "Tracers" }):AddColorPicker("TracerColor", { Default = Color3.new(1,1,1) })
    MiscVisuals:AddDropdown("Tracer_Origin", { Text = "Line Origin", Default = "Bottom", Values = {"Top", "Center", "Bottom"} })
    MiscVisuals:AddDivider()
    MiscVisuals:AddToggle("Esp_OOF", { Text = "Off-Screen Indicators" }):AddColorPicker("OOFColor", { Default = Color3.new(1,1,1) })
    MiscVisuals:AddSlider("OOF_Radius", { Text = "OOF Radius", Default = 200, Min = 50, Max = 600, Rounding = 0 })
    MiscVisuals:AddSlider("OOF_Size", { Text = "OOF Arrow Size", Default = 15, Min = 5, Max = 50, Rounding = 0 })

    local skeletonLinks = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightHand", "RightLowerArm"}
    }

    local function RemovePlayerESP(player)
        local data = self.ESP_Cache[player]
        if data then
            for _, obj in data.Drawings do if obj.Remove then obj:Remove() end end
            for _, line in data.Skeleton do if line.Remove then line:Remove() end end
            if data.Highlight then data.Highlight:Destroy() end
            self.ESP_Cache[player] = nil
        end
    end

    local function CreatePlayerESP(player)
        if player == LocalPlayer then return end
        RemovePlayerESP(player)

        local highlight = Instance.new("Highlight")
        highlight.Name = "ArcaneChams"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false

        local drawings = {
            BoxFilled = DrawingHandler:Square({ Thickness = 1, Filled = true, Visible = false }),
            Box = DrawingHandler:Square({ Thickness = 1, Visible = false }),
            BoxOutline = DrawingHandler:Square({ Thickness = 3, Color = Color3.new(0,0,0), Visible = false }),
            Name = DrawingHandler:Text({ Size = 14, Center = true, Outline = true, Visible = false }),
            Distance = DrawingHandler:Text({ Size = 13, Center = true, Outline = true, Visible = false }),
            HealthBg = DrawingHandler:Line({ Thickness = 2.3, Color = Color3.new(0,0,0), Visible = false }),
            HealthBar = DrawingHandler:Line({ Thickness = 2, Visible = false }),
            Tracer = DrawingHandler:Line({ Thickness = 1, Visible = false }),
            OOF = DrawingHandler:Triangle({ Thickness = 1, Filled = true, Visible = false })
        }

        local skeleton = {}
        for i = 1, #skeletonLinks do
            skeleton[i] = DrawingHandler:Line({ Thickness = 1, Visible = false, Color = Color3.new(1,1,1) })
        end

        self.ESP_Cache[player] = {
            Drawings = drawings,
            Skeleton = skeleton,
            Highlight = highlight
        }
    end

    Players.PlayerAdded:Connect(CreatePlayerESP)
    Players.PlayerRemoving:Connect(RemovePlayerESP)
    for _, p in Players:GetPlayers() do CreatePlayerESP(p) end

    RunService.RenderStepped:Connect(function()
        local enabled = Toggles.Esp_Enabled.Value
        local teamCheck = Toggles.Esp_TeamCheck.Value
        local distLimit = Toggles.Esp_DistLimitEnabled.Value
        local maxDist = Options.Esp_MaxDist.Value
        local camPos = Camera.CFrame.Position
        
        for player, cache in self.ESP_Cache do
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local objects = cache.Drawings
            local skeletonLines = cache.Skeleton
            local highlight = cache.Highlight

            local function hideAll()
                for _, obj in objects do obj.Visible = false end
                for _, line in skeletonLines do line.Visible = false end
                highlight.Enabled = false
            end

            if not (enabled and char and hrp and hum and hum.Health > 0) or (teamCheck and IsSameTeam(player)) then
                hideAll() continue
            end

            local dist = (camPos - hrp.Position).Magnitude
            if distLimit and dist > maxDist then hideAll() continue end

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local viewportSize = Camera.ViewportSize
            local screenCenter = viewportSize / 2

            -- Off-Screen Indicator Logic
            if Toggles.Esp_OOF.Value and not onScreen then
                local relativePos = Camera.CFrame:PointToObjectSpace(hrp.Position)
                local angle = _mathAtan2(relativePos.Y, relativePos.X)
                local radius = Options.OOF_Radius.Value
                local size = Options.OOF_Size.Value
                local dir = _v2(_mathCos(angle), -_mathSin(angle))
                local perp = _v2(-dir.Y, dir.X)
                local arrowPos = screenCenter + (dir * radius)
                local basePos = arrowPos - (dir * size)
                
                objects.OOF.PointA = arrowPos
                objects.OOF.PointB = basePos + (perp * (size * 0.5))
                objects.OOF.PointC = basePos - (perp * (size * 0.5))
                objects.OOF.Color = Options.OOFColor.Value
                objects.OOF.Visible = true
            else
                objects.OOF.Visible = false
            end

            if onScreen then
                local head = char:FindFirstChild("Head") or hrp
                local headPos = Camera:WorldToViewportPoint(head.Position + _v3(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - _v3(0, 3, 0))
                local h = _mathAbs(headPos.Y - legPos.Y)
                local w = h * 0.6
                local boxPos = _v2(pos.X - w/2, pos.Y - h/2)

                -- Box Logic
                local showBox = Toggles.Esp_Box.Value
                objects.Box.Visible = showBox
                objects.BoxOutline.Visible = showBox
                if showBox then
                    objects.Box.Position = boxPos
                    objects.Box.Size = _v2(w, h)
                    objects.Box.Color = Options.BoxColor.Value
                    objects.BoxOutline.Position = boxPos
                    objects.BoxOutline.Size = _v2(w, h)
                    
                    local fill = Toggles.Esp_BoxFill.Value
                    objects.BoxFilled.Visible = fill
                    if fill then
                        objects.BoxFilled.Position = boxPos
                        objects.BoxFilled.Size = _v2(w, h)
                        objects.BoxFilled.Color = Options.BoxFillColor.Value
                        objects.BoxFilled.Transparency = Options.BoxFillColor.Transparency
                    end
                else
                    objects.BoxFilled.Visible = false
                end

                -- Name & Distance
                objects.Name.Visible = Toggles.Esp_Name.Value
                if objects.Name.Visible then
                    objects.Name.Position = _v2(pos.X, boxPos.Y - 15)
                    objects.Name.Text = player.Name
                    objects.Name.Color = Options.NameColor.Value
                end

                objects.Distance.Visible = Toggles.Esp_Distance.Value
                if objects.Distance.Visible then
                    objects.Distance.Position = _v2(pos.X, boxPos.Y + h + 2)
                    objects.Distance.Text = _mathFloor(dist) .. "m"
                    objects.Distance.Color = Options.DistanceColor.Value
                end

                -- Health Bar
                objects.HealthBar.Visible = Toggles.Esp_HealthBar.Value
                objects.HealthBg.Visible = objects.HealthBar.Visible
                if objects.HealthBar.Visible then
                    local hpPercent = _mathClamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = h * hpPercent
                    objects.HealthBg.From = _v2(boxPos.X - 5, boxPos.Y)
                    objects.HealthBg.To = _v2(boxPos.X - 5, boxPos.Y + h)
                    objects.HealthBar.From = _v2(boxPos.X - 5, boxPos.Y + h)
                    objects.HealthBar.To = _v2(boxPos.X - 5, boxPos.Y + h - barHeight)
                    objects.HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hpPercent)
                end

                -- Tracers
                objects.Tracer.Visible = Toggles.Esp_Tracers.Value
                if objects.Tracer.Visible then
                    local mode = Options.Tracer_Origin.Value
                    local originY = (mode == "Top" and 0) or (mode == "Center" and viewportSize.Y / 2) or viewportSize.Y
                    objects.Tracer.From = _v2(viewportSize.X / 2, originY)
                    objects.Tracer.To = _v2(pos.X, pos.Y + h/2)
                    objects.Tracer.Color = Options.TracerColor.Value
                end

                -- Skeleton
                local showSkelly = Toggles.Esp_Skeleton.Value
                if showSkelly then
                    for i, link in skeletonLinks do
                        local p1, p2 = char:FindFirstChild(link[1]), char:FindFirstChild(link[2])
                        local line = skeletonLines[i]
                        if p1 and p2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            if vis1 and vis2 then
                                line.Visible = true
                                line.From = _v2(pos1.X, pos1.Y)
                                line.To = _v2(pos2.X, pos2.Y)
                                line.Color = Options.SkeletonColor.Value
                            else line.Visible = false end
                        else line.Visible = false end
                    end
                else
                    for _, line in skeletonLines do line.Visible = false end
                end
            else
                for _, obj in objects do if obj ~= objects.OOF then obj.Visible = false end end
                for _, line in skeletonLines do line.Visible = false end
            end

            -- Chams Logic
            if Toggles.Chams_Enabled.Value then
                if highlight.Parent ~= CoreGui then highlight.Parent = CoreGui end
                highlight.Adornee = char
                highlight.Enabled = true
                highlight.FillColor = Options.ChamsFillColor.Value
                highlight.FillTransparency = Toggles.Chams_Fill.Value and Options.ChamsFillColor.Transparency or 1
                highlight.OutlineColor = Options.ChamsOutlineColor.Value
                highlight.OutlineTransparency = Toggles.Chams_Outline.Value and Options.ChamsOutlineColor.Transparency or 1
                highlight.DepthMode = Toggles.Chams_Occluded.Value and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            else
                highlight.Enabled = false
            end
        end
    end)
end

function UI:SetupMovement()
    local MoveTab = self:CreateTab("Movement")

    local SpeedGroup = MoveTab:AddLeftGroupbox("Speed")
    SpeedGroup:AddToggle("Speed_Enabled", { Text = "Enabled" }):AddKeyPicker("SpeedKey", { Default = "None", Text = "Speed", Mode = "Toggle" })
    SpeedGroup:AddDropdown("Speed_Mode", { Text = "Mode", Default = "Velocity", Values = {"Velocity", "CFrame"} })
    SpeedGroup:AddSlider("Speed_Value", { Text = "Speed", Default = 16, Min = 16, Max = 200, Rounding = 1 })

    local FlyGroup = MoveTab:AddLeftGroupbox("Fly")
    FlyGroup:AddToggle("Fly_Enabled", { Text = "Enabled" }):AddKeyPicker("FlyKey", { Default = "None", Text = "Fly", Mode = "Toggle" })
    FlyGroup:AddDropdown("Fly_Mode", { Text = "Mode", Default = "Velocity", Values = {"Velocity", "CFrame"} })
    FlyGroup:AddSlider("Fly_Speed", { Text = "Speed", Default = 50, Min = 10, Max = 200, Rounding = 1 })

    local HoverGroup = MoveTab:AddRightGroupbox("Target Hovering")
    HoverGroup:AddToggle("Hover_Enabled", { Text = "Enabled" }):AddKeyPicker("HoverKey", { Default = "None", Text = "Hover", Mode = "Toggle" })
    HoverGroup:AddToggle("Hover_Visuals", { Text = "Ring" }):AddColorPicker("Hover_RingColor", { Default = Color3.fromRGB(255, 50, 50) })
    HoverGroup:AddSlider("Hover_Offset", { Text = "Height Offset", Default = 15, Min = -50, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Radius", { Text = "Radius (Distance)", Default = 20, Min = 5, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Speed", { Text = "Rotation Speed", Default = 30, Min = 1, Max = 120, Rounding = 0, Suffix = " RPM" })

    local HoverRingCache = {}
    for i = 1, 32 do table.insert(HoverRingCache, DrawingHandler:Line({Thickness = 1, Visible = false})) end

    RunService.Heartbeat:Connect(function(dt)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hrp and hum) then return end

        if Toggles.Speed_Enabled.Value then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                if Options.Speed_Mode.Value == "Velocity" then
                    hrp.Velocity = _v3(moveDir.X * Options.Speed_Value.Value, hrp.Velocity.Y, moveDir.Z * Options.Speed_Value.Value)
                else
                    hrp.CFrame += (moveDir * (Options.Speed_Value.Value * dt))
                end
            end
        end

        if Toggles.Fly_Enabled.Value then
            local speed = Options.Fly_Speed.Value
            local velocity = _v3(0,0,0)
            local camCF = Camera.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity += camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity -= camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity += camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity += _v3(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity -= _v3(0, 1, 0) end

            if Options.Fly_Mode.Value == "Velocity" then
                local bv = hrp:FindFirstChild("ArcaneFlyVelocity") or Instance.new("BodyVelocity")
                bv.Name = "ArcaneFlyVelocity"; bv.MaxForce = _v3(1e9, 1e9, 1e9); bv.Velocity = velocity * speed; bv.Parent = hrp
            else
                local bv = hrp:FindFirstChild("ArcaneFlyVelocity")
                if bv then bv:Destroy() end
                hrp.Anchored = true
                hrp.CFrame += (velocity * (speed * dt))
            end
        else
            local bv = hrp:FindFirstChild("ArcaneFlyVelocity")
            if bv then bv:Destroy() end
            if Options.Fly_Mode.Value == "CFrame" then hrp.Anchored = false end
        end

        if Toggles.Hover_Enabled.Value then
            local target, minDist = nil, math.huge
            for _, p in Players:GetPlayers() do
                if p ~= LocalPlayer and not IsSameTeam(p) then
                    local phum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    local phrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if phrp and phum and phum.Health > 0 then
                        local d = (hrp.Position - phrp.Position).Magnitude
                        if d < minDist then minDist = d target = phrp end
                    end
                end
            end

            if target then
                local theta = os.clock() * (Options.Hover_Speed.Value / 60) * (math.pi * 2) 
                local radius, height = Options.Hover_Radius.Value, Options.Hover_Offset.Value
                local tPos = target.Position + _v3(_mathCos(theta) * radius, height, _mathSin(theta) * radius)
                
                hrp.CFrame = _cfLookAt(tPos, target.Position)
                hrp.Velocity, hrp.RotVelocity = _v3(0,0,0), _v3(0,0,0)

                if Toggles.Hover_Visuals.Value then
                    local segs = #HoverRingCache
                    for i = 1, segs do
                        local a1, a2 = (i/segs) * (math.pi*2), ((i+1)/segs) * (math.pi*2)
                        local p1 = target.Position + _v3(_mathCos(a1)*radius, height, _mathSin(a1)*radius)
                        local p2 = target.Position + _v3(_mathCos(a2)*radius, height, _mathSin(a2)*radius)
                        local v1, vis1 = Camera:WorldToViewportPoint(p1)
                        local v2, vis2 = Camera:WorldToViewportPoint(p2)
                        local line = HoverRingCache[i]
                        if vis1 and vis2 then
                            line.Visible = true; line.From = _v2(v1.X, v1.Y); line.To = _v2(v2.X, v2.Y); line.Color = Options.Hover_RingColor.Value
                        else line.Visible = false end
                    end
                else for _, l in HoverRingCache do l.Visible = false end end
            else for _, l in HoverRingCache do l.Visible = false end end
        else for _, l in HoverRingCache do l.Visible = false end end
    end)
end

function UI:SetupSettings(folder, tabName)
    local targetTab = self:CreateTab(tabName)
    ThemeManager:SetFolder(folder)
    SaveManager:SetFolder(folder .. "/configs")
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
    SaveManager:BuildConfigSection(targetTab)
    ThemeManager:ApplyToTab(targetTab)
    
    local menuGroup = targetTab:AddLeftGroupbox('Menu')
    menuGroup:AddButton('Unload', function() Library:Unload() end)
    menuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })
    Library.ToggleKeybind = Options.MenuKeybind
    SaveManager:LoadAutoloadConfig()
end

function UI:Notify(text, time) Library:Notify(text, time or 5) end

return UI
