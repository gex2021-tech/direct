-- ============================================================
-- DERELICT  |  Combined UI + ESP + Spoofer (custom, no Linoria)
-- ============================================================
-- - Tab system (Main / Visuals / Farm / Misc)
-- - Every checkbox is bindable (click [+] to set key, right-click
--   to cycle Toggle / Hold / Clear)
-- - Real player list, real activity log, real ESP rendering
-- ============================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UserInput   = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

-- Cleanup any previous instance (PlayerGui + CoreGui)
for _, pg in ipairs({PlayerGui, pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or PlayerGui}) do
    local prev = pg:FindFirstChild("DerelictUI")
    if prev then prev:Destroy() end
end

-- ───────────────────────────────────────────────────────────
-- DERELICT GLOBAL TABLE
-- ───────────────────────────────────────────────────────────
Derelict = {
    Version = "2.0.1-Fixed",
    Theme = {
        MainColor  = Color3.fromRGB(25, 25, 35),
        AccentColor = Color3.fromRGB(0, 170, 255),
        TextColor  = Color3.fromRGB(255, 255, 255),
    },
    ActiveConnections = {},
    Notifications = {},
}

function Derelict:Connect(conn)
    table.insert(self.ActiveConnections, conn)
    return conn
end

function Derelict:DisconnectAll()
    for _, conn in ipairs(self.ActiveConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    self.ActiveConnections = {}
end

local function track(c) Derelict:Connect(c); return c end

-- ───────────────────────────────────────────────────────────
-- HELPERS
-- ───────────────────────────────────────────────────────────
local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function Stroke(p, c, t)
    return New("UIStroke", { Color = c or Color3.fromRGB(45,45,45), Thickness = t or 1 }, p)
end
local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 2) }, p) end
local function Hex(h)
    h = h:gsub("#", "")
    return Color3.fromRGB(
        tonumber("0x"..h:sub(1,2)),
        tonumber("0x"..h:sub(3,4)),
        tonumber("0x"..h:sub(5,6))
    )
end

-- ───────────────────────────────────────────────────────────
-- PALETTE
-- ───────────────────────────────────────────────────────────
local C = {
    bg=Hex("0d0d0d"), panel=Hex("131313"), hdr=Hex("1a1a1a"),
    border=Hex("2d2d2d"), text=Hex("cccccc"), dim=Hex("777777"),
    accent=Hex("4a9eff"), red=Hex("e84343"), orange=Hex("e87d1e"),
    green=Hex("3ecf5b"), purple=Hex("9b59b6"), row_alt=Hex("0f0f0f"),
}

-- ═══════════════════════════════════════════════════════════
-- STATE SYSTEM  (Toggles / Options + listeners + bindings)
-- ═══════════════════════════════════════════════════════════
local Toggles, Options = {}, {}
local CheckboxRefs = {}   -- toggleName -> ARRAY of refs (multi-panel safe)
local KeybindList                 -- ScrollingFrame, populated later

local function CreateToggle(name, default, displayLabel)
    local t = {
        Value = default, Binds = {}, -- list of { Key=string, Mode="Toggle"|"Hold" }
        Label = displayLabel or name, _l = {},
    }
    function t:Set(v)
        if t.Value == v then return end
        t.Value = v
        -- SYNCHRONOUS dispatch → instant visual update (no scheduler delay)
        for _, fn in ipairs(t._l) do
            local ok, err = pcall(fn, v)
            if not ok then warn("[Derelict] listener error: "..tostring(err)) end
        end
    end
    function t:OnChanged(fn) table.insert(t._l, fn); return t end
    Toggles[name] = t
    return t
end
local function CreateOption(name, default)
    local o = { Value = default, _l = {} }
    function o:Set(v) 
        if o.Value == v then return end
        o.Value = v
        for _, fn in ipairs(o._l) do
            local ok, err = pcall(fn, v)
            if not ok then warn("[Derelict] option listener error: "..tostring(err)) end
        end
    end
    function o:OnChanged(fn) table.insert(o._l, fn); return o end
    Options[name] = o
    return o
end

-- ── DEFINITIONS ────────────────────────────────────────────
-- Visuals / ESP
CreateToggle("ESP_Enabled",   true,  "Enable ESP")
CreateToggle("Show_Boxes",    true,  "Show Boxes")
CreateToggle("Show_Names",    true,  "Show Names")
CreateToggle("Show_Health",   true,  "Show Health Bars")
CreateToggle("Show_Distance", true,  "Show Distance")
CreateToggle("Show_Tracers",  false, "Show Tracers")
CreateToggle("Show_Enemies",  true,  "Show Enemies")
CreateToggle("Show_Bosses",   true,  "Show Bosses")
CreateToggle("Show_Items",    true,  "Show Items/Loot")
CreateToggle("Show_Players",  true,  "Show Players")

-- Main / character + movement
CreateToggle("Infinite_Stamina", true,  "Infinite Stamina")
-- CreateToggle("No_Fall_Damage",   false, "No Fall Damage") -- Feature incompleta, removida temporalmente
CreateToggle("No_Clip",          false, "No Clip")
CreateToggle("Fly_Mode",         false, "Fly Mode")
CreateToggle("Infinite_Jump",    false, "Infinite Jump")

-- Farm
CreateToggle("Auto_Farm",      false, "Auto Farm")
CreateToggle("Auto_Boss",      false, "Auto Boss")
CreateToggle("Auto_Collect",   false, "Auto Collect Loot")
CreateToggle("Skip_Cutscenes", false, "Skip Cutscenes")

-- Options
CreateOption("ESP_Distance",  500)
CreateOption("Fly_Speed",      60)
CreateOption("Color_Enemy",   Color3.fromRGB(255,50,50))
CreateOption("Color_Boss",    Color3.fromRGB(180,0,255))
CreateOption("Color_Item",    Color3.fromRGB(50,255,50))
CreateOption("Color_Player",  Color3.fromRGB(50,150,255))
-- Linked numeric params → conditional Value slider in keybind panel
Toggles.ESP_Enabled.valueOption = { key="ESP_Distance", label="Max Distance", min=100, max=2000 }
Toggles.Fly_Mode.valueOption    = { key="Fly_Speed",    label="Fly Speed",    min=10,  max=200  }

-- ═══════════════════════════════════════════════════════════
-- SCREEN GUI + MAIN WINDOW + TITLE BAR + NAVBAR
-- ═══════════════════════════════════════════════════════════
local SGui = New("ScreenGui", {
    Name="DerelictUI", ResetOnSpawn=false, DisplayOrder=2147483647,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
}, PlayerGui)
do  -- Move to CoreGui so the ScreenGui renders above the Drawing API layer
    pcall(function() syn.protect_gui(SGui) end)
    pcall(function() protect_gui(SGui) end)
    local ok = pcall(function() SGui.Parent = game:GetService("CoreGui") end)
    if not ok then
        local hui = pcall(gethui) and gethui()
        if hui then
            SGui.Parent = hui
        else
            SGui.Parent = PlayerGui
        end
    end
end

-- ───────────────────────────────────────────────────────────
-- NOTIFY SYSTEM (Toast Notifications)
-- ───────────────────────────────────────────────────────────
local NotifyContainer = nil
function Notify(title, msg, nType)
    if not NotifyContainer then
        NotifyContainer = New("Frame", {
            Position = UDim2.new(1, -10, 1, -10),
            Size = UDim2.new(0, 280, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, SGui)
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, NotifyContainer)
    end

    local color = C.accent
    if nType == "Success" then color = C.green
    elseif nType == "Error" then color = C.red
    elseif nType == "Warning" then color = C.orange end

    local toast = New("Frame", {
        Size = UDim2.new(0, 280, 0, 50),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        LayoutOrder = #NotifyContainer:GetChildren(),
    }, NotifyContainer)
    Corner(toast, 4)
    Stroke(toast, color, 1)

    New("TextLabel", {
        Position = UDim2.new(0, 8, 0, 4),
        Size = UDim2.new(1, -16, 0, 14),
        Text = title,
        TextColor3 = color,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    }, toast)

    New("TextLabel", {
        Position = UDim2.new(0, 8, 0, 18),
        Size = UDim2.new(1, -16, 0, 28),
        Text = msg or "",
        TextColor3 = C.text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Font = Enum.Font.Gotham,
        TextSize = 9,
    }, toast)

    table.insert(Derelict.Notifications, toast)

    -- Animate in
    toast.Position = UDim2.new(1, 10, 1, -10)
    pcall(function()
        TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -290, 0, 0),
        }):Play()
    end)

    -- Auto-dismiss after 4s
    spawn(function()
        wait(4)
        pcall(function()
            TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 10, 0, 0),
            }):Play()
        end)
        wait(0.3)
        toast:Destroy()
    end)
end

local Main = New("Frame", {
    Name="Main", Size=UDim2.new(0,960,0,590),
    Position=UDim2.new(0.5,-480,0.5,-295),
    BackgroundColor3=C.bg, BorderSizePixel=0, Active=true,
}, SGui)
Stroke(Main, C.border, 1)

local TitleBar = New("Frame", {
    Size=UDim2.new(1,0,0,22), BackgroundColor3=C.hdr, BorderSizePixel=0,
}, Main)
Stroke(TitleBar, C.border, 1)
New("TextLabel", {
    Size=UDim2.new(1,-52,1,0), Position=UDim2.new(0,8,0,0),
    Text="Derelict | Competitive Hub", TextColor3=C.text,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold, TextSize=11,
}, TitleBar)
local closeBtn = New("TextButton", {
    Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-22,0,0),
    Text="X", TextColor3=Color3.new(1,1,1), BackgroundColor3=Hex("5a1010"),
    BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=11,
}, TitleBar)
closeBtn.MouseButton1Click:Connect(function() Main.Visible=false end)

