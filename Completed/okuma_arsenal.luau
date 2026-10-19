-- ============================================================================
-- Okuma UI Demo  (v3 — Ouroboros-parity pass)
-- Standalone UI, no game features yet.
-- ============================================================================

local genv = (type(getgenv) == "function" and getgenv()) or _G

-- kill any previous instance: its connections + every leftover ScreenGui
pcall(function()
    if genv.OkumaARSNAL_Cleanup then genv.OkumaARSNAL_Cleanup() end
end)
pcall(function()
    local roots = { game:GetService("CoreGui") }
    if type(gethui) == "function" then table.insert(roots, gethui()) end
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg then table.insert(roots, pg) end
    for _, root in ipairs(roots) do
        for _, c in ipairs(root:GetChildren()) do
            if c.Name:sub(1, 12) == "OkumaARSNAL_" then c:Destroy() end
        end
    end
end)

-- ============================================================================
-- ICON ASSET IDS   (set to "" to use the Lucide fallback)
-- ============================================================================
local ICONS = {
    logo          = "89786629350927",
    home          = "rbxassetid://13060262582",
    shield        = "rbxassetid://13780781482",
    wind          = "rbxassetid://17514296908",
    target        = "rbxassetid://107058246184363",
    zap           = "rbxassetid://117079418447477",
    wrench        = "rbxassetid://74185647224574",
    settings      = "rbxassetid://13300915335",
    search        = "rbxassetid://132302594577680",
    minimize      = "rbxassetid://130317465465959",
    expand        = "",
    play          = "rbxassetid://8517323802",
    rejoin        = "rbxassetid://123793179318056",
    shuffle       = "rbxassetid://71866957367213",
    lowest        = "rbxassetid://71866957367213",
    copy          = "rbxassetid://85360060654230",
    discord       = "rbxassetid://18505728250",
    globe         = "rbxassetid://121176334529781",
    checklist     = "rbxassetid://13289068631",
    chevron_right = "rbxassetid://89820329941528",
    overview      = "",
    beta_badge    = "",
    tag           = "",
    user_person   = "",
    folder        = "",
    chevron_down  = "",
    unload        = "",
    volt          = "",
}

local LUCIDE_FALLBACK = {
    logo         = "diamond",
    expand       = "expand",
    overview     = "layout-dashboard",
    beta_badge   = "flask-conical",
    tag          = "tag",
    user_person  = "user",
    lowest       = "trending-down",
    folder       = "folder",
    chevron_down = "chevron-down",
    unload       = "power",
    volt         = "zap",
}

local LucideAtlas = nil
local LUCIDE_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
task.spawn(function()
    local ok, result = pcall(function()
        local src = game:HttpGet(LUCIDE_URL)
        return loadstring(src)()
    end)
    if ok and type(result) == "table" then
        LucideAtlas = result
    else
    end
end)

-- ============================================================================
-- SERVICES
-- ============================================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local CoreGui          = game:GetService("CoreGui")
local ContentProvider  = game:GetService("ContentProvider")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================================
-- THEME
-- ============================================================================
local T = {
    BgDeep    = Color3.fromRGB(16, 16, 17),
    Sidebar   = Color3.fromRGB(20, 20, 21),
    Card      = Color3.fromRGB(25, 25, 26),
    CardAlt   = Color3.fromRGB(34, 34, 37),
    CardHover = Color3.fromRGB(42, 42, 46),
    Border    = Color3.fromRGB(52, 52, 56),
    BorderLow = Color3.fromRGB(40, 40, 43),
    Text      = Color3.fromRGB(236, 236, 240),
    TextDim   = Color3.fromRGB(140, 140, 150),
    TextMute  = Color3.fromRGB(92, 92, 102),
    Accent    = Color3.fromRGB(236, 236, 240),
    AccentDim = Color3.fromRGB(190, 190, 196),
    AccentOn  = Color3.fromRGB(236, 236, 240),
    Success   = Color3.fromRGB(110, 220, 130),
    Warning   = Color3.fromRGB(240, 190, 110),
    Error     = Color3.fromRGB(240, 110, 130),
    Toggle_On = Color3.fromRGB(236, 236, 240),
    Toggle_Off= Color3.fromRGB(42, 42, 46),
}
local F = {
    Bold    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    Medium  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
    Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
}

-- ============================================================================
-- HELPERS
-- ============================================================================
local function New(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then inst[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end
local function Corner(p, r)   return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function Stroke(p, c, t)
    return New("UIStroke", { Color = c or T.BorderLow, Thickness = t or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end
local function Padding(p, l, r, t, b)
    return New("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0), Parent = p })
end
local function VList(p, gap, hAlign)
    return New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 0), HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left, Parent = p })
end
local function HList(p, gap, vAlign)
    return New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 0), VerticalAlignment = vAlign or Enum.VerticalAlignment.Center, Parent = p })
end
local function Tween(obj, props, dur, style)
    local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end

local function resolveIconUrl(assetId)
    if not assetId or assetId == "" then return nil end
    local numeric = tostring(assetId):match("%d+")
    if not numeric then return nil end
    return "rbxthumb://type=Asset&id=" .. numeric .. "&w=150&h=150"
end

local PRESERVE_COLOR = { discord = true, logo = true }

task.spawn(function()
    local list = {}
    for _, id in pairs(ICONS) do
        local url = resolveIconUrl(id)
        if url then table.insert(list, url) end
    end
    pcall(function() ContentProvider:PreloadAsync(list) end)
end)

local function makeLucideIcon(parent, lucideName, size, color, preserveColor)
    if not LucideAtlas then return nil end
    local atlas = LucideAtlas["48px"] or LucideAtlas["24px"] or LucideAtlas
    if not atlas then return nil end
    local entry = atlas[lucideName]
    if not entry then return nil end
    local props = {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, size, 0, size),
        Image = "rbxassetid://" .. tostring(entry[1]),
        ImageRectSize   = Vector2.new(entry[2][1], entry[2][2]),
        ImageRectOffset = Vector2.new(entry[3][1], entry[3][2]),
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    }
    if not preserveColor then props.ImageColor3 = color end
    local img = New("ImageLabel", props)
    New("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width, Parent = img })
    return img
end

local function MakeIcon(parent, name, size, color)
    size = size or 18
    color = color or T.Text
    local preserve = PRESERVE_COLOR[name] == true

    local url = resolveIconUrl(ICONS[name])
    if url then
        local props = {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, size, 0, size),
            Image = url,
            ScaleType = Enum.ScaleType.Fit, Parent = parent,
        }
        if not preserve then props.ImageColor3 = color end
        local img = New("ImageLabel", props)
        New("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width, Parent = img })
        return img
    end

    local lucideName = LUCIDE_FALLBACK[name] or name
    local lucide = makeLucideIcon(parent, lucideName, size, color, preserve)
    if lucide then return lucide end

    local placeholder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0, size, 0, size), Parent = parent,
    })
    placeholder:SetAttribute("OkumaIconPending", name)
    placeholder:SetAttribute("OkumaIconSize",   size)
    placeholder:SetAttribute("OkumaIconColorR", color.R)
    placeholder:SetAttribute("OkumaIconColorG", color.G)
    placeholder:SetAttribute("OkumaIconColorB", color.B)
    return placeholder
end

local function sweepIconPlaceholders(root)
    if not LucideAtlas or not root then return end
    for _, d in ipairs(root:GetDescendants()) do
        local pending = d:GetAttribute("OkumaIconPending")
        if pending and d:IsA("Frame") then
            local sz    = d:GetAttribute("OkumaIconSize") or 18
            local color = Color3.new(
                d:GetAttribute("OkumaIconColorR") or 1,
                d:GetAttribute("OkumaIconColorG") or 1,
                d:GetAttribute("OkumaIconColorB") or 1)
            local parent = d.Parent
            local lucideName = LUCIDE_FALLBACK[pending] or pending
            local newIcon = makeLucideIcon(parent, lucideName, sz, color, PRESERVE_COLOR[pending] == true)
            if newIcon then
                newIcon.Position    = d.Position
                newIcon.AnchorPoint = d.AnchorPoint
                newIcon.LayoutOrder = d.LayoutOrder
                newIcon.ZIndex      = d.ZIndex
                d:Destroy()
            end
        end
    end
end

-- ============================================================================
-- MOUNT GUI
-- ============================================================================
local function MountGui()
    local sg = New("ScreenGui", {
        Name = "OkumaARSNAL_" .. tostring(math.random(1e6, 9e6)),
        ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
    })
    local ok = pcall(function()
        if type(gethui) == "function" then sg.Parent = gethui(); return end
        if syn and type(syn.protect_gui) == "function" then syn.protect_gui(sg); sg.Parent = CoreGui; return end
        if type(protect_gui) == "function" then protect_gui(sg); sg.Parent = CoreGui; return end
        sg.Parent = CoreGui
    end)
    if not ok or not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    return sg
end
local gui = MountGui()

task.spawn(function()
    while not LucideAtlas do task.wait(0.2) end
    sweepIconPlaceholders(gui)
end)

-- ============================================================================
-- CONFIG PERSISTENCE
-- ============================================================================
local CONFIG_FILE = "okuma_arsenal.json"
local Config = {
    toggleKey   = "RightControl",
    antiAfk     = true,
    minimizeOnStart = false,
    toggleButton = "Mobile only",
    preset      = "Mono",
    notifs      = true,
}
local HttpService = game:GetService("HttpService")
local function SaveConfig()
    if type(writefile) ~= "function" then return end
    local snap = {}
    for k, v in pairs(Config) do snap[k] = v end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(snap)) end)
