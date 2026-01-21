local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")

local Arcane = {
    Registry = {},
    MenuRegistry = {},
    Notifications = {},
    Config = {
        WindowSize = Vector2.new(450, 500),
        MainColor = Color3.fromRGB(15, 15, 15),
        FrameColor = Color3.fromRGB(20, 20, 20),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        InlineColor = Color3.fromRGB(5, 5, 5),
        AccentColor = Color3.fromRGB(120, 84, 147),
        SelectedColor = Color3.fromRGB(180, 150, 255),
        SecondaryColor = Color3.fromRGB(160, 160, 160),
        Font = 2,
        TextSize = 13
    },
    Settings = {}, 
    Folder = "Arcane_Configs"
}

if not isfolder(Arcane.Folder) then 
    makefolder(Arcane.Folder) 
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function Create(Type, Properties, IsMenu)
    local Obj = Drawing.new(Type)
    for K, V in next, Properties do
        Obj[K] = V
    end
    table.insert(IsMenu and Arcane.MenuRegistry or Arcane.Registry, Obj)
    return Obj
end

function Arcane:ClearMenu()
    for i = #self.MenuRegistry, 1, -1 do
        if self.MenuRegistry[i] then
            self.MenuRegistry[i]:Remove()
            self.MenuRegistry[i] = nil
        end
    end
end

function Arcane:Log(Text, Cooldown)
    local Duration = Cooldown or 3
    local Log = {
        Active = true,
        Alpha = 0,
        TargetAlpha = 1,
        Pos = Vector2.new(-350, -60), 
        TargetPos = Vector2.new(25, 25),
        Text = Text,
        Timer = Duration,
        MaxTimer = Duration
    }

    local Out = Create("Square", {Thickness = 1, Color = self.Config.OutlineColor, Filled = false, ZIndex = 100, Visible = true})
    local Main = Create("Square", {Color = self.Config.MainColor, Filled = true, ZIndex = 99, Visible = true})
    local Accent = Create("Square", {Color = self.Config.AccentColor, Filled = true, ZIndex = 101, Visible = true})
    local Txt = Create("Text", {Text = Text, Size = 14, Font = 2, Color = Color3.fromRGB(230, 230, 230), ZIndex = 102, Visible = true})
    
    local CometSegments = {}
    local SegmentCount = 12
    for i = 1, SegmentCount do
        table.insert(CometSegments, Create("Square", {
            Color = self.Config.AccentColor, 
            Filled = true, 
            ZIndex = 103, 
            Visible = true,
            Transparency = (i / SegmentCount)
        }))
    end

    task.spawn(function()
        while Log.Active do
            local Delta = RunService.RenderStepped:Wait()
            
            Log.Alpha = lerp(Log.Alpha, Log.TargetAlpha, 0.035)
            
            local YOffset = 25
            for i, v in next, Arcane.Notifications do
                if v == Log then break end
                YOffset = YOffset + 42 
            end
            
            if Log.TargetAlpha == 0 then
                Log.TargetPos = Vector2.new(-350, -60)
            else
                Log.TargetPos = Vector2.new(25, YOffset)
            end
            
            Log.Pos = Log.Pos:Lerp(Log.TargetPos, 0.045)

            local Width = Txt.TextBounds.X + 45
            local Size = Vector2.new(Width, 34)
            
            Main.Size = Size
            Main.Position = Log.Pos
            Main.Transparency = Log.Alpha
            
            Out.Size = Size
            Out.Position = Log.Pos
            Out.Transparency = Log.Alpha

            Accent.Size = Vector2.new(2.5, Size.Y)
            Accent.Position = Log.Pos
            Accent.Transparency = Log.Alpha

            Txt.Position = Log.Pos + Vector2.new(15, 10)
            Txt.Transparency = Log.Alpha

            local Progress = math.clamp(1 - (Log.Timer / Log.MaxTimer), 0, 1)
            local BarTravelWidth = Width * Progress
            local SegmentWidth = 3
            
            for i, Seg in next, CometSegments do
                Seg.Size = Vector2.new(SegmentWidth, 2)
                Seg.Position = Log.Pos + Vector2.new(BarTravelWidth - (SegmentWidth * (SegmentCount - i)), Size.Y - 2)
                
                if Seg.Position.X < Log.Pos.X then
                    Seg.Visible = false
                else
                    Seg.Visible = true
                    Seg.Transparency = (i / SegmentCount) * Log.Alpha
                end
            end

            if Log.TargetAlpha == 1 then
                Log.Timer = Log.Timer - Delta
                if Log.Timer <= 0 then Log.TargetAlpha = 0 end
            elseif Log.Alpha < 0.01 then
                Log.Active = false
            end
        end
        
        Main:Remove(); Out:Remove(); Accent:Remove(); Txt:Remove()
        for _, Seg in next, CometSegments do Seg:Remove() end
        for i, v in next, Arcane.Notifications do
            if v == Log then table.remove(Arcane.Notifications, i) break end
        end
    end)
    table.insert(Arcane.Notifications, Log)
