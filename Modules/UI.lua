local UI = {}
UI.__index = UI

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local DrawingAPIClass = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaSecurity/ArcaneRivals/refs/heads/main/Modules/Drawing.lua"))()
local DrawingHandler = DrawingAPIClass.new()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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
    if not player or not LocalPlayer then return false end
    local myTeam = LocalPlayer:GetAttribute("TeamID")
    local theirTeam = player:GetAttribute("TeamID")
    return myTeam ~= nil and theirTeam ~= nil and myTeam == theirTeam
end

local function GetCharacterExtents(character)
    local cf, size = character:GetBoundingBox()
    local corners = {
        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
    }
    
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local screenCorners = {}
    local onScreenCount = 0

    for _, corner in ipairs(corners) do
        local pos, onScreen = Camera:WorldToViewportPoint(corner.Position)
        if onScreen then onScreenCount = onScreenCount + 1 end
        
        table.insert(screenCorners, Vector2.new(pos.X, pos.Y))
        
        if pos.X < minX then minX = pos.X end
        if pos.X > maxX then maxX = pos.X end
        if pos.Y < minY then minY = pos.Y end
        if pos.Y > maxY then maxY = pos.Y end
    end

    return onScreenCount > 0, minX, minY, maxX - minX, maxY - minY, screenCorners
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
    EspGroup:AddDropdown("Box_Mode", { Text = "Box Mode", Default = "2D", Values = {"2D", "Corner", "3D"} })
    EspGroup:AddToggle("Esp_BoxFill", { Text = "Box Fill" }):AddColorPicker("BoxFillColor", { Default = Color3.new(1, 0, 0), Transparency = 0.5 })
    
    EspGroup:AddToggle("Esp_Name", { Text = "Name" }):AddColorPicker("NameColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_Distance", { Text = "Distance" }):AddColorPicker("DistanceColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_HealthBar", { Text = "Health Bar" }):AddColorPicker("HealthBarColor", { Default = Color3.new(0, 1, 0) })
    EspGroup:AddToggle("Esp_Skeleton", { Text = "Skeleton" }):AddColorPicker("SkeletonColor", { Default = Color3.new(1,1,1) })
    
    local ChamsGroup = VisualsTab:AddLeftGroupbox("Chams")
    ChamsGroup:AddToggle("Chams_Enabled", { Text = "Enabled" })
    ChamsGroup:AddToggle("Chams_Fill", { Text = "Fill" }):AddColorPicker("ChamsFillColor", { Default = Color3.fromRGB(150, 0, 0), Transparency = 0.5 })
    ChamsGroup:AddToggle("Chams_Outline", { Text = "Outline" }):AddColorPicker("ChamsOutlineColor", { Default = Color3.fromRGB(255, 0, 0), Transparency = 0 })
    ChamsGroup:AddToggle("Chams_Occluded", { Text = "Occluded (Wallcheck)", Default = true })

    local TracerGroup = VisualsTab:AddRightGroupbox("Bullet Effects")
    TracerGroup:AddToggle("CustomTracers", { Text = "Bullet Tracers" })
    TracerGroup:AddLabel("Tracer Color"):AddColorPicker("Tracer_Color", { Default = Color3.fromRGB(255, 255, 255) })
    TracerGroup:AddSlider("Tracer_Thickness", { Text = "Thickness", Default = 0.03, Min = 0.01, Max = 0.5, Rounding = 3 })
    TracerGroup:AddSlider("Tracer_Duration", { Text = "Lifetime (s)", Default = 1.5, Min = 0.1, Max = 5, Rounding = 1 })

    local MiscVisuals = VisualsTab:AddRightGroupbox("Visuals Extras")
    MiscVisuals:AddToggle("Esp_Tracers", { Text = "Tracers (Lines)" }):AddColorPicker("TracerColor", { Default = Color3.new(1,1,1) })
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
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
    }

    local function RemovePlayerESP(player)
        if self.ESP_Cache[player] then
            for _, obj in pairs(self.ESP_Cache[player].Drawings) do
                if obj.Remove then obj:Remove() end
            end
            for _, line in pairs(self.ESP_Cache[player].Skeleton) do
                if line.Remove then line:Remove() end
            end
            for _, line in pairs(self.ESP_Cache[player].Box3D) do
                if line.Remove then line:Remove() end
            end
            for _, line in pairs(self.ESP_Cache[player].CornerBox) do
                if line.Remove then line:Remove() end
            end
            if self.ESP_Cache[player].Highlight then
                self.ESP_Cache[player].Highlight:Destroy()
            end
            self.ESP_Cache[player] = nil
        end
    end

    local function CreatePlayerESP(player)
        if player == LocalPlayer then return end
        RemovePlayerESP(player)

        local highlight = Instance.new("Highlight")
        highlight.Name = "ArcaneChams"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false

        self.ESP_Cache[player] = {
            Drawings = {
                BoxFilled = DrawingHandler:Square({ Thickness = 1, Filled = true, Visible = false }),
                Box = DrawingHandler:Square({ Thickness = 1, Visible = false }),
                BoxOutline = DrawingHandler:Square({ Thickness = 3, Color = Color3.new(0,0,0), Visible = false }),
                Name = DrawingHandler:Text({ Size = 14, Center = true, Outline = true, Visible = false }),
                Distance = DrawingHandler:Text({ Size = 13, Center = true, Outline = true, Visible = false }),
                HealthBar = DrawingHandler:Line({ Thickness = 2, Visible = false }),
                Tracer = DrawingHandler:Line({ Thickness = 1, Visible = false }),
                OOF = DrawingHandler:Triangle({ Thickness = 1, Filled = true, Visible = false })
            },
            Skeleton = {},
            Box3D = {},
            CornerBox = {},
            Highlight = highlight
        }

        for i = 1, 14 do table.insert(self.ESP_Cache[player].Skeleton, DrawingHandler:Line({ Thickness = 1, Visible = false, Color = Color3.new(1,1,1) })) end
        for i = 1, 12 do table.insert(self.ESP_Cache[player].Box3D, DrawingHandler:Line({ Thickness = 1, Visible = false, Color = Color3.new(1,1,1) })) end
        for i = 1, 8 do table.insert(self.ESP_Cache[player].CornerBox, DrawingHandler:Line({ Thickness = 1, Visible = false, Color = Color3.new(1,1,1) })) end
    end

    Players.PlayerAdded:Connect(CreatePlayerESP)
    Players.PlayerRemoving:Connect(RemovePlayerESP)
    for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end

    RunService.RenderStepped:Connect(function()
        local enabled = Toggles.Esp_Enabled and Toggles.Esp_Enabled.Value
        
        for player, cache in pairs(self.ESP_Cache) do
            local objects = cache.Drawings
            local skeletonLines = cache.Skeleton
            local box3dLines = cache.Box3D
            local cornerLines = cache.CornerBox
            local highlight = cache.Highlight

            local function HideAll()
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                for _, line in pairs(box3dLines) do line.Visible = false end
                for _, line in pairs(cornerLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
            end

            if not enabled then 
                HideAll()
                continue 
            end

            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not char or not hrp or not hum or hum.Health <= 0 or (Toggles.Esp_TeamCheck.Value and IsSameTeam(player)) then
                HideAll()
                continue
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if Toggles.Esp_DistLimitEnabled.Value and dist > Options.Esp_MaxDist.Value then
                HideAll()
                continue
            end

            local onScreen, x, y, w, h, corners = GetCharacterExtents(char)
            local pos = Vector2.new(x + w/2, y + h/2)
            local viewportSize = Camera.ViewportSize
            local screenCenter = viewportSize / 2

            if Toggles.Esp_OOF.Value and not onScreen then
                local relativePos = Camera.CFrame:PointToObjectSpace(hrp.Position)
                local angle = math.atan2(relativePos.Y, relativePos.X)
                local radius = Options.OOF_Radius.Value
                local size = Options.OOF_Size.Value
                local dir = Vector2.new(math.cos(angle), -math.sin(angle))
                local perp = Vector2.new(-dir.Y, dir.X)
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
                local boxMode = Options.Box_Mode.Value
                local boxColor = Options.BoxColor.Value

                -- 2D Box
                if Toggles.Esp_Box.Value and boxMode == "2D" then
                    objects.Box.Visible = true
                    objects.Box.Position = Vector2.new(x, y)
                    objects.Box.Size = Vector2.new(w, h)
                    objects.Box.Color = boxColor
                    
                    objects.BoxOutline.Visible = true
                    objects.BoxOutline.Position = Vector2.new(x, y)
                    objects.BoxOutline.Size = Vector2.new(w, h)

                    if Toggles.Esp_BoxFill.Value then
                        objects.BoxFilled.Visible = true
                        objects.BoxFilled.Position = Vector2.new(x, y)
                        objects.BoxFilled.Size = Vector2.new(w, h)
                        objects.BoxFilled.Color = Options.BoxFillColor.Value
                        objects.BoxFilled.Transparency = Options.BoxFillColor.Transparency
                    else
                        objects.BoxFilled.Visible = false
                    end
                else
                    objects.Box.Visible = false
                    objects.BoxOutline.Visible = false
                    objects.BoxFilled.Visible = false
                end

                -- Corner Box
                if Toggles.Esp_Box.Value and boxMode == "Corner" then
                    local lineL = math.min(w, h) / 3
                    local tl = Vector2.new(x, y)
                    local tr = Vector2.new(x + w, y)
                    local bl = Vector2.new(x, y + h)
                    local br = Vector2.new(x + w, y + h)

                    local function DrawCorner(idx, p1, p2)
                        local l = cornerLines[idx]
                        l.Visible = true
                        l.From = p1
                        l.To = p2
                        l.Color = boxColor
                    end

                    DrawCorner(1, tl, tl + Vector2.new(lineL, 0))
                    DrawCorner(2, tl, tl + Vector2.new(0, lineL))
                    DrawCorner(3, tr, tr - Vector2.new(lineL, 0))
                    DrawCorner(4, tr, tr + Vector2.new(0, lineL))
                    DrawCorner(5, bl, bl + Vector2.new(lineL, 0))
                    DrawCorner(6, bl, bl - Vector2.new(0, lineL))
                    DrawCorner(7, br, br - Vector2.new(lineL, 0))
                    DrawCorner(8, br, br - Vector2.new(0, lineL))
                else
                    for _, l in pairs(cornerLines) do l.Visible = false end
                end

                -- 3D Box
                if Toggles.Esp_Box.Value and boxMode == "3D" then
                    -- corners table from GetCharacterExtents has 8 Vector2s
                    local c = corners
                    -- Indices mapping for 3D box connections
                    local connections = {
                        {1,2}, {2,4}, {4,3}, {3,1}, -- Top Face
                        {5,6}, {6,8}, {8,7}, {7,5}, -- Bottom Face
                        {1,5}, {2,6}, {3,7}, {4,8}  -- Pillars
                    }
                    for i, conn in ipairs(connections) do
                        local l = box3dLines[i]
                        l.Visible = true
                        l.From = c[conn[1]]
                        l.To = c[conn[2]]
                        l.Color = boxColor
                    end
                else
                    for _, l in pairs(box3dLines) do l.Visible = false end
                end

                if Toggles.Esp_Name.Value then
                    objects.Name.Visible = true
                    objects.Name.Position = Vector2.new(x + w/2, y - 15)
                    objects.Name.Text = player.Name
                    objects.Name.Color = Options.NameColor.Value
                else
                    objects.Name.Visible = false
                end

                if Toggles.Esp_Distance.Value then
                    objects.Distance.Visible = true
                    objects.Distance.Position = Vector2.new(x + w/2, y + h + 2)
                    objects.Distance.Text = math.floor(dist) .. "m"
                    objects.Distance.Color = Options.DistanceColor.Value
                else
                    objects.Distance.Visible = false
                end

                if Toggles.Esp_HealthBar.Value then
                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = h * hpPercent
                    objects.HealthBar.Visible = true
                    objects.HealthBar.From = Vector2.new(x - 5, y + h)
                    objects.HealthBar.To = Vector2.new(x - 5, y + h - barHeight)
                    objects.HealthBar.Color = Options.HealthBarColor.Value
                else
                    objects.HealthBar.Visible = false
                end

                if Toggles.Esp_Tracers.Value then
                    local originY = (Options.Tracer_Origin.Value == "Top" and 0) or (Options.Tracer_Origin.Value == "Center" and viewportSize.Y / 2) or viewportSize.Y
                    objects.Tracer.Visible = true
                    objects.Tracer.From = Vector2.new(viewportSize.X / 2, originY)
                    objects.Tracer.To = Vector2.new(x + w/2, y + h/2)
                    objects.Tracer.Color = Options.TracerColor.Value
                else
                    objects.Tracer.Visible = false
                end

                if Toggles.Esp_Skeleton.Value then
                    for i, link in ipairs(skeletonLinks) do
                        local p1 = char:FindFirstChild(link[1])
                        local p2 = char:FindFirstChild(link[2])
                        local line = skeletonLines[i]
                        
                        if p1 and p2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            
                            if vis1 and vis2 then
                                line.Visible = true
                                line.From = Vector2.new(pos1.X, pos1.Y)
                                line.To = Vector2.new(pos2.X, pos2.Y)
                                line.Color = Options.SkeletonColor.Value
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                else
                    for _, line in pairs(skeletonLines) do line.Visible = false end
                end

            else
                HideAll()
                if objects.OOF.Visible then objects.OOF.Visible = true end -- Keep OOF if active
            end

            -- Chams
            if Toggles.Chams_Enabled and Toggles.Chams_Enabled.Value then
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

    local PhaseGroup = MoveTab:AddLeftGroupbox("Phase")
    PhaseGroup:AddToggle("Phase_Enabled", { Text = "Phase (Noclip)" }):AddKeyPicker("PhaseKey", { Default = "None", Text = "Phase", Mode = "Toggle" })

    local HoverGroup = MoveTab:AddRightGroupbox("Target Hovering")
    HoverGroup:AddToggle("Hover_Enabled", { Text = "Enabled" }):AddKeyPicker("HoverKey", { Default = "None", Text = "Hover", Mode = "Toggle" })
    HoverGroup:AddToggle("Hover_Visuals", { Text = "Show Visuals (3D Ring)" }):AddColorPicker("Hover_RingColor", { Default = Color3.fromRGB(255, 50, 50) })
    HoverGroup:AddSlider("Hover_Offset", { Text = "Height Offset", Default = 15, Min = -50, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Radius", { Text = "Radius (Distance)", Default = 20, Min = 5, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Speed", { Text = "Rotation Speed", Default = 30, Min = 1, Max = 120, Rounding = 0, Suffix = " RPM" })

    -- 3D Circle Cache
    local HoverRingCache = {}
    for i = 1, 32 do
        table.insert(HoverRingCache, DrawingHandler:Line({Thickness = 1, Visible = false}))
    end

    -- Phase Loop
    RunService.Stepped:Connect(function()
        if Toggles.Phase_Enabled.Value and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if not char or not hrp or not hum then return end

        if Toggles.Speed_Enabled.Value then
            local moveDir = hum.MoveDirection
            if Options.Speed_Mode.Value == "Velocity" then
                if moveDir.Magnitude > 0 then
                    hrp.Velocity = Vector3.new(moveDir.X * Options.Speed_Value.Value, hrp.Velocity.Y, moveDir.Z * Options.Speed_Value.Value)
                end
            elseif Options.Speed_Mode.Value == "CFrame" then
                if moveDir.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (moveDir * (Options.Speed_Value.Value * dt))
                end
            end
        end

        if Toggles.Fly_Enabled.Value then
            local camCF = Camera.CFrame
            local speed = Options.Fly_Speed.Value
            local velocity = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity = velocity - Vector3.new(0, 1, 0) end

            if Options.Fly_Mode.Value == "Velocity" then
                hrp.Velocity = velocity * speed
                local bv = hrp:FindFirstChild("ArcaneFlyVelocity") or Instance.new("BodyVelocity")
                bv.Name = "ArcaneFlyVelocity"
                bv.Parent = hrp
                bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bv.Velocity = velocity * speed
            elseif Options.Fly_Mode.Value == "CFrame" then
                local bv = hrp:FindFirstChild("ArcaneFlyVelocity")
                if bv then bv:Destroy() end
                
                -- Standard CFrame Fly Logic
                hrp.Anchored = true
                if velocity.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (velocity * (speed * dt))
                end
            end
        else
            local bv = hrp and hrp:FindFirstChild("ArcaneFlyVelocity")
            if bv then bv:Destroy() end
            if Options.Fly_Mode.Value == "CFrame" and hrp then
                 hrp.Anchored = false
            end
        end

        if Toggles.Hover_Enabled.Value then
            local target = nil
            local minDist = math.huge
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not IsSameTeam(p) then
                    local pch = p.Character
                    local phrp = pch and pch:FindFirstChild("HumanoidRootPart")
                    local phum = pch and pch:FindFirstChild("Humanoid")
                    
                    if phrp and phum and phum.Health > 0 then
                        local d = (hrp.Position - phrp.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            target = phrp
                        end
                    end
                end
            end

            if target then
                local rpm = Options.Hover_Speed.Value
                local theta = tick() * (rpm / 60) * (math.pi * 2) 
                local radius = Options.Hover_Radius.Value
                local height = Options.Hover_Offset.Value
                
                local offsetX = math.cos(theta) * radius
                local offsetZ = math.sin(theta) * radius
                local targetPos = target.Position + Vector3.new(offsetX, height, offsetZ)
                
                hrp.CFrame = CFrame.lookAt(targetPos, target.Position)
                hrp.Velocity = Vector3.zero 
                hrp.RotVelocity = Vector3.zero

                if Toggles.Hover_Visuals.Value then
                    local center = target.Position
                    local segments = #HoverRingCache
                    
                    for i = 1, segments do
                        local line = HoverRingCache[i]
                        local a1 = (i / segments) * (math.pi * 2)
                        local a2 = ((i + 1) / segments) * (math.pi * 2)
                        
                        local h = height
                        local p1 = center + Vector3.new(math.cos(a1)*radius, h, math.sin(a1)*radius)
                        local p2 = center + Vector3.new(math.cos(a2)*radius, h, math.sin(a2)*radius)
                        
                        local v1, vis1 = Camera:WorldToViewportPoint(p1)
                        local v2, vis2 = Camera:WorldToViewportPoint(p2)
                        
                        if vis1 and vis2 then
                            line.Visible = true
                            line.From = Vector2.new(v1.X, v1.Y)
                            line.To = Vector2.new(v2.X, v2.Y)
                            line.Color = Options.Hover_RingColor.Value
                        else
                            line.Visible = false
                        end
                    end
                else
                    for _, line in ipairs(HoverRingCache) do line.Visible = false end
                end
            else
                for _, line in ipairs(HoverRingCache) do line.Visible = false end
            end
        else
            for _, line in ipairs(HoverRingCache) do line.Visible = false end
        end
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

function UI:Notify(text, time)
    Library:Notify(text, time or 5)
end

return UI