end
local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    local ok = pcall(function() return isfile(CONFIG_FILE) end)
    if not ok then return end
    local existsOk, exists = pcall(isfile, CONFIG_FILE)
    if not existsOk or not exists then return end
    local readOk, content = pcall(readfile, CONFIG_FILE)
    if not readOk or not content or content == "" then return end
    local decOk, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if decOk and type(decoded) == "table" then
        for k, v in pairs(decoded) do Config[k] = v end
    end
end
LoadConfig()

-- every long-lived connection goes through Track() so Unload / re-execute can kill them all
local Connections = {}
local function Track(conn)
    table.insert(Connections, conn)
    return conn
end

-- ============================================================================
-- NOTIFICATIONS (toast)
-- ============================================================================
-- ZIndex 100: in Sibling mode the holder must outrank the window or toasts render underneath it
local toastHolder = New("Frame", {
    Name = "Toasts",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 250, 0, 320),
    BackgroundTransparency = 1, ZIndex = 100, Parent = gui,
})
New("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6), Parent = toastHolder,
})

local toastSeq = 0
local MAX_TOASTS = 4

-- Ouroboros-style toast: square icon badge, title + subtitle, X close, progress bar at the bottom.
-- opts.color picks the badge tint (defaults to Success-green, like their "Copied" toast).
-- opts.icon is a Lucide name; defaults to "check" / "x" based on color.
local function Notify(opts)
    if not Config.notifs then return end
    opts = opts or {}
    toastSeq = toastSeq + 1
    local accent  = opts.color or T.Success
    local hasBody = opts.body ~= nil and opts.body ~= ""
    local duration = opts.duration or 2.6
    local iconName = opts.icon or ((accent == T.Error) and "x" or (accent == T.Warning) and "alert-triangle" or "check")
    local height = 64

    -- never let toasts pile up: evict the oldest ones
    local live = {}
    for _, c in ipairs(toastHolder:GetChildren()) do
        if c:IsA("Frame") then table.insert(live, c) end
    end
    table.sort(live, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    while #live >= MAX_TOASTS do
        table.remove(live, 1):Destroy()
    end

    local wrap = New("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1,
        LayoutOrder = toastSeq, Parent = toastHolder,
    })
    local card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 40, 0, 0),
        BackgroundColor3 = T.Card, BorderSizePixel = 0,
        GroupTransparency = 1, ClipsDescendants = true, Parent = wrap,
    })
    Corner(card, 12); Stroke(card, T.BorderLow, 1)
    card.BackgroundColor3 = Color3.fromRGB(16, 16, 17)

    -- plain tinted icon (no badge box), title takes the accent color — like their "Copied" toast
    local badgeIcon = MakeIcon(card, iconName, 20, accent)
    badgeIcon.Position = UDim2.new(0, 16, 0, 11)

    New("TextLabel", {
        Position = UDim2.new(0, 46, 0, 9), Size = UDim2.new(1, -76, 0, 16),
        BackgroundTransparency = 1, Text = opts.title or "Okuma", TextColor3 = accent,
        FontFace = F.Bold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    if hasBody then
        New("TextLabel", {
            Position = UDim2.new(0, 46, 0, 28), Size = UDim2.new(1, -76, 0, 14),
            BackgroundTransparency = 1, Text = opts.body, TextColor3 = T.TextDim,
            FontFace = F.Regular, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
        })
    end

    -- close (X) button
    local closeBtn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8),
        Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, Parent = card,
    })
    local closeIcon = MakeIcon(closeBtn, "x", 13, T.TextDim)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- progress bar: thin, inset from the edges, white fill on a dark track (drains over `duration`)
    local barTrack = New("Frame", {
        Position = UDim2.new(0, 16, 1, -10), Size = UDim2.new(1, -32, 0, 3),
        BackgroundColor3 = Color3.fromRGB(44, 44, 46), BorderSizePixel = 0, Parent = card,
    })
    Corner(barTrack, 2)
    local barFill = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, Parent = barTrack,
    })
    Corner(barFill, 2)

    local dismissed = false
    local function dismiss()
        if dismissed or not wrap.Parent then return end
        dismissed = true
        Tween(card, { Position = UDim2.new(0, 40, 0, 0), GroupTransparency = 1 }, 0.3, Enum.EasingStyle.Quint)
        task.delay(0.32, function() if wrap.Parent then wrap:Destroy() end end)
    end
    closeBtn.MouseButton1Click:Connect(dismiss)

    Tween(card, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.35, Enum.EasingStyle.Quint)
    Tween(barFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, dismiss)
end

-- clipboard helper
local function Copy(text)
    local fn = setclipboard or (syn and syn.write_clipboard) or (toclipboard)
    if type(fn) == "function" then pcall(fn, text); return true end
    return false
end

-- ============================================================================
-- WINDOW
-- ============================================================================
local WINDOW_W, WINDOW_H = 820, 560
local SIDEBAR_W = 190

local window = New("Frame", {
    Name = "Window",
    Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
    Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2),
    BackgroundColor3 = T.BgDeep, BorderSizePixel = 0, Parent = gui, ClipsDescendants = true,
})
Corner(window, 16); Stroke(window, T.Border, 1)

local dragging, dragStart, startPos
local function hookDrag(host)
    host.Active = true
    host.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
end
Track(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

-- ============================================================================
-- SIDEBAR
-- ============================================================================
local sidebar = New("CanvasGroup", {
    Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundColor3 = T.Sidebar, BorderSizePixel = 0, Parent = window,
})
New("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = T.BorderLow, BorderSizePixel = 0, Parent = sidebar })

local brand = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = sidebar })
Padding(brand, 16, 12, 16, 10); hookDrag(brand)

local brandTile = New("Frame", {
    Size = UDim2.new(0, 32, 0, 32), BackgroundTransparency = 1,
    BorderSizePixel = 0, Parent = brand,
})
Corner(brandTile, 10)
local brandGlyph = MakeIcon(brandTile, "logo", 32, T.BgDeep); Corner(brandGlyph, 10)
brandGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
brandGlyph.Position = UDim2.new(0.5, 0, 0.5, 0)

New("TextLabel", { Position = UDim2.new(0, 44, 0, 4), Size = UDim2.new(1, -44, 0, 16),
    BackgroundTransparency = 1, Text = "Okuma", TextColor3 = T.Text,
    FontFace = F.Bold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = brand })
New("TextLabel", { Position = UDim2.new(0, 44, 0, 22), Size = UDim2.new(1, -44, 0, 12),
    BackgroundTransparency = 1, Text = "Beta", TextColor3 = T.TextDim,
    FontFace = F.Regular, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = brand })

local navHolder = New("Frame", {
    Position = UDim2.new(0, 0, 0, 72), Size = UDim2.new(1, 0, 1, -148),
    BackgroundTransparency = 1, Parent = sidebar,
})
Padding(navHolder, 10, 10, 4, 4); VList(navHolder, 2)

local navRefs = {}
local pages = {}
local activePageId = nil

local function AddNavItem(id, title, iconName)
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, LayoutOrder = #navRefs + 1, Parent = navHolder,
    })
    Corner(btn, 9)

    local iconObj = MakeIcon(btn, iconName, 18, T.TextDim)
    iconObj.Position = UDim2.new(0, 14, 0.5, -9)

    local labelObj = New("TextLabel", {
        Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1, Text = title, TextColor3 = T.TextDim,
        FontFace = F.Medium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })

    btn.MouseEnter:Connect(function()
        if activePageId ~= id then
            Tween(btn, { BackgroundTransparency = 0.72 }, 0.15)
            btn.BackgroundColor3 = T.Card
        end
    end)
    btn.MouseLeave:Connect(function()
        if activePageId ~= id then
            Tween(btn, { BackgroundTransparency = 1 }, 0.15)
        end
    end)
    btn.MouseButton1Click:Connect(function() _G.OkumaUI_SelectPage(id) end)

    navRefs[id] = { button = btn, iconObj = iconObj, labelObj = labelObj }
end

AddNavItem("home",     "Home",       "home")
AddNavItem("aimbot",   "Aimbot",     "target")
AddNavItem("visuals",  "Visuals",    "eye")
AddNavItem("utility",  "Utility",    "wrench")
AddNavItem("settings", "Settings",   "settings")

-- user card
local userCard = New("TextButton", {
    AutoButtonColor = false, Text = "",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 60),
    BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = sidebar,
})
Corner(userCard, 10); Stroke(userCard, T.BorderLow, 1); Padding(userCard, 10, 10, 10, 10)

local avatarHolder = New("Frame", {
    Position = UDim2.new(0, 0, 0.5, -16), Size = UDim2.new(0, 34, 0, 34),
    BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Parent = userCard,
})
Corner(avatarHolder, 17); Stroke(avatarHolder, T.Border, 1)
local avatarImg = New("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "", Parent = avatarHolder,
})
Corner(avatarImg, 17)
pcall(function()
    local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    avatarImg.Image = thumb
end)
local dot = New("Frame", { Position = UDim2.new(0, 25, 0, 25), Size = UDim2.new(0, 9, 0, 9),
    BackgroundColor3 = T.Success, BorderSizePixel = 0, Parent = userCard })
Corner(dot, 5)
Stroke(dot, T.Card, 2)