end

function Arcane:CreateWindow(Title)
    local Viewport = workspace.CurrentCamera.ViewportSize
    local Pos = (Viewport / 2) - (self.Config.WindowSize / 2)
    
    local Window = {
        BasePos = Pos,
        Size = self.Config.WindowSize,
        Tabs = {},
        Visible = true,
        ToggleKey = Enum.KeyCode.RightControl,
        IsBinding = false,
        TabAlignment = "TopRight",
        SelectedTab = nil,
        Dragging = false,
        DragStart = nil,
        StartPos = nil,
        ScrollOffset = 0,
        Elements = {},
        ContextMenu = {
            Open = false,
            Pos = Vector2.new(0,0),
            Size = Vector2.new(0,0),
            TargetSize = Vector2.new(0,0),
            Alpha = 0
        },
        AnimData = {
            TabPositions = {},
            LerpSpeed = 0.15,
            ContentRelativePos = Vector2.new(10, 55),
            NavLineRelativePos = Vector2.new(10, 26)
        },
        ActiveTextbox = nil
    }

    Window.Elements.Out1 = Create("Square", {Position = Pos - Vector2.new(1, 1), Size = Window.Size + Vector2.new(2, 2), Color = self.Config.InlineColor, Filled = false, Thickness = 1, Visible = true, ZIndex = 1})
    Window.Elements.Out2 = Create("Square", {Position = Pos, Size = Window.Size, Color = self.Config.OutlineColor, Filled = false, Thickness = 1, Visible = true, ZIndex = 2})
    Window.Elements.Main = Create("Square", {Position = Pos + Vector2.new(1, 1), Size = Window.Size - Vector2.new(2, 2), Color = self.Config.MainColor, Filled = true, Visible = true, ZIndex = 3})
    Window.Elements.HeaderT = Create("Text", {Text = Title, Color = self.Config.AccentColor, Size = self.Config.TextSize, Font = self.Config.Font, Visible = true, ZIndex = 4})
    Window.Elements.HeaderWtf = Create("Text", {Text = ".wtf", Color = Color3.fromRGB(255, 255, 255), Size = self.Config.TextSize, Font = self.Config.Font, Visible = true, ZIndex = 4})
    Window.Elements.NavLine = Create("Square", {Size = Vector2.new(Window.Size.X - 20, 1), Color = self.Config.OutlineColor, Filled = true, Visible = true, ZIndex = 4})
    Window.Elements.ContentFrame = Create("Square", {Size = Window.Size - Vector2.new(20, 65), Color = self.Config.FrameColor, Filled = true, Visible = true, ZIndex = 4})
    Window.Elements.ContentOutline = Create("Square", {Size = Window.Elements.ContentFrame.Size + Vector2.new(2, 2), Color = self.Config.OutlineColor, Filled = false, Thickness = 1, Visible = true, ZIndex = 5})
    
    function Window:UpdateLayout()
        if not self.Visible then return end
        
        local ViewportSize = workspace.CurrentCamera.ViewportSize
        local MaxX, MaxY = ViewportSize.X - self.Size.X, ViewportSize.Y - self.Size.Y
        self.BasePos = Vector2.new(math.clamp(self.BasePos.X, 0, MaxX), math.clamp(self.BasePos.Y, 0, MaxY))

        local IsBottom = (self.TabAlignment == "BottomRight" or self.TabAlignment == "BottomLeft")
        local IsLeft = (self.TabAlignment == "TopLeft" or self.TabAlignment == "BottomLeft")
        
        self.Elements.Out1.Position = self.BasePos - Vector2.new(1, 1)
        self.Elements.Out2.Position = self.BasePos
        self.Elements.Main.Position = self.BasePos + Vector2.new(1, 1)
        self.Elements.HeaderT.Position = self.BasePos + Vector2.new(8, 6)
        self.Elements.HeaderWtf.Position = self.BasePos + Vector2.new(8 + self.Elements.HeaderT.TextBounds.X, 6)

        local TargetFrameY = IsBottom and 30 or 55
        local TargetNavY = IsBottom and (self.Size.Y - 26) or 26
        
        local TargetContentRel = Vector2.new(10, TargetFrameY)
        local TargetNavLineRel = Vector2.new(10, TargetNavY)

        self.AnimData.ContentRelativePos = self.AnimData.ContentRelativePos:Lerp(TargetContentRel, self.AnimData.LerpSpeed)
        self.AnimData.NavLineRelativePos = self.AnimData.NavLineRelativePos:Lerp(TargetNavLineRel, self.AnimData.LerpSpeed)

        self.Elements.ContentFrame.Position = self.BasePos + self.AnimData.ContentRelativePos
        self.Elements.ContentOutline.Position = self.Elements.ContentFrame.Position - Vector2.new(1, 1)
        self.Elements.NavLine.Position = self.BasePos + self.AnimData.NavLineRelativePos
        
        self.NavArea = {Pos = self.Elements.NavLine.Position - Vector2.new(0, 2), Size = Vector2.new(self.Size.X - 20, 24)}

        local CurrentOffset = 15
        local TargetTabY = IsBottom and (self.Size.Y - 22) or 32
        
        for i, Tab in next, self.Tabs do
            local Width = Tab.Instance.TextBounds.X
            local TabX = IsLeft and CurrentOffset or (self.Size.X - CurrentOffset - Width)
            local TargetTabRel = Vector2.new(TabX, TargetTabY)
            
            if not self.AnimData.TabPositions[Tab] then self.AnimData.TabPositions[Tab] = TargetTabRel end
            self.AnimData.TabPositions[Tab] = self.AnimData.TabPositions[Tab]:Lerp(TargetTabRel, self.AnimData.LerpSpeed)
            Tab.Instance.Position = self.BasePos + self.AnimData.TabPositions[Tab]
            
            CurrentOffset = CurrentOffset + Width + 15
            
            local LeftY, RightY = 15 - self.ScrollOffset, 15 - self.ScrollOffset
            local IsActive = (self.SelectedTab == Tab)
            
            for j, Section in next, Tab.Sections do
                local IsLeftCol = (j % 2 ~= 0)
                local TargetSecX = IsLeftCol and 10 or (self.Elements.ContentFrame.Size.X / 2 + 5)
                local TargetSecY = IsLeftCol and LeftY or RightY
                local FinalPos = self.Elements.ContentFrame.Position + Vector2.new(TargetSecX, TargetSecY)
                
                local SectionHeight = 20
                for _, Elm in next, Section.Elements do
                    SectionHeight = SectionHeight + Elm.Height
                end
                Section.Main.Size = Vector2.new(Window.Elements.ContentFrame.Size.X / 2 - 15, SectionHeight)
                Section.Outline.Size = Section.Main.Size

                local InBounds = (FinalPos.Y >= self.Elements.ContentFrame.Position.Y) and (FinalPos.Y + Section.Main.Size.Y <= self.Elements.ContentFrame.Position.Y + self.Elements.ContentFrame.Size.Y)

                Section.Main.Visible = IsActive and self.Visible and InBounds
                Section.Outline.Visible = IsActive and self.Visible and InBounds
                Section.Title.Visible = IsActive and self.Visible and InBounds
                Section.Main.Position = FinalPos
                Section.Outline.Position = FinalPos
                Section.Title.Position = FinalPos + Vector2.new(10, -7)

                local ElementY = 10
                for _, Element in next, Section.Elements do
                    Element.Update(FinalPos + Vector2.new(10, ElementY), IsActive and self.Visible and InBounds)
                    ElementY = ElementY + Element.Height
                end

                if IsLeftCol then LeftY = LeftY + Section.Main.Size.Y + 15 else RightY = RightY + Section.Main.Size.Y + 15 end
            end
        end
    end

    function Window:CreateTab(Name)
        local Tab = {Name = Name, Sections = {}, Instance = Create("Text", {Text = Name, Size = Arcane.Config.TextSize, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, Visible = true, ZIndex = 5})}
        
        function Tab:CreateSection(SName)
            local Section = {
                Elements = {},
                Main = Create("Square", {Size = Vector2.new(Window.Elements.ContentFrame.Size.X / 2 - 15, 10), Color = Arcane.Config.MainColor, Filled = true, Visible = false, ZIndex = 6}),
                Outline = Create("Square", {Size = Vector2.new(Window.Elements.ContentFrame.Size.X / 2 - 15, 10), Color = Arcane.Config.OutlineColor, Filled = false, Thickness = 1, Visible = false, ZIndex = 7}),
                Title = Create("Text", {Text = SName, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.AccentColor, Visible = false, ZIndex = 8})
            }

            function Section:AddLabel(Text, Align) 
                local Label = {Height = 15, Text = Text}
                local L = Create("Text", {Text = Text, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                
                function Label.Update(Base, Visible)
                    local XOffset = 0
                    if Align == "Center" then XOffset = (Section.Main.Size.X - L.TextBounds.X - 20)/2 
                    elseif Align == "Right" then XOffset = (Section.Main.Size.X - L.TextBounds.X - 20) end
                    L.Position = Base + Vector2.new(XOffset, 0)
                    L.Visible = Visible
                end
                table.insert(Section.Elements, Label)
            end

            function Section:AddToggle(TName, Default, Callback)
                local Toggle = {Value = Default or false, Height = 20}
                local Box = Create("Square", {Size = Vector2.new(10, 10), Color = Arcane.Config.OutlineColor, Filled = true, ZIndex = 9, Visible = false})
                local Label = Create("Text", {Text = TName, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                
                Arcane.Settings[TName] = Toggle.Value

                function Toggle.Update(Base, Visible)
                    Box.Position = Base + Vector2.new(0, 2)
                    Label.Position = Base + Vector2.new(15, 0)
                    Box.Visible, Label.Visible = Visible, Visible
                    Box.Color = Toggle.Value and Arcane.Config.AccentColor or Arcane.Config.OutlineColor
                end

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and Box.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= Box.Position.X and M.X <= Label.Position.X + Label.TextBounds.X and M.Y >= Box.Position.Y and M.Y <= Box.Position.Y + 12 then
                            Toggle.Value = not Toggle.Value
                            Arcane.Settings[TName] = Toggle.Value
                            Callback(Toggle.Value)
                        end
                    end
                end)
                table.insert(Section.Elements, Toggle)
                return Toggle
            end

            function Section:AddSlider(SName, Min, Max, Default, Callback)
                local Slider = {Value = Default or Min, Height = 35, Dragging = false}
                local Label = Create("Text", {Text = SName, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                local Bar = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 4), Color = Arcane.Config.FrameColor, Filled = true, ZIndex = 9, Visible = false})
                local Fill = Create("Square", {Size = Vector2.new(0, 4), Color = Arcane.Config.AccentColor, Filled = true, ZIndex = 10, Visible = false})
                local ValLabel = Create("Text", {Text = tostring(Slider.Value), Size = Arcane.Config.TextSize - 2, Font = Arcane.Config.Font, Color = Color3.fromRGB(255,255,255), ZIndex = 11, Visible = false})

                Arcane.Settings[SName] = Slider.Value

                function Slider.Update(Base, Visible)
                    Label.Position = Base
                    Bar.Position = Base + Vector2.new(0, 20)
                    local Percent = math.clamp((Slider.Value - Min) / (Max - Min), 0, 1)
                    Fill.Size = Vector2.new(Bar.Size.X * Percent, 4)
                    Fill.Position = Bar.Position
                    ValLabel.Text = tostring(math.floor(Slider.Value))
                    ValLabel.Position = Bar.Position + Vector2.new(Bar.Size.X - ValLabel.TextBounds.X, -16)
                    Label.Visible, Bar.Visible, Fill.Visible, ValLabel.Visible = Visible, Visible, Visible, Visible
                    if Slider.Dragging then
                        local M = UserInputService:GetMouseLocation()
                        local NewP = math.clamp((M.X - Bar.Position.X) / Bar.Size.X, 0, 1)
                        Slider.Value = Min + (Max - Min) * NewP
                        Arcane.Settings[SName] = Slider.Value
                        Callback(Slider.Value)
                    end
                end

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and Bar.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= Bar.Position.X and M.X <= Bar.Position.X + Bar.Size.X and M.Y >= Bar.Position.Y - 5 and M.Y <= Bar.Position.Y + 10 then
                            Slider.Dragging = true
                        end
                    end
                end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Slider.Dragging = false end end)
                table.insert(Section.Elements, Slider)
            end

            function Section:AddKeybind(Default, Callback, IsMenuBind)
                local Keybind = {Value = Default, Height = 20, Binding = false, Callback = Callback, JustBound = false}
                local Label = Create("Text", {Text = IsMenuBind and "Toggle Menu" or "Bind", Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                local BindTxt = Create("Text", {Text = "[ " .. (Keybind.Value and Keybind.Value.Name or "None") .. " ]", Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 12, Visible = false})

                function Keybind.Update(Base, Visible)
                    Label.Position = Base
                    Label.Visible = Visible
                    BindTxt.Visible = Visible
                    BindTxt.Position = Base + Vector2.new(Section.Main.Size.X - BindTxt.TextBounds.X - 20, 0)
                    BindTxt.Text = Keybind.Binding and "[ ... ]" or "[ " .. (Keybind.Value and Keybind.Value.Name or "None") .. " ]"
                end

                UserInputService.InputBegan:Connect(function(input)
                    if Keybind.Binding and input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind.Value = input.KeyCode
                        Keybind.Binding = false
                        Keybind.JustBound = true
                        task.delay(0.1, function() Keybind.JustBound = false end)
                        Window.IsBinding = false
                        if Keybind.Callback and not IsMenuBind then Keybind.Callback(Keybind.Value) end
                        if IsMenuBind then Window.ToggleKey = Keybind.Value end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and BindTxt.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= BindTxt.Position.X and M.X <= BindTxt.Position.X + BindTxt.TextBounds.X and M.Y >= BindTxt.Position.Y and M.Y <= BindTxt.Position.Y + 15 then
                            Keybind.Binding = true
                            Window.IsBinding = true
                        end
                    elseif not Keybind.Binding and not Keybind.JustBound and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Keybind.Value then
                        if Keybind.Callback and not Window.IsBinding then Keybind.Callback() end
                    end
                end)
                table.insert(Section.Elements, Keybind)
                return Keybind
            end

            function Section:AddDropdown(Name, Items, Callback)
                local Dropdown = {Open = false, Height = 35, Selected = Items[1] or "None", Items = Items}
                local Label = Create("Text", {Text = Name, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                local Box = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.FrameColor, Filled = true, ZIndex = 9, Visible = false})
                local BoxOut = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.OutlineColor, Filled = false, ZIndex = 10, Visible = false})
                local Current = Create("Text", {Text = Dropdown.Selected, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Color3.fromRGB(200,200,200), ZIndex = 11, Visible = false})
                
                local DropItems = {}
                Arcane.Settings[Name] = Dropdown.Selected

                function Dropdown:Refresh(NewItems)
                    Dropdown.Items = NewItems
                    for _, v in next, DropItems do v.Box:Remove(); v.Text:Remove() end
                    table.clear(DropItems)
                end

                function Dropdown.Update(Base, Visible)
                    Label.Position = Base
                    Box.Position = Base + Vector2.new(0, 15)
                    BoxOut.Position = Box.Position
                    Current.Position = Box.Position + Vector2.new(5, 2)
                    Label.Visible, Box.Visible, BoxOut.Visible, Current.Visible = Visible, Visible, Visible, Visible
                    Current.Text = Dropdown.Selected .. (Dropdown.Open and " ^" or " v")
                    
                    if Dropdown.Open then
                        Dropdown.Height = 35 + (#Dropdown.Items * 18)
                        for i, v in next, Dropdown.Items do
                            if not DropItems[i] then
                                DropItems[i] = {
                                    Box = Create("Square", {Filled = true, Color = Arcane.Config.FrameColor, ZIndex = 25}),
                                    Text = Create("Text", {Text = v, Size = 13, Font = 2, Color = Color3.fromRGB(200,200,200), ZIndex = 26})
                                }
                            end
                            local ItemBox = DropItems[i].Box
                            local ItemText = DropItems[i].Text
                            ItemBox.Visible, ItemText.Visible = Visible, Visible
                            ItemBox.Size = Vector2.new(Box.Size.X, 18)
                            ItemBox.Position = Box.Position + Vector2.new(0, 18 * i)
                            ItemText.Position = ItemBox.Position + Vector2.new(5, 2)
                            local M = UserInputService:GetMouseLocation()
                            if M.X >= ItemBox.Position.X and M.X <= ItemBox.Position.X + ItemBox.Size.X and M.Y >= ItemBox.Position.Y and M.Y <= ItemBox.Position.Y + ItemBox.Size.Y then
                                ItemText.Color = Arcane.Config.AccentColor
                            else
                                ItemText.Color = Color3.fromRGB(200,200,200)
                            end
                        end
                    else
                        Dropdown.Height = 35
                        for _, v in next, DropItems do v.Box.Visible = false; v.Text.Visible = false end
                    end
                end

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and Box.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= Box.Position.X and M.X <= Box.Position.X + Box.Size.X and M.Y >= Box.Position.Y and M.Y <= Box.Position.Y + Box.Size.Y then
                            Dropdown.Open = not Dropdown.Open
                            Window:UpdateLayout()
                            return
                        end
                        if Dropdown.Open then
                            for i, v in next, Dropdown.Items do
                                local ItemBox = DropItems[i].Box
                                if M.X >= ItemBox.Position.X and M.X <= ItemBox.Position.X + ItemBox.Size.X and M.Y >= ItemBox.Position.Y and M.Y <= ItemBox.Position.Y + ItemBox.Size.Y then
                                    Dropdown.Selected = v
                                    Arcane.Settings[Name] = v
                                    Dropdown.Open = false
                                    Callback(v)
                                    Window:UpdateLayout()
                                    break
                                end
                            end
                        end
                    end
                end)
                table.insert(Section.Elements, Dropdown)
                return Dropdown
            end

            function Section:AddMultiDropdown(Name, Items, Callback)
                local MultiDrop = {Open = false, Height = 35, Selected = {}}
                local Label = Create("Text", {Text = Name, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                local Box = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.FrameColor, Filled = true, ZIndex = 9, Visible = false})
                local BoxOut = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.OutlineColor, Filled = false, ZIndex = 10, Visible = false})
                local Current = Create("Text", {Text = "...", Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Color3.fromRGB(200,200,200), ZIndex = 11, Visible = false})
                
                local DropItems = {}
                Arcane.Settings[Name] = MultiDrop.Selected

                function MultiDrop.Update(Base, Visible)
                    Label.Position = Base
                    Box.Position = Base + Vector2.new(0, 15)
                    BoxOut.Position = Box.Position
                    Current.Position = Box.Position + Vector2.new(5, 2)
                    Label.Visible, Box.Visible, BoxOut.Visible, Current.Visible = Visible, Visible, Visible, Visible
                    
                    local Count = 0
                    for _ in next, MultiDrop.Selected do Count = Count + 1 end
                    Current.Text = (Count == 0 and "None" or tostring(Count).." Selected") .. (MultiDrop.Open and " ^" or " v")
                    
                    if MultiDrop.Open then
                        MultiDrop.Height = 35 + (#Items * 18)
                        for i, v in next, Items do
                            if not DropItems[i] then
                                DropItems[i] = {
                                    Box = Create("Square", {Filled = true, Color = Arcane.Config.FrameColor, ZIndex = 25}),
                                    Text = Create("Text", {Text = v, Size = 13, Font = 2, Color = Color3.fromRGB(200,200,200), ZIndex = 26})
                                }
                            end
                            local ItemBox = DropItems[i].Box
                            local ItemText = DropItems[i].Text
                            ItemBox.Visible, ItemText.Visible = Visible, Visible
                            ItemBox.Size = Vector2.new(Box.Size.X, 18)
                            ItemBox.Position = Box.Position + Vector2.new(0, 18 * i)
                            ItemText.Position = ItemBox.Position + Vector2.new(5, 2)
                            local IsSelected = MultiDrop.Selected[v]
                            ItemText.Color = IsSelected and Arcane.Config.SelectedColor or Color3.fromRGB(200,200,200)
                        end
                    else
                        MultiDrop.Height = 35
                        for _, v in next, DropItems do v.Box.Visible = false; v.Text.Visible = false end
                    end
                end

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and Box.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= Box.Position.X and M.X <= Box.Position.X + Box.Size.X and M.Y >= Box.Position.Y and M.Y <= Box.Position.Y + Box.Size.Y then
                            MultiDrop.Open = not MultiDrop.Open
                            Window:UpdateLayout()
                            return
                        end
                        if MultiDrop.Open then
                            for i, v in next, Items do
                                local ItemBox = DropItems[i].Box
                                if M.X >= ItemBox.Position.X and M.X <= ItemBox.Position.X + ItemBox.Size.X and M.Y >= ItemBox.Position.Y and M.Y <= ItemBox.Position.Y + ItemBox.Size.Y then
                                    if MultiDrop.Selected[v] then MultiDrop.Selected[v] = nil else MultiDrop.Selected[v] = true end
                                    Arcane.Settings[Name] = MultiDrop.Selected
                                    Callback(MultiDrop.Selected)
                                    break
                                end
                            end
                        end
                    end
                end)
                table.insert(Section.Elements, MultiDrop)
            end

            function Section:AddTextbox(Name, Callback)
                local Textbox = {Value = "", Height = 35, Focused = false}
                local Label = Create("Text", {Text = Name, Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Arcane.Config.SecondaryColor, ZIndex = 9, Visible = false})
                local Box = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.FrameColor, Filled = true, ZIndex = 9, Visible = false})
                local BoxOut = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.OutlineColor, Filled = false, ZIndex = 10, Visible = false})
                local InputTxt = Create("Text", {Text = "", Size = Arcane.Config.TextSize - 1, Font = Arcane.Config.Font, Color = Color3.fromRGB(255,255,255), ZIndex = 11, Visible = false})

                function Textbox.Update(Base, Visible)
                    Label.Position = Base
                    Box.Position = Base + Vector2.new(0, 15)
                    BoxOut.Position = Box.Position
                    InputTxt.Position = Box.Position + Vector2.new(5, 2)
                    Label.Visible, Box.Visible, BoxOut.Visible, InputTxt.Visible = Visible, Visible, Visible, Visible
                    BoxOut.Color = Textbox.Focused and Arcane.Config.AccentColor or Arcane.Config.OutlineColor
                    InputTxt.Text = Textbox.Value .. (Textbox.Focused and "|" or "")
                end

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and Box.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= Box.Position.X and M.X <= Box.Position.X + Box.Size.X and M.Y >= Box.Position.Y and M.Y <= Box.Position.Y + Box.Size.Y then
                            Textbox.Focused = true
                            Window.ActiveTextbox = Textbox
                            Window.IsBinding = true
                            ContextActionService:BindActionAtPriority("DisableInput", function() return Enum.ContextActionResult.Sink end, true, 3000, Enum.UserInputType.Keyboard)
                        else
                            if Textbox.Focused then
                                Textbox.Focused = false
                                if Window.ActiveTextbox == Textbox then Window.ActiveTextbox = nil end
                                Window.IsBinding = false
                                ContextActionService:UnbindAction("DisableInput")
                            end
                        end
                    elseif Textbox.Focused and input.UserInputType == Enum.UserInputType.Keyboard then
                        local Key = input.KeyCode
                        if Key == Enum.KeyCode.Backspace then
                            Textbox.Value = string.sub(Textbox.Value, 1, -2)
                            Callback(Textbox.Value)
                        elseif Key == Enum.KeyCode.Return then
                            Textbox.Focused = false
                            if Window.ActiveTextbox == Textbox then Window.ActiveTextbox = nil end
                            Window.IsBinding = false
                            ContextActionService:UnbindAction("DisableInput")
                            Callback(Textbox.Value)
                        elseif Key == Enum.KeyCode.Space then
                            Textbox.Value = Textbox.Value .. " "
                            Callback(Textbox.Value)
                        else
                            local StringKey = UserInputService:GetStringForKeyCode(Key)
                            if StringKey and #StringKey == 1 then
                                local Shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
                                Textbox.Value = Textbox.Value .. (Shift and StringKey:upper() or StringKey:lower())
                                Callback(Textbox.Value)
                            end
                        end
                    end
                end)
                table.insert(Section.Elements, Textbox)
                return Textbox
            end

            function Section:AddButton(BName, Callback)
                local Button = {Height = 25}
                local Frame = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.FrameColor, Filled = true, ZIndex = 9, Visible = false})
                local Out = Create("Square", {Size = Vector2.new(Section.Main.Size.X - 20, 18), Color = Arcane.Config.OutlineColor, Filled = false, ZIndex = 10, Visible = false})
                local Label = Create("Text", {Text = BName, Size = Arcane.Config.TextSize - 2, Font = Arcane.Config.Font, Color = Color3.fromRGB(255,255,255), ZIndex = 11, Visible = false})

                function Button.Update(Base, Visible)
                    Frame.Position = Base
                    Out.Position = Base
                    Label.Position = Base + (Frame.Size / 2) - (Label.TextBounds / 2)
                    Frame.Visible, Out.Visible, Label.Visible = Visible, Visible, Visible
                end

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and Frame.Visible then
                        local M = UserInputService:GetMouseLocation()
                        if M.X >= Frame.Position.X and M.X <= Frame.Position.X + Frame.Size.X and M.Y >= Frame.Position.Y and M.Y <= Frame.Position.Y + Frame.Size.Y then
                            Frame.Color = Arcane.Config.AccentColor
                            Callback()
                            task.wait(0.1)
                            Frame.Color = Arcane.Config.FrameColor
                        end
                    end
                end)
                table.insert(Section.Elements, Button)
            end

            table.insert(Tab.Sections, Section)
            return Section
        end

        if #self.Tabs == 0 then self.SelectedTab = Tab end
        table.insert(self.Tabs, Tab)
        return Tab
    end

    function Window:OpenSettings(MousePos)
        Arcane:ClearMenu()
        self.ContextMenu.Open = true
        self.ContextMenu.Pos = MousePos
        self.ContextMenu.Size = Vector2.new(100, 0) 
        self.ContextMenu.Alpha = 0
        self.ContextMenu.TargetSize = Vector2.new(100, 4 * 22)
        local BG = Create("Square", {Position = MousePos, Size = Vector2.new(100, 0), Color = Arcane.Config.MainColor, Filled = true, Visible = true, ZIndex = 50}, true)
        local Outline = Create("Square", {Position = MousePos, Size = Vector2.new(100, 0), Color = Arcane.Config.OutlineColor, Filled = false, Thickness = 1, Visible = true, ZIndex = 51}, true)
        local Options = {"TopRight", "TopLeft", "BottomRight", "BottomLeft"}
        local TextObjs = {}
        for i, Opt in next, Options do
            table.insert(TextObjs, {
                Text = Create("Text", {Text = Opt, Position = MousePos, Size = 13, Font = 2, Color = Color3.fromRGB(200,200,200), Visible = false, ZIndex = 52}, true),
                Option = Opt,
                RelY = (i-1)*22
            })
        end
        task.spawn(function()
            while self.ContextMenu.Open do
                RunService.RenderStepped:Wait()
                self.ContextMenu.Size = self.ContextMenu.Size:Lerp(self.ContextMenu.TargetSize, 0.2)
                BG.Size = self.ContextMenu.Size
                Outline.Size = self.ContextMenu.Size
                for _, Obj in next, TextObjs do
                    local YPos = self.ContextMenu.Pos.Y + Obj.RelY
                    if YPos < self.ContextMenu.Pos.Y + self.ContextMenu.Size.Y - 20 then
                        Obj.Text.Visible = true
                        Obj.Text.Position = self.ContextMenu.Pos + Vector2.new(5, Obj.RelY + 4)
                        local M = UserInputService:GetMouseLocation()
                        local Hover = M.X >= self.ContextMenu.Pos.X and M.X <= self.ContextMenu.Pos.X + 100 and M.Y >= YPos and M.Y <= YPos + 22
                        Obj.Text.Color = Hover and Arcane.Config.AccentColor or Color3.fromRGB(200,200,200)
                        if Hover and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            self.TabAlignment = Obj.Option
                            self:UpdateLayout()
                            self.ContextMenu.Open = false
                        end
                    else Obj.Text.Visible = false end
                end
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    local M = UserInputService:GetMouseLocation()
                    if not (M.X >= self.ContextMenu.Pos.X and M.X <= self.ContextMenu.Pos.X + 100 and M.Y >= self.ContextMenu.Pos.Y and M.Y <= self.ContextMenu.Pos.Y + self.ContextMenu.Size.Y) then
                        self.ContextMenu.Open = false
                    end
                end
            end
            Arcane:ClearMenu()
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel and Window.Visible then
            local Mouse = UserInputService:GetMouseLocation()
            if Mouse.X >= Window.Elements.ContentFrame.Position.X and Mouse.X <= Window.Elements.ContentFrame.Position.X + Window.Elements.ContentFrame.Size.X and Mouse.Y >= Window.Elements.ContentFrame.Position.Y and Mouse.Y <= Window.Elements.ContentFrame.Position.Y + Window.Elements.ContentFrame.Size.Y then
                Window.ScrollOffset = math.max(0, Window.ScrollOffset - (input.Position.Z * 20))
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Window.ToggleKey and not Window.IsBinding then
                Window.Visible = not Window.Visible
                for _, Obj in next, Arcane.Registry do Obj.Visible = Window.Visible end
                if not Window.Visible then 
                    ContextActionService:UnbindAction("DisableZoom")
                    ContextActionService:UnbindAction("DisableInput")
                end
            end
        end

        if not Window.Visible then return end
        
        local Mouse = UserInputService:GetMouseLocation()
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Mouse.X >= Window.BasePos.X and Mouse.X <= Window.BasePos.X + Window.Size.X and Mouse.Y >= Window.BasePos.Y and Mouse.Y <= Window.BasePos.Y + 25 then
                Window.Dragging = true; Window.DragStart = Mouse; Window.StartPos = Window.BasePos
            end
            for _, Tab in next, Window.Tabs do
                local P, S = Tab.Instance.Position, Tab.Instance.TextBounds
                if Mouse.X >= P.X and Mouse.X <= P.X + S.X and Mouse.Y >= P.Y and Mouse.Y <= P.Y + S.Y then
                    Window.SelectedTab = Tab; Window.ScrollOffset = 0
                end
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            if Mouse.X >= Window.NavArea.Pos.X and Mouse.X <= Window.NavArea.Pos.X + Window.NavArea.Size.X and Mouse.Y >= Window.NavArea.Pos.Y and Mouse.Y <= Window.NavArea.Pos.Y + Window.NavArea.Size.Y then
                Window:OpenSettings(Mouse)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Window.Dragging = false end end)

    local ZoomBound = false
    RunService.RenderStepped:Connect(function()
        if not Window.Visible then 
            if ZoomBound then ContextActionService:UnbindAction("DisableZoom") ZoomBound = false end
            return 
        end
        
        local Mouse = UserInputService:GetMouseLocation()
        local InBounds = Mouse.X >= Window.Elements.ContentFrame.Position.X and 
                         Mouse.X <= Window.Elements.ContentFrame.Position.X + Window.Elements.ContentFrame.Size.X and 
                         Mouse.Y >= Window.Elements.ContentFrame.Position.Y and 
                         Mouse.Y <= Window.Elements.ContentFrame.Position.Y + Window.Elements.ContentFrame.Size.Y

        if InBounds then
            if not ZoomBound then
                ContextActionService:BindActionAtPriority("DisableZoom", function() return Enum.ContextActionResult.Sink end, false, 3000, Enum.UserInputType.MouseWheel)
                ZoomBound = true
            end
        else
            if ZoomBound then
                ContextActionService:UnbindAction("DisableZoom")
                ZoomBound = false
            end
        end

        if Window.Dragging then
            local Delta = UserInputService:GetMouseLocation() - Window.DragStart
            Window.BasePos = Window.StartPos + Delta
        end
        Window:UpdateLayout()
        
        for _, Tab in next, Window.Tabs do
            local P, S = Tab.Instance.Position, Tab.Instance.TextBounds
            local IsHovered = Mouse.X >= P.X and Mouse.X <= P.X + S.X and Mouse.Y >= P.Y and Mouse.Y <= P.Y + S.Y
            if Window.SelectedTab == Tab then Tab.Instance.Color = Arcane.Config.SelectedColor
            elseif IsHovered then Tab.Instance.Color = Arcane.Config.AccentColor
            else Tab.Instance.Color = Arcane.Config.SecondaryColor end
        end
    end)

    return Window
end

return Arcane