local NavBar = New("Frame", {
    Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,22),
    BackgroundColor3=Hex("0f0f0f"), BorderSizePixel=0,
}, Main)
Stroke(NavBar, C.border, 1)

local Content = New("Frame", {
    Size=UDim2.new(1,0,1,-42), Position=UDim2.new(0,0,0,42),
    BackgroundTransparency=1, ClipsDescendants=true,
}, Main)

-- ═══════════════════════════════════════════════════════════
-- WIDGET FACTORIES
-- ═══════════════════════════════════════════════════════════
local function Panel(parent, x, y, w, h, title)
    local f = New("Frame", {
        Position=UDim2.new(0,x,0,y), Size=UDim2.new(0,w,0,h),
        BackgroundColor3=C.panel, BorderSizePixel=0, ClipsDescendants=true,
    }, parent)
    Stroke(f, C.border, 1)
    if title then
        local hdr = New("Frame", {
            Size=UDim2.new(1,0,0,18), BackgroundColor3=C.hdr, BorderSizePixel=0,
        }, f)
        Stroke(hdr, C.border, 1)
        New("TextLabel", {
            Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,8,0,0),
            Text=title, TextColor3=C.text, BackgroundTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Left,
            Font=Enum.Font.GothamBold, TextSize=10,
        }, hdr)
    end
    return f
end

local function PanelContent(panel)
    return New("Frame", {
        Position=UDim2.new(0,0,0,18), Size=UDim2.new(1,0,1,-18),
        BackgroundTransparency=1,
    }, panel)
end

local function Section(parent, y, text)
    New("TextLabel", {
        Position=UDim2.new(0,8,0,y), Size=UDim2.new(1,-16,0,12),
        Text=text, TextColor3=C.accent, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold, TextSize=9,
    }, parent)
    New("Frame", {
        Position=UDim2.new(0,8,0,y+12), Size=UDim2.new(1,-16,0,1),
        BackgroundColor3=C.border, BorderSizePixel=0,
    }, parent)
end

-- ── Bindable Checkbox ──────────────────────────────────────
-- Click row toggles state.
-- Click [bind] -> enters capture mode (next key sets bind).
-- Right-click [bind] -> cycles: Toggle -> Hold -> (clear) -> Toggle
-- ───────────────────────────────────────────────────────────
local bindingFor = nil   -- toggle currently waiting for a key
local function UpdateCheckboxVisual(name)
    local refs = CheckboxRefs[name]; if not refs then return end
    local t = Toggles[name]; local on = t.Value
    for _, r in ipairs(refs) do
        local col = on and (r.color or C.accent) or C.bg
        r.box.BackgroundColor3 = col
        if r.boxStroke then r.boxStroke.Color = on and (r.color or C.accent) or C.border end
        if r.check then r.check.Visible = on end
    end
end
local function UpdateBindLabel(name)
    local refs = CheckboxRefs[name]; if not refs then return end
    local t = Toggles[name]
    for _, r in ipairs(refs) do
        if r.bindBtn then
            if bindingFor == name then
                r.bindBtn.Text = "..."; r.bindBtn.TextColor3 = C.orange
            elseif #t.Binds > 0 and t.Binds[1].Key then
                local b = t.Binds[1]
                local extra = (#t.Binds > 1) and ("+"..(#t.Binds-1)) or ""
                r.bindBtn.Text = "["..b.Key:sub(1,4)..":"..(b.Mode=="Hold" and "H" or "T")..extra.."]"
                r.bindBtn.TextColor3 = b.Mode=="Hold" and C.orange or C.accent
            else
                r.bindBtn.Text = "[+]"; r.bindBtn.TextColor3 = C.dim
            end
        end
    end
end
local RefreshKeybindList = function() end -- forward decl; reassigned after kbPanel
local OpenKeybindPopup   = function() end -- forward decl; reassigned after kbPanel
local function UpdateAllBinds()
    for n,_ in pairs(CheckboxRefs) do UpdateBindLabel(n) end
    RefreshKeybindList()
end

local function Checkbox(parent, y, toggleName, color)
    local t = Toggles[toggleName]
    if not t then warn("[Derelict] Missing toggle: "..toggleName); return end

    local row = New("TextButton", {
        Position=UDim2.new(0,0,0,y), Size=UDim2.new(1,0,0,17),
        Text="", BackgroundTransparency=1, AutoButtonColor=false,
    }, parent)

    local box = New("Frame", {
        Position=UDim2.new(0,8,0.5,-5), Size=UDim2.new(0,10,0,10),
        BackgroundColor3=C.bg, BorderSizePixel=0,
    }, row)
    local boxStroke = Stroke(box, C.border, 1)
    local check = New("TextLabel", {
        Size=UDim2.new(1,0,1,0), Text="✓", TextColor3=Color3.new(1,1,1),
        BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=8,
        Visible=false,
    }, box)

    New("TextLabel", {
        Position=UDim2.new(0,22,0,0), Size=UDim2.new(1,-72,1,0),
        Text=t.Label, TextColor3=C.text, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.Gotham, TextSize=10,
    }, row)

    local bindBtn = New("TextButton", {
        Position=UDim2.new(1,-46,0.5,-7), Size=UDim2.new(0,42,0,14),
        Text="[+]", TextColor3=C.dim, BackgroundColor3=C.bg,
        BorderSizePixel=0, Font=Enum.Font.Gotham, TextSize=8,
        AutoButtonColor=false,
    }, row)
    Stroke(bindBtn, C.border, 1)

    if not CheckboxRefs[toggleName] then CheckboxRefs[toggleName] = {} end
    local ref = { box=box, boxStroke=boxStroke, check=check, bindBtn=bindBtn, color=color, row=row }
    table.insert(CheckboxRefs[toggleName], ref)

    UpdateCheckboxVisual(toggleName)
    UpdateBindLabel(toggleName)

    -- LEFT-click row → toggle value
    row.MouseButton1Click:Connect(function() t:Set(not t.Value) end)

    -- LEFT-click [+] bindBtn → quick key capture
    bindBtn.MouseButton1Click:Connect(function()
        if bindingFor and bindingFor ~= toggleName then
            local prev = bindingFor; bindingFor = nil; UpdateBindLabel(prev)
        end
        bindingFor = toggleName; UpdateBindLabel(toggleName)
    end)
    -- RIGHT-click [+] bindBtn → open the contextual keybind popup (ONLY trigger)
    bindBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            OpenKeybindPopup(toggleName)
        end
    end)

    -- Direct memory-pointer closure → instant visual update on toggle
    t:OnChanged(function(v)
        local col = v and (color or C.accent) or C.bg
        box.BackgroundColor3 = col
        boxStroke.Color      = v and (color or C.accent) or C.border
        check.Visible        = v
    end)
    return row
end

local function FilterRow(parent, y, toggleName, swatchColor, optionName)
    Checkbox(parent, y, toggleName, swatchColor)
    local refs = CheckboxRefs[toggleName]
    local r = refs[#refs]  -- last inserted ref belongs to this call
    -- Move bind button left so swatch fits on the right edge
    r.bindBtn.Position = UDim2.new(1,-66,0.5,-7)
    local sw = New("Frame", {
        Position=UDim2.new(1,-22,0.5,-6), Size=UDim2.new(0,14,0,12),
        BackgroundColor3=swatchColor, BorderSizePixel=0,
    }, r.row)
    Stroke(sw, C.border, 1); Corner(sw, 2)
    if optionName and Options[optionName] then
        Options[optionName]:OnChanged(function(v) sw.BackgroundColor3 = v end)
    end
end

-- Single shared slider input router (instead of 2 listeners per slider)
local _activeSlider = nil  -- {setFromX = function}
track(UserInput.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then _activeSlider = nil end
end))
track(UserInput.InputChanged:Connect(function(i)
    if _activeSlider and i.UserInputType==Enum.UserInputType.MouseMovement then
        _activeSlider.setFromX(i.Position.X)
    end
end))
local function Slider(parent, y, label, optionName, min, max)
    local opt = Options[optionName]
    local row = New("Frame", {
        Position=UDim2.new(0,0,0,y), Size=UDim2.new(1,0,0,28),
        BackgroundTransparency=1,
    }, parent)
    New("TextLabel", {
        Position=UDim2.new(0,8,0,0), Size=UDim2.new(0.65,0,0,13),
        Text=label, TextColor3=C.dim, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.Gotham, TextSize=9,
    }, row)
    local valLbl = New("TextLabel", {
        Position=UDim2.new(0.65,0,0,0), Size=UDim2.new(0.35,-8,0,13),
        Text=tostring(opt.Value), TextColor3=C.text, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Right,
        Font=Enum.Font.Gotham, TextSize=9,
    }, row)
    local bar = New("TextButton", {
        Position=UDim2.new(0,8,0,16), Size=UDim2.new(1,-16,0,4),
        BackgroundColor3=C.border, BorderSizePixel=0, Text="",
        AutoButtonColor=false,
    }, row)
    Corner(bar, 4)
    local pct = math.clamp((opt.Value-min)/(max-min), 0, 1)
    local fill = New("Frame", {
        Size=UDim2.new(pct,0,1,0), BackgroundColor3=C.accent,
        BorderSizePixel=0,
    }, bar)
    Corner(fill, 4)
    local thumb = New("Frame", {
        Position=UDim2.new(pct,-4,0.5,-4), Size=UDim2.new(0,8,0,8),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    }, bar)

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + rel*(max-min) + 0.5)
        opt:Set(v)
        fill.Size = UDim2.new(rel,0,1,0)
        thumb.Position = UDim2.new(rel,-4,0.5,-4)
        valLbl.Text = tostring(v)
    end

    local handle = { setFromX = setFromX }
    bar.MouseButton1Down:Connect(function()
        _activeSlider = handle
        setFromX(UserInput:GetMouseLocation().X)
    end)