New("TextLabel", {
    Position = UDim2.new(0, 44, 0, 4), Size = UDim2.new(1, -72, 0, 14),
    BackgroundTransparency = 1, Text = LocalPlayer.DisplayName or LocalPlayer.Name,
    TextColor3 = T.Text, FontFace = F.Medium, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = userCard,
})
New("TextLabel", {
    Position = UDim2.new(0, 44, 0, 22), Size = UDim2.new(1, -72, 0, 12),
    BackgroundTransparency = 1, Text = ("@%s"):format(LocalPlayer.Name),
    TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = userCard,
})
local userChevron = MakeIcon(userCard, "chevron_right", 14, T.TextDim)
userChevron.AnchorPoint = Vector2.new(1, 0.5)
userChevron.Position = UDim2.new(1, -4, 0.5, 0)

-- ============================================================================
-- CONTENT
-- ============================================================================
local content = New("CanvasGroup", {
    Name = "Content", Position = UDim2.new(0, SIDEBAR_W, 0, 0),
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    BackgroundColor3 = T.BgDeep, BorderSizePixel = 0, Parent = window,
})

local header = New("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, Parent = content })
Padding(header, 24, 20, 18, 10); hookDrag(header)

local headerIcon = MakeIcon(header, "home", 24, T.Text)
headerIcon.Position = UDim2.new(0, 0, 0.5, -12)

local headerTitle = New("TextLabel", {
    Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
    BackgroundTransparency = 1, Text = "Welcome to Okuma!", TextColor3 = T.Text,
    FontFace = F.Bold, TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = header,
})

local searchBox = New("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -48, 0.5, -16), Size = UDim2.new(0, 200, 0, 32),
    BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = header,
})
Corner(searchBox, 9); Stroke(searchBox, T.BorderLow, 1)
local searchIcon = MakeIcon(searchBox, "search", 14, T.TextDim)
searchIcon.Position = UDim2.new(0, 12, 0.5, -7)
local searchInput = New("TextBox", {
    Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -40, 1, 0),
    BackgroundTransparency = 1, PlaceholderText = "Search",
    PlaceholderColor3 = T.TextDim, TextColor3 = T.Text, FontFace = F.Regular,
    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = searchBox,
})
-- live nav filter (defined after navRefs exist; see wiring near the bottom)

local minBtn = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0.5, -16), Size = UDim2.new(0, 32, 0, 32),
    BackgroundColor3 = T.Card, BorderSizePixel = 0, Text = "",
    AutoButtonColor = false, Parent = header,
})
Corner(minBtn, 9); Stroke(minBtn, T.BorderLow, 1)
local minIcon = MakeIcon(minBtn, "minimize", 14, T.TextDim)
minIcon.AnchorPoint = Vector2.new(0.5, 0.5)
minIcon.Position = UDim2.new(0.5, 0, 0.5, 0)

-- body (scrolling)
local body = New("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 64), Size = UDim2.new(1, 0, 1, -94),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = T.Border,
    ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y, Parent = content,
})
Padding(body, 24, 20, 4, 24); VList(body, 14)

-- footer
local footer = New("Frame", {
    Position = UDim2.new(0, 0, 1, -30), Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = T.Sidebar, BorderSizePixel = 0, Parent = content,
})
New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.BorderLow, BorderSizePixel = 0, Parent = footer })
Padding(footer, 20, 16, 0, 0)

local footerDot = New("Frame", { Position = UDim2.new(0, 0, 0.5, -4), Size = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = T.Success, BorderSizePixel = 0, Parent = footer })
Corner(footerDot, 4)
New("TextLabel", { Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0, 46, 1, 0),
    BackgroundTransparency = 1, Text = "Volt", TextColor3 = T.Text,
    FontFace = F.Bold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = footer })
New("TextLabel", { Position = UDim2.new(0, 62, 0, 0), Size = UDim2.new(1, -220, 1, 0),
    BackgroundTransparency = 1, Text = "Your executor is supported and fully compatible.",
    TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = footer })
New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -62, 0, 0),
    Size = UDim2.new(0, 70, 1, 0), BackgroundTransparency = 1,
    Text = "Hide with", TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Right, Parent = footer })
local hidePill = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.new(0, 54, 0, 22), BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = footer })
Corner(hidePill, 6); Stroke(hidePill, T.BorderLow, 1)
New("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "RCtrl", TextColor3 = T.Text, FontFace = F.Medium, TextSize = 10, Parent = hidePill })

-- ============================================================================
-- MINI BAR + smooth animation
-- ============================================================================
local MINI_W, MINI_H = 200, 44
local miniBar = New("CanvasGroup", {
    Name = "MiniBar",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = T.Sidebar,
    BorderSizePixel = 0,
    GroupTransparency = 1,
    Visible = false, Parent = window,
})
-- full pill like Ouroboros: round logo | title | ........ signal bars + player count
Corner(miniBar, 22); Padding(miniBar, 8, 16, 6, 6); hookDrag(miniBar)
miniBar.BackgroundColor3 = Color3.fromRGB(16, 16, 17)

local miniTile = New("Frame", {
    Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 0, 0.5, -15),
    BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Parent = miniBar,
})
Corner(miniTile, 15); 
local miniGlyph = MakeIcon(miniTile, "logo", 30, T.Text); Corner(miniGlyph, 15)
miniGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
miniGlyph.Position = UDim2.new(0.5, 0, 0.5, 0)

New("TextLabel", { Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(0, 70, 1, 0),
    BackgroundTransparency = 1, Text = "Okuma", TextColor3 = T.Text,
    FontFace = F.Bold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = miniBar })

-- signal bars + player count (right side)
local miniStats = New("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.new(0, 46, 1, 0), BackgroundTransparency = 1, Parent = miniBar,
})
HList(miniStats, 6)
miniStats.Size = UDim2.new(0, 58, 1, 0)
local miniBars = New("Frame", { Size = UDim2.new(0, 22, 0, 12), BackgroundTransparency = 1, Parent = miniStats })
HList(miniBars, 2, Enum.VerticalAlignment.Bottom)
local miniBarList = {}
for _, h in ipairs({ 5, 5, 7, 9 }) do
    local bar = New("Frame", { Size = UDim2.new(0, 4, 0, h), BackgroundColor3 = T.TextDim,
        BorderSizePixel = 0, Parent = miniBars })
    Corner(bar, 2)
    table.insert(miniBarList, bar)
end
-- the bars breathe up and down while the pill is showing
task.spawn(function()
    while gui.Parent do
        if miniBar.Visible then
            for _, bar in ipairs(miniBarList) do
                Tween(bar, { Size = UDim2.new(0, 4, 0, math.random(4, 12)) }, 0.35, Enum.EasingStyle.Sine)
            end
        end
        task.wait(0.4)
    end
end)
-- shows FPS (updated from the FPS counter below)
local miniCount = New("TextLabel", { Size = UDim2.new(0, 26, 1, 0), BackgroundTransparency = 1,
    Text = "--", TextColor3 = T.Text, FontFace = F.Bold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = miniStats })

-- the whole pill expands on click (no separate button)
local expandBtn = New("TextButton", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
    AutoButtonColor = false, ZIndex = 5, Parent = miniBar,
})

local EASE_SIZE = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local EASE_FADE = TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- ============================================================================
-- OVERLAY LAYER  (dropdown lists live here)
-- In Sibling ZIndex mode a list parented inside its row renders UNDER every row below it.
-- Parenting it to a top-level layer and positioning it by AbsolutePosition fixes that.
-- ============================================================================
local overlay = New("Frame", {
    Name = "Overlay", Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1, ZIndex = 100, Parent = window,
})
local dropCatcher = New("TextButton", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
    AutoButtonColor = false, Visible = false, ZIndex = 1, Parent = overlay,
})
local currentDrop = nil
local function closeOpenDrop()
    if currentDrop then currentDrop.close() end
end
dropCatcher.MouseButton1Click:Connect(closeOpenDrop)

local minimized = false
local animating = false
local function setMinimized(state)
    if animating or minimized == state then return end
    animating = true
    minimized = state
    closeOpenDrop()
    if minimized then
        TweenService:Create(sidebar, EASE_FADE, { GroupTransparency = 1 }):Play()
        TweenService:Create(content, EASE_FADE, { GroupTransparency = 1 }):Play()
        TweenService:Create(window, EASE_SIZE, { Size = UDim2.new(0, MINI_W, 0, MINI_H) }):Play()
        task.wait(0.24)
        sidebar.Visible = false; content.Visible = false
        miniBar.GroupTransparency = 1; miniBar.Visible = true
        TweenService:Create(miniBar, EASE_FADE, { GroupTransparency = 0 }):Play()
        task.wait(0.3)
    else
        TweenService:Create(miniBar, EASE_FADE, { GroupTransparency = 1 }):Play()
        TweenService:Create(window, EASE_SIZE, { Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H) }):Play()
        task.wait(0.24)
        miniBar.Visible = false
        sidebar.GroupTransparency = 1; content.GroupTransparency = 1
        sidebar.Visible = true; content.Visible = true
        TweenService:Create(sidebar, EASE_FADE, { GroupTransparency = 0 }):Play()
        TweenService:Create(content, EASE_FADE, { GroupTransparency = 0 }):Play()
        task.wait(0.3)
    end
    animating = false
end
minBtn.MouseButton1Click:Connect(function() setMinimized(true) end)

-- the pill is both draggable and clickable: a click only expands if the window did not move
hookDrag(expandBtn)
local pillDownPos = Vector2.zero
expandBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pillDownPos = window.AbsolutePosition
    end
end)
expandBtn.MouseButton1Click:Connect(function()
    if (window.AbsolutePosition - pillDownPos).Magnitude > 4 then return end
    setMinimized(false)
end)

