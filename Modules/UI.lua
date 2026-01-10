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
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
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
                HealthBg = DrawingHandler:Line({ Thickness = 2, Color = Color3.new(0,0,0), Visible = false }),
                Tracer = DrawingHandler:Line({ Thickness = 1, Visible = false }),
                OOF = DrawingHandler:Triangle({ Thickness = 1, Filled = true, Visible = false })
            },
            Skeleton = {},
            Highlight = highlight
        }

        for i = 1, 14 do
            table.insert(self.ESP_Cache[player].Skeleton, DrawingHandler:Line({ Thickness = 1, Visible = false, Color = Color3.new(1,1,1) }))
        end
    end

    Players.PlayerAdded:Connect(CreatePlayerESP)
    Players.PlayerRemoving:Connect(RemovePlayerESP)
    for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end

    RunService.RenderStepped:Connect(function()
        local enabled = Toggles.Esp_Enabled and Toggles.Esp_Enabled.Value
        
        for player, cache in pairs(self.ESP_Cache) do
            local objects = cache.Drawings
            local skeletonLines = cache.Skeleton
            local highlight = cache.Highlight

            if not enabled then 
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
                continue 
            end

            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not char or not hrp or not hum or hum.Health <= 0 or (Toggles.Esp_TeamCheck.Value and IsSameTeam(player)) then
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
                continue
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if Toggles.Esp_DistLimitEnabled.Value and dist > Options.Esp_MaxDist.Value then
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
                continue
            end

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
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
                local head = char:FindFirstChild("Head") or hrp
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                local h = math.abs(headPos.Y - legPos.Y)
                local w = h * 0.6
                local boxPos = Vector2.new(pos.X - w/2, pos.Y - h/2)

                if Toggles.Esp_Box.Value then
                    objects.Box.Visible = true
                    objects.Box.Position = boxPos
                    objects.Box.Size = Vector2.new(w, h)
                    objects.Box.Color = Options.BoxColor.Value
                    
                    objects.BoxOutline.Visible = true
                    objects.BoxOutline.Position = boxPos
                    objects.BoxOutline.Size = Vector2.new(w, h)

                    if Toggles.Esp_BoxFill.Value then
                        objects.BoxFilled.Visible = true
                        objects.BoxFilled.Position = boxPos
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

                if Toggles.Esp_Name.Value then
                    objects.Name.Visible = true
                    objects.Name.Position = Vector2.new(pos.X, boxPos.Y - 15)
                    objects.Name.Text = player.Name
                    objects.Name.Color = Options.NameColor.Value
                else
                    objects.Name.Visible = false
                end

                if Toggles.Esp_Distance.Value then
                    objects.Distance.Visible = true
                    objects.Distance.Position = Vector2.new(pos.X, boxPos.Y + h + 2)
                    objects.Distance.Text = math.floor(dist) .. "m"
                    objects.Distance.Color = Options.DistanceColor.Value
                else
                    objects.Distance.Visible = false
                end

                if Toggles.Esp_HealthBar.Value then
                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = h * hpPercent
                    
                    objects.HealthBg.Visible = true
                    objects.HealthBg.From = Vector2.new(boxPos.X - 5, boxPos.Y)
                    objects.HealthBg.To = Vector2.new(boxPos.X - 5, boxPos.Y + h)
                    
                    objects.HealthBar.Visible = true
                    objects.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + h)
                    objects.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + h - barHeight)
                    objects.HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hpPercent)
                else
                    objects.HealthBar.Visible = false
                    objects.HealthBg.Visible = false
                end

                if Toggles.Esp_Tracers.Value then
                    local originY = (Options.Tracer_Origin.Value == "Top" and 0) or (Options.Tracer_Origin.Value == "Center" and viewportSize.Y / 2) or viewportSize.Y
                    objects.Tracer.Visible = true
                    objects.Tracer.From = Vector2.new(viewportSize.X / 2, originY)
                    objects.Tracer.To = Vector2.new(pos.X, pos.Y + h/2)
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
                for _, obj in pairs(objects) do 
                    if obj ~= objects.OOF then obj.Visible = false end
                end
                for _, line in pairs(skeletonLines) do line.Visible = false end
            end

            -- Safe Check for Chams
            if Toggles.Chams_Enabled and Toggles.Chams_Enabled.Value then
                if highlight.Parent ~= CoreGui then
                    highlight.Parent = CoreGui
                end
                highlight.Adornee = char
                highlight.Enabled = true
                
                if Toggles.Chams_Fill and Toggles.Chams_Fill.Value and Options.ChamsFillColor then
                    highlight.FillColor = Options.ChamsFillColor.Value
                    highlight.FillTransparency = Options.ChamsFillColor.Transparency
                else
                    highlight.FillTransparency = 1
                end
                
                if Toggles.Chams_Outline and Toggles.Chams_Outline.Value and Options.ChamsOutlineColor then
                    highlight.OutlineColor = Options.ChamsOutlineColor.Value
                    highlight.OutlineTransparency = Options.ChamsOutlineColor.Transparency
                else
                    highlight.OutlineTransparency = 1
                end
                
                if Toggles.Chams_Occluded and Toggles.Chams_Occluded.Value then
                    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                else
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
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
    HoverGroup:AddToggle("Hover_Visuals", { Text = "Show Visuals (3D Ring)" }):AddColorPicker("Hover_RingColor", { Default = Color3.fromRGB(255, 50, 50) })
    HoverGroup:AddSlider("Hover_Offset", { Text = "Height Offset", Default = 15, Min = -50, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Radius", { Text = "Radius (Distance)", Default = 20, Min = 5, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Speed", { Text = "Rotation Speed", Default = 30, Min = 1, Max = 120, Rounding = 0, Suffix = " RPM" })

    -- 3D Circle Cache
    local HoverRingCache = {}
    for i = 1, 32 do
        table.insert(HoverRingCache, DrawingHandler:Line({Thickness = 1, Visible = false}))
    end

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

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                velocity = velocity + camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                velocity = velocity - camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                velocity = velocity - camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                velocity = velocity + camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                velocity = velocity - Vector3.new(0, 1, 0)
            end

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
                
                hrp.Anchored = true
                hrp.CFrame = hrp.CFrame + (velocity * (speed * dt))
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
                -- Calculation (RPM to Angular)
                local rpm = Options.Hover_Speed.Value
                local theta = tick() * (rpm / 60) * (math.pi * 2) 
                local radius = Options.Hover_Radius.Value
                local height = Options.Hover_Offset.Value
                
                -- Position Calculation
                local offsetX = math.cos(theta) * radius
                local offsetZ = math.sin(theta) * radius
                local targetPos = target.Position + Vector3.new(offsetX, height, offsetZ)
                
                -- Apply Movement (CFrame based, looking at target)
                hrp.CFrame = CFrame.lookAt(targetPos, target.Position)
                hrp.Velocity = Vector3.zero 
                hrp.RotVelocity = Vector3.zero

                -- 3D Ring Visuals
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
