-- ============================================================
-- DERELICT UI - Visual copy (NO functional code)
-- ============================================================
local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui  = LocalPlayer:WaitForChild("PlayerGui")

-- ───────────────────────────────────────────────────────────
-- HELPERS
-- ───────────────────────────────────────────────────────────
local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", { Color = color or Color3.fromRGB(45,45,45), Thickness = thickness or 1 }, parent)
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 2) }, parent)
end

local function Hex(h)
    h = h:gsub("#","")
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
    bg      = Hex("0d0d0d"),
    panel   = Hex("131313"),
    hdr     = Hex("1a1a1a"),
    border  = Hex("2d2d2d"),
    text    = Hex("cccccc"),
    dim     = Hex("777777"),
    accent  = Hex("4a9eff"),
    red     = Hex("e84343"),
    orange  = Hex("e87d1e"),
    green   = Hex("3ecf5b"),
    purple  = Hex("9b59b6"),
    row_alt = Hex("111111"),
}

-- ───────────────────────────────────────────────────────────
-- SCREEN GUI + MAIN WINDOW
-- ───────────────────────────────────────────────────────────
local SGui = New("ScreenGui", {
    Name = "DerelictUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, PlayerGui)

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 960, 0, 590),
    Position = UDim2.new(0.5, -480, 0.5, -295),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
}, SGui)
Stroke(Main, C.border, 1)

-- ── Title bar ──────────────────────────────────────────────
local TitleBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundColor3 = C.hdr,
    BorderSizePixel = 0,
}, Main)
Stroke(TitleBar, C.border, 1)

New("TextLabel", {
    Size  = UDim2.new(1, -90, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    Text  = "Derelict | Competitive Hub",
    TextColor3 = C.text,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font  = Enum.Font.GothamBold,
    TextSize = 11,
}, TitleBar)

-- close / minimise buttons
for i, lbl in ipairs({"_", "X"}) do
    local btn = New("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -22*i, 0, 0),
        Text = lbl,
        TextColor3 = C.dim,
        BackgroundColor3 = i == 1 and C.hdr or Hex("5a1010"),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
    }, TitleBar)
    if i == 1 then btn.MouseButton1Click:Connect(function() Main.Visible = false end) end
end

-- ── Top nav tabs ───────────────────────────────────────────
local NavBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundColor3 = Hex("0f0f0f"),
    BorderSizePixel = 0,
}, Main)
Stroke(NavBar, C.border, 1)

local navTabs = {"Lock", "Pages", "xx tab", "Misc", "Settings"}
for i, name in ipairs(navTabs) do
    New("TextLabel", {
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(0, (i-1)*72 + 4, 0, 0),
        Text = name,
        TextColor3 = i == 1 and C.text or C.dim,
        BackgroundTransparency = 1,
        Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = 10,
    }, NavBar)
end

-- thin underline on selected tab
New("Frame", {
    Size = UDim2.new(0, 70, 0, 2),
    Position = UDim2.new(0, 4, 1, -2),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, NavBar)

-- ── Content area ───────────────────────────────────────────
local Content = New("Frame", {
    Size = UDim2.new(1, 0, 1, -42),
    Position = UDim2.new(0, 0, 0, 42),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, Main)

-- ═══════════════════════════════════════════════════════════
-- WIDGET FACTORIES
-- ═══════════════════════════════════════════════════════════

-- Panel with header label
local function Panel(parent, x, y, w, h, title)
    local f = New("Frame", {
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, w, 0, h),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    Stroke(f, C.border, 1)

    if title then
        local hdr = New("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundColor3 = C.hdr,
            BorderSizePixel = 0,
        }, f)
        Stroke(hdr, C.border, 1)
        New("TextLabel", {
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Text = title,
            TextColor3 = C.text,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
        }, hdr)
    end
    return f
end

-- Scroll-able inner frame starting below the 18px header
local function PanelContent(panel)
    return New("Frame", {
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 1, -18),
        BackgroundTransparency = 1,
    }, panel)
end

-- Checkbox row
local function Checkbox(parent, y, label, checked, color)
    local row = New("Frame", {
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 15),
        BackgroundTransparency = 1,
    }, parent)
    local col = checked and (color or C.accent) or C.bg
    local box = New("Frame", {
        Position = UDim2.new(0, 8, 0.5, -5),
        Size = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = col,
        BorderSizePixel = 0,
    }, row)
    Stroke(box, checked and (color or C.accent) or C.border, 1)
    if checked then
        New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "✓",
            TextColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 8,
        }, box)
    end
    New("TextLabel", {
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -26, 1, 0),
        Text = label,
        TextColor3 = C.text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 10,
    }, row)