-- ============================================================================
-- PAGES  (with fade transition)
-- ============================================================================
local function MakePage(id, title, iconName)
    local frame = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = body,
    })
    VList(frame, 14)
    pages[id] = { frame = frame, title = title, iconName = iconName }
    return frame
end

-- close any open dropdown when the page scrolls
body:GetPropertyChangedSignal("CanvasPosition"):Connect(function() closeOpenDrop() end)

local pageSwitchDebounce = false
_G.OkumaUI_SelectPage = function(id)
    if pageSwitchDebounce then return end
    local newPage = pages[id]
    if not newPage then return end
    if activePageId == id then return end
    pageSwitchDebounce = true

    local oldPage = activePageId and pages[activePageId] or nil

    -- update nav visuals
    for pid, ref in pairs(navRefs) do
        local isActive = (pid == id)
        -- look the icon up live: it may have been swapped from a placeholder to a real ImageLabel
        local icon = ref.button:FindFirstChildWhichIsA("ImageLabel")
        local col = isActive and T.Text or T.TextDim
        if isActive then
            Tween(ref.button, { BackgroundTransparency = 0 }, 0.18); ref.button.BackgroundColor3 = T.Card
        else
            Tween(ref.button, { BackgroundTransparency = 1 }, 0.18)
        end
        Tween(ref.labelObj, { TextColor3 = col }, 0.18)
        if icon then Tween(icon, { ImageColor3 = col }, 0.18) end
    end

    -- update header
    headerTitle.Text = newPage.title
    if headerIcon and headerIcon.Parent then headerIcon:Destroy() end
    headerIcon = MakeIcon(header, newPage.iconName, 24, T.Text)
    headerIcon.Position = UDim2.new(0, 0, 0.5, -12)

    -- fade transition (one tween per page, never leaves the debounce stuck)
    closeOpenDrop()
    local ok, err = pcall(function()
        if oldPage then
            TweenService:Create(oldPage.frame, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                { GroupTransparency = 1 }):Play()
            task.wait(0.12)
            oldPage.frame.Visible = false
        end
        body.CanvasPosition = Vector2.new(0, 0)
        newPage.frame.GroupTransparency = 1
        newPage.frame.Visible = true
        TweenService:Create(newPage.frame, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { GroupTransparency = 0 }):Play()
        task.wait(0.1)
    end)
    activePageId = id
    pageSwitchDebounce = false
end

-- ============================================================================
-- COMPONENTS
-- ============================================================================

-- plain card: no header, children added directly
local function Card(parent)
    local c = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = parent,
    })
    Corner(c, 12); Stroke(c, T.BorderLow, 1); Padding(c, 20, 20, 18, 18); VList(c, 12)
    return c
end

-- Ouroboros-style card: title header with 2 action icons (folder + chevron) and separator
-- Returns the content body (children go here)
local function TitledCard(parent, title, iconName)
    local c = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = parent,
    })
    Corner(c, 12); Stroke(c, T.BorderLow, 1); VList(c, 0)
    c.ClipsDescendants = true

    local hdr = New("Frame", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Parent = c,
    })
    hdr.BackgroundTransparency = 0
    hdr.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
    Padding(hdr, 18, 14, 0, 0)

    local titleIcon = MakeIcon(hdr, iconName or "overview", 16, T.TextDim)
    titleIcon.AnchorPoint = Vector2.new(0, 0.5)
    titleIcon.Position = UDim2.new(0, 0, 0.5, 0)

    New("TextLabel", {
        Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -96, 1, 0),
        BackgroundTransparency = 1, Text = title, TextColor3 = T.Text,
        FontFace = F.Bold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = hdr,
    })

    local actions = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 60, 0, 24), BackgroundTransparency = 1, Parent = hdr,
    })
    HList(actions, 4, Enum.VerticalAlignment.Center)

    local function tinyIconBtn(iconName)
        local b = New("TextButton", {
            Size = UDim2.new(0, 26, 0, 22), BackgroundTransparency = 1,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = actions,
        })
        local ic = MakeIcon(b, iconName, 14, T.TextDim)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.new(0.5, 0, 0.5, 0)
        -- the icon can be swapped (placeholder -> Lucide) after creation, so look it up live
        local function currentIcon() return b:FindFirstChildWhichIsA("ImageLabel") end
        b.MouseEnter:Connect(function()
            local i = currentIcon(); if i then Tween(i, { ImageColor3 = T.Text }, 0.12) end
        end)
        b.MouseLeave:Connect(function()
            local i = currentIcon(); if i then Tween(i, { ImageColor3 = T.TextDim }, 0.12) end
        end)
        return b, ic
    end
    local folderBtn = tinyIconBtn("picture-in-picture-2")
    local chevronBtn, chevronIc = tinyIconBtn("chevron_down")

    local separator = New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.BorderLow,
        BorderSizePixel = 0, Parent = c })

    -- CanvasGroup so the body can fade while its height animates
    local bodyFrame = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = c,
    })
    Padding(bodyFrame, 18, 18, 14, 16); VList(bodyFrame, 10)

    -- animated collapse / expand
    local collapsed, busy, fullH = false, false, 0
    local COLLAPSE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    chevronBtn.MouseButton1Click:Connect(function()
        if busy then return end
        busy = true
        collapsed = not collapsed
        local chev = chevronBtn:FindFirstChildWhichIsA("ImageLabel") or chevronIc
        Tween(chev, { Rotation = collapsed and -90 or 0 }, 0.25)
        if collapsed then
            fullH = bodyFrame.AbsoluteSize.Y
            bodyFrame.AutomaticSize = Enum.AutomaticSize.None
            bodyFrame.Size = UDim2.new(1, 0, 0, fullH)
            TweenService:Create(bodyFrame, COLLAPSE_INFO,
                { Size = UDim2.new(1, 0, 0, 0), GroupTransparency = 1 }):Play()
            task.wait(0.3)
            bodyFrame.Visible = false
            separator.Visible = false
        else
            separator.Visible = true
            bodyFrame.Visible = true
            TweenService:Create(bodyFrame, COLLAPSE_INFO,
                { Size = UDim2.new(1, 0, 0, fullH), GroupTransparency = 0 }):Play()
            task.wait(0.3)
            bodyFrame.AutomaticSize = Enum.AutomaticSize.Y
            bodyFrame.Size = UDim2.new(1, 0, 0, 0)
        end
        busy = false
    end)

    return bodyFrame
end

-- Row: label on left, control on right
local function Row(parent, labelText)
    local r = New("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = parent })
    if labelText then
        New("TextLabel", {
            Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0),
            BackgroundTransparency = 1, Text = labelText, TextColor3 = T.Text,
            FontFace = F.Medium, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = r,
        })
    end
    return r
end

local function Toggle(parent, labelText, default, cb)
    local r = Row(parent, labelText)
    local track = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 36, 0, 20),
        BackgroundColor3 = default and T.Toggle_On or T.Toggle_Off,
        BorderSizePixel = 0, Parent = r,
    })
    Corner(track, 10)
    local knob = New("Frame", {
        Position = UDim2.new(0, default and 18 or 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = track,
    })
    Corner(knob, 8)
    local btn = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, Parent = r })
    local state = default and true or false
    local ON_KNOB, OFF_KNOB = Color3.fromRGB(16, 16, 17), Color3.fromRGB(138, 138, 148)
    knob.BackgroundColor3 = state and ON_KNOB or OFF_KNOB
    btn.MouseButton1Click:Connect(function()
        state = not state
        Tween(track, { BackgroundColor3 = state and T.Toggle_On or T.Toggle_Off }, 0.18)
        Tween(knob, { Position = UDim2.new(0, state and 18 or 2, 0.5, -8),
            BackgroundColor3 = state and ON_KNOB or OFF_KNOB }, 0.18)
        if cb then local ok, err = pcall(cb, state); if not ok then Notify({ title = "Something went wrong", body = tostring(err):sub(1, 90), color = T.Error, icon = "x", duration = 5 }) end end
    end)
    return { Set = function(_, v)
        state = v and true or false
        track.BackgroundColor3 = state and T.Toggle_On or T.Toggle_Off
        knob.BackgroundColor3 = state and ON_KNOB or OFF_KNOB
        knob.Position = UDim2.new(0, state and 18 or 2, 0.5, -8)
    end, Get = function() return state end }
end