end

local function SmallBtn(parent, x, y, w, h, text, onClick)
    local b = New("TextButton", {
        Position=UDim2.new(0,x,0,y), Size=UDim2.new(0,w,0,h),
        Text=text, TextColor3=C.text, BackgroundColor3=C.hdr,
        BorderSizePixel=0, Font=Enum.Font.Gotham, TextSize=9,
    }, parent)
    Stroke(b, C.border, 1)
    if onClick then b.MouseButton1Click:Connect(onClick) end
    return b
end

local function TabStrip(parent, y, tabs)
    local row = New("Frame", {
        Position=UDim2.new(0,4,0,y), Size=UDim2.new(1,-8,0,16),
        BackgroundTransparency=1,
    }, parent)
    for i,name in ipairs(tabs) do
        New("TextLabel", {
            Position=UDim2.new(0,(i-1)*55,0,0), Size=UDim2.new(0,50,1,0),
            Text=name, TextColor3=i==1 and C.text or C.dim,
            BackgroundTransparency=1,
            Font=i==1 and Enum.Font.GothamBold or Enum.Font.Gotham,
            TextSize=9,
        }, row)
    end
    New("Frame", {
        Position=UDim2.new(0,0,1,-2), Size=UDim2.new(0,50,0,2),
        BackgroundColor3=C.accent, BorderSizePixel=0,
    }, row)
end

-- ═══════════════════════════════════════════════════════════
-- TAB SYSTEM  +  TAB CONTENT BUILDERS
-- ═══════════════════════════════════════════════════════════
local NAV_TABS = { "Main", "Visuals", "Farm", "Misc" }
local Pages, NavLabels, NavUnderlines = {}, {}, {}

for i, name in ipairs(NAV_TABS) do
    local btn = New("TextButton", {
        Size=UDim2.new(0,72,1,0),
        Position=UDim2.new(0,(i-1)*74+4,0,0),
        Text=name, TextColor3=C.dim,
        BackgroundTransparency=1, AutoButtonColor=false,
        Font=Enum.Font.Gotham, TextSize=10,
    }, NavBar)
    local ul = New("Frame", {
        Size=UDim2.new(0,72,0,2),
        Position=UDim2.new(0,(i-1)*74+4,1,-2),
        BackgroundColor3=C.bg, BorderSizePixel=0,
    }, NavBar)
    NavLabels[name]    = btn
    NavUnderlines[name]= ul

    btn.MouseButton1Click:Connect(function()
        for n, frame in pairs(Pages) do frame.Visible = (n == name) end
        for n, lbl in pairs(NavLabels) do
            local active = (n == name)
            lbl.TextColor3 = active and C.text or C.dim
            lbl.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
            NavUnderlines[n].BackgroundColor3 = active and C.accent or C.bg
        end
    end)
end

local function MakePage(name)
    local p = New("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false,
    }, Content)
    Pages[name] = p
    return p
end

-- ═══════════════════════════════════════════════════════════
-- ALWAYS-VISIBLE COLUMNS  (right column + center bottom)
-- ═══════════════════════════════════════════════════════════
local Always = New("Frame", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
}, Content)

-- ═══════════════════════════════════════════════════════════
-- KEYBIND POPUP
-- ═══════════════════════════════════════════════════════════
local kbPanel = New("Frame", {
    Position=UDim2.new(0,0,0,0), Size=UDim2.new(0,320,0,160),
    BackgroundColor3=Hex("141414"), BorderSizePixel=0,
    Visible=false, ZIndex=100,
}, SGui)
Corner(kbPanel, 8)
Stroke(kbPanel, Hex("2a2a2a"), 1)

local kbCurrent  = nil
local kbBindIdx  = 1
local KbRebuildChips

local function ClosePopup()
    if bindingFor then local n=bindingFor; bindingFor=nil; UpdateBindLabel(n) end
    if kbCurrent and Toggles[kbCurrent] then
        local t = Toggles[kbCurrent]
        for i = #t.Binds, 1, -1 do
            if not t.Binds[i].Key then table.remove(t.Binds, i) end
        end
        UpdateBindLabel(kbCurrent)
    end
    kbPanel.Visible = false
end

local _popupIgnoreNextClose = false
local kbInner = New("Frame", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, Active=true,
}, kbPanel)
kbInner.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _popupIgnoreNextClose = true
    end
end)
track(UserInput.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 and kbPanel.Visible then
        if _popupIgnoreNextClose then
            _popupIgnoreNextClose = false
            return
        end
        local mp = UserInput:GetMouseLocation()
        local pp, ps = kbPanel.AbsolutePosition, kbPanel.AbsoluteSize
        if mp.X<pp.X or mp.X>pp.X+ps.X or mp.Y<pp.Y or mp.Y>pp.Y+ps.Y then
            ClosePopup()
        end
    end
end))

-- ── LEFT: menu ──
local kbLeft = New("Frame",{
    Position=UDim2.new(0,0,0,0), Size=UDim2.new(0,120,1,0),
    BackgroundColor3=Hex("111111"), BorderSizePixel=0,
}, kbInner)
Corner(kbLeft, 8)
local kbLeftClip = New("Frame",{
    Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1, ClipsDescendants=true,
}, kbLeft)
Corner(kbLeftClip, 8)

local function HoverFx(btn, hoverColor)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hoverColor end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Hex("111111") end)
end

-- + New Bind
local kbNewBtn = New("TextButton",{
    Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,53),
    Text="", BackgroundColor3=Hex("111111"),
    BorderSizePixel=0, AutoButtonColor=false, Active=true, ZIndex=101,
}, kbLeftClip)
New("TextLabel",{
    Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-36,0,22),
    Text="+ New Bind", TextColor3=C.accent, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold, TextSize=11,
}, kbNewBtn)
New("TextLabel",{
    Position=UDim2.new(1,-22,0,0), Size=UDim2.new(0,18,1,0),
    Text="›", TextColor3=C.accent, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Center,
    Font=Enum.Font.GothamBold, TextSize=14,
}, kbNewBtn)
HoverFx(kbNewBtn, Hex("1a1a2e"))
kbNewBtn.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    if not kbCurrent or not Toggles[kbCurrent] then return end
    local t = Toggles[kbCurrent]
    table.insert(t.Binds, { Key=nil, Mode="Toggle" })
    kbBindIdx = #t.Binds
    bindingFor = kbCurrent
    kbKeyBtn.Text = "Press key..."
    kbKeyBtn.TextColor3 = C.orange
    kbModeT.BackgroundColor3 = C.accent; kbModeT.TextColor3 = Color3.new(1,1,1); kbModeTStroke.Color = C.accent
    kbModeH.BackgroundColor3 = Hex("222222"); kbModeH.TextColor3 = Hex("777777"); kbModeHStroke.Color = Hex("2a2a2a")
    UpdateBindLabel(kbCurrent)
    if KbRebuildChips then KbRebuildChips() end
end)
New("Frame",{
    Position=UDim2.new(0,12,0,53), Size=UDim2.new(1,-24,0,1),
    BackgroundColor3=Hex("2a2a2a"), BorderSizePixel=0,
}, kbLeftClip)

-- Hotkeys
local kbHotBtn = New("TextButton",{
    Position=UDim2.new(0,0,0,54), Size=UDim2.new(1,0,0,53),
    Text="", BackgroundColor3=Hex("111111"),
    BorderSizePixel=0, AutoButtonColor=false, Active=true, ZIndex=101,
}, kbLeftClip)
New("TextLabel",{
    Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-20,0,22),
    Text="Hotkeys", TextColor3=Hex("cccccc"), BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.Gotham, TextSize=11,
}, kbHotBtn)
HoverFx(kbHotBtn, Hex("1a1a1a"))
kbHotBtn.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    print("[Derelict] active hotkeys:")
    for _, t in pairs(Toggles) do
        for _, b in ipairs(t.Binds) do
            if b.Key then print("  "..t.Label.." -> "..b.Key.." ("..b.Mode..")") end
        end
    end
end)
New("Frame",{
    Position=UDim2.new(0,12,0,107), Size=UDim2.new(1,-24,0,1),
    BackgroundColor3=Hex("2a2a2a"), BorderSizePixel=0,
}, kbLeftClip)

-- Vertical divider
New("Frame",{
    Position=UDim2.new(0,120,0,0), Size=UDim2.new(0,1,1,0),
    BackgroundColor3=Hex("2a2a2a"), BorderSizePixel=0,
}, kbInner)

-- ── RIGHT: config ──
local kbRight = New("Frame",{
    Position=UDim2.new(0,122,0,0), Size=UDim2.new(1,-122,1,0),
    BackgroundTransparency=1,
}, kbInner)

