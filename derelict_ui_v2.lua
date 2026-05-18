-- ============================================================
-- DERELICT UI v2  –  for derelict_esp.lua
-- Tabs: Main | Visuals | Farm | Misc
-- Real player list + real activity log
-- ============================================================
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

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
    return New("UIStroke", {
        Color = color or Color3.fromRGB(45, 45, 45),
        Thickness = thickness or 1,
    }, parent)
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 2) }, parent)
end

local function Hex(h)
    h = h:gsub("#", "")
    return Color3.fromRGB(
        tonumber("0x" .. h:sub(1, 2)),
        tonumber("0x" .. h:sub(3, 4)),
        tonumber("0x" .. h:sub(5, 6))
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
    row_alt = Hex("0f0f0f"),
}

-- ───────────────────────────────────────────────────────────
-- SCREEN GUI + MAIN WINDOW
-- ───────────────────────────────────────────────────────────
local SGui = New("ScreenGui", {
    Name            = "DerelictUI",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 999,
    IgnoreGuiInset  = true,
}, PlayerGui)

local Main = New("Frame", {
    Name             = "Main",
    Size             = UDim2.new(0, 960, 0, 590),
    Position         = UDim2.new(0.5, -480, 0.5, -295),
    BackgroundColor3 = C.bg,
    BorderSizePixel  = 0,
    Active           = true,
}, SGui)
Stroke(Main, C.border, 1)

-- ── Title bar ──────────────────────────────────────────────
local TitleBar = New("Frame", {
    Size             = UDim2.new(1, 0, 0, 22),
    BackgroundColor3 = C.hdr,
    BorderSizePixel  = 0,
}, Main)
Stroke(TitleBar, C.border, 1)

New("TextLabel", {
    Size                 = UDim2.new(1, -52, 1, 0),
    Position             = UDim2.new(0, 8, 0, 0),
    Text                 = "Derelict | Competitive Hub",
    TextColor3           = C.text,
    BackgroundTransparency = 1,
    TextXAlignment       = Enum.TextXAlignment.Left,
    Font                 = Enum.Font.GothamBold,
    TextSize             = 11,
}, TitleBar)

local function WinBtn(idx, label, bg)
    local b = New("TextButton", {
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(1, -22 * idx, 0, 0),
        Text             = label,
        TextColor3       = idx == 1 and Hex("aaaaaa") or Color3.new(1, 1, 1),
        BackgroundColor3 = bg,
        BorderSizePixel  = 0,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
    }, TitleBar)
    return b
end

WinBtn(2, "_", C.hdr)
local closeBtn = WinBtn(1, "X", Hex("5a1010"))
closeBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- ── Nav tabs: Main | Visuals | Farm | Misc ─────────────────
local NavBar = New("Frame", {
    Size             = UDim2.new(1, 0, 0, 20),
    Position         = UDim2.new(0, 0, 0, 22),
    BackgroundColor3 = Hex("0f0f0f"),
    BorderSizePixel  = 0,
}, Main)
Stroke(NavBar, C.border, 1)

local NAV_TABS = { "Main", "Visuals", "Farm", "Misc" }
local navUnderlines = {}
local navLabels     = {}

for i, name in ipairs(NAV_TABS) do
    local lbl = New("TextLabel", {
        Size             = UDim2.new(0, 72, 1, 0),
        Position         = UDim2.new(0, (i - 1) * 74 + 4, 0, 0),
        Text             = name,
        TextColor3       = i == 1 and C.text or C.dim,
        BackgroundTransparency = 1,
        Font             = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize         = 10,
    }, NavBar)
    local ul = New("Frame", {
        Size             = UDim2.new(0, 72, 0, 2),
        Position         = UDim2.new(0, (i - 1) * 74 + 4, 1, -2),
        BackgroundColor3 = i == 1 and C.accent or C.bg,
        BorderSizePixel  = 0,
    }, NavBar)
    navLabels[i]     = lbl
    navUnderlines[i] = ul
end

-- ── Content area ───────────────────────────────────────────
local Content = New("Frame", {
    Size               = UDim2.new(1, 0, 1, -42),
    Position           = UDim2.new(0, 0, 0, 42),
    BackgroundTransparency = 1,
    ClipsDescendants   = true,
}, Main)