local function Dropdown(parent, labelText, options, default, cb)
    -- stacked like Ouroboros: label on top, full-width select underneath
    local hasLabel = labelText ~= nil and labelText ~= ""
    local r = New("Frame", {
        Size = UDim2.new(1, 0, 0, hasLabel and 54 or 32), BackgroundTransparency = 1, Parent = parent,
    })
    if hasLabel then
        New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = labelText,
            TextColor3 = T.Text, FontFace = F.Medium, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = r,
        })
    end
    local head = New("TextButton", {
        Position = UDim2.new(0, 0, 0, hasLabel and 22 or 0),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.BgDeep, BorderSizePixel = 0, Text = "",
        AutoButtonColor = false, Parent = r,
    })
    Corner(head, 7); Stroke(head, T.BorderLow, 1)
    local headLbl = New("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1, Text = default or (options[1] or ""),
        TextColor3 = T.Text, FontFace = F.Regular, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = head,
    })
    local chevron = MakeIcon(head, "chevron_down", 12, T.TextDim)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -8, 0.5, 0)

    local listHeight = math.min(#options, 6) * 23 + 8
    -- parented to the overlay layer, NOT to the row (see OVERLAY LAYER note)
    local list = New("Frame", {
        Size = UDim2.new(0, 150, 0, listHeight),
        BackgroundColor3 = T.CardAlt, BorderSizePixel = 0,
        Visible = false, ZIndex = 5, Parent = overlay,
    })
    Corner(list, 8); Stroke(list, T.Border, 1); Padding(list, 4, 4, 4, 4); VList(list, 1)

    local selected = default or options[1]
    local function close()
        list.Visible = false
        Tween(chevron, { Rotation = 0 }, 0.18)
        if currentDrop and currentDrop.list == list then
            currentDrop = nil
            dropCatcher.Visible = false
        end
    end
    local function build()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local b = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = opt,
                TextColor3 = (opt == selected) and T.Text or T.TextDim,
                FontFace = F.Regular, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, Parent = list, ZIndex = 6,
            })
            Padding(b, 10, 10, 0, 0)
            b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.5; b.BackgroundColor3 = T.CardHover end)
            b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
            b.MouseButton1Click:Connect(function()
                selected = opt; headLbl.Text = opt
                close(); build()
                if cb then pcall(cb, opt) end
            end)
        end
    end
    build()

    local function open()
        closeOpenDrop()
        local rel = head.AbsolutePosition - overlay.AbsolutePosition
        local w = head.AbsoluteSize.X
        local y = rel.Y + head.AbsoluteSize.Y + 4
        -- not enough room below? open upward instead
        if y + listHeight > overlay.AbsoluteSize.Y - 8 then
            y = rel.Y - listHeight - 4
        end
        list.Size = UDim2.new(0, w, 0, listHeight)
        list.Position = UDim2.new(0, rel.X, 0, y)
        list.Visible = true
        dropCatcher.Visible = true
        currentDrop = { list = list, close = close }
        Tween(chevron, { Rotation = 180 }, 0.18)
    end
    head.MouseButton1Click:Connect(function()
        if list.Visible then close() else open() end
    end)
    return { Set = function(_, v) selected = v; headLbl.Text = v; build() end,
             Get = function() return selected end }
end

-- Row with right-aligned keybind pill
local function KeybindRow(parent, labelText, keyText)
    local r = Row(parent, labelText)
    local pill = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 50, 0, 22),
        BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Parent = r,
    })
    Corner(pill, 6); Stroke(pill, T.BorderLow, 1)
    New("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = keyText, TextColor3 = T.Text, FontFace = F.Medium, TextSize = 10, Parent = pill })
    return pill
end

-- Row with right-aligned static status text
local function StatusRow(parent, labelText, valueText)
    local r = Row(parent, labelText)
    New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 150, 1, 0), BackgroundTransparency = 1,
        Text = valueText, TextColor3 = T.TextDim, FontFace = F.Medium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = r,
    })
    return r
end

-- Color chip row (color swatch + hex label)
local function ColorRow(parent, labelText, color, hexText)
    local r = Row(parent, labelText)
    local wrap = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 130, 0, 24), BackgroundTransparency = 1, Parent = r,
    })

    New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0),
        Size = UDim2.new(0, 70, 1, 0), BackgroundTransparency = 1,
        Text = hexText, TextColor3 = T.TextDim, FontFace = F.Medium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap,
    })

    local chip = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 20),
        BackgroundColor3 = color, BorderSizePixel = 0, Parent = wrap,
    })
    Corner(chip, 5); Stroke(chip, T.BorderLow, 1)
    local chev = MakeIcon(wrap, "chevron_down", 10, T.TextDim)
    chev.AnchorPoint = Vector2.new(0.5, 0.5)
    chev.Position = UDim2.new(1, -40, 0.5, 0)
    chev.Rotation = -90   -- show as a sideways chevron to indicate expand
    return r
end

local function Button(parent, labelText, cb, variant, iconName)
    local isPrimary = variant == "primary"
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = isPrimary and T.Accent or T.CardAlt,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = parent,
    })
    Corner(b, 8)
    if not isPrimary then Stroke(b, T.BorderLow, 1) end
    local content = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Parent = b,
    })
    HList(content, 7)
    if iconName then
        MakeIcon(content, iconName, 14, isPrimary and T.BgDeep or T.TextDim)
    end
    New("TextLabel", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Text = labelText, TextColor3 = isPrimary and T.BgDeep or T.Text,
        FontFace = F.Medium, TextSize = 12, Parent = content })
    b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = isPrimary and T.AccentDim or T.CardHover }, 0.15) end)
    b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = isPrimary and T.Accent or T.CardAlt }, 0.15) end)
    b.MouseButton1Down:Connect(function() Tween(b, { Size = UDim2.new(1, 0, 0, 30) }, 0.08) end)
    b.MouseButton1Up:Connect(function()   Tween(b, { Size = UDim2.new(1, 0, 0, 32) }, 0.12) end)
    b.MouseButton1Click:Connect(function() if cb then local ok, err = pcall(cb); if not ok then Notify({ title = "Something went wrong", body = tostring(err):sub(1, 90), color = T.Error, icon = "x", duration = 5 }) end end end)
    return b
end

-- Grid of 2 buttons in one row
local function ButtonRow(parent, items)
    local r = New("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = parent })
    HList(r, 8)
    for _, it in ipairs(items) do
        local btn = New("TextButton", {
            Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Text = it.label,
            TextColor3 = T.Text, FontFace = F.Medium, TextSize = 12, AutoButtonColor = false, Parent = r,
        })
        Corner(btn, 8); Stroke(btn, T.BorderLow, 1)
        btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = T.CardHover }, 0.15) end)
        btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = T.CardAlt }, 0.15) end)
        btn.MouseButton1Click:Connect(function() if it.cb then pcall(it.cb) end end)
    end
    return r
end

-- labeled input (single-line textbox)
local function Input(parent, labelText, placeholder, default, cb)
    local r = Row(parent, labelText)
    local box = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 150, 0, 26),
        BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Parent = r,
    })
    Corner(box, 7)
    local stroke = Stroke(box, T.BorderLow, 1)
    Padding(box, 10, 10, 0, 0)
    local tb = New("TextBox", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = placeholder or "", PlaceholderColor3 = T.TextDim,
        TextColor3 = T.Text, FontFace = F.Regular, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Text = default or "", Parent = box,
    })
    tb.Focused:Connect(function() Tween(stroke, { Color = T.Accent }, 0.15) end)
    tb.FocusLost:Connect(function()
        Tween(stroke, { Color = T.BorderLow }, 0.15)
        if cb then pcall(cb, tb.Text) end
    end)
    return tb
end

-- ============================================================================
-- HOME PAGE
-- ============================================================================
local homePage = MakePage("home", "Welcome to Okuma!", "home")

-- Sub-tabs (Overview / Main Menu)
local subTabBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = homePage,
})
HList(subTabBar, 6)

local function SubTab(parent, text, iconName, active)
    local b = New("TextButton", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 32),
        BackgroundColor3 = active and T.Card or T.CardAlt,
        BackgroundTransparency = active and 0 or 0.45,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = parent,
    })
    Corner(b, 10)
    if active then Stroke(b, T.Border, 1) else Stroke(b, T.BorderLow, 1) end
    Padding(b, 14, 16, 0, 0)
    HList(b, 7)
    MakeIcon(b, iconName, 14, active and T.Text or T.TextDim)
    New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = active and T.Text or T.TextDim,
        FontFace = F.Medium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b,
    })
    return b
end
SubTab(subTabBar, "Overview",  "overview", true)
SubTab(subTabBar, "Main Menu", "play",     false)

-- WELCOME BACK card
local welcome = Card(homePage)
New("TextLabel", {
    Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
    Text = "WELCOME BACK", TextColor3 = T.TextMute, FontFace = F.Bold, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = welcome, LayoutOrder = 1,
})
local welcomeRow = New("Frame", {
    Size = UDim2.new(1, 0, 0, 94), BackgroundTransparency = 1, Parent = welcome, LayoutOrder = 2,
})
New("TextLabel", {
    Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -110, 0, 32),
    BackgroundTransparency = 1, Text = LocalPlayer.DisplayName or LocalPlayer.Name,
    TextColor3 = T.Text, FontFace = F.Bold, TextSize = 26,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = welcomeRow,
})
New("TextLabel", {
    Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, -110, 0, 14),
    BackgroundTransparency = 1, Text = ("@%s"):format(LocalPlayer.Name),
    TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = welcomeRow,
})

local welcomeAvatar = New("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 94, 0, 94), BackgroundColor3 = T.CardAlt,
    BorderSizePixel = 0, Parent = welcomeRow,
})
Corner(welcomeAvatar, 12); Stroke(welcomeAvatar, T.BorderLow, 1)
local welcomeAvatarImg = New("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "",
    ScaleType = Enum.ScaleType.Fit, Parent = welcomeAvatar,
})
Corner(welcomeAvatarImg, 12)
pcall(function()
    local big = Players:GetUserThumbnailAsync(LocalPlayer.UserId,
        Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size180x180)
    welcomeAvatarImg.Image = big
end)

local badges = New("Frame", { Position = UDim2.new(0, 0, 0, 66), Size = UDim2.new(1, -110, 0, 28), BackgroundTransparency = 1, Parent = welcomeRow })
HList(badges, 8)
local function Badge(parent, text, iconName)
    local b = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Parent = parent,
    })
    Corner(b, 8); Stroke(b, T.BorderLow, 1); Padding(b, 10, 12, 0, 0); HList(b, 6)
    MakeIcon(b, iconName, 12, T.TextDim)
    New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = T.Text,
        FontFace = F.Medium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b,
    })
    return b
end
Badge(badges, "Beta",   "beta_badge")
Badge(badges, "Name",   "tag")
Badge(badges, "Avatar", "user_person")