-- Key
New("TextLabel",{
    Position=UDim2.new(0,10,0,10), Size=UDim2.new(0,24,0,14),
    Text="Key", TextColor3=Hex("888888"), BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold, TextSize=9,
}, kbRight)
local kbKeyBtnFrame = New("Frame",{
    Position=UDim2.new(0,36,0,8), Size=UDim2.new(1,-46,0,22),
    BackgroundColor3=Hex("1e1e1e"), BorderSizePixel=0, Active=true, ZIndex=101,
}, kbRight)
Corner(kbKeyBtnFrame, 5)
Stroke(kbKeyBtnFrame, Hex("2e2e2e"), 1)
local kbKeyBtn = New("TextLabel",{
    Size=UDim2.new(1,0,1,0),
    Text="-", TextColor3=Hex("777777"), BackgroundTransparency=1,
    Font=Enum.Font.GothamBold, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Center,
}, kbKeyBtnFrame)

-- Mode
New("TextLabel",{
    Position=UDim2.new(0,10,0,36), Size=UDim2.new(0,32,0,14),
    Text="Mode", TextColor3=Hex("888888"), BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold, TextSize=9,
}, kbRight)
local kbModeT = New("TextButton",{
    Position=UDim2.new(0,44,0,34), Size=UDim2.new(0,54,0,22),
    Text="Toggle", TextColor3=Color3.new(1,1,1), BackgroundColor3=C.accent,
    BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=9,
    AutoButtonColor=false, Active=true, ZIndex=101,
}, kbRight)
Corner(kbModeT, 5)
local kbModeTStroke = Stroke(kbModeT, C.accent, 1)
local kbModeH = New("TextButton",{
    Position=UDim2.new(0,102,0,34), Size=UDim2.new(0,54,0,22),
    Text="Hold", TextColor3=Hex("777777"), BackgroundColor3=Hex("222222"),
    BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=9,
    AutoButtonColor=false, Active=true, ZIndex=101,
}, kbRight)
Corner(kbModeH, 5)
local kbModeHStroke = Stroke(kbModeH, Hex("2a2a2a"), 1)

-- Separator
New("Frame",{
    Position=UDim2.new(0,8,0,62), Size=UDim2.new(1,-16,0,1),
    BackgroundColor3=Hex("2a2a2a"), BorderSizePixel=0,
}, kbRight)

-- Binds
New("TextLabel",{
    Position=UDim2.new(0,10,0,68), Size=UDim2.new(0,36,0,14),
    Text="Binds", TextColor3=Hex("888888"), BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold, TextSize=9,
}, kbRight)
local kbChips = New("ScrollingFrame",{
    Position=UDim2.new(0,8,0,84), Size=UDim2.new(1,-16,0,26),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollingDirection=Enum.ScrollingDirection.X,
    ScrollBarThickness=0,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.X,
}, kbRight)
local kbChipsLayout = New("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4),
    SortOrder=Enum.SortOrder.LayoutOrder,
    VerticalAlignment=Enum.VerticalAlignment.Center,
}, kbChips)

-- Separator
New("Frame",{
    Position=UDim2.new(0,8,0,116), Size=UDim2.new(1,-16,0,1),
    BackgroundColor3=Hex("2a2a2a"), BorderSizePixel=0,
}, kbRight)

-- Footer: Del | Hide | Menu
local kbDelBtn = New("TextButton",{
    Position=UDim2.new(0,8,0,122), Size=UDim2.new(0,34,0,26),
    Text="Del", TextColor3=C.red, BackgroundColor3=Hex("1e1e1e"),
    BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=9,
    AutoButtonColor=false, Active=true, ZIndex=101,
}, kbRight)
Corner(kbDelBtn, 5)
Stroke(kbDelBtn, Hex("2e2e2e"), 1)
local kbHideBtn = New("TextButton",{
    Position=UDim2.new(0,46,0,122), Size=UDim2.new(0,42,0,26),
    Text="Hide", TextColor3=Hex("777777"), BackgroundColor3=Hex("1e1e1e"),
    BorderSizePixel=0, Font=Enum.Font.Gotham, TextSize=9,
    AutoButtonColor=false, Active=true, ZIndex=101,
}, kbRight)
Corner(kbHideBtn, 5)
Stroke(kbHideBtn, Hex("2e2e2e"), 1)
local kbMenuBtn = New("TextButton",{
    Position=UDim2.new(1,-32,0,122), Size=UDim2.new(0,26,0,26),
    Text=":", TextColor3=Hex("777777"), BackgroundColor3=Hex("1e1e1e"),
    BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=14,
    AutoButtonColor=false, Active=true, ZIndex=101,
}, kbRight)
Corner(kbMenuBtn, 5)
Stroke(kbMenuBtn, Hex("2e2e2e"), 1)

-- ─ Handlers ──
kbDelBtn.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    if not kbCurrent or not Toggles[kbCurrent] then return end
    local t = Toggles[kbCurrent]
    if #t.Binds > 0 then
        table.remove(t.Binds, kbBindIdx)
        kbBindIdx = math.max(1, math.min(kbBindIdx, #t.Binds))
    end
    if bindingFor==kbCurrent then bindingFor=nil end
    if #t.Binds == 0 then
        kbKeyBtn.Text = "-"
        kbKeyBtn.TextColor3 = Hex("777777")
        kbModeT.BackgroundColor3 = C.accent; kbModeT.TextColor3 = Color3.new(1,1,1); kbModeTStroke.Color = C.accent
        kbModeH.BackgroundColor3 = Hex("222222"); kbModeH.TextColor3 = Hex("777777"); kbModeHStroke.Color = Hex("2a2a2a")
    else
        local b = t.Binds[kbBindIdx]
        if b and b.Key then
            kbKeyBtn.Text = b.Key; kbKeyBtn.TextColor3 = Color3.new(1,1,1)
        else
            kbKeyBtn.Text = "-"; kbKeyBtn.TextColor3 = Hex("777777")
        end
        local mode = (b and b.Mode) or "Toggle"
        local isTog = mode ~= "Hold"
        kbModeT.BackgroundColor3 = isTog and C.accent or Hex("222222")
        kbModeT.TextColor3 = isTog and Color3.new(1,1,1) or Hex("777777")
        kbModeTStroke.Color = isTog and C.accent or Hex("2a2a2a")
        kbModeH.BackgroundColor3 = (not isTog) and C.orange or Hex("222222")
        kbModeH.TextColor3 = (not isTog) and Color3.new(1,1,1) or Hex("777777")
        kbModeHStroke.Color = (not isTog) and C.orange or Hex("2a2a2a")
    end
    UpdateBindLabel(kbCurrent)
    if KbRebuildChips then KbRebuildChips() end
end)
kbHideBtn.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    if not kbCurrent then return end
    local refs=CheckboxRefs[kbCurrent]
    if refs then for _,r in ipairs(refs) do if r.bindBtn then r.bindBtn.Visible=not r.bindBtn.Visible end end end
end)
kbMenuBtn.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    for _,t in pairs(Toggles) do t.Binds = {} end
    bindingFor=nil; kbCurrent=nil; kbBindIdx=1
    KbRefresh(); UpdateAllBinds(); kbPanel.Visible=false
end)

-- ── Refresh ──
local function KbRefresh()
    if not kbCurrent or not Toggles[kbCurrent] then
        kbKeyBtn.Text="-"; kbKeyBtn.TextColor3=Hex("777777")
        kbModeT.BackgroundColor3=C.accent; kbModeT.TextColor3=Color3.new(1,1,1); kbModeTStroke.Color=C.accent
        kbModeH.BackgroundColor3=Hex("222222"); kbModeH.TextColor3=Hex("777777"); kbModeHStroke.Color=Hex("2a2a2a")
        if KbRebuildChips then KbRebuildChips() end
        return
    end
    local t = Toggles[kbCurrent]
    local b = t.Binds[kbBindIdx]
    if bindingFor==kbCurrent then
        kbKeyBtn.Text="Press key..."; kbKeyBtn.TextColor3=C.orange
    elseif b and b.Key then
        kbKeyBtn.Text=b.Key; kbKeyBtn.TextColor3=Color3.new(1,1,1)
    else
        kbKeyBtn.Text="-"; kbKeyBtn.TextColor3=Hex("777777")
    end
    local mode = (b and b.Mode) or "Toggle"
    local isTog = mode ~= "Hold"
    kbModeT.BackgroundColor3 = isTog and C.accent or Hex("222222")
    kbModeT.TextColor3       = isTog and Color3.new(1,1,1) or Hex("777777")
    kbModeTStroke.Color      = isTog and C.accent or Hex("2a2a2a")
    kbModeH.BackgroundColor3 = (not isTog) and C.orange or Hex("222222")
    kbModeH.TextColor3       = (not isTog) and Color3.new(1,1,1) or Hex("777777")
    kbModeHStroke.Color      = (not isTog) and C.orange or Hex("2a2a2a")
    if KbRebuildChips then KbRebuildChips() end
end