end

-- Labeled value row (right-aligned value)
local function LabelValue(parent, y, label, value)
    local row = New("Frame", {
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
    }, parent)
    New("TextLabel", {
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.62, 0, 1, 0),
        Text = label,
        TextColor3 = C.dim,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 9,
    }, row)
    New("TextLabel", {
        Position = UDim2.new(0.62, 0, 0, 0),
        Size = UDim2.new(0.38, -8, 1, 0),
        Text = tostring(value),
        TextColor3 = C.text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.Gotham,
        TextSize = 9,
    }, row)
end

-- Slider
local function Slider(parent, y, label, value, min, max)
    local row = New("Frame", {
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
    }, parent)
    New("TextLabel", {
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.65, 0, 0, 12),
        Text = label,
        TextColor3 = C.dim,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 9,
    }, row)
    New("TextLabel", {
        Position = UDim2.new(0.65, 0, 0, 0),
        Size = UDim2.new(0.35, -8, 0, 12),
        Text = tostring(value),
        TextColor3 = C.text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.Gotham,
        TextSize = 9,
    }, row)
    local track = New("Frame", {
        Position = UDim2.new(0, 8, 0, 15),
        Size = UDim2.new(1, -16, 0, 4),
        BackgroundColor3 = C.border,
        BorderSizePixel = 0,
    }, row)
    Corner(track, 4)
    local pct = math.clamp((value - min) / (max - min), 0, 1)
    local fill = New("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, track)
    Corner(fill, 4)
    -- thumb
    New("Frame", {
        Position = UDim2.new(pct, -4, 0.5, -4),
        Size = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
    }, track)
end

-- Section separator + label
local function Section(parent, y, text)
    New("TextLabel", {
        Position = UDim2.new(0, 8, 0, y),
        Size = UDim2.new(1, -16, 0, 12),
        Text = text,
        TextColor3 = C.accent,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
    }, parent)
    New("Frame", {
        Position = UDim2.new(0, 8, 0, y + 12),
        Size = UDim2.new(1, -16, 0, 1),
        BackgroundColor3 = C.border,
        BorderSizePixel = 0,
    }, parent)
end

-- Small header-button (for toolbars)
local function Btn(parent, x, y, w, h, text)
    local b = New("TextButton", {
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, w, 0, h),
        Text = text,
        TextColor3 = C.text,
        BackgroundColor3 = C.hdr,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 9,
    }, parent)
    Stroke(b, C.border, 1)
    return b
end