-- STATS card
local statsCard = Card(homePage)
local statsRow = New("Frame", { Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, Parent = statsCard, LayoutOrder = 1 })

local function StatCol(parent, xPct, label, valueText, unit, minT, avgT, maxT)
    local col = New("Frame", {
        Position = UDim2.new(xPct, 0, 0, 0), Size = UDim2.new(0.5, -10, 1, 0),
        BackgroundTransparency = 1, Parent = parent,
    })
    New("TextLabel", {
        Size = UDim2.new(0, 50, 0, 14), BackgroundTransparency = 1,
        Text = label, TextColor3 = T.TextDim, FontFace = F.Medium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = col,
    })
    New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(1, -50, 0, 14), BackgroundTransparency = 1,
        Text = ("min %s   avg %s   max %s"):format(minT, avgT, maxT),
        TextColor3 = T.TextMute, FontFace = F.Regular, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = col,
    })
    local valueLabel = New("TextLabel", {
        Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = valueText .. "  " .. ('<font color="rgb(140,140,150)" size="12">%s</font>'):format(unit),
        RichText = true, TextColor3 = T.Text, FontFace = F.Bold, TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = col,
    })
    local chart = New("Frame", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.new(0, 120, 0, 20), BackgroundTransparency = 1, Parent = col,
    })
    HList(chart, 2, Enum.VerticalAlignment.Bottom)
    for i = 1, 14 do
        local h = 4 + math.random(0, 14)
        local bar = New("Frame", { Size = UDim2.new(0, 4, 0, h),
            BackgroundColor3 = T.Success, BorderSizePixel = 0, Parent = chart })
        Corner(bar, 1)
    end
    return valueLabel
end

local fpsLabel  = StatCol(statsRow, 0,   "FPS",  "61", "fps", "0", "55", "61")
local pingLabel = StatCol(statsRow, 0.5, "Ping", "39", "ms",  "39", "131", "184")

New("Frame", { Position = UDim2.new(0, 0, 0, 80), Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = T.BorderLow, BorderSizePixel = 0, Parent = statsCard, LayoutOrder = 2 })

local counters = New("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = statsCard, LayoutOrder = 3 })
local function Counter(parent, xPct, label, value)
    local c = New("Frame", {
        Position = UDim2.new(xPct, 0, 0, 0), Size = UDim2.new(1/3, 0, 1, 0),
        BackgroundTransparency = 1, Parent = parent,
    })
    local valLbl = New("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = value, TextColor3 = T.Text, FontFace = F.Bold, TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = c })
    New("TextLabel", { Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1, Text = label, TextColor3 = T.TextDim,
        FontFace = F.Regular, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = c })
    return valLbl
end
local playersLbl = Counter(counters, 0,   "Players", ("%d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers))
local execsLbl   = Counter(counters, 1/3, "Execs",   "1")
local sessionLbl = Counter(counters, 2/3, "Session", "0s")

-- GAME card
local gameCard = Card(homePage)
local gameHeader = New("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = gameCard, LayoutOrder = 1 })

local gameImg = New("ImageLabel", {
    Size = UDim2.new(0, 54, 0, 54), BackgroundColor3 = T.CardAlt, BorderSizePixel = 0,
    Image = "", ScaleType = Enum.ScaleType.Crop, Parent = gameHeader,
})
Corner(gameImg, 10); Stroke(gameImg, T.BorderLow, 1)

local gameNameLabel = New("TextLabel", {
    Position = UDim2.new(0, 66, 0, 6), Size = UDim2.new(1, -66, 0, 20),
    BackgroundTransparency = 1, Text = "Loading...", TextColor3 = T.Text,
    FontFace = F.Bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = gameHeader,
})
local gameMetaLabel = New("TextLabel", {
    Position = UDim2.new(0, 66, 0, 28), Size = UDim2.new(1, -66, 0, 14),
    BackgroundTransparency = 1, Text = ("%d/%d players"):format(#Players:GetPlayers(), Players.MaxPlayers),
    TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = gameHeader,
})
task.spawn(function()
    local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
    if ok and info then
        gameNameLabel.Text = info.Name or "Unknown"
        gameMetaLabel.Text = ("by %s  ·  %d/%d players"):format(info.Creator and info.Creator.Name or "?", #Players:GetPlayers(), Players.MaxPlayers)
        if info.IconImageAssetId and info.IconImageAssetId ~= 0 then
            gameImg.Image = "rbxassetid://" .. info.IconImageAssetId
        end
    end
end)

local actions = New("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, Parent = gameCard, LayoutOrder = 2 })
HList(actions, 8)
local function ActionBtn(parent, label, iconName, cb)
    local b = New("TextButton", {
        Size = UDim2.new(0.25, -6, 1, 0), BackgroundColor3 = T.CardAlt,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = parent,
    })
    Corner(b, 10); Stroke(b, T.BorderLow, 1)
    local ic = MakeIcon(b, iconName, 20, T.Text)
    ic.AnchorPoint = Vector2.new(0.5, 0)
    ic.Position = UDim2.new(0.5, 0, 0, 12)
    New("TextLabel", { Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1, Text = label, TextColor3 = T.TextDim,
        FontFace = F.Medium, TextSize = 11, Parent = b })
    b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = T.CardHover }, 0.15) end)
    b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = T.CardAlt }, 0.15) end)
    b.MouseButton1Click:Connect(function() if cb then local ok, err = pcall(cb); if not ok then Notify({ title = "Something went wrong", body = tostring(err):sub(1, 90), color = T.Error, icon = "x", duration = 5 }) end end end)
    return b
end

local TeleportService = game:GetService("TeleportService")
ActionBtn(actions, "Rejoin", "rejoin", function()
    Notify({ title = "Rejoin", body = "Teleporting back to this server…", color = T.Accent })
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end)
ActionBtn(actions, "Hop", "shuffle", function()
    Notify({ title = "Server Hop", body = "Finding a new server…", color = T.Accent })
    task.spawn(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        local ok, data = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
        if ok and data and data.data then
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) end)
                    return
                end
            end
        end
        Notify({ title = "Server Hop", body = "No server found.", color = T.Error })
    end)
end)
ActionBtn(actions, "Lowest", "lowest", function()
    Notify({ title = "Lowest", body = "Hopping to least-populated server…", color = T.Accent })
    task.spawn(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        local ok, data = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
        if ok and data and data.data then
            local best
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    if not best or s.playing < best.playing then best = s end
                end
            end
            if best then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer) end)
                return
            end
        end
        Notify({ title = "Lowest", body = "No server found.", color = T.Error })
    end)
end)
ActionBtn(actions, "Job ID", "copy", function()
    if Copy(game.JobId) then
        Notify({ title = "Job ID", body = "Copied to clipboard.", color = T.Success })
    else
        Notify({ title = "Job ID", body = "Clipboard unavailable.", color = T.Error })
    end
end)

New("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
    Text = ("Job %s…  ·  Place %d"):format(string.sub(game.JobId, 1, 10), game.PlaceId),
    TextColor3 = T.TextMute, FontFace = F.Regular, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = gameCard, LayoutOrder = 3 })

-- LINKS card
local linksCard = Card(homePage)
New("TextLabel", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
    Text = "LINKS", TextColor3 = T.TextMute, FontFace = F.Bold, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = linksCard, LayoutOrder = 1 })

local function LinkRow(parent, iconName, title, subtitle, trailingIcon, cb)
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Parent = parent })
    local ic = MakeIcon(row, iconName, 24, T.Text)
    ic.AnchorPoint = Vector2.new(0, 0.5)
    ic.Position = UDim2.new(0, 2, 0.5, 0)
    New("TextLabel", { Position = UDim2.new(0, 40, 0, 6), Size = UDim2.new(1, -80, 0, 16),
        BackgroundTransparency = 1, Text = title, TextColor3 = T.Text,
        FontFace = F.Medium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    if subtitle then
        New("TextLabel", { Position = UDim2.new(0, 40, 0, 24), Size = UDim2.new(1, -80, 0, 14),
            BackgroundTransparency = 1, Text = subtitle, TextColor3 = T.TextDim,
            FontFace = F.Regular, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    end
    local trailing = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 32, 0, 28), BackgroundColor3 = T.CardAlt,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = row,
    })
    Corner(trailing, 8); Stroke(trailing, T.BorderLow, 1)
    local trIcon = MakeIcon(trailing, trailingIcon or "copy", 14, T.TextDim)
    trIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    trIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    trailing.MouseEnter:Connect(function() Tween(trailing, { BackgroundColor3 = T.CardHover }, 0.15) end)
    trailing.MouseLeave:Connect(function() Tween(trailing, { BackgroundColor3 = T.CardAlt }, 0.15) end)
    trailing.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
    return row
end
LinkRow(linksCard, "discord",  "Community", "https://discord.gg/okuma",  "copy", function()
    if Copy("https://discord.gg/okuma") then Notify({ title = "Community", body = "Discord link copied.", color = T.Success }) end
end)
LinkRow(linksCard, "globe",    "Website",   "https://okuma.app",         "copy", function()
    if Copy("https://okuma.app") then Notify({ title = "Website", body = "Link copied.", color = T.Success }) end
end)
LinkRow(linksCard, "checklist","Feature list", "7 features across 4 tabs", "chevron_right", function()
    _G.OkumaUI_SelectPage("protection")
end)

-- ============================================================================
-- SETTINGS PAGE (two-column: Menu | Themes)
-- ============================================================================
local settingsPage = MakePage("settings", "Settings", "settings")

local twoColRow = New("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Parent = settingsPage,
})
HList(twoColRow, 14, Enum.VerticalAlignment.Top)