-- ── Chips ──
KbRebuildChips = function()
    for _, c in ipairs(kbChips:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    if not kbCurrent or not Toggles[kbCurrent] then return end
    local t = Toggles[kbCurrent]
    for i, b in ipairs(t.Binds) do
        local sel = (i == kbBindIdx)
        local chip = New("TextButton",{
            Size=UDim2.new(0,54,0,24), LayoutOrder=i,
            Text=(b.Key or "-")..","..((b.Mode=="Hold") and "H" or "T"),
            TextColor3=sel and Color3.new(1,1,1) or Hex("777777"),
            BackgroundColor3=sel and C.accent or Hex("1e1e1e"),
            BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=9,
            AutoButtonColor=false,
        }, kbChips)
        Corner(chip, 5)
        Stroke(chip, sel and C.accent or Hex("2e2e2e"), 1)
        local idx = i
        chip.MouseButton1Click:Connect(function()
            _popupIgnoreNextClose = true
            kbBindIdx = idx; if bindingFor then bindingFor=nil end
            local t2 = Toggles[kbCurrent]
            local b2 = t2.Binds[kbBindIdx]
            if b2 and b2.Key then
                kbKeyBtn.Text = b2.Key; kbKeyBtn.TextColor3 = Color3.new(1,1,1)
            else
                kbKeyBtn.Text = "-"; kbKeyBtn.TextColor3 = Hex("777777")
            end
            local mode2 = (b2 and b2.Mode) or "Toggle"
            local isTog2 = mode2 ~= "Hold"
            kbModeT.BackgroundColor3 = isTog2 and C.accent or Hex("222222")
            kbModeT.TextColor3 = isTog2 and Color3.new(1,1,1) or Hex("777777")
            kbModeTStroke.Color = isTog2 and C.accent or Hex("2a2a2a")
            kbModeH.BackgroundColor3 = (not isTog2) and C.orange or Hex("222222")
            kbModeH.TextColor3 = (not isTog2) and Color3.new(1,1,1) or Hex("777777")
            kbModeHStroke.Color = (not isTog2) and C.orange or Hex("2a2a2a")
            KbRebuildChips()
        end)
    end
    -- trailing "+" chip
    local addChip = New("TextButton",{
        Size=UDim2.new(0,24,0,24), LayoutOrder=#t.Binds+1,
        Text="+", TextColor3=C.accent, BackgroundColor3=Hex("1e1e1e"),
        BorderSizePixel=0, Font=Enum.Font.GothamBold, TextSize=12,
        AutoButtonColor=false,
    }, kbChips)
    Corner(addChip, 5)
    Stroke(addChip, Hex("2e2e2e"), 1)
    addChip.MouseButton1Click:Connect(function()
        _popupIgnoreNextClose = true
        table.insert(t.Binds, { Key=nil, Mode="Toggle" })
        kbBindIdx = #t.Binds
        bindingFor = kbCurrent
        kbKeyBtn.Text = "Press key..."
        kbKeyBtn.TextColor3 = C.orange
        kbModeT.BackgroundColor3 = C.accent; kbModeT.TextColor3 = Color3.new(1,1,1); kbModeTStroke.Color = C.accent
        kbModeH.BackgroundColor3 = Hex("222222"); kbModeH.TextColor3 = Hex("777777"); kbModeHStroke.Color = Hex("2a2a2a")
        UpdateBindLabel(kbCurrent)
        KbRebuildChips()
    end)
end

-- ── Key input ──
kbKeyBtnFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _popupIgnoreNextClose = true
        if not kbCurrent or not Toggles[kbCurrent] then return end
        local t = Toggles[kbCurrent]
        if not t.Binds[kbBindIdx] then
            table.insert(t.Binds,{Key=nil,Mode="Toggle"}); kbBindIdx=#t.Binds
        end
        bindingFor=kbCurrent
        kbKeyBtn.Text = "Press key..."
        kbKeyBtn.TextColor3 = C.orange
        UpdateBindLabel(kbCurrent)
    end
end)

-- ── Mode buttons ──
kbModeT.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    if not kbCurrent or not Toggles[kbCurrent] then return end
    local b = Toggles[kbCurrent].Binds[kbBindIdx]
    if not b or not b.Key then return end
    b.Mode="Toggle"
    kbModeT.BackgroundColor3 = C.accent; kbModeT.TextColor3 = Color3.new(1,1,1); kbModeTStroke.Color = C.accent
    kbModeH.BackgroundColor3 = Hex("222222"); kbModeH.TextColor3 = Hex("777777"); kbModeHStroke.Color = Hex("2a2a2a")
    UpdateBindLabel(kbCurrent)
end)
kbModeH.MouseButton1Click:Connect(function()
    _popupIgnoreNextClose = true
    if not kbCurrent or not Toggles[kbCurrent] then return end
    local b = Toggles[kbCurrent].Binds[kbBindIdx]
    if not b or not b.Key then return end
    b.Mode="Hold"
    kbModeT.BackgroundColor3 = Hex("222222"); kbModeT.TextColor3 = Hex("777777"); kbModeTStroke.Color = Hex("2a2a2a")
    kbModeH.BackgroundColor3 = C.orange; kbModeH.TextColor3 = Color3.new(1,1,1); kbModeHStroke.Color = C.orange
    UpdateBindLabel(kbCurrent)
end)