-- ═══════════════════════════════════════════════════════════
-- WIDGET FACTORIES
-- ═══════════════════════════════════════════════════════════

local function Panel(parent, x, y, w, h, title)
    local f = New("Frame", {
        Position         = UDim2.new(0, x, 0, y),
        Size             = UDim2.new(0, w, 0, h),
        BackgroundColor3 = C.panel,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, parent)
    Stroke(f, C.border, 1)
    if title then
        local hdr = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 18),
            BackgroundColor3 = C.hdr,
            BorderSizePixel  = 0,
        }, f)
        Stroke(hdr, C.border, 1)
        New("TextLabel", {
            Size                 = UDim2.new(1, -8, 1, 0),
            Position             = UDim2.new(0, 8, 0, 0),
            Text                 = title,
            TextColor3           = C.text,
            BackgroundTransparency = 1,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Font                 = Enum.Font.GothamBold,
            TextSize             = 10,
        }, hdr)
    end
    return f
end

local function PanelContent(panel)
    return New("Frame", {
        Position           = UDim2.new(0, 0, 0, 18),
        Size               = UDim2.new(1, 0, 1, -18),
        BackgroundTransparency = 1,
    }, panel)
end

local function Section(parent, y, text)
    New("TextLabel", {
        Position             = UDim2.new(0, 8, 0, y),
        Size                 = UDim2.new(1, -16, 0, 12),
        Text                 = text,
        TextColor3           = C.accent,
        BackgroundTransparency = 1,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Font                 = Enum.Font.GothamBold,
        TextSize             = 9,
    }, parent)
    New("Frame", {
        Position         = UDim2.new(0, 8, 0, y + 12),
        Size             = UDim2.new(1, -16, 0, 1),
        BackgroundColor3 = C.border,
        BorderSizePixel  = 0,
    }, parent)
end

local function Checkbox(parent, y, label, checked, color)
    local row = New("Frame", {
        Position           = UDim2.new(0, 0, 0, y),
        Size               = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
    }, parent)
    local col = checked and (color or C.accent) or C.bg
    local box = New("Frame", {
        Position         = UDim2.new(0, 8, 0.5, -5),
        Size             = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = col,
        BorderSizePixel  = 0,
    }, row)
    Stroke(box, checked and (color or C.accent) or C.border, 1)
    if checked then
        New("TextLabel", {
            Size                 = UDim2.new(1, 0, 1, 0),
            Text                 = "✓",
            TextColor3           = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            Font                 = Enum.Font.GothamBold,
            TextSize             = 8,
        }, box)
    end
    New("TextLabel", {
        Position             = UDim2.new(0, 22, 0, 0),
        Size                 = UDim2.new(1, -26, 1, 0),
        Text                 = label,
        TextColor3           = C.text,
        BackgroundTransparency = 1,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Font                 = Enum.Font.Gotham,
        TextSize             = 10,
    }, row)
    return row
end

-- Checkbox with color swatch on the right
local function FilterRow(parent, y, label, checked, swatchColor)
    local row = Checkbox(parent, y, label, checked, swatchColor)
    local swatch = New("Frame", {
        Position         = UDim2.new(1, -22, 0.5, -6),
        Size             = UDim2.new(0, 14, 0, 12),
        BackgroundColor3 = swatchColor,
        BorderSizePixel  = 0,
    }, row)
    Stroke(swatch, C.border, 1)
    Corner(swatch, 2)
end