local leftCol = New("Frame", {
    Size = UDim2.new(0.5, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Parent = twoColRow,
})
VList(leftCol, 14)

local rightCol = New("Frame", {
    Size = UDim2.new(0.5, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Parent = twoColRow,
})
VList(rightCol, 14)

-- Menu card
local menuBody = TitledCard(leftCol, "Menu", "monitor")
KeybindRow(menuBody, "Toggle UI", "RCtrl")
Dropdown(menuBody, "Toggle button", { "Mobile only", "Always", "Never" }, Config.toggleButton, function(v)
    Config.toggleButton = v; SaveConfig()
end)
Toggle(menuBody, "Anti AFK", Config.antiAfk, function(v)
    Config.antiAfk = v; SaveConfig()
    Notify({ title = "Anti AFK", body = v and "Enabled." or "Disabled.", color = v and T.Success or T.TextDim })
end)
Toggle(menuBody, "Minimize UI on Start", Config.minimizeOnStart, function(v)
    Config.minimizeOnStart = v; SaveConfig()
end)
Button(menuBody, "Unload", function()
    Notify({ title = "Okuma", body = "Unloading…", color = T.Error })
    task.wait(0.4)
    if genv.OkumaARSNAL_Cleanup then genv.OkumaARSNAL_Cleanup() end
end, nil, "unload")

-- Configs card
local configsBody = TitledCard(leftCol, "Configs", "folder")
New("TextLabel", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
    Text = "no configs yet", TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = configsBody })

-- Themes card
local themesBody = TitledCard(rightCol, "Themes", "palette")
Dropdown(themesBody, "Preset", { "Mono", "Plum", "Ocean" }, Config.preset, function(v)
    Config.preset = v; SaveConfig()
    Notify({ title = "Theme", body = "Preset set to " .. v .. ".", color = T.Accent })
end)
Input(themesBody, "", "theme name", "", nil)
ButtonRow(themesBody, {
    { label = "Create", cb = function() Notify({ title = "Theme", body = "Theme created.", color = T.Success }) end },
})
Dropdown(themesBody, "Theme", { "no themes" }, "no themes")
ButtonRow(themesBody, {
    { label = "Save", cb = function() SaveConfig(); Notify({ title = "Config", body = "Saved to disk.", color = T.Success }) end },
    { label = "Load", cb = function() LoadConfig(); Notify({ title = "Config", body = "Reloaded from disk.", color = T.Accent }) end },
})
ButtonRow(themesBody, {
    { label = "Delete",      cb = function() Notify({ title = "Theme", body = "Deleted.", color = T.Error }) end },
    { label = "Set Default", cb = function() Notify({ title = "Theme", body = "Set as default.", color = T.Accent }) end },
})
New("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
    Text = "Default theme: none", TextColor3 = T.TextDim, FontFace = F.Regular, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = themesBody })
ColorRow(themesBody, "Accent",     Color3.fromRGB(236,236,240), "#ECECF0")
ColorRow(themesBody, "Background", Color3.fromRGB(16,16,17),    "#101011")
ColorRow(themesBody, "Surface",    Color3.fromRGB(25,25,26),    "#19191A")
ColorRow(themesBody, "Text",       Color3.fromRGB(234,234,236), "#EAEAEC")

-- ============================================================================
-- STUB PAGES (Protection, Movement, Target, Fling, Utility)
-- ============================================================================
-- ============================================================================
-- ARSENAL FEATURES  (wrapped in a function: separate Luau register budget)
-- ============================================================================
local extraCleanups = {}
local function mountArsenal()
local defaults = {
    aimOn = false, aimKey = "Right mouse", aimPart = "Head", aimFov = 150, aimSmooth = 4,
    aimTeam = true, aimWall = true, showFov = true,
    trigOn = false, trigDelay = 40,
    espOn = false, espNames = true, espTeam = false, fovCam = 70,
    hbOn = false, hbSize = 6,
    gmSpread = false, gmRapid = false, gmReload = false, gmAmmo = false,
    walkSpeed = 16, jumpPower = 50, infJump = false, bhop = false, fly = false, flySpeed = 60, noclip = false,
}
for k, v in pairs(defaults) do if Config[k] == nil then Config[k] = v end end

local FC = {}
local function fdrop(name)
    if FC[name] then pcall(function() FC[name]:Disconnect() end); FC[name] = nil end
end
local function fconn(name, conn) fdrop(name); FC[name] = conn; Track(conn) end
local function toast(title, on)
    Notify({ title = title, body = on and "Enabled" or "Disabled",
        color = on and T.Success or T.TextDim, icon = on and "check" or "x" })
end
local function getChar()
    local c = LocalPlayer.Character
    return c, c and c:FindFirstChildWhichIsA("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end
local function sameTeam(p)
    if p.Team == nil and LocalPlayer.Team == nil then return false end
    return p.Team == LocalPlayer.Team
end
local function charParts(p)
    local c = p.Character
    local h = c and c:FindFirstChildWhichIsA("Humanoid")
    if not (c and h and h.Health > 0) then return nil end
    return c, h, c:FindFirstChild("HumanoidRootPart")
end

-- ---- Aimbot ---------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function visible(cam, part, char)
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, cam, char }
    local origin = cam.CFrame.Position
    return workspace:Raycast(origin, part.Position - origin, rayParams) == nil
end
local function getTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local mouse = UserInputService:GetMouseLocation()
    local best, bestD = nil, Config.aimFov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not (Config.aimTeam and sameTeam(p)) then
            local c = charParts(p)
            if c then
                local part = c:FindFirstChild(Config.aimPart) or c:FindFirstChild("HumanoidRootPart")
                if part then
                    local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if d < bestD and (not Config.aimWall or visible(cam, part, c)) then
                            best, bestD = part, d
                        end
                    end
                end
            end
        end
    end
    return best
end
local function aimHeld()
    local k = Config.aimKey
    if k == "Always" then return true end
    local ut = (k == "Left mouse") and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseButton2
    return UserInputService:IsMouseButtonPressed(ut)
end

local fovCircle = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0,
    Visible = false, Parent = gui,
})
Corner(fovCircle, 1000)
Stroke(fovCircle, Color3.fromRGB(255, 255, 255), 1).Transparency = 0.45

local AIM_STEP = "OkumaArsenalAim"
RunService:BindToRenderStep(AIM_STEP, Enum.RenderPriority.Camera.Value + 1, function()
    local mouse = UserInputService:GetMouseLocation()
    fovCircle.Visible = Config.aimOn and Config.showFov
    fovCircle.Position = UDim2.fromOffset(mouse.X, mouse.Y)
    fovCircle.Size = UDim2.fromOffset(Config.aimFov * 2, Config.aimFov * 2)
    if not Config.aimOn or not aimHeld() then return end
    local part = getTarget()
    if not part then return end
    local cam = workspace.CurrentCamera
    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, part.Position), 1 / math.max(1, Config.aimSmooth))
end)

-- ---- Triggerbot -----------------------------------------------------------
local lastShot = 0
fconn("trig", RunService.Heartbeat:Connect(function()
    if not Config.trigOn then return end
    if os.clock() - lastShot < Config.trigDelay / 1000 + 0.06 then return end
    local t = LocalPlayer:GetMouse().Target
    local model = t and t:FindFirstAncestorOfClass("Model")
    local p = model and Players:GetPlayerFromCharacter(model)
    if p and p ~= LocalPlayer and not (Config.aimTeam and sameTeam(p)) and charParts(p) then
        lastShot = os.clock()
        task.delay(Config.trigDelay / 1000, function()
            if type(mouse1click) == "function" then mouse1click()
            elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
                mouse1press(); task.wait(0.02); mouse1release()
            end
        end)
    end
end))

-- ---- ESP ------------------------------------------------------------------
local espFolder = New("Folder", { Name = "ESP", Parent = gui })
local espObjs = {}
local function clearEsp(p)
    local o = espObjs[p]; if not o then return end
    pcall(function() o.hl:Destroy() end); pcall(function() o.bb:Destroy() end)
    espObjs[p] = nil
end
local function clearAllEsp() for p in pairs(espObjs) do clearEsp(p) end end
local function updateEsp()
    if not Config.espOn then clearAllEsp(); return end
    local _, _, myHrp = getChar()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c, h = charParts(p)
            local head = c and c:FindFirstChild("Head")
            if c and head and (Config.espTeam or not sameTeam(p)) then
                local o = espObjs[p]
                if not o or o.char ~= c then
                    clearEsp(p)
                    local hl = Instance.new("Highlight")
                    hl.Adornee = c; hl.FillTransparency = 0.6; hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = espFolder
                    local bb = Instance.new("BillboardGui")
                    bb.Adornee = head; bb.Size = UDim2.fromOffset(170, 34)
                    bb.StudsOffset = Vector3.new(0, 2.6, 0); bb.AlwaysOnTop = true; bb.Parent = espFolder
                    local lbl = New("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                        FontFace = F.Bold, TextSize = 13, TextStrokeTransparency = 0.4, Parent = bb })
                    o = { hl = hl, bb = bb, lbl = lbl, char = c }
                    espObjs[p] = o
                end
                local col = (p.Team and p.TeamColor.Color) or Color3.fromRGB(255, 70, 70)
                o.hl.FillColor = col; o.hl.OutlineColor = col
                o.lbl.TextColor3 = col; o.lbl.Visible = Config.espNames
                local dist = myHrp and math.floor((myHrp.Position - head.Position).Magnitude) or 0
                o.lbl.Text = ("%s  [%d]  %dm"):format(p.DisplayName, math.floor(h.Health), dist)
            else
                clearEsp(p)
            end
        end
    end
    for p in pairs(espObjs) do if not p.Parent then clearEsp(p) end end
end
do
    local acc = 0
    fconn("esp", RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc < 0.12 then return end
        acc = 0; updateEsp()
    end))