-- ─ Open popup ──
OpenKeybindPopup = function(name)
    if not name or not Toggles[name] then return end
    kbCurrent = name
    kbBindIdx = math.max(1, #Toggles[name].Binds)
    bindingFor = nil
    KbRefresh()
    local mp=UserInput:GetMouseLocation()
    local vp=Camera.ViewportSize
    local pw,ph=320,160
    kbPanel.AnchorPoint=Vector2.new(0,0)
    kbPanel.Size    =UDim2.new(0,pw,0,ph)
    kbPanel.Position=UDim2.new(0,math.clamp(mp.X+6,0,vp.X-pw),
                                0,math.clamp(mp.Y+6,0,vp.Y-ph))
    kbPanel.ZIndex=100; kbPanel.Parent=SGui; kbPanel.Visible=true
end

RefreshKeybindList = function()
    if kbPanel.Visible then KbRefresh() end
end

-- ── Right mid: Log (decorative) ────────────────────────────
local logPanel = Panel(Always, 562, 4, 394, 270, "Log")
local logC = PanelContent(logPanel)
TabStrip(logC, 3, { "Editor", "Options" })
for i,n in ipairs({"File","Load","Unload","Save","Refresh","Unloader"}) do
    SmallBtn(logC, (i-1)*58+4, 22, 54, 16, n)
end
local codeArea = New("Frame", {
    Position=UDim2.new(0,4,0,42), Size=UDim2.new(1,-8,1,-46),
    BackgroundColor3=C.bg, BorderSizePixel=0, ClipsDescendants=true,
}, logC)
Stroke(codeArea, C.border, 1)
local gutter = New("Frame", {
    Size=UDim2.new(0,28,1,0), BackgroundColor3=C.hdr, BorderSizePixel=0,
}, codeArea)
Stroke(gutter, C.border, 1)
New("TextLabel", {
    Position=UDim2.new(0,2,0,6), Size=UDim2.new(1,-4,0,12),
    Text="1", TextColor3=C.dim, BackgroundTransparency=1,
    Font=Enum.Font.Code, TextSize=9,
}, gutter)
New("TextLabel", {
    Position=UDim2.new(0,34,0,6), Size=UDim2.new(1,-38,0,12),
    Text="-- // Derelict ESP loaded", TextColor3=Hex("6a9955"),
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.Code, TextSize=9,
}, codeArea)

-- ── Right bottom: Activity (real) ──────────────────────────
local actPanel = Panel(Always, 562, 278, 394, 270, "Activity")
local actOuter = PanelContent(actPanel)
TabStrip(actOuter, 3, { "Players", "Chat" })
local actScroll = New("ScrollingFrame", {
    Position=UDim2.new(0,4,0,22), Size=UDim2.new(1,-8,1,-24),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=4,
    ScrollBarImageColor3=C.border, CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, actOuter)
local actEntries = {}
local actLabels = {}
local function AddActivity(text, color)
    table.insert(actEntries, 1, { text=text, color=color or C.dim })
    if #actEntries > 80 then
        table.remove(actEntries)
        local last = actLabels[#actLabels]
        if last then last:Destroy() end
        table.remove(actLabels)
    end
    local lbl = New("TextLabel", {
        Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,11),
        Text=text, TextColor3=color or C.dim, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.Gotham, TextSize=8,
        TextTruncate=Enum.TextTruncate.AtEnd,
    }, actScroll)
    table.insert(actLabels, 1, lbl)
    for i, l in ipairs(actLabels) do
        l.Position = UDim2.new(0,0,0,(i-1)*11)
    end
end

-- ── Center bottom: Player List (real) ──────────────────────
local plPanel = Panel(Always, 260, 4, 298, 540, "Player List")
local plOuter = PanelContent(plPanel)
TabStrip(plOuter, 3, { "Players", "Info" })
local plHdr = New("Frame", {
    Position=UDim2.new(0,4,0,23), Size=UDim2.new(1,-8,0,15),
    BackgroundColor3=C.hdr, BorderSizePixel=0,
}, plOuter)
Stroke(plHdr, C.border, 1)
for i, col in ipairs({"Player","Dist (m)","Health"}) do
    New("TextLabel", {
        Position=UDim2.new(0,(i-1)*96,0,0), Size=UDim2.new(0,96,1,0),
        Text=col, TextColor3=C.dim, BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Center,
        Font=Enum.Font.GothamBold, TextSize=9,
    }, plHdr)
end
for _, x in ipairs({96,192}) do
    New("Frame", { Position=UDim2.new(0,x,0,0), Size=UDim2.new(0,1,1,0),
        BackgroundColor3=C.border, BorderSizePixel=0 }, plHdr)
end
local plScroll = New("ScrollingFrame", {
    Position=UDim2.new(0,4,0,40), Size=UDim2.new(1,-8,1,-44),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=4,
    ScrollBarImageColor3=C.border, CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, plOuter)

local plRows = {}
local function UpdatePlayerList()
    local lc = LocalPlayer.Character
    local lr = lc and lc:FindFirstChild("HumanoidRootPart")
    local seen = {}
    local idx = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            idx = idx + 1
            seen[p] = true
            local ch  = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local rt  = ch and ch:FindFirstChild("HumanoidRootPart")
            local dist= (lr and rt) and tostring(math.floor((rt.Position-lr.Position).Magnitude)) or "?"
            local pct = (hum and hum.MaxHealth>0) and math.floor(hum.Health/hum.MaxHealth*100) or nil
            local hp  = pct and (pct.."%") or "?"
            local hpC = C.green
            if pct then
                if pct<25 then hpC=C.red elseif pct<60 then hpC=C.orange end
            end
            local row = plRows[p]
            if not row then
                row = New("Frame", {
                    Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,14),
                    BackgroundColor3=idx%2==0 and C.row_alt or C.panel,
                    BorderSizePixel=0,
                }, plScroll)
                local nameLbl = New("TextLabel", {
                    Position=UDim2.new(0,0,0,0), Size=UDim2.new(0,96,1,0),
                    Text=p.Name, TextColor3=C.text, BackgroundTransparency=1,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Font=Enum.Font.Gotham, TextSize=8,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                }, row)
                local distLbl = New("TextLabel", {
                    Position=UDim2.new(0,96,0,0), Size=UDim2.new(0,96,1,0),
                    TextColor3=C.dim, BackgroundTransparency=1,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Font=Enum.Font.Gotham, TextSize=8,
                }, row)
                local hpLbl = New("TextLabel", {
                    Position=UDim2.new(0,192,0,0), Size=UDim2.new(0,96,1,0),
                    TextColor3=hpC, BackgroundTransparency=1,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Font=Enum.Font.Gotham, TextSize=8,
                }, row)
                for _,x in ipairs({96,192}) do
                    New("Frame", { Position=UDim2.new(0,x,0,0), Size=UDim2.new(0,1,1,0),
                        BackgroundColor3=C.border, BorderSizePixel=0 }, row)
                end
                plRows[p] = { row=row, name=nameLbl, dist=distLbl, hp=hpLbl }
            end
            local r = plRows[p]
            r.row.Position = UDim2.new(0,0,0,(idx-1)*14)
            r.row.BackgroundColor3 = idx%2==0 and C.row_alt or C.panel
            r.dist.Text = dist
            r.hp.Text = hp
            r.hp.TextColor3 = hpC
        end
    end
    for p, r in pairs(plRows) do
        if not seen[p] then
            r.row:Destroy()
            plRows[p] = nil
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- PAGE: MAIN  (character & movement)
-- ═══════════════════════════════════════════════════════════
local pMain = MakePage("Main")
local pMainCfg = Panel(pMain, 4, 4, 252, 540, "Configurations")
local pmc = PanelContent(pMainCfg)
Section(pmc, 4, "Character")
Checkbox(pmc, 20, "Infinite_Stamina", C.orange)
-- Checkbox(pmc, 38, "No_Fall_Damage") -- Removido: feature incompleta
Section(pmc, 60, "Movement")
Checkbox(pmc, 76, "No_Clip")
Checkbox(pmc, 94, "Fly_Mode")
Checkbox(pmc, 112,"Infinite_Jump")

-- ═══════════════════════════════════════════════════════════
-- PAGE: VISUALS  (ESP + Filters + Tools)
-- ═══════════════════════════════════════════════════════════
local pVis = MakePage("Visuals")
local pVisCfg = Panel(pVis, 4, 4, 252, 540, "Configurations")
local pvc = PanelContent(pVisCfg)
Section(pvc, 4, "ESP General")
Checkbox(pvc, 20,  "ESP_Enabled",   C.accent)
Checkbox(pvc, 38,  "Show_Boxes",    C.accent)
Checkbox(pvc, 56,  "Show_Names",    C.accent)
Checkbox(pvc, 74,  "Show_Health",   C.green)
Checkbox(pvc, 92,  "Show_Distance", C.accent)
Checkbox(pvc, 110, "Show_Tracers")
Slider(pvc, 130, "Max Render Distance", "ESP_Distance", 100, 2000)

Section(pvc, 162, "Filters & Colors")
FilterRow(pvc, 178, "Show_Enemies", C.red,    "Color_Enemy")
FilterRow(pvc, 196, "Show_Bosses",  C.purple, "Color_Boss")
FilterRow(pvc, 214, "Show_Items",   C.green,  "Color_Item")
FilterRow(pvc, 232, "Show_Players", C.accent, "Color_Player")

-- ═══════════════════════════════════════════════════════════
-- PAGE: FARM
-- ═══════════════════════════════════════════════════════════
local pFarm = MakePage("Farm")
local pFarmCfg = Panel(pFarm, 4, 4, 252, 540, "Configurations")
local pfc = PanelContent(pFarmCfg)
Section(pfc, 4, "Auto Farm")
Checkbox(pfc, 20, "Auto_Farm")
Checkbox(pfc, 38, "Auto_Boss")
Checkbox(pfc, 56, "Auto_Collect")
Checkbox(pfc, 74, "Skip_Cutscenes")
-- ═══════════════════════════════════════════════════════════
-- PAGE: MISC  (UI controls + info)
-- ═══════════════════════════════════════════════════════════
local pMisc = MakePage("Misc")
local pMiscCfg = Panel(pMisc, 4, 4, 252, 540, "Configurations")
local pmsc = PanelContent(pMiscCfg)
Section(pmsc, 4, "UI")
SmallBtn(pmsc, 8, 22, 80, 18, "Unload", function()
    Notify("Derelict", "Unloading...", "Warning")
    Derelict:DisconnectAll()
    SGui:Destroy()
end)
New("TextLabel", {
    Position=UDim2.new(0,96,0,24), Size=UDim2.new(1,-104,0,14),
    Text="Menu bind:  RightShift", TextColor3=C.dim,
    BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.Gotham, TextSize=9,
}, pmsc)
SmallBtn(pmsc, 8, 46, 80, 18, "Save Config", function()
    local configName = "default"
    local config = {
        Toggles = {},
        Options = {},
        Binds = {},
    }
    for name, t in pairs(Toggles) do
        config.Toggles[name] = t.Value
        config.Binds[name] = {}
        for _, b in ipairs(t.Binds) do
            table.insert(config.Binds[name], { Key=b.Key, Mode=b.Mode })
        end
    end
    for name, o in pairs(Options) do
        local v = o.Value
        if typeof(v) == "Color3" then
            config.Options[name] = { R=v.R, G=v.G, B=v.B }
        else
            config.Options[name] = v
        end
    end
    local serialized = "-- Derelict Config\nreturn " .. tostring(config):gsub("table: 0x%x+", "")
    -- Use a simple Lua table format
    local lines = {"return {"}
    -- Toggles
    table.insert(lines, "  Toggles = {")
    for name, val in pairs(config.Toggles) do
        table.insert(lines, string.format('    ["%s"] = %s,', name, tostring(val)))
    end
    table.insert(lines, "  },")
    -- Options
    table.insert(lines, "  Options = {")
    for name, val in pairs(config.Options) do
        if typeof(val) == "table" and val.R then
            table.insert(lines, string.format('    ["%s"] = Color3.new(%s, %s, %s),', name, val.R, val.G, val.B))
        else
            table.insert(lines, string.format('    ["%s"] = %s,', name, tostring(val)))
        end
    end
    table.insert(lines, "  },")
    -- Binds
    table.insert(lines, "  Binds = {")
    for name, binds in pairs(config.Binds) do
        if #binds > 0 then
            table.insert(lines, string.format('    ["%s"] = {', name))
            for _, b in ipairs(binds) do
                table.insert(lines, string.format('      { Key="%s", Mode="%s" },', b.Key or "", b.Mode or "Toggle"))
            end
            table.insert(lines, "    },")
        end
    end
    table.insert(lines, "  },")
    table.insert(lines, "}")
    local content = table.concat(lines, "\n")
    pcall(function()
        makefolder("Derelict/configs")
        writefile("Derelict/configs/" .. configName .. ".lua", content)
        Notify("Config", "Saved: " .. configName, "Success")
    end)
end)
SmallBtn(pmsc, 96, 46, 80, 18, "Load Config", function()
    pcall(function()
        if isfile("Derelict/configs/default.lua") then
            local chunk = loadfile("Derelict/configs/default.lua")
            if chunk then
                local cfg = chunk()
                if cfg and cfg.Toggles then
                    for name, val in pairs(cfg.Toggles) do
                        if Toggles[name] then Toggles[name]:Set(val) end
                    end
                end
                if cfg and cfg.Options then
                    for name, val in pairs(cfg.Options) do
                        if Options[name] then
                            if typeof(val) == "table" and val.R then
                                Options[name]:Set(Color3.new(val.R, val.G, val.B))
                            else
                                Options[name]:Set(val)
                            end
                        end
                    end
                end
                if cfg and cfg.Binds then
                    for name, binds in pairs(cfg.Binds) do
                        if Toggles[name] then
                            Toggles[name].Binds = {}
                            for _, b in ipairs(binds) do
                                if b.Key and b.Key ~= "" then
                                    table.insert(Toggles[name].Binds, { Key=b.Key, Mode=b.Mode or "Toggle" })
                                end
                            end
                        end
                    end
                    UpdateAllBinds()
                end
                Notify("Config", "Loaded: default", "Success")
            end
        else
            Notify("Config", "No config found", "Error")
        end
    end)
end)

Section(pmsc, 76, "About")
New("TextLabel", {
    Position=UDim2.new(0,8,0,92), Size=UDim2.new(1,-16,0,80),
    Text="Derelict | Competitive Hub\nCustom UI build (no Linoria)\nClick [+] next to any toggle\nto bind a key. Right-click the\nbind to switch Toggle/Hold or\nclear it.",
    TextColor3=C.dim, BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,
    TextWrapped=true, Font=Enum.Font.Gotham, TextSize=9,
}, pmsc)

-- ═══════════════════════════════════════════════════════════
-- INITIAL TAB
-- ═══════════════════════════════════════════════════════════
local function ShowTab(name)
    for n, frame in pairs(Pages) do frame.Visible = (n == name) end
    for n, lbl in pairs(NavLabels) do
        local active = (n == name)
        lbl.TextColor3 = active and C.text or C.dim
        lbl.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
        NavUnderlines[n].BackgroundColor3 = active and C.accent or C.bg
    end
end
ShowTab("Visuals")

-- ═══════════════════════════════════════════════════════════
-- KEYBIND CAPTURE  +  BIND HANDLING
-- ═══════════════════════════════════════════════════════════
track(UserInput.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode.Name

    -- 1) capture mode
    if bindingFor then
        if key == "Escape" then
            local n = bindingFor; bindingFor = nil; UpdateBindLabel(n)
            return
        end
        local t = Toggles[bindingFor]
        -- Direct-click capture targets bind #1; popup capture targets the selected chip
        local idx = (kbPanel.Visible and bindingFor == kbCurrent) and kbBindIdx or 1
        if not t.Binds[idx] then
            t.Binds[idx] = { Key=key, Mode="Toggle" }
        else
            t.Binds[idx].Key  = key
            t.Binds[idx].Mode = t.Binds[idx].Mode or "Toggle"
        end
        local n = bindingFor; bindingFor = nil
        UpdateBindLabel(n); RefreshKeybindList()
        return
    end

    -- 2) menu toggle (hard-coded RightShift)
    if key == "RightShift" then 
        Main.Visible = not Main.Visible
        if not Main.Visible then ClosePopup() end
        return 
    end

    -- 3) block inputs when chat/textbox is focused
    local focused = pcall(function() return UserInput:GetFocusedObject() end) and UserInput:GetFocusedObject()
    if focused and focused:IsA("TextBox") then return end

    if processed then return end

    -- 4) bound toggles (multi-bind: iterate every bind entry)
    for _, t in pairs(Toggles) do
        for _, b in ipairs(t.Binds) do
            if b.Key == key then
                if b.Mode == "Toggle" then t:Set(not t.Value)
                elseif b.Mode == "Hold"   then t:Set(true) end
                break
            end
        end
    end
