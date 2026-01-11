local UI = {}
UI.__index = UI

-- Resources
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaSecurity/ArcaneRivals/refs/heads/main/Modules/Resources/UiLibrary.lua"))({cheatname = "Arcane", gamename = "Rivals"})
library:init()

local DrawingAPIClass = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaSecurity/ArcaneRivals/refs/heads/main/Modules/Drawing.lua"))()
local DrawingHandler = DrawingAPIClass.new()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Local State to mirror Linoria behavior for logic compatibility
local Toggles = {}
local Options = {}

function UI.new(title)
    local self = setmetatable({}, UI)
    
    self.Window = library.NewWindow({
        title = title or "Arcane Rivals", 
        size = UDim2.new(0, 550, 0.7, 20)
    })

    self.Tabs = {}
    self.ESP_Cache = {}
    
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
    local MainSec = VisualsTab:AddSection("ESP Main", 1)
    local ChamsSec = VisualsTab:AddSection("Chams", 1)
    local TracerSec = VisualsTab:AddSection("Bullet Effects", 2)
    local ExtrasSec = VisualsTab:AddSection("Visuals Extras", 2)

    -- ESP Main
    MainSec:AddToggle({text = "Enabled", flag = "Esp_Enabled", callback = function(v) Toggles.Esp_Enabled = {Value = v} end})
    MainSec:AddToggle({text = "Team Check", flag = "Esp_TeamCheck", callback = function(v) Toggles.Esp_TeamCheck = {Value = v} end})
    MainSec:AddToggle({text = "Use Distance Limit", flag = "Esp_DistLimitEnabled", callback = function(v) Toggles.Esp_DistLimitEnabled = {Value = v} end})
    MainSec:AddSlider({text = "Max Distance", flag = "Esp_MaxDist", min = 100, max = 5000, increment = 1, callback = function(v) Options.Esp_MaxDist = {Value = v} end})
    
    MainSec:AddSeparator({text = "Elements"})
    MainSec:AddToggle({text = "Box", flag = "Esp_Box", callback = function(v) Toggles.Esp_Box = {Value = v} end})
    MainSec:AddColor({text = "Box Color", flag = "BoxColor", callback = function(v) Options.BoxColor = {Value = v} end})
    
    MainSec:AddToggle({text = "Box Fill", flag = "Esp_BoxFill", callback = function(v) Toggles.Esp_BoxFill = {Value = v} end})
    MainSec:AddColor({text = "Fill Color", flag = "BoxFillColor", callback = function(v) Options.BoxFillColor = {Value = v, Transparency = 0.5} end})
    
    MainSec:AddToggle({text = "Name", flag = "Esp_Name", callback = function(v) Toggles.Esp_Name = {Value = v} end})
    MainSec:AddColor({text = "Name Color", flag = "NameColor", callback = function(v) Options.NameColor = {Value = v} end})
    
    MainSec:AddToggle({text = "Distance", flag = "Esp_Distance", callback = function(v) Toggles.Esp_Distance = {Value = v} end})
    MainSec:AddColor({text = "Distance Color", flag = "DistanceColor", callback = function(v) Options.DistanceColor = {Value = v} end})
    
    MainSec:AddToggle({text = "Health Bar", flag = "Esp_HealthBar", callback = function(v) Toggles.Esp_HealthBar = {Value = v} end})
    MainSec:AddToggle({text = "Skeleton", flag = "Esp_Skeleton", callback = function(v) Toggles.Esp_Skeleton = {Value = v} end})
    MainSec:AddColor({text = "Skeleton Color", flag = "SkeletonColor", callback = function(v) Options.SkeletonColor = {Value = v} end})

    -- Chams
    ChamsSec:AddToggle({text = "Enabled", flag = "Chams_Enabled", callback = function(v) Toggles.Chams_Enabled = {Value = v} end})
    ChamsSec:AddToggle({text = "Fill", flag = "Chams_Fill", callback = function(v) Toggles.Chams_Fill = {Value = v} end})
    ChamsSec:AddColor({text = "Fill Color", flag = "ChamsFillColor", callback = function(v) Options.ChamsFillColor = {Value = v, Transparency = 0.5} end})
    ChamsSec:AddToggle({text = "Outline", flag = "Chams_Outline", callback = function(v) Toggles.Chams_Outline = {Value = v} end})
    ChamsSec:AddColor({text = "Outline Color", flag = "ChamsOutlineColor", callback = function(v) Options.ChamsOutlineColor = {Value = v, Transparency = 0} end})
    ChamsSec:AddToggle({text = "Visible Check", flag = "Chams_Occluded", callback = function(v) Toggles.Chams_Occluded = {Value = v} end})

    -- Bullet Effects
    TracerSec:AddToggle({text = "Bullet Tracers", flag = "CustomTracers", callback = function(v) Toggles.CustomTracers = {Value = v} end})
    TracerSec:AddColor({text = "Tracer Color", flag = "Tracer_Color", callback = function(v) Options.Tracer_Color = {Value = v} end})
    TracerSec:AddSlider({text = "Thickness", flag = "Tracer_Thickness", min = 0.01, max = 0.5, increment = 0.01, callback = function(v) Options.Tracer_Thickness = {Value = v} end})
    TracerSec:AddSlider({text = "Lifetime", flag = "Tracer_Duration", min = 0.1, max = 5, increment = 0.1, callback = function(v) Options.Tracer_Duration = {Value = v} end})

    -- Visuals Extras
    ExtrasSec:AddToggle({text = "Tracers", flag = "Esp_Tracers", callback = function(v) Toggles.Esp_Tracers = {Value = v} end})
    ExtrasSec:AddColor({text = "Tracer Color", flag = "TracerColor", callback = function(v) Options.TracerColor = {Value = v} end})
    ExtrasSec:AddList({text = "Line Origin", flag = "Tracer_Origin", values = {"Top", "Center", "Bottom"}, callback = function(v) Options.Tracer_Origin = {Value = v} end})
    ExtrasSec:AddSeparator({text = "OOF"})
    ExtrasSec:AddToggle({text = "Off-Screen Indicators", flag = "Esp_OOF", callback = function(v) Toggles.Esp_OOF = {Value = v} end})
    ExtrasSec:AddColor({text = "OOF Color", flag = "OOFColor", callback = function(v) Options.OOFColor = {Value = v} end})
    ExtrasSec:AddSlider({text = "OOF Radius", flag = "OOF_Radius", min = 50, max = 600, increment = 1, callback = function(v) Options.OOF_Radius = {Value = v} end})
    ExtrasSec:AddSlider({text = "OOF Size", flag = "OOF_Size", min = 5, max = 50, increment = 1, callback = function(v) Options.OOF_Size = {Value = v} end})

    local skeletonLinks = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
    }

    local function RemovePlayerESP(player)
        if self.ESP_Cache[player] then
            for _, obj in pairs(self.ESP_Cache[player].Drawings) do if obj.Remove then obj:Remove() end end
            for _, line in pairs(self.ESP_Cache[player].Skeleton) do if line.Remove then line:Remove() end end
            if self.ESP_Cache[player].Highlight then self.ESP_Cache[player].Highlight:Destroy() end
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

        self.ESP_Cache[player] = {
            Drawings = {
                BoxFilled = DrawingHandler:Square({ Thickness = 1, Filled = true, Visible = false }),
                Box = DrawingHandler:Square({ Thickness = 1, Visible = false }),
                BoxOutline = DrawingHandler:Square({ Thickness = 3, Color = Color3.new(0,0,0), Visible = false }),
                Name = DrawingHandler:Text({ Size = 14, Center = true, Outline = true, Visible = false }),
                Distance = DrawingHandler:Text({ Size = 13, Center = true, Outline = true, Visible = false }),
                HealthBg = DrawingHandler:Line({ Thickness = 2.3, Color = Color3.new(0,0,0), Visible = false }),
                HealthBar = DrawingHandler:Line({ Thickness = 2, Visible = false }),
                Tracer = DrawingHandler:Line({ Thickness = 1, Visible = false }),
                OOF = DrawingHandler:Triangle({ Thickness = 1, Filled = true, Visible = false })
            },
            Skeleton = {},
            Highlight = highlight
        }
        for i = 1, 14 do table.insert(self.ESP_Cache[player].Skeleton, DrawingHandler:Line({ Thickness = 1, Visible = false })) end
    end

    Players.PlayerAdded:Connect(CreatePlayerESP)
    Players.PlayerRemoving:Connect(RemovePlayerESP)
    for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end

    RunService.RenderStepped:Connect(function()
        local enabled = Toggles.Esp_Enabled and Toggles.Esp_Enabled.Value
        for player, cache in pairs(self.ESP_Cache) do
            local objects, skeletonLines, highlight = cache.Drawings, cache.Skeleton, cache.Highlight
            if not enabled then 
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
                continue 
            end

            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not char or not hrp or not hum or hum.Health <= 0 or (Toggles.Esp_TeamCheck and Toggles.Esp_TeamCheck.Value and IsSameTeam(player)) then
                for _, obj in pairs(objects) do obj.Visible = false end
                for _, line in pairs(skeletonLines) do line.Visible = false end
                if highlight then highlight.Enabled = false end
                continue
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            if Toggles.Esp_DistLimitEnabled and Toggles.Esp_DistLimitEnabled.Value and dist > (Options.Esp_MaxDist and Options.Esp_MaxDist.Value or 500) then
                for _, obj in pairs(objects) do obj.Visible = false end
                continue
            end

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local viewportSize = Camera.ViewportSize
            local screenCenter = viewportSize / 2

            if Toggles.Esp_OOF and Toggles.Esp_OOF.Value and not onScreen then
                local relativePos = Camera.CFrame:PointToObjectSpace(hrp.Position)
                local angle = math.atan2(relativePos.Y, relativePos.X)
                local radius, size = Options.OOF_Radius.Value, Options.OOF_Size.Value
                local dir = Vector2.new(math.cos(angle), -math.sin(angle))
                local perp = Vector2.new(-dir.Y, dir.X)
                local arrowPos = screenCenter + (dir * radius)
                local basePos = arrowPos - (dir * size)
                objects.OOF.PointA = arrowPos
                objects.OOF.PointB = basePos + (perp * (size * 0.5))
                objects.OOF.PointC = basePos - (perp * (size * 0.5))
                objects.OOF.Color = Options.OOFColor.Value
                objects.OOF.Visible = true
            else objects.OOF.Visible = false end

            if onScreen then
                local head = char:FindFirstChild("Head") or hrp
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local h = math.abs(headPos.Y - legPos.Y)
                local w = h * 0.6
                local boxPos = Vector2.new(pos.X - w/2, pos.Y - h/2)

                if Toggles.Esp_Box and Toggles.Esp_Box.Value then
                    objects.Box.Visible = true; objects.Box.Position = boxPos; objects.Box.Size = Vector2.new(w, h); objects.Box.Color = Options.BoxColor.Value
                    objects.BoxOutline.Visible = true; objects.BoxOutline.Position = boxPos; objects.BoxOutline.Size = Vector2.new(w, h)
                    if Toggles.Esp_BoxFill and Toggles.Esp_BoxFill.Value then
                        objects.BoxFilled.Visible = true; objects.BoxFilled.Position = boxPos; objects.BoxFilled.Size = Vector2.new(w, h)
                        objects.BoxFilled.Color = Options.BoxFillColor.Value; objects.BoxFilled.Transparency = Options.BoxFillColor.Transparency
                    else objects.BoxFilled.Visible = false end
                else objects.Box.Visible = false; objects.BoxOutline.Visible = false; objects.BoxFilled.Visible = false end

                if Toggles.Esp_Name and Toggles.Esp_Name.Value then
                    objects.Name.Visible = true; objects.Name.Position = Vector2.new(pos.X, boxPos.Y - 15); objects.Name.Text = player.Name; objects.Name.Color = Options.NameColor.Value
                else objects.Name.Visible = false end

                if Toggles.Esp_Distance and Toggles.Esp_Distance.Value then
                    objects.Distance.Visible = true; objects.Distance.Position = Vector2.new(pos.X, boxPos.Y + h + 2); objects.Distance.Text = math.floor(dist) .. "m"; objects.Distance.Color = Options.DistanceColor.Value
                else objects.Distance.Visible = false end

                if Toggles.Esp_HealthBar and Toggles.Esp_HealthBar.Value then
                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = h * hpPercent
                    objects.HealthBg.Visible = true; objects.HealthBg.From = Vector2.new(boxPos.X - 5, boxPos.Y); objects.HealthBg.To = Vector2.new(boxPos.X - 5, boxPos.Y + h)
                    objects.HealthBar.Visible = true; objects.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + h); objects.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + h - barHeight)
                    objects.HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hpPercent)
                else objects.HealthBar.Visible = false; objects.HealthBg.Visible = false end

                if Toggles.Esp_Tracers and Toggles.Esp_Tracers.Value then
                    local originY = (Options.Tracer_Origin.Value == "Top" and 0) or (Options.Tracer_Origin.Value == "Center" and viewportSize.Y / 2) or viewportSize.Y
                    objects.Tracer.Visible = true; objects.Tracer.From = Vector2.new(viewportSize.X / 2, originY); objects.Tracer.To = Vector2.new(pos.X, pos.Y + h/2); objects.Tracer.Color = Options.TracerColor.Value
                else objects.Tracer.Visible = false end

                if Toggles.Esp_Skeleton and Toggles.Esp_Skeleton.Value then
                    for i, link in ipairs(skeletonLinks) do
                        local p1, p2, line = char:FindFirstChild(link[1]), char:FindFirstChild(link[2]), skeletonLines[i]
                        if p1 and p2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position); local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            if vis1 and vis2 then line.Visible = true; line.From = Vector2.new(pos1.X, pos1.Y); line.To = Vector2.new(pos2.X, pos2.Y); line.Color = Options.SkeletonColor.Value
                            else line.Visible = false end
                        else line.Visible = false end
                    end
                else for _, line in pairs(skeletonLines) do line.Visible = false end end
            else
                for _, obj in pairs(objects) do if obj ~= objects.OOF then obj.Visible = false end end
                for _, line in pairs(skeletonLines) do line.Visible = false end
            end

            if Toggles.Chams_Enabled and Toggles.Chams_Enabled.Value then
                if highlight.Parent ~= CoreGui then highlight.Parent = CoreGui end
                highlight.Adornee = char; highlight.Enabled = true
                highlight.FillTransparency = (Toggles.Chams_Fill and Toggles.Chams_Fill.Value) and Options.ChamsFillColor.Transparency or 1
                highlight.FillColor = Options.ChamsFillColor.Value
                highlight.OutlineTransparency = (Toggles.Chams_Outline and Toggles.Chams_Outline.Value) and Options.ChamsOutlineColor.Transparency or 1
                highlight.OutlineColor = Options.ChamsOutlineColor.Value
                highlight.DepthMode = (Toggles.Chams_Occluded and Toggles.Chams_Occluded.Value) and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            else highlight.Enabled = false end
        end
    end)