end
fconn("espLeave", Players.PlayerRemoving:Connect(clearEsp))

-- ---- Bunny hop (just repeats the normal jump input)
fconn("bhop", RunService.Heartbeat:Connect(function()
    if not Config.bhop or not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
    local _, h = getChar()
    if h and h.FloorMaterial ~= Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

local function setCamFov(v)
    Config.fovCam = v; SaveConfig()
    local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = v end
end

-- ============================================================================
-- SLIDER COMPONENT  (not in the base UI yet)
-- ============================================================================
local function Slider(parent, labelText, minV, maxV, default, cb)
    local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = parent })
    New("TextLabel", { Size = UDim2.new(0.7, 0, 0, 18), BackgroundTransparency = 1, Text = labelText,
        TextColor3 = T.Text, FontFace = F.Medium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap })
    local valLbl = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0.3, 0, 0, 18), BackgroundTransparency = 1, Text = tostring(default),
        TextColor3 = T.TextDim, FontFace = F.Medium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap })
    local track = New("Frame", { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = T.CardAlt, BorderSizePixel = 0, Parent = wrap })
    Corner(track, 2)
    local rel0 = math.clamp((default - minV) / (maxV - minV), 0, 1)
    local fill = New("Frame", { Size = UDim2.new(rel0, 0, 1, 0), BackgroundColor3 = T.Text,
        BorderSizePixel = 0, Parent = track })
    Corner(fill, 2)
    local knob = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(rel0, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = T.Text, BorderSizePixel = 0, Parent = track })
    Corner(knob, 6)
    local hit = New("TextButton", { Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = wrap })
    local sliding = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + rel * (maxV - minV) + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        if cb then pcall(cb, v) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true; setFromX(i.Position.X)
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end))
    return wrap
end

-- ============================================================================
-- PAGES
-- ============================================================================
local aimPage = MakePage("aimbot", "Aimbot", "target")
local aim = TitledCard(aimPage, "Aimbot", "target")
Toggle(aim, "Enable aimbot", Config.aimOn, function(v) Config.aimOn = v; SaveConfig(); toast("Aimbot", v) end)
Dropdown(aim, "Aim key", { "Right mouse", "Left mouse", "Always" }, Config.aimKey, function(v) Config.aimKey = v; SaveConfig() end)
Dropdown(aim, "Target part", { "Head", "HumanoidRootPart" }, Config.aimPart, function(v) Config.aimPart = v; SaveConfig() end)
Slider(aim, "FOV radius (px)", 30, 500, Config.aimFov, function(v) Config.aimFov = v; SaveConfig() end)
Slider(aim, "Smoothness (1 = instant)", 1, 20, Config.aimSmooth, function(v) Config.aimSmooth = v; SaveConfig() end)
Toggle(aim, "Team check", Config.aimTeam, function(v) Config.aimTeam = v; SaveConfig() end)
Toggle(aim, "Wall check", Config.aimWall, function(v) Config.aimWall = v; SaveConfig() end)
Toggle(aim, "Show FOV circle", Config.showFov, function(v) Config.showFov = v; SaveConfig() end)
local trig = TitledCard(aimPage, "Triggerbot", "zap")
Toggle(trig, "Enable triggerbot", Config.trigOn, function(v) Config.trigOn = v; SaveConfig(); toast("Triggerbot", v) end)
Slider(trig, "Delay (ms)", 0, 300, Config.trigDelay, function(v) Config.trigDelay = v; SaveConfig() end)

local visPage = MakePage("visuals", "Visuals", "eye")
local esp = TitledCard(visPage, "ESP", "eye")
Toggle(esp, "Enable ESP", Config.espOn, function(v) Config.espOn = v; SaveConfig(); toast("ESP", v) end)
Toggle(esp, "Name, health, distance", Config.espNames, function(v) Config.espNames = v; SaveConfig() end)
Toggle(esp, "Show teammates", Config.espTeam, function(v) Config.espTeam = v; SaveConfig() end)
local cam = TitledCard(visPage, "Camera", "eye")
Slider(cam, "Field of view", 40, 120, Config.fovCam, setCamFov)

local utilPage = MakePage("utility", "Utility", "wrench")
local session = TitledCard(utilPage, "Session", "wrench")
Toggle(session, "Bunny hop (hold Space)", Config.bhop, function(v) Config.bhop = v; SaveConfig(); toast("Bunny hop", v) end)
Button(session, "Rejoin", function()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end, nil, "rejoin")
Button(session, "Reset character", function()
    local _, h = getChar(); if h then h.Health = 0 end
end, nil, "unload")

-- restore saved states on load
-- ---- small icon in front of every row label ---------------------------------
local LABEL_ICONS = {
    ["Enable aimbot"] = "crosshair", ["Aim key"] = "keyboard", ["Target part"] = "scan",
    ["FOV radius (px)"] = "circle", ["Smoothness (1 = instant)"] = "sliders-horizontal",
    ["Team check"] = "users", ["Wall check"] = "brick-wall", ["Show FOV circle"] = "circle",
    ["Enable triggerbot"] = "zap", ["Delay (ms)"] = "timer",
    ["Enable ESP"] = "eye", ["Name, health, distance"] = "tag", ["Show teammates"] = "users",
    ["Field of view"] = "scan", ["Bunny hop (hold Space)"] = "arrow-up",
    ["Toggle UI"] = "keyboard", ["Toggle button"] = "mouse-pointer-click", ["Anti AFK"] = "timer",
    ["Minimize UI on Start"] = "minimize-2", ["Preset"] = "palette", ["Theme"] = "swatch-book",
}
for _, d in ipairs(body:GetDescendants()) do
    local iconName = d:IsA("TextLabel") and LABEL_ICONS[d.Text]
    if iconName then
        local ic = MakeIcon(d.Parent, iconName, 14, T.TextDim)
        ic.AnchorPoint = Vector2.new(0, 0.5)
        ic.Position = UDim2.new(0, 0, d.Position.Y.Scale + d.Size.Y.Scale / 2, d.Position.Y.Offset + d.Size.Y.Offset / 2)
        d.Position = UDim2.new(d.Position.X.Scale, d.Position.X.Offset + 22, d.Position.Y.Scale, d.Position.Y.Offset)
        d.Size = UDim2.new(d.Size.X.Scale, d.Size.X.Offset - 22, d.Size.Y.Scale, d.Size.Y.Offset)
    end
end

if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = Config.fovCam end

table.insert(extraCleanups, function()
    pcall(function() RunService:UnbindFromRenderStep(AIM_STEP) end)
    clearAllEsp()
    for name in pairs(FC) do fdrop(name) end
end)
end
mountArsenal()

_G.OkumaUI_SelectPage("home")

-- ============================================================================
-- SEARCH FILTER (live: hides nav items that don't match)
-- ============================================================================
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(searchInput.Text)
    for id, ref in pairs(navRefs) do
        local title = string.lower(ref.labelObj.Text)
        ref.button.Visible = (q == "") or (string.find(title, q, 1, true) ~= nil)
    end
end)

-- ============================================================================
-- ANTI AFK (real)
-- ============================================================================
local VirtualUser = game:GetService("VirtualUser")
Track(LocalPlayer.Idled:Connect(function()
    if not Config.antiAfk then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

-- ============================================================================
-- LIVE DATA
-- ============================================================================
local frames = 0; local lastTime = tick()
Track(RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastTime >= 1 then
        local f = frames / (now - lastTime)
        fpsLabel.Text = ("%d  <font color=\"rgb(140,140,150)\" size=\"12\">fps</font>"):format(math.floor(f))
        miniCount.Text = tostring(math.floor(f))
        frames = 0; lastTime = now
    end
end))

task.spawn(function()
    while gui.Parent do
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and pingLabel then
            pingLabel.Text = ("%d  <font color=\"rgb(140,140,150)\" size=\"12\">ms</font>"):format(ping)
        end
        task.wait(1)
    end
end)

local sessionStart = tick()
task.spawn(function()
    while gui.Parent do
        local s = math.floor(tick() - sessionStart)
        local text
        if     s < 60   then text = s .. "s"
        elseif s < 3600 then text = math.floor(s/60) .. "m " .. (s % 60) .. "s"
        else                 text = math.floor(s/3600) .. "h " .. math.floor((s%3600)/60) .. "m" end
        if sessionLbl then sessionLbl.Text = text end
        if playersLbl then playersLbl.Text = ("%d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers) end
        task.wait(1)
    end
end)

-- ============================================================================
-- TOGGLE KEY + CLEANUP
-- ============================================================================
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        closeOpenDrop()
        window.Visible = not window.Visible
    end
end))

genv.OkumaARSNAL_Cleanup = function()
    for _, fn in ipairs(extraCleanups) do pcall(fn) end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    pcall(function() gui:Destroy() end)
    genv.OkumaARSNAL_Cleanup = nil
end

-- minimize on start (if enabled in settings)
if Config.minimizeOnStart then
    task.delay(0.6, function() setMinimized(true) end)
end

task.delay(0.8, function()
    Notify({ title = "Okuma", body = "UI loaded. Press RCtrl to hide/show.", color = T.Success })
end)


