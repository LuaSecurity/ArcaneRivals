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
        Title = title or "Arcane Remastered",
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

-- Helper to calculate corners of a CFrame + Size
local function GetCorners(cf, size)
    local corners = {}
    local x, y, z = size.X / 2, size.Y / 2, size.Z / 2
    local factors = {
        Vector3.new(-x, -y, -z), Vector3.new(-x, -y, z), Vector3.new(-x, y, -z), Vector3.new(-x, y, z),
        Vector3.new(x, -y, -z), Vector3.new(x, -y, z), Vector3.new(x, y, -z), Vector3.new(x, y, z)
    }
    for _, factor in ipairs(factors) do
        table.insert(corners, (cf * CFrame.new(factor)).Position)
    end
    return corners
end

function UI:SetupVisuals()
    local VisualsTab = self:CreateTab("Visuals")
    
    local EspGroup = VisualsTab:AddLeftGroupbox("ESP Main")
    EspGroup:AddToggle("Esp_Enabled", { Text = "Enabled", Default = false })
    EspGroup:AddToggle("Esp_TeamCheck", { Text = "Team Check", Default = true })
    EspGroup:AddSlider("Esp_MaxDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0 })
    EspGroup:AddDivider()
    
    -- BOX SETTINGS
    EspGroup:AddDropdown("Esp_BoxType", { Values = { "2D Box", "Corner Box", "3D Box" }, Default = "2D Box", Text = "Box Type" })
    EspGroup:AddToggle("Esp_Box", { Text = "Draw Box" }):AddColorPicker("BoxColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_BoxFill", { Text = "Box Fill" }):AddColorPicker("BoxFillColor", { Default = Color3.new(1, 0, 0), Transparency = 0.5 })
    
    -- INFO SETTINGS
    EspGroup:AddToggle("Esp_Name", { Text = "Name" }):AddColorPicker("NameColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_Distance", { Text = "Distance" }):AddColorPicker("DistanceColor", { Default = Color3.new(1,1,1) })
    EspGroup:AddToggle("Esp_HealthBar", { Text = "Health Bar" }):AddColorPicker("HealthBarColor", { Default = Color3.fromRGB(0, 255, 0) })
    EspGroup:AddToggle("Esp_Skeleton", { Text = "Skeleton" }):AddColorPicker("SkeletonColor", { Default = Color3.new(1,1,1) })

    local ChamsGroup = VisualsTab:AddLeftGroupbox("Chams")
    ChamsGroup:AddToggle("Chams_Enabled", { Text = "Enabled" })
    ChamsGroup:AddToggle("Chams_Fill", { Text = "Fill" }):AddColorPicker("ChamsFillColor", { Default = Color3.fromRGB(150, 0, 0), Transparency = 0.5 })
    ChamsGroup:AddToggle("Chams_Outline", { Text = "Outline" }):AddColorPicker("ChamsOutlineColor", { Default = Color3.fromRGB(255, 0, 0), Transparency = 0 })
    ChamsGroup:AddToggle("Chams_Occluded", { Text = "Visible Check", Default = true })

    local MiscVisuals = VisualsTab:AddRightGroupbox("Visuals Extras")
    MiscVisuals:AddToggle("Esp_Tracers", { Text = "Tracers" }):AddColorPicker("TracerColor", { Default = Color3.new(1,1,1) })
    MiscVisuals:AddDropdown("Tracer_Origin", { Text = "Line Origin", Default = "Bottom", Values = {"Top", "Center", "Bottom"} })
    MiscVisuals:AddDivider()
    MiscVisuals:AddToggle("Esp_OOF", { Text = "Off-Screen Indicators" }):AddColorPicker("OOFColor", { Default = Color3.new(1,1,1) })
    MiscVisuals:AddSlider("OOF_Radius", { Text = "OOF Radius", Default = 200, Min = 50, Max = 600, Rounding = 0 })

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
                if type(obj) == "table" and obj.Remove then obj:Remove() end
            end
            if self.ESP_Cache[player].Box3D then
                for _, line in pairs(self.ESP_Cache[player].Box3D) do line:Remove() end
            end
            if self.ESP_Cache[player].BoxCorners then
                for _, line in pairs(self.ESP_Cache[player].BoxCorners) do line:Remove() end
            end
            for _, line in pairs(self.ESP_Cache[player].Skeleton) do line:Remove() end
            
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
            Box3D = {},
            BoxCorners = {},
            Skeleton = {},
            Highlight = highlight
        }

        -- Pre-create 12 lines for 3D box
        for i = 1, 12 do table.insert(self.ESP_Cache[player].Box3D, DrawingHandler:Line({ Thickness = 1, Visible = false })) end
        
        -- Pre-create 8 lines for Corner Box (4 corners x 2 lines each)
        for i = 1, 8 do table.insert(self.ESP_Cache[player].BoxCorners, DrawingHandler:Line({ Thickness = 1, Visible = false })) end

        -- Pre-create skeleton lines
        for i = 1, 14 do table.insert(self.ESP_Cache[player].Skeleton, DrawingHandler:Line({ Thickness = 1, Visible = false, Color = Color3.new(1,1,1) })) end
    end

    Players.PlayerAdded:Connect(CreatePlayerESP)
    Players.PlayerRemoving:Connect(RemovePlayerESP)
    for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end

    RunService.RenderStepped:Connect(function()
        local enabled = Toggles.Esp_Enabled and Toggles.Esp_Enabled.Value
        
        for player, cache in pairs(self.ESP_Cache) do
            local objects = cache.Drawings
            local lines3d = cache.Box3D
            local corners2d = cache.BoxCorners
            local skeletonLines = cache.Skeleton
            local highlight = cache.Highlight

            -- Cleanup function to hide everything for this player
            local function hideAll()
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(lines3d) do line.Visible = false end
                for _, line in pairs(corners2d) do line.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
            end

            if not enabled then hideAll() continue end

            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not char or not hrp or not hum or hum.Health <= 0 or (Toggles.Esp_TeamCheck.Value and IsSameTeam(player)) then
                hideAll()
                continue
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if dist > Options.Esp_MaxDist.Value then
                hideAll()
                continue
            end

            local _, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local viewportSize = Camera.ViewportSize
            local screenCenter = viewportSize / 2

            -- Off Screen Indicators
            if Toggles.Esp_OOF.Value and not onScreen then
                local relativePos = Camera.CFrame:PointToObjectSpace(hrp.Position)
                local angle = math.atan2(relativePos.Y, relativePos.X)
                local radius = Options.OOF_Radius.Value
                local size = 15 -- standard size
                
                local dir = Vector2.new(math.cos(angle), -math.sin(angle))
                local perp = Vector2.new(-dir.Y, dir.X)
                local arrowPos = screenCenter + (dir * radius)
                local basePos = arrowPos - (dir * size)
                
                objects.OOF.PointA = arrowPos
                objects.OOF.PointB = basePos + (perp * (size * 0.5))
                objects.OOF.PointC = basePos - (perp * (size * 0.5))
                objects.OOF.Color = Options.OOFColor.Value
                objects.OOF.Visible = true
                
                -- Hide everything else
                for k, v in pairs(objects) do if k ~= "OOF" then v.Visible = false end end
                for _, l in pairs(lines3d) do l.Visible = false end
                for _, l in pairs(corners2d) do l.Visible = false end
                for _, l in pairs(skeletonLines) do l.Visible = false end
                if highlight then highlight.Enabled = false end
                continue
            else
                objects.OOF.Visible = false
            end

            -- Main ESP Calculation
            local cf, size = char:GetBoundingBox()
            local corners = GetCorners(cf, size)
            local screenCorners = {}
            local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
            local allOnScreen = false

            for _, corner in ipairs(corners) do
                local sPos, vis = Camera:WorldToViewportPoint(corner)
                if vis then allOnScreen = true end
                table.insert(screenCorners, Vector2.new(sPos.X, sPos.Y))
                if sPos.X < minX then minX = sPos.X end
                if sPos.Y < minY then minY = sPos.Y end
                if sPos.X > maxX then maxX = sPos.X end
                if sPos.Y > maxY then maxY = sPos.Y end
            end

            -- If totally offscreen despite checks
            if not allOnScreen and not onScreen then 
                hideAll()
                continue
            end

            local boxWidth = maxX - minX
            local boxHeight = maxY - minY
            local boxSize = Vector2.new(boxWidth, boxHeight)
            local boxPos = Vector2.new(minX, minY)
            
            -- Box Logic
            local boxType = Options.Esp_BoxType.Value
            local showBox = Toggles.Esp_Box.Value

            -- Reset Box Viz
            objects.Box.Visible = false
            objects.BoxOutline.Visible = false
            objects.BoxFilled.Visible = false
            for _, l in pairs(lines3d) do l.Visible = false end
            for _, l in pairs(corners2d) do l.Visible = false end

            if showBox then
                if boxType == "2D Box" then
                    objects.Box.Visible = true
                    objects.Box.Position = boxPos
                    objects.Box.Size = boxSize
                    objects.Box.Color = Options.BoxColor.Value
                    
                    objects.BoxOutline.Visible = true
                    objects.BoxOutline.Position = boxPos
                    objects.BoxOutline.Size = boxSize
                    
                    if Toggles.Esp_BoxFill.Value then
                        objects.BoxFilled.Visible = true
                        objects.BoxFilled.Position = boxPos
                        objects.BoxFilled.Size = boxSize
                        objects.BoxFilled.Color = Options.BoxFillColor.Value
                        objects.BoxFilled.Transparency = Options.BoxFillColor.Transparency
                    end

                elseif boxType == "Corner Box" then
                    local len = boxHeight / 5
                    local c = Options.BoxColor.Value
                    local th = 1
                    
                    -- Top Left
                    corners2d[1].From = Vector2.new(minX, minY); corners2d[1].To = Vector2.new(minX + len, minY); corners2d[1].Visible = true; corners2d[1].Color = c
                    corners2d[2].From = Vector2.new(minX, minY); corners2d[2].To = Vector2.new(minX, minY + len); corners2d[2].Visible = true; corners2d[2].Color = c
                    -- Top Right
                    corners2d[3].From = Vector2.new(maxX, minY); corners2d[3].To = Vector2.new(maxX - len, minY); corners2d[3].Visible = true; corners2d[3].Color = c
                    corners2d[4].From = Vector2.new(maxX, minY); corners2d[4].To = Vector2.new(maxX, minY + len); corners2d[4].Visible = true; corners2d[4].Color = c
                    -- Bottom Left
                    corners2d[5].From = Vector2.new(minX, maxY); corners2d[5].To = Vector2.new(minX + len, maxY); corners2d[5].Visible = true; corners2d[5].Color = c
                    corners2d[6].From = Vector2.new(minX, maxY); corners2d[6].To = Vector2.new(minX, maxY - len); corners2d[6].Visible = true; corners2d[6].Color = c
                    -- Bottom Right
                    corners2d[7].From = Vector2.new(maxX, maxY); corners2d[7].To = Vector2.new(maxX - len, maxY); corners2d[7].Visible = true; corners2d[7].Color = c
                    corners2d[8].From = Vector2.new(maxX, maxY); corners2d[8].To = Vector2.new(maxX, maxY - len); corners2d[8].Visible = true; corners2d[8].Color = c

                elseif boxType == "3D Box" then
                    -- 3D lines connection indices
                    local connections = {
                        {1,2}, {2,4}, {4,3}, {3,1}, -- Top
                        {5,6}, {6,8}, {8,7}, {7,5}, -- Bottom
                        {1,5}, {2,6}, {3,7}, {4,8}  -- Sides
                    }
                    for i, conn in ipairs(connections) do
                        local p1 = screenCorners[conn[1]]
                        local p2 = screenCorners[conn[2]]
                        lines3d[i].Visible = true
                        lines3d[i].From = p1
                        lines3d[i].To = p2
                        lines3d[i].Color = Options.BoxColor.Value
                    end
                end
            end

            -- Health Bar
            if Toggles.Esp_HealthBar.Value then
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barHeight = boxHeight * hpPercent
                
                objects.HealthBar.Visible = true
                objects.HealthBar.From = Vector2.new(minX - 5, maxY)
                objects.HealthBar.To = Vector2.new(minX - 5, maxY - barHeight)
                objects.HealthBar.Color = Options.HealthBarColor.Value
            else
                objects.HealthBar.Visible = false
            end

            -- Name & Distance
            if Toggles.Esp_Name.Value then
                objects.Name.Visible = true
                objects.Name.Position = Vector2.new(minX + (boxWidth/2), minY - 20)
                objects.Name.Text = player.Name
                objects.Name.Color = Options.NameColor.Value
            else
                objects.Name.Visible = false
            end

            if Toggles.Esp_Distance.Value then
                objects.Distance.Visible = true
                objects.Distance.Position = Vector2.new(minX + (boxWidth/2), maxY + 5)
                objects.Distance.Text = math.floor(dist) .. "m"
                objects.Distance.Color = Options.DistanceColor.Value
            else
                objects.Distance.Visible = false
            end

            -- Tracers
            if Toggles.Esp_Tracers.Value then
                local originY = (Options.Tracer_Origin.Value == "Top" and 0) or (Options.Tracer_Origin.Value == "Center" and viewportSize.Y / 2) or viewportSize.Y
                objects.Tracer.Visible = true
                objects.Tracer.From = Vector2.new(viewportSize.X / 2, originY)
                objects.Tracer.To = Vector2.new(minX + (boxWidth/2), maxY)
                objects.Tracer.Color = Options.TracerColor.Value
            else
                objects.Tracer.Visible = false
            end

            -- Skeleton
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

            -- Chams
            if Toggles.Chams_Enabled.Value then
                if highlight.Parent ~= CoreGui then highlight.Parent = CoreGui end
                highlight.Adornee = char
                highlight.Enabled = true
                highlight.FillColor = Options.ChamsFillColor.Value
                highlight.FillTransparency = Options.ChamsFillColor.Transparency
                highlight.OutlineColor = Options.ChamsOutlineColor.Value
                highlight.OutlineTransparency = Options.ChamsOutlineColor.Transparency
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

    local PhaseGroup = MoveTab:AddRightGroupbox("Phase (Noclip)")
    PhaseGroup:AddToggle("Phase_Enabled", { Text = "Enabled" }):AddKeyPicker("PhaseKey", { Default = "None", Text = "Phase", Mode = "Toggle" })
    PhaseGroup:AddLabel("Walk through walls")

    local HoverGroup = MoveTab:AddRightGroupbox("Target Hovering")
    HoverGroup:AddToggle("Hover_Enabled", { Text = "Enabled" }):AddKeyPicker("HoverKey", { Default = "None", Text = "Hover", Mode = "Toggle" })
    HoverGroup:AddToggle("Hover_Visuals", { Text = "Ring" }):AddColorPicker("Hover_RingColor", { Default = Color3.fromRGB(255, 50, 50) })
    HoverGroup:AddSlider("Hover_Offset", { Text = "Height Offset", Default = 15, Min = -50, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Radius", { Text = "Radius", Default = 20, Min = 5, Max = 50, Rounding = 1 })
    HoverGroup:AddSlider("Hover_Speed", { Text = "RPM", Default = 30, Min = 1, Max = 120, Rounding = 0 })

    -- Phase Logic (Stepped for Physics)
    RunService.Stepped:Connect(function()
        if Toggles.Phase_Enabled.Value and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Movement Loop
    RunService.Heartbeat:Connect(function(dt)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if not char or not hrp or not hum then return end

        -- SPEED
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

        -- FLY
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
                
                -- Crucial fix for CFrame fly: kill physics velocity
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
                
                if velocity.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (velocity * (speed * dt))
                end
            end
        else
            local bv = hrp and hrp:FindFirstChild("ArcaneFlyVelocity")
            if bv then bv:Destroy() end
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