end

function UI:SetupMovement()
    local MoveTab = self:CreateTab("Movement")
    local SpeedSec = MoveTab:AddSection("Speed", 1)
    local FlySec = MoveTab:AddSection("Fly", 1)
    local HoverSec = MoveTab:AddSection("Target Hovering", 2)

    SpeedSec:AddToggle({text = "Enabled", flag = "Speed_Enabled", callback = function(v) Toggles.Speed_Enabled = {Value = v} end})
    SpeedSec:AddBind({text = "Speed Key", flag = "SpeedKey", callback = function() Toggles.Speed_Enabled.Value = not Toggles.Speed_Enabled.Value end})
    SpeedSec:AddList({text = "Mode", flag = "Speed_Mode", values = {"Velocity", "CFrame"}, callback = function(v) Options.Speed_Mode = {Value = v} end})
    SpeedSec:AddSlider({text = "Speed", flag = "Speed_Value", min = 16, max = 200, increment = 1, callback = function(v) Options.Speed_Value = {Value = v} end})

    FlySec:AddToggle({text = "Enabled", flag = "Fly_Enabled", callback = function(v) Toggles.Fly_Enabled = {Value = v} end})
    FlySec:AddBind({text = "Fly Key", flag = "FlyKey", callback = function() Toggles.Fly_Enabled.Value = not Toggles.Fly_Enabled.Value end})
    FlySec:AddList({text = "Mode", flag = "Fly_Mode", values = {"Velocity", "CFrame"}, callback = function(v) Options.Fly_Mode = {Value = v} end})
    FlySec:AddSlider({text = "Speed", flag = "Fly_Speed", min = 10, max = 200, increment = 1, callback = function(v) Options.Fly_Speed = {Value = v} end})

    HoverSec:AddToggle({text = "Enabled", flag = "Hover_Enabled", callback = function(v) Toggles.Hover_Enabled = {Value = v} end})
    HoverSec:AddToggle({text = "Ring", flag = "Hover_Visuals", callback = function(v) Toggles.Hover_Visuals = {Value = v} end})
    HoverSec:AddColor({text = "Ring Color", flag = "Hover_RingColor", callback = function(v) Options.Hover_RingColor = {Value = v} end})
    HoverSec:AddSlider({text = "Height Offset", flag = "Hover_Offset", min = -50, max = 50, increment = 1, callback = function(v) Options.Hover_Offset = {Value = v} end})
    HoverSec:AddSlider({text = "Radius", flag = "Hover_Radius", min = 5, max = 50, increment = 1, callback = function(v) Options.Hover_Radius = {Value = v} end})
    HoverSec:AddSlider({text = "Rotation Speed", flag = "Hover_Speed", min = 1, max = 120, increment = 1, callback = function(v) Options.Hover_Speed = {Value = v} end})

    local HoverRingCache = {}
    for i = 1, 32 do table.insert(HoverRingCache, DrawingHandler:Line({Thickness = 1, Visible = false})) end

    RunService.Heartbeat:Connect(function(dt)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not char or not hrp or not hum then return end

        if Toggles.Speed_Enabled and Toggles.Speed_Enabled.Value then
            local moveDir = hum.MoveDirection
            if Options.Speed_Mode.Value == "Velocity" then
                if moveDir.Magnitude > 0 then hrp.Velocity = Vector3.new(moveDir.X * Options.Speed_Value.Value, hrp.Velocity.Y, moveDir.Z * Options.Speed_Value.Value) end
            elseif Options.Speed_Mode.Value == "CFrame" then
                if moveDir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (moveDir * (Options.Speed_Value.Value * dt)) end
            end
        end

        if Toggles.Fly_Enabled and Toggles.Fly_Enabled.Value then
            local speed, velocity = Options.Fly_Speed.Value, Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity -= Vector3.new(0, 1, 0) end

            if Options.Fly_Mode.Value == "Velocity" then
                local bv = hrp:FindFirstChild("ArcaneFlyVelocity") or Instance.new("BodyVelocity", hrp)
                bv.Name = "ArcaneFlyVelocity"; bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Velocity = velocity * speed
            else
                local bv = hrp:FindFirstChild("ArcaneFlyVelocity"); if bv then bv:Destroy() end
                hrp.Anchored = true; hrp.CFrame += (velocity * (speed * dt))
            end
        else
            local bv = hrp:FindFirstChild("ArcaneFlyVelocity"); if bv then bv:Destroy() end
            if Options.Fly_Mode and Options.Fly_Mode.Value == "CFrame" then hrp.Anchored = false end
        end

        if Toggles.Hover_Enabled and Toggles.Hover_Enabled.Value then
            local target, minDist = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not IsSameTeam(p) then
                    local pch = p.Character; local phrp = pch and pch:FindFirstChild("HumanoidRootPart"); local phum = pch and pch:FindFirstChild("Humanoid")
                    if phrp and phum and phum.Health > 0 then
                        local d = (hrp.Position - phrp.Position).Magnitude
                        if d < minDist then minDist = d; target = phrp end
                    end
                end
            end
            if target then
                local theta = tick() * (Options.Hover_Speed.Value / 60) * (math.pi * 2) 
                local targetPos = target.Position + Vector3.new(math.cos(theta) * Options.Hover_Radius.Value, Options.Hover_Offset.Value, math.sin(theta) * Options.Hover_Radius.Value)
                hrp.CFrame = CFrame.lookAt(targetPos, target.Position)
                hrp.Velocity = Vector3.zero; hrp.RotVelocity = Vector3.zero
                if Toggles.Hover_Visuals.Value then
                    local segments = #HoverRingCache
                    for i = 1, segments do
                        local line, a1, a2 = HoverRingCache[i], (i/segments)*(math.pi*2), ((i+1)/segments)*(math.pi*2)
                        local p1 = target.Position + Vector3.new(math.cos(a1)*Options.Hover_Radius.Value, Options.Hover_Offset.Value, math.sin(a1)*Options.Hover_Radius.Value)
                        local p2 = target.Position + Vector3.new(math.cos(a2)*Options.Hover_Radius.Value, Options.Hover_Offset.Value, math.sin(a2)*Options.Hover_Radius.Value)
                        local v1, vis1 = Camera:WorldToViewportPoint(p1); local v2, vis2 = Camera:WorldToViewportPoint(p2)
                        if vis1 and vis2 then line.Visible = true; line.From = Vector2.new(v1.X, v1.Y); line.To = Vector2.new(v2.X, v2.Y); line.Color = Options.Hover_RingColor.Value
                        else line.Visible = false end
                    end
                else for _, line in ipairs(HoverRingCache) do line.Visible = false end end
            else for _, line in ipairs(HoverRingCache) do line.Visible = false end end
        else for _, line in ipairs(HoverRingCache) do line.Visible = false end end
    end)
end

function UI:SetupSettings(folder, tabName)
    local SettingsTab = library:CreateSettingsTab(self.Window)
    local menuSec = SettingsTab:AddSection("Menu", 1)
    
    menuSec:AddButton({text = "Unload", callback = function() 
        -- Logic to cleanup drawings and unload
        library:SendNotification("Unloading...", 3)
    end})
end

function UI:Notify(text, time)
    library:SendNotification(text, time or 5)
end

return UI