local function Slider(parent, y, label, value, min, max)
    local row = New("Frame", {
        Position           = UDim2.new(0, 0, 0, y),
        Size               = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1,
    }, parent)
    New("TextLabel", {
        Position             = UDim2.new(0, 8, 0, 0),
        Size                 = UDim2.new(0.65, 0, 0, 13),
        Text                 = label,
        TextColor3           = C.dim,
        BackgroundTransparency = 1,
        TextXAlignment       = Enum.TextXAlignment.Left,
        Font                 = Enum.Font.Gotham,
        TextSize             = 9,
    }, row)
    New("TextLabel", {
        Position             = UDim2.new(0.65, 0, 0, 0),
        Size                 = UDim2.new(0.35, -8, 0, 13),
        Text                 = tostring(value),
        TextColor3           = C.text,
        BackgroundTransparency = 1,
        TextXAlignment       = Enum.TextXAlignment.Right,
        Font                 = Enum.Font.Gotham,
        TextSize             = 9,
    }, row)
    local track = New("Frame", {
        Position         = UDim2.new(0, 8, 0, 16),
        Size             = UDim2.new(1, -16, 0, 4),
        BackgroundColor3 = C.border,
        BorderSizePixel  = 0,
    }, row)
    Corner(track, 4)
    local pct = math.clamp((value - min) / (max - min), 0, 1)
    local fill = New("Frame", {
        Size             = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel  = 0,
    }, track)
    Corner(fill, 4)
    New("Frame", {
        Position         = UDim2.new(pct, -4, 0.5, -4),
        Size             = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel  = 0,
    }, track)
    Corner(track:FindFirstChildOfClass("Frame") or track, 4)
end

local function SmallBtn(parent, x, y, w, h, text)
    local b = New("TextButton", {
        Position         = UDim2.new(0, x, 0, y),
        Size             = UDim2.new(0, w, 0, h),
        Text             = text,
        TextColor3       = C.text,
        BackgroundColor3 = C.hdr,
        BorderSizePixel  = 0,
        Font             = Enum.Font.Gotham,
        TextSize         = 9,
    }, parent)
    Stroke(b, C.border, 1)
    return b
end

local function TabStrip(parent, y, tabs)
    local row = New("Frame", {
        Position           = UDim2.new(0, 4, 0, y),
        Size               = UDim2.new(1, -8, 0, 16),
        BackgroundTransparency = 1,
    }, parent)
    for i, name in ipairs(tabs) do
        New("TextLabel", {
            Position             = UDim2.new(0, (i - 1) * 55, 0, 0),
            Size                 = UDim2.new(0, 50, 1, 0),
            Text                 = name,
            TextColor3           = i == 1 and C.text or C.dim,
            BackgroundTransparency = 1,
            Font                 = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham,
            TextSize             = 9,
        }, row)
    end
    New("Frame", {
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(0, 50, 0, 2),
        BackgroundColor3 = C.accent,
        BorderSizePixel  = 0,
    }, row)
end

-- ═══════════════════════════════════════════════════════════
-- LEFT COLUMN – CONFIGURATIONS  (full height, no triggerbot)
-- x=4, y=4, w=252, h=540
-- ═══════════════════════════════════════════════════════════
local cfgPanel = Panel(Content, 4, 4, 252, 540, "Configurations")
local cfg      = PanelContent(cfgPanel)

-- ── Section: ESP General ───────────────────────────────────
Section(cfg, 4, "ESP General")
Checkbox(cfg, 20,  "Enable ESP",        true,  C.accent)
Checkbox(cfg, 38,  "Show Boxes",        true,  C.accent)
Checkbox(cfg, 56,  "Show Names",        true,  C.accent)
Checkbox(cfg, 74,  "Show Health Bars",  true,  C.green)
Checkbox(cfg, 92,  "Show Distance",     true,  C.accent)
Checkbox(cfg, 110, "Show Tracers",      false)
Slider  (cfg, 130, "Max Render Distance", 500, 100, 2000)

-- ── Section: Filters & Colors ──────────────────────────────
Section(cfg, 162, "Filters & Colors")
FilterRow(cfg, 178, "Show Enemies",    true,  C.red)
FilterRow(cfg, 196, "Show Bosses",     true,  C.purple)
FilterRow(cfg, 214, "Show Items/Loot", true,  C.green)
FilterRow(cfg, 232, "Show Players",    true,  C.accent)

-- ── Section: Character ─────────────────────────────────────
Section(cfg, 256, "Character")
Checkbox(cfg, 272, "Infinite Stamina (Spoofer)", true,  C.orange)
Checkbox(cfg, 290, "No Fall Damage",             false)