end))
track(UserInput.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode.Name
    for _, t in pairs(Toggles) do
        for _, b in ipairs(t.Binds) do
            if b.Key == key and b.Mode == "Hold" then t:Set(false); break end
        end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- DRAG
-- ═══════════════════════════════════════════════════════════
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=Main.Position
        end
    end)
    TitleBar.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                                      startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    TitleBar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- BACKEND: SPOOFER HOOKS (Infinite Stamina)
-- ═══════════════════════════════════════════════════════════
do
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then
        local oldNamecall = mt.__namecall
        local oldIndex    = mt.__index
        pcall(setreadonly, mt, false)

        -- Use closure() as fallback if newcclosure is not available in Potassium
        local closureFunc = newcclosure or closure or function(f) return f end

        mt.__namecall = closureFunc(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}
            if Toggles.Infinite_Stamina.Value and not (checkcaller and checkcaller()) then
                if method == "GetAttribute" and type(args[1]) == "string" then
                    local a = string.lower(args[1])
                    if a == "stamina" or a == "energy" then return 1000 end
                end
            end
            return oldNamecall(self, ...)
        end)

        mt.__index = closureFunc(function(t, k)
            if Toggles.Infinite_Stamina.Value and not (checkcaller and checkcaller()) then
                if tostring(k) == "Value" and typeof(t) == "Instance" then
                    local n = string.lower(t.Name)
                    if n == "stamina" or n == "energy" then return 1000 end
                end
            end
            return oldIndex(t, k)
        end)

        pcall(setreadonly, mt, true)
    end
end

-- ═══════════════════════════════════════════════════════════
-- BACKEND: ESP RENDERING
-- ═══════════════════════════════════════════════════════════
local espObjects = {}

local function createDrawingObj(dtype, props)
    local d = Drawing.new(dtype)
    for k,v in pairs(props) do d[k] = v end
    return d
end
local function worldToScreen(pos)
    local s, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on, s.Z
end
local function createESP(target, espType)
    local e = { target=target, type=espType, drawings={} }
    e.drawings.name = createDrawingObj("Text", { Size=13, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Font=Drawing.Fonts.UI, Visible=false })
    e.drawings.box = createDrawingObj("Square", { Thickness=1, Filled=false, Visible=false, Transparency=1 })
    e.drawings.boxOutline = createDrawingObj("Square", { Thickness=3, Color=Color3.new(0,0,0), Filled=false, Visible=false, Transparency=0.5 })
    e.drawings.tracer = createDrawingObj("Line", { Thickness=1, Visible=false, Transparency=0.8 })
    e.drawings.healthBar = createDrawingObj("Square", { Thickness=1, Color=Color3.fromRGB(0,255,0), Filled=true, Visible=false })
    e.drawings.healthBarBg = createDrawingObj("Square", { Thickness=1, Color=Color3.fromRGB(20,20,20), Filled=true, Visible=false })
    e.drawings.distance = createDrawingObj("Text", { Size=11, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Color=Color3.fromRGB(200,200,200), Font=Drawing.Fonts.UI, Visible=false })
    return e
end
local function destroyESP(e) for _,d in pairs(e.drawings) do pcall(function() d:Remove() end) end end
local function hideESP(e)
    if e.hidden then return end
    for _,d in pairs(e.drawings) do d.Visible=false end
    e.hidden = true
end

local function isPlayer(model)
    for _, p in ipairs(Players:GetPlayers()) do if p.Character == model then return true end end
    return false
end
local function isBoss(model)
    local n = model.Name:lower()
    if n:find("boss") or n:find("guardian") or n:find("king") then return true end
    local h = model:FindFirstChildOfClass("Humanoid")
    return h and h.MaxHealth >= 500
end
local function isEnemy(model)
    local h = model:FindFirstChildOfClass("Humanoid")
    if not h or isPlayer(model) or h.Health <= 0 then return false end
    return true
end
local function isItem(obj)
    local n = obj.Name:lower()
    if n:find("item") or n:find("loot") or n:find("chest") or n:find("ore") or n:find("herb") then return true end
    return obj:FindFirstChildOfClass("ProximityPrompt") ~= nil
end

local function getPos(target)
    if target:IsA("Model") then
        local r = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target:FindFirstChildWhichIsA("BasePart")
        if r then return r.Position end
    elseif target:IsA("BasePart") then return target.Position end
    return nil
end

local function updateESP(e)
    if not Toggles.ESP_Enabled.Value then return hideESP(e) end
    if not e.target or not e.target.Parent then return hideESP(e) end
    if e.type=="enemy"  and not Toggles.Show_Enemies.Value then return hideESP(e) end
    if e.type=="boss"   and not Toggles.Show_Bosses.Value  then return hideESP(e) end
    if e.type=="item"   and not Toggles.Show_Items.Value   then return hideESP(e) end
    if e.type=="player" and not Toggles.Show_Players.Value then return hideESP(e) end

    local pos = getPos(e.target); if not pos then return hideESP(e) end
    local lc  = LocalPlayer.Character
    local lr  = lc and lc:FindFirstChild("HumanoidRootPart")
    if not lr then return hideESP(e) end

    local dist = (pos - lr.Position).Magnitude
    if dist > Options.ESP_Distance.Value then return hideESP(e) end

    local hp, mhp
    if e.target:IsA("Model") then
        local h = e.target:FindFirstChildOfClass("Humanoid")
        if h then hp, mhp = h.Health, h.MaxHealth end
    end
    if hp and hp <= 0 then return hideESP(e) end

    local color = Options.Color_Enemy.Value
    if e.type=="boss"   then color = Options.Color_Boss.Value
    elseif e.type=="item"   then color = Options.Color_Item.Value
    elseif e.type=="player" then color = Options.Color_Player.Value end

    local size = Vector3.new(4,5,4)
    local screenTop, onTop = worldToScreen(pos + Vector3.new(0, size.Y/2+1, 0))
    local screenBot       = worldToScreen(pos - Vector3.new(0, size.Y/2+1, 0))
    local screenCen, onC  = worldToScreen(pos)
    if not onC then return hideESP(e) end

    -- Z-ORDER: clip drawings that would render over the menu rectangle
    if Main and Main.Visible then
        local mp, ms = Main.AbsolutePosition, Main.AbsoluteSize
        local function inM(v) return v.X>=mp.X and v.X<=mp.X+ms.X and v.Y>=mp.Y and v.Y<=mp.Y+ms.Y end
        if inM(screenCen) or inM(screenTop) or inM(screenBot) then return hideESP(e) end
    end

    e.hidden = false    -- past all the early-returns, this ESP will draw

    local boxH = math.abs(screenBot.Y - screenTop.Y)
    local boxW = boxH * 0.55

    if Toggles.Show_Names.Value then
        e.drawings.name.Text     = e.target.Name
        e.drawings.name.Position = Vector2.new(screenTop.X, screenTop.Y - 15)
        e.drawings.name.Color    = color
        e.drawings.name.Visible  = true
    else e.drawings.name.Visible = false end

    if Toggles.Show_Boxes.Value then
        e.drawings.boxOutline.Position = Vector2.new(screenCen.X - boxW/2, screenTop.Y)
        e.drawings.boxOutline.Size     = Vector2.new(boxW, boxH)
        e.drawings.boxOutline.Visible  = true
        e.drawings.box.Position = Vector2.new(screenCen.X - boxW/2, screenTop.Y)
        e.drawings.box.Size     = Vector2.new(boxW, boxH)
        e.drawings.box.Color    = color
        e.drawings.box.Visible  = true
    else
        e.drawings.box.Visible        = false
        e.drawings.boxOutline.Visible = false
    end

    if Toggles.Show_Tracers.Value then
        e.drawings.tracer.From    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        e.drawings.tracer.To      = screenBot
        e.drawings.tracer.Color   = color
        e.drawings.tracer.Visible = true
    else e.drawings.tracer.Visible = false end

    if Toggles.Show_Health.Value and hp and mhp then
        local bx = screenCen.X - boxW/2 - 5
        local by = screenTop.Y
        e.drawings.healthBarBg.Position = Vector2.new(bx, by)
        e.drawings.healthBarBg.Size     = Vector2.new(2, boxH)
        e.drawings.healthBarBg.Visible  = true
        local pct = math.clamp(hp/mhp, 0, 1)
        e.drawings.healthBar.Position = Vector2.new(bx, by + boxH*(1-pct))
        e.drawings.healthBar.Size     = Vector2.new(2, boxH*pct)
        e.drawings.healthBar.Color    = Color3.fromRGB(255*(1-pct), 255*pct, 0)
        e.drawings.healthBar.Visible  = true
    else
        e.drawings.healthBar.Visible   = false
        e.drawings.healthBarBg.Visible = false
    end

    if Toggles.Show_Distance.Value then
        e.drawings.distance.Text     = math.floor(dist).."m"
        e.drawings.distance.Position = Vector2.new(screenCen.X, screenBot.Y + 2)
        e.drawings.distance.Visible  = true
    else e.drawings.distance.Visible = false end