-- Tab strip (Players / Colors etc.)
local function TabStrip(parent, y, tabs)
    local row = New("Frame", {
        Position = UDim2.new(0, 4, 0, y),
        Size = UDim2.new(1, -8, 0, 16),
        BackgroundTransparency = 1,
    }, parent)
    for i, name in ipairs(tabs) do
        New("TextLabel", {
            Position = UDim2.new(0, (i-1)*55, 0, 0),
            Size = UDim2.new(0, 50, 1, 0),
            Text = name,
            TextColor3 = i == 1 and C.text or C.dim,
            BackgroundTransparency = 1,
            Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham,
            TextSize = 9,
        }, row)
    end
    -- underline first tab
    New("Frame", {
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(0, 50, 0, 2),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, row)
end

-- ═══════════════════════════════════════════════════════════
-- LEFT COLUMN – CONFIGURATIONS  (x=4, y=4, w=252, h=288)
-- ═══════════════════════════════════════════════════════════
local cfgPanel = Panel(Content, 4, 4, 252, 290, "Configurations")
local cfg = PanelContent(cfgPanel)

-- inner tab bar
local cfgTabBar = New("Frame", {
    Position = UDim2.new(0, 4, 0, 3),
    Size = UDim2.new(1, -8, 0, 15),
    BackgroundTransparency = 1,
}, cfg)
for i, t in ipairs({"Anti-Aim", "Pages", "xx tab", "Misc", "Settings"}) do
    New("TextLabel", {
        Position = UDim2.new(0, (i-1)*47, 0, 0),
        Size = UDim2.new(0, 44, 1, 0),
        Text = t,
        TextColor3 = i == 1 and C.text or C.dim,
        BackgroundTransparency = 1,
        Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = 9,
    }, cfgTabBar)
end

Section(cfg, 20, "Anti-Aim")
LabelValue(cfg, 35,  "Enabled",              "Enabled")
LabelValue(cfg, 50,  "Target Detection",     "Mode Selector / try")
LabelValue(cfg, 65,  "Smoothing",            "Always Off")
LabelValue(cfg, 80,  "Sample+Shape Movement","turn")
LabelValue(cfg, 95,  "Legit Check",          "Hold")
LabelValue(cfg, 110, "Recoil",               "Off / Hop")

Section(cfg, 127, "Aim")
Slider(cfg, 143, "FOV",           75,  0,   180)
Slider(cfg, 172, "Max Distance",  500, 100, 2000)
Slider(cfg, 201, "Key Speed",     47,  0,   100)
Slider(cfg, 230, "Sway Delay",    100, 0,   500)
Slider(cfg, 259, "Reaction Time", 50,  0,   200)

-- ═══════════════════════════════════════════════════════════
-- LEFT COLUMN – TRIGGER BOT  (x=4, y=298, w=252, h=246)
-- ═══════════════════════════════════════════════════════════
local trgPanel = Panel(Content, 4, 298, 252, 246, "Trigger Bot")
local trg = PanelContent(trgPanel)

Section(trg, 3, "General")
Checkbox(trg, 18, "Enabled",         true,  C.accent)
Checkbox(trg, 35, "Head Only",       false)
Checkbox(trg, 50, "Lean AutoOnly",   false)
Checkbox(trg, 65, "In-FOV Mode",     true,  C.green)

-- inner bordered sub-block
local trgBox = New("Frame", {
    Position = UDim2.new(0, 6, 0, 83),
    Size = UDim2.new(1, -12, 0, 44),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, trg)
Stroke(trgBox, C.border, 1)
New("TextLabel", {
    Position = UDim2.new(0, 6, 0, 2),
    Size = UDim2.new(1, -12, 0, 12),
    Text = "cc Mods          In-Fo Mode",
    TextColor3 = C.dim,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham,
    TextSize = 9,
}, trgBox)
-- small colour swatch
New("Frame", {
    Position = UDim2.new(0, 6, 0, 17),
    Size = UDim2.new(0, 30, 0, 18),
    BackgroundColor3 = C.border,
    BorderSizePixel = 0,
}, trgBox)
-- "try" text tag
New("TextLabel", {
    Position = UDim2.new(0, 160, 0, 20),
    Size = UDim2.new(0, 30, 0, 12),
    Text = "try",
    TextColor3 = C.dim,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 8,
}, trgBox)

Section(trg, 132, "Timing")
Slider(trg, 148, "Reaction Time", 100, 0, 500)
Slider(trg, 177, "FOV",           5,   0, 100)
Slider(trg, 206, "Max Distance",  300, 100, 2000)

-- ═══════════════════════════════════════════════════════════
-- CENTER COLUMN – TOOLS  (x=260, y=4, w=298, h=268)
-- ═══════════════════════════════════════════════════════════
local toolsPanel = Panel(Content, 260, 4, 298, 268, "Tools")
local tools = PanelContent(toolsPanel)

-- Save / Refresh buttons inside the header
Btn(toolsPanel, 200, 0, 50, 18, "Save")
Btn(toolsPanel, 254, 0, 42, 18, "Refresh")

local toolItems = {
    { "Outline",    true,  C.red    },
    { "Aimbot",     true,  C.red    },
    { "Linoria",    true,  C.accent },
    { "Trigger",    true,  C.orange },
    { "Linoria",    true,  C.accent },
    { "Toggle",     false           },
    { "Prediction", false           },
    { "Test Box",   false           },
    { "Building",   false           },
    { "Resolver",   false           },
    { "Test Color", false           },
    { "On Others",  false           },
}

for i, item in ipairs(toolItems) do
    Checkbox(tools, (i-1)*18 + 4, item[1], item[2], item[3])
    -- small arrow/chevron on each row
    New("TextLabel", {
        Position = UDim2.new(1, -14, 0, (i-1)*18 + 4),
        Size = UDim2.new(0, 12, 0, 14),
        Text = "›",
        TextColor3 = C.dim,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, tools)
end

-- ═══════════════════════════════════════════════════════════
-- CENTER COLUMN – ENEMY LIST  (x=260, y=276, w=298, h=268)
-- ═══════════════════════════════════════════════════════════
local enemyPanel = Panel(Content, 260, 276, 298, 268, "Enemy List")
local enemy = PanelContent(enemyPanel)

TabStrip(enemy, 3, {"Players", "Colors"})

-- Table column header
local tblHdr = New("Frame", {
    Position = UDim2.new(0, 4, 0, 23),
    Size = UDim2.new(1, -8, 0, 15),
    BackgroundColor3 = C.hdr,
    BorderSizePixel = 0,
}, enemy)
Stroke(tblHdr, C.border, 1)
for i, col in ipairs({"Player", "Team", "Priority"}) do
    New("TextLabel", {
        Position = UDim2.new(0, (i-1)*96, 0, 0),
        Size = UDim2.new(0, 96, 1, 0),
        Text = col,
        TextColor3 = C.dim,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
    }, tblHdr)
end

-- Separator lines between columns
for _, xOff in ipairs({96, 192}) do
    New("Frame", {
        Position = UDim2.new(0, xOff, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = C.border,
        BorderSizePixel = 0,
    }, tblHdr)
end

local playerRows = {
    { "FleckSamsame",      "Phantoms", "Neutral" },
    { "lgynx3017",         "Phantoms", "Neutral" },
    { "yeet-bro",          "Phantoms", "Neutral" },
    { "sper.unlock0x2.90", "Phantoms", "Neutral" },
    { "BlackSockman",      "Phantoms", "Neutral" },
    { "kuzent2",           "Phantoms", "Neutral" },
    { "cam.brena",         "Phantoms", "Neutral" },
    { "xskiiill",          "Phantoms", "Neutral" },
    { "NSPR",              "Phantoms", "Neutral" },
    { "Twinkle_pie",       "Phantoms", "Neutral" },
    { "SiCiD_091736",      "Phantoms", "Neutral" },
    { "harlem.dave17482",  "Phantoms", "Neutral" },
    { "xschamun",          "Phantoms", "Neutral" },
    { "BlackDragon17",     "Ghosts",   "Neutral" },
    { "Antcrazy494",       "Ghosts",   "Neutral" },
}

for i, row in ipairs(playerRows) do
    local r = New("Frame", {
        Position = UDim2.new(0, 4, 0, 38 + (i-1)*13),
        Size = UDim2.new(1, -8, 0, 13),
        BackgroundColor3 = i % 2 == 0 and C.row_alt or C.panel,
        BorderSizePixel = 0,
    }, enemy)
    for j, val in ipairs(row) do
        New("TextLabel", {
            Position = UDim2.new(0, (j-1)*96, 0, 0),
            Size = UDim2.new(0, 96, 1, 0),
            Text = val,
            TextColor3 = j == 1 and C.text or (j == 3 and C.dim or C.dim),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.Gotham,
            TextSize = 8,
        }, r)
    end
    -- column separators
    for _, xOff in ipairs({96, 192}) do
        New("Frame", {
            Position = UDim2.new(0, xOff, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = C.border,
            BorderSizePixel = 0,
        }, r)
    end
end

-- ═══════════════════════════════════════════════════════════
-- RIGHT COLUMN – KEY BIND(S)  (x=562, y=4, w=394, h=44)
-- ═══════════════════════════════════════════════════════════
local kbPanel = Panel(Content, 562, 4, 394, 44, "Key bind(s)")
local kb = PanelContent(kbPanel)

New("TextLabel", {
    Position = UDim2.new(0, 8, 0, 4),
    Size = UDim2.new(1, -16, 0, 14),
    Text = "[M]  Any Aimput",
    TextColor3 = C.text,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham,
    TextSize = 10,
}, kb)

-- ═══════════════════════════════════════════════════════════
-- RIGHT COLUMN – LOG  (x=562, y=52, w=394, h=240)
-- ═══════════════════════════════════════════════════════════
local logPanel = Panel(Content, 562, 52, 394, 240, "Log")
local log = PanelContent(logPanel)

TabStrip(log, 3, {"Editor", "Options"})

-- Toolbar
local toolbarY = 22
for i, name in ipairs({"File", "Load", "Unload", "Save", "Refresh", "Unloader"}) do
    Btn(log, (i-1)*58 + 4, toolbarY, 54, 16, name)
end

-- Code editor area
local codeArea = New("Frame", {
    Position = UDim2.new(0, 4, 0, 42),
    Size = UDim2.new(1, -8, 1, -46),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, log)
Stroke(codeArea, C.border, 1)

-- Line numbers gutter
local gutter = New("Frame", {
    Size = UDim2.new(0, 28, 1, 0),
    BackgroundColor3 = C.hdr,
    BorderSizePixel = 0,
}, codeArea)
Stroke(gutter, C.border, 1)

New("TextLabel", {
    Position = UDim2.new(0, 2, 0, 6),
    Size = UDim2.new(1, -4, 0, 12),
    Text = "1",
    TextColor3 = C.dim,
    BackgroundTransparency = 1,
    Font = Enum.Font.Code,
    TextSize = 9,
}, gutter)

-- Code content
New("TextLabel", {
    Position = UDim2.new(0, 34, 0, 6),
    Size = UDim2.new(1, -38, 0, 12),
    Text = "-- // Welcome to constant.cc",
    TextColor3 = Hex("6a9955"),
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Code,
    TextSize = 9,
}, codeArea)

-- cursor blink line
New("Frame", {
    Position = UDim2.new(0, 34, 0, 6),
    Size = UDim2.new(0, 1, 0, 12),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, codeArea)

-- ═══════════════════════════════════════════════════════════
-- RIGHT COLUMN – ACTIVITY  (x=562, y=296, w=394, h=248)
-- ═══════════════════════════════════════════════════════════
local actPanel = Panel(Content, 562, 296, 394, 248, "Activity")
local act = PanelContent(actPanel)

TabStrip(act, 3, {"Players", "Chat"})

local actLog = {
    "Player RobinsMR (1049164193) has Left.",
    "Player xxxx-xxxxx (1267641684) has Left.",
    "Player Salut (2290383509214) has Left.",
    "Player Jefflux02 (2307155507) has Joined.",
    "Player Jenn (503409127) has been kicked.",
    "Player EmRty (xar 5e2176838 180) has Joined.",
    "Player mr (1x523956731) has Joined.",
    "Player hxlNotDetected (1381191998) has Left.",
    "Player dAnay (2993001) has Left.",
    "Player nadia_lkain.35 [28 190 143783] has Left.",
    "Player zstc@1 (5200196923) has Joined.",
    "Player znz010 (62922936035) has Left.",
    "Player rmd.pcab (83182735300) has Joined.",
    "Player STVS (175) (54189310) has Joined.",
    "Player Rover O smSom:nil (447630977) has Left.",
    "Player 7213unk-1 (971083939) has Joined.",
    "Player zrns=SY (9588198929) has Joined.",
    "Player Hrng.OVG (1308120800) has Left.",
    "Player hxlNotDetected (1381191998) has Left.",
    "Player kWade-Onr2 (RL) (384150094) has Left.",
    "Player A-Munt (1108139189) has Left.",
    "Player sc-RMC_Gmscoc (53) (522590) as Left.",
    "Player J.ubertsng (100073100) has Left.",
    "Player Brxch_man (100057207958) has Joined.",
    "Player Non.com_new (1523750100) has Left.",
}

for i, line in ipairs(actLog) do
    New("TextLabel", {
        Position = UDim2.new(0, 4, 0, 20 + (i-1)*10),
        Size = UDim2.new(1, -8, 0, 10),
        Text = line,
        TextColor3 = C.dim,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, act)
end

-- ═══════════════════════════════════════════════════════════
-- DRAG  (title bar)
-- ═══════════════════════════════════════════════════════════
local dragging, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Main.Position
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