-- ── Section: Farm ──────────────────────────────────────────
Section(cfg, 314, "Farm")
Checkbox(cfg, 330, "Auto Farm",        false)
Checkbox(cfg, 348, "Auto Collect Loot",false)
Checkbox(cfg, 366, "Skip Cutscenes",   false)
Checkbox(cfg, 384, "Auto Boss",        false)

-- ── Section: Misc ──────────────────────────────────────────
Section(cfg, 408, "Misc")
Checkbox(cfg, 424, "No Clip",          false)
Checkbox(cfg, 442, "Fly Mode",         false)
Checkbox(cfg, 460, "Infinite Jump",    false)

-- ── Section: UI ────────────────────────────────────────────
Section(cfg, 484, "UI")
SmallBtn(cfg, 8, 500, 54, 18, "Unload")
New("TextLabel", {
    Position             = UDim2.new(0, 70, 0, 502),
    Size                 = UDim2.new(1, -80, 0, 14),
    Text                 = "Menu bind:  RightShift",
    TextColor3           = C.dim,
    BackgroundTransparency = 1,
    TextXAlignment       = Enum.TextXAlignment.Left,
    Font                 = Enum.Font.Gotham,
    TextSize             = 9,
}, cfg)

-- ═══════════════════════════════════════════════════════════
-- CENTER TOP – TOOLS / ESP FILTERS QUICK PANEL
-- x=260, y=4, w=298, h=268
-- ═══════════════════════════════════════════════════════════
local toolsPanel = Panel(Content, 260, 4, 298, 268, "Tools")
SmallBtn(toolsPanel, 200, 0, 50, 18, "Save")
SmallBtn(toolsPanel, 254, 0, 42, 18, "Refresh")

local tools = PanelContent(toolsPanel)

local toolItems = {
    { "Outline",      true,  C.red    },
    { "ESP Boxes",    true,  C.accent },
    { "ESP Names",    true,  C.accent },
    { "Health Bars",  true,  C.green  },
    { "Tracers",      false           },
    { "Distance",     true,  C.accent },
    { "Show Enemies", true,  C.red    },
    { "Show Bosses",  true,  C.purple },
    { "Show Items",   true,  C.green  },
    { "Show Players", true,  C.accent },
    { "Inf. Stamina", true,  C.orange },
    { "No Fall Dmg",  false           },
}

for i, item in ipairs(toolItems) do
    Checkbox(tools, (i - 1) * 18 + 4, item[1], item[2], item[3])
    New("TextLabel", {
        Position             = UDim2.new(1, -14, 0, (i - 1) * 18 + 4),
        Size                 = UDim2.new(0, 12, 0, 14),
        Text                 = "›",
        TextColor3           = C.dim,
        BackgroundTransparency = 1,
        Font                 = Enum.Font.GothamBold,
        TextSize             = 12,
    }, tools)
end

-- ═══════════════════════════════════════════════════════════
-- CENTER BOTTOM – PLAYER LIST  (real, scrollable)
-- x=260, y=276, w=298, h=268
-- ═══════════════════════════════════════════════════════════
local plPanel  = Panel(Content, 260, 276, 298, 268, "Player List")
local plOuter  = PanelContent(plPanel)

TabStrip(plOuter, 3, {"Players", "Info"})

-- Table header
local plHdr = New("Frame", {
    Position         = UDim2.new(0, 4, 0, 23),
    Size             = UDim2.new(1, -8, 0, 15),
    BackgroundColor3 = C.hdr,
    BorderSizePixel  = 0,
}, plOuter)
Stroke(plHdr, C.border, 1)

local plCols = { "Player", "Dist (m)", "Health" }
for i, col in ipairs(plCols) do
    New("TextLabel", {
        Position             = UDim2.new(0, (i - 1) * 96, 0, 0),
        Size                 = UDim2.new(0, 96, 1, 0),
        Text                 = col,
        TextColor3           = C.dim,
        BackgroundTransparency = 1,
        TextXAlignment       = Enum.TextXAlignment.Center,
        Font                 = Enum.Font.GothamBold,
        TextSize             = 9,
    }, plHdr)