end

-- ── Scanner loop ──
local function checkESP(obj)
    if not SGui.Parent then return end
    if obj:IsA("Model") and not espObjects[obj] and isEnemy(obj) then
        espObjects[obj] = createESP(obj, isBoss(obj) and "boss" or "enemy")
    end
    if (obj:IsA("Model") or obj:IsA("BasePart")) and not espObjects[obj] and isItem(obj) then
        espObjects[obj] = createESP(obj, "item")
    end
end

-- Initial scan: only top-level Models (fast), DescendantAdded catches nested items
spawn(function()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") then checkESP(obj) end
    end
end)
track(workspace.DescendantAdded:Connect(checkESP))

-- Periodic: cleanup dead ESPs + register new players
spawn(function()
    while SGui.Parent do
        for tgt, e in pairs(espObjects) do
            if not tgt or not tgt.Parent then destroyESP(e); espObjects[tgt] = nil end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not espObjects[p.Character] then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then
                    espObjects[p.Character] = createESP(p.Character, "player")
                end
            end
        end
        wait(2)
    end
end)

-- ── Render loop ────────────────────────────────────────────
track(RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    for _, e in pairs(espObjects) do pcall(updateESP, e) end
end))

-- ═══════════════════════════════════════════════════════════
-- BACKEND: NO FALL DAMAGE / INFINITE JUMP / FLY / NOCLIP
-- ═══════════════════════════════════════════════════════════
local function getHum() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end

-- Infinite Jump
local infJumpBV, infJumpConn
local function StopInfJump()
    if infJumpBV then infJumpBV:Destroy(); infJumpBV = nil end
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
end
local function StartInfJump()
    StopInfJump()
    local r = getRoot()
    if not r then return end
    infJumpBV = Instance.new("BodyVelocity")
    infJumpBV.MaxForce = Vector3.new(0, 1e5, 0)
    infJumpBV.Velocity = Vector3.zero
    infJumpBV.Parent = r
    infJumpConn = RunService.Heartbeat:Connect(function()
        if not Toggles.Infinite_Jump.Value then return end
        local h = getHum()
        local r2 = getRoot()
        if not h or not r2 or not infJumpBV then return end
        if h.FloorMaterial == Enum.Material.Air and UserInput:IsKeyDown(Enum.KeyCode.Space) then
            infJumpBV.Velocity = Vector3.new(0, 50, 0)
        else
            infJumpBV.Velocity = Vector3.zero
        end
    end)
end
Toggles.Infinite_Jump:OnChanged(function(v)
    if v then
        StartInfJump()
        Notify("Infinite Jump", "Enabled", "Success")
    else
        StopInfJump()
        Notify("Infinite Jump", "Disabled", "Info")
    end
end)

-- Fly
local flyBV, flyBG, flyConn
local function StopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    if flyConn then flyConn:Disconnect(); flyConn=nil end
end
local function StartFly()
    StopFly()
    local r = getRoot(); if not r then return end
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1e9,1e9,1e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = r
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9); flyBG.P = 1e4; flyBG.Parent = r
    flyConn = RunService.Heartbeat:Connect(function()
        if not Toggles.Fly_Mode.Value then return end
        local r2 = getRoot(); if not r2 or not flyBV then return end
        flyBG.CFrame = Camera.CFrame
        local move = Vector3.zero
        local cf = Camera.CFrame
        if UserInput:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        flyBV.Velocity = move.Magnitude > 0 and move.Unit*Options.Fly_Speed.Value or Vector3.zero
    end)
end
Toggles.Fly_Mode:OnChanged(function(v)
    if v then
        StartFly()
        Notify("Fly Mode", "Enabled - Speed: "..Options.Fly_Speed.Value, "Success")
    else
        StopFly()
        Notify("Fly Mode", "Disabled", "Info")
    end
end)

-- ═══════════════════════════════════════════════════════════
-- REAL ACTIVITY EVENTS
-- ═══════════════════════════════════════════════════════════
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        AddActivity("  "..p.Name.."  is in the server.", C.dim)
    end
end
track(Players.PlayerAdded:Connect(function(p)
    AddActivity("  Player "..p.Name.."  has Joined.", C.green)
    wait(0.1); UpdatePlayerList()
end))
track(Players.PlayerRemoving:Connect(function(p)
    AddActivity("  Player "..p.Name.."  has Left.", C.red)
    wait(0.1); UpdatePlayerList()
end))

-- ═══════════════════════════════════════════════════════════
-- INITIAL UPDATES + PERIODIC REFRESH
-- ═══════════════════════════════════════════════════════════
UpdatePlayerList()
RefreshKeybindList()

do  -- physics helpers + UI refresh
    local _t = 0
    -- Rebuild Infinite Jump on character respawn
    track(LocalPlayer.CharacterAdded:Connect(function()
        if Toggles.Infinite_Jump.Value then
            wait(0.5)
            StartInfJump()
        end
    end))
    -- NoClip part cache: rebuilt on character respawn, kept in sync via DescendantAdded
    local noclipConn = nil
    local noclipParts, noclipChar, noclipChildConn = {}, nil, nil
    local function rebuildNoclipCache()
        noclipParts = {}
        local ch = LocalPlayer.Character
        noclipChar = ch
        if noclipChildConn then noclipChildConn:Disconnect(); noclipChildConn = nil end
        if not ch then return end
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then table.insert(noclipParts, p) end
        end
        noclipChildConn = ch.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then table.insert(noclipParts, d) end
        end)
        track(noclipChildConn)
    end
    track(LocalPlayer.CharacterAdded:Connect(rebuildNoclipCache))
    if LocalPlayer.Character then rebuildNoclipCache() end

    Toggles.No_Clip:OnChanged(function(v)
        if v then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    if LocalPlayer.Character ~= noclipChar then rebuildNoclipCache() end
                    for i = 1, #noclipParts do
                        local p = noclipParts[i]
                        if p.CanCollide then p.CanCollide = false end
                    end
                end)
                track(noclipConn)
            end
            Notify("No Clip", "Enabled - Collision disabled", "Success")
        else
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
            end
            Notify("No Clip", "Disabled - Collision restored", "Info")
        end
    end)

    track(RunService.Heartbeat:Connect(function(dt)
        -- Player list refresh (throttled to 2s)
        _t = _t + dt
        if _t >= 2 then _t=0; UpdatePlayerList() end
    end))
end

-- Cleanup on GUI destroy
SGui.AncestryChanged:Connect(function()
    if not SGui.Parent then
        Derelict:DisconnectAll()
        for _, e in pairs(espObjects) do destroyESP(e) end
        espObjects = {}
    end
end)

-- ═══════════════════════════════════════════════════════════
local function applyTypography(d)
    if not (d:IsA("TextLabel") or d:IsA("TextButton")) then return end
    d.Font = Enum.Font.Code          -- closest pixel-perfect monospace to ProggyTiny
    d.TextStrokeColor3 = Color3.new(0, 0, 0)
    -- stronger outline for saturated (coloured) text; subtle for white/grey
    local c = d.TextColor3
    local sat = math.max(math.abs(c.R-c.G), math.abs(c.G-c.B), math.abs(c.R-c.B))
    d.TextStrokeTransparency = sat > 0.12 and 0.3 or 0.78
end
-- Pass over everything already built
for _, d in ipairs(SGui:GetDescendants()) do applyTypography(d) end
-- Auto-apply to dynamic rows (player list, activity, keybind list entries, etc.)
track(SGui.DescendantAdded:Connect(function(d)
    spawn(function()
        if d.Parent then applyTypography(d) end
    end)
end))

print("[Derelict v"..Derelict.Version.."] loaded — right-click [+] on any row to open the keybind popup.")