end
for _, xOff in ipairs({ 96, 192 }) do
    New("Frame", {
        Position         = UDim2.new(0, xOff, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = C.border,
        BorderSizePixel  = 0,
    }, plHdr)
end

-- Scrolling frame for rows
local plScroll = New("ScrollingFrame", {
    Position                 = UDim2.new(0, 4, 0, 40),
    Size                     = UDim2.new(1, -8, 1, -44),
    BackgroundTransparency   = 1,
    BorderSizePixel          = 0,
    ScrollBarThickness       = 4,
    ScrollBarImageColor3     = C.border,
    CanvasSize               = UDim2.new(0, 0, 0, 0),
    ScrollingDirection       = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize      = Enum.AutomaticSize.Y,
}, plOuter)

-- ── Real player list update function ──────────────────────
local function UpdatePlayerList()
    for _, child in ipairs(plScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local localChar  = LocalPlayer.Character
    local localRoot  = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local list       = Players:GetPlayers()
    local idx        = 0

    for _, p in ipairs(list) do
        if p ~= LocalPlayer then
            idx = idx + 1
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            local distText  = "?"
            local healthPct = hum and hum.MaxHealth > 0
                and math.floor((hum.Health / hum.MaxHealth) * 100)
                or nil
            local healthText = healthPct and (healthPct .. "%") or "?"

            if localRoot and root then
                distText = tostring(math.floor((root.Position - localRoot.Position).Magnitude))
            end

            local healthColor = C.green
            if healthPct then
                if    healthPct < 25 then healthColor = C.red
                elseif healthPct < 60 then healthColor = C.orange
                end
            end

            local row = New("Frame", {
                Position         = UDim2.new(0, 0, 0, (idx - 1) * 14),
                Size             = UDim2.new(1, 0, 0, 14),
                BackgroundColor3 = idx % 2 == 0 and C.row_alt or C.panel,
                BorderSizePixel  = 0,
            }, plScroll)

            local vals = { p.Name, distText, healthText }
            local cols = { C.text, C.dim,    healthColor }
            for j, val in ipairs(vals) do
                New("TextLabel", {
                    Position             = UDim2.new(0, (j - 1) * 96, 0, 0),
                    Size                 = UDim2.new(0, 96, 1, 0),
                    Text                 = val,
                    TextColor3           = cols[j],
                    BackgroundTransparency = 1,
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    Font                 = Enum.Font.Gotham,
                    TextSize             = 8,
                    TextTruncate         = Enum.TextTruncate.AtEnd,
                }, row)
            end
            for _, xOff in ipairs({ 96, 192 }) do
                New("Frame", {
                    Position         = UDim2.new(0, xOff, 0, 0),
                    Size             = UDim2.new(0, 1, 1, 0),
                    BackgroundColor3 = C.border,
                    BorderSizePixel  = 0,
                }, row)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- RIGHT TOP – KEY BIND(S)
-- x=562, y=4, w=394, h=44
-- ═══════════════════════════════════════════════════════════
local kbPanel = Panel(Content, 562, 4, 394, 44, "Key bind(s)")
local kb      = PanelContent(kbPanel)

New("TextLabel", {
    Position             = UDim2.new(0, 8, 0, 4),
    Size                 = UDim2.new(1, -16, 0, 14),
    Text                 = "[RightShift]  Toggle Menu",
    TextColor3           = C.text,
    BackgroundTransparency = 1,
    TextXAlignment       = Enum.TextXAlignment.Left,
    Font                 = Enum.Font.Gotham,
    TextSize             = 10,
}, kb)

-- ═══════════════════════════════════════════════════════════
-- RIGHT MID – LOG (decorative)
-- x=562, y=52, w=394, h=240
-- ═══════════════════════════════════════════════════════════
local logPanel = Panel(Content, 562, 52, 394, 240, "Log")
local logC     = PanelContent(logPanel)

TabStrip(logC, 3, { "Editor", "Options" })

local toolbarBtns = { "File", "Load", "Unload", "Save", "Refresh", "Unloader" }
for i, name in ipairs(toolbarBtns) do
    SmallBtn(logC, (i - 1) * 58 + 4, 22, 54, 16, name)
end

local codeArea = New("Frame", {
    Position         = UDim2.new(0, 4, 0, 42),
    Size             = UDim2.new(1, -8, 1, -46),
    BackgroundColor3 = C.bg,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
}, logC)
Stroke(codeArea, C.border, 1)

local gutter = New("Frame", {
    Size             = UDim2.new(0, 28, 1, 0),
    BackgroundColor3 = C.hdr,
    BorderSizePixel  = 0,
}, codeArea)
Stroke(gutter, C.border, 1)

New("TextLabel", {
    Position             = UDim2.new(0, 2, 0, 6),
    Size                 = UDim2.new(1, -4, 0, 12),
    Text                 = "1",
    TextColor3           = C.dim,
    BackgroundTransparency = 1,
    Font                 = Enum.Font.Code,
    TextSize             = 9,
}, gutter)

New("TextLabel", {
    Position             = UDim2.new(0, 34, 0, 6),
    Size                 = UDim2.new(1, -38, 0, 12),
    Text                 = "-- // Derelict ESP loaded",
    TextColor3           = Hex("6a9955"),
    BackgroundTransparency = 1,
    TextXAlignment       = Enum.TextXAlignment.Left,
    Font                 = Enum.Font.Code,
    TextSize             = 9,
}, codeArea)

-- ═══════════════════════════════════════════════════════════
-- RIGHT BOTTOM – ACTIVITY (real join/leave)
-- x=562, y=296, w=394, h=248
-- ═══════════════════════════════════════════════════════════
local actPanel  = Panel(Content, 562, 296, 394, 248, "Activity")
local actOuter  = PanelContent(actPanel)

TabStrip(actOuter, 3, { "Players", "Chat" })

local actScroll = New("ScrollingFrame", {
    Position                 = UDim2.new(0, 4, 0, 22),
    Size                     = UDim2.new(1, -8, 1, -24),
    BackgroundTransparency   = 1,
    BorderSizePixel          = 0,
    ScrollBarThickness       = 4,
    ScrollBarImageColor3     = C.border,
    CanvasSize               = UDim2.new(0, 0, 0, 0),
    ScrollingDirection       = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize      = Enum.AutomaticSize.Y,
}, actOuter)

local actEntries = {}

local function RebuildActivity()
    for _, child in ipairs(actScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    for i, entry in ipairs(actEntries) do
        New("TextLabel", {
            Position             = UDim2.new(0, 0, 0, (i - 1) * 11),
            Size                 = UDim2.new(1, 0, 0, 11),
            Text                 = entry.text,
            TextColor3           = entry.color,
            BackgroundTransparency = 1,
            TextXAlignment       = Enum.TextXAlignment.Left,
            Font                 = Enum.Font.Gotham,
            TextSize             = 8,
            TextTruncate         = Enum.TextTruncate.AtEnd,
        }, actScroll)
    end
end

local function AddActivity(text, color)
    table.insert(actEntries, 1, { text = text, color = color or C.dim })
    if #actEntries > 80 then table.remove(actEntries) end
    RebuildActivity()
end

-- seed with current players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        AddActivity("  " .. p.Name .. "  is in the server.", C.dim)
    end
end

-- real events
Players.PlayerAdded:Connect(function(p)
    AddActivity("  Player " .. p.Name .. "  has Joined.", C.green)
    task.wait(0.1)
    UpdatePlayerList()
end)

Players.PlayerRemoving:Connect(function(p)
    AddActivity("  Player " .. p.Name .. "  has Left.", C.red)
    task.wait(0.1)
    UpdatePlayerList()
end)

-- ═══════════════════════════════════════════════════════════
-- DRAG
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

-- ═══════════════════════════════════════════════════════════
-- RUNTIME UPDATES
-- ═══════════════════════════════════════════════════════════

-- Initial population
UpdatePlayerList()

-- Refresh distances every 2 seconds
local distTimer = 0
RunService.Heartbeat:Connect(function(dt)
    distTimer = distTimer + dt
    if distTimer >= 2 then
        distTimer = 0
        UpdatePlayerList()
    end
end)
