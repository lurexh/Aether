if getgenv().AETHER_LOADED and type(getgenv().AETHER_UNLOAD) == "function" then
    pcall(getgenv().AETHER_UNLOAD)
end
getgenv().AETHER_LOADED = true

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CoreGui = game:GetService("CoreGui"),
    VirtualUser = game:GetService("VirtualUser"),
}

local LP = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============ CONFIG ============
local Config = {
    Accent = Color3.fromRGB(197, 0, 0),
    Background = Color3.fromRGB(18, 18, 18),
    Secondary = Color3.fromRGB(28, 28, 28),
    Text = Color3.fromRGB(240, 240, 240),
    Font = Enum.Font.Montserrat,
    RateLimit = 0.1,
    Version = "0.0.1",
}

-- ============ STATE ============
local State = {
    ESP = { Players = false, Murderer = false, Sheriff = false, Innocent = false, Gun = false, Coins = false, Traps = false },
    SilentAim = false,
    AutoShoot = false,
    AutoKnife = false,
    KillAura = false,
    KillAuraDist = 15,
    TargetPriority = "Nearest",
    FOVRadius = 200,
    WallCheck = false,
    Prediction = true,
    PingComp = true,
    Fly = false,
    FlySpeed = 50,
    Speed = false,
    SpeedValue = 16,
    JumpPower = false,
    JumpValue = 50,
    Noclip = false,
    InfiniteJump = false,
    Fullbright = false,
    AntiAFK = false,
    GodMode = false,
    AutoFarm = false,
    FarmMode = "Nearest",
    AutoGrabGun = false,
    AutoEndRound = false,
    ESPTransparency = 0.5,
    ShowArrows = true,
    ShowLabels = true,
}

local Connections = {}
local Highlights = {}
local ESPObjects = {}

local function track(conn)
    table.insert(Connections, conn)
    return conn
end

local function safeFire(remote, ...)
    if not remote then return end
    task.spawn(function()
        pcall(function() remote:FireServer(...) end)
    end)
    task.wait(Config.RateLimit)
end

local function safeInvoke(remote, ...)
    if not remote then return end
    local result
    pcall(function() result = remote:InvokeServer(...) end)
    task.wait(Config.RateLimit)
    return result
end

-- ============ ROLE DETECTION ============
local function findMurderer()
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr.Character then
            if plr.Character:FindFirstChild("Knife") then return plr end
            if plr.Backpack and plr.Backpack:FindFirstChild("Knife") then return plr end
        end
    end
    return nil
end

local function findSheriff()
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr.Character then
            if plr.Character:FindFirstChild("Gun") then return plr end
            if plr.Backpack and plr.Backpack:FindFirstChild("Gun") then return plr end
        end
    end
    return nil
end

local function isSheriff(plr)
    if plr == LP then
        return LP.Backpack:FindFirstChild("Gun") or (LP.Character and LP.Character:FindFirstChild("Gun"))
    end
    return plr == findSheriff()
end

local function isMurderer(plr)
    if plr == LP then
        return LP.Backpack:FindFirstChild("Knife") or (LP.Character and LP.Character:FindFirstChild("Knife"))
    end
    return plr == findMurderer()
end

-- ============ GUI FRAMEWORK ============
local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(obj, r)
    create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, obj)
end

local function stroke(obj, color, thickness)
    return create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 60),
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

local function getRoot()
    local root = create("ScreenGui", {
        Name = "Aether",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    local ok = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(root)
            root.Parent = Services.CoreGui
        elseif gethui then
            root.Parent = gethui()
        else
            root.Parent = Services.CoreGui
        end
    end)
    if not ok then root.Parent = LP:WaitForChild("PlayerGui") end
    return root
end

local ScreenGui = getRoot()

-- Main window
local Main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(560, 380),
    Position = UDim2.new(0.5, -280, 0.5, -190),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
}, ScreenGui)
corner(Main, 12)
stroke(Main, Color3.fromRGB(50, 50, 50), 1)

-- Sidebar
local Sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.fromOffset(140, 380),
    BackgroundColor3 = Config.Secondary,
    BorderSizePixel = 0,
}, Main)
corner(Sidebar, 12)
create("Frame", {
    Size = UDim2.new(0, 12, 1, 0),
    Position = UDim2.new(1, -6, 0, 0),
    BackgroundColor3 = Config.Secondary,
    BorderSizePixel = 0,
}, Sidebar)

-- Title
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 8),
    BackgroundTransparency = 1,
    Text = "Aether",
    TextColor3 = Config.Accent,
    Font = Config.Font,
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Center,
}, Sidebar)
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "v" .. Config.Version,
    TextColor3 = Color3.fromRGB(120, 120, 120),
    Font = Config.Font,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
}, Sidebar)

-- Tab container
local TabHolder = create("Frame", {
    Size = UDim2.new(1, -16, 1, -80),
    Position = UDim2.new(0, 8, 0, 68),
    BackgroundTransparency = 1,
}, Sidebar)
create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, TabHolder)

-- Content area
local Content = create("Frame", {
    Size = UDim2.new(1, -160, 1, -60),
    Position = UDim2.new(0, 152, 0, 50),
    BackgroundTransparency = 1,
}, Main)

local ContentHolder = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Config.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Content)
create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, ContentHolder)

local header = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 152, 0, 15),
    BackgroundTransparency = 1,
    Text = "Main",
    TextColor3 = Config.Text,
    Font = Config.Font,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)
create("Frame", {
    Size = UDim2.new(1, -160, 0, 1),
    Position = UDim2.new(0, 152, 0, 48),
    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
    BorderSizePixel = 0,
}, Main)

-- ============ UI ELEMENT BUILDERS ============
local function clearContent()
    for _, c in ipairs(ContentHolder:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function addSection(text)
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Config.Accent,
        Font = Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, ContentHolder)
    return lbl
end

local function addToggle(name, default, callback)
    local holder = create("Frame", {
        Size = UDim2.new(1, -8, 0, 34),
        BackgroundColor3 = Config.Secondary,
        BorderSizePixel = 0,
    }, ContentHolder)
    corner(holder, 6)
    stroke(holder, Color3.fromRGB(50, 50, 50), 1)

    create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local enabled = default
    local track = create("Frame", {
        Size = UDim2.fromOffset(44, 20),
        Position = UDim2.new(1, -54, 0.5, -10),
        BackgroundColor3 = enabled and Config.Accent or Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
    }, holder)
    corner(track, 10)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = enabled and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    corner(knob, 7)

    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, holder)

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        Services.TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Config.Accent or Color3.fromRGB(60, 60, 60)
        }):Play()
        Services.TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
        }):Play()
        if callback then pcall(callback, enabled) end
    end)

    return holder
end

local function addButton(name, callback, bgOverride)
    local btn = create("TextButton", {
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundColor3 = bgOverride or Config.Secondary,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 13,
    }, ContentHolder)
    corner(btn, 6)
    stroke(btn, Color3.fromRGB(50, 50, 50), 1)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return btn
end

local function addInput(name, placeholder, callback)
    local holder = create("Frame", {
        Size = UDim2.new(1, -8, 0, 56),
        BackgroundColor3 = Config.Secondary,
        BorderSizePixel = 0,
    }, ContentHolder)
    corner(holder, 6)
    stroke(holder, Color3.fromRGB(50, 50, 50), 1)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local box = create("TextBox", {
        Size = UDim2.new(1, -80, 0, 24),
        Position = UDim2.new(0, 10, 0, 26),
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        PlaceholderText = placeholder,
        Text = "",
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    corner(box, 4)

    local submit = create("TextButton", {
        Size = UDim2.fromOffset(58, 24),
        Position = UDim2.new(1, -68, 0, 26),
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
        Text = "Set",
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 12,
    }, holder)
    corner(submit, 4)
    submit.MouseButton1Click:Connect(function()
        if callback then pcall(callback, box.Text) end
    end)
    return holder
end

local function addSlider(name, min, max, default, callback)
    local holder = create("Frame", {
        Size = UDim2.new(1, -8, 0, 50),
        BackgroundColor3 = Config.Secondary,
        BorderSizePixel = 0,
    }, ContentHolder)
    corner(holder, 6)
    stroke(holder, Color3.fromRGB(50, 50, 50), 1)

    local lbl = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = name .. ": " .. tostring(default),
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local bar = create("Frame", {
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 32),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
    }, holder)
    corner(bar, 3)

    local fill = create("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Config.Accent,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 3)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel
        if max - min > 20 then val = math.floor(val) end
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = name .. ": " .. tostring(val)
        if callback then pcall(callback, val) end
    end

    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, bar)
    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    track(Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))
    track(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    return holder
end

local function addDropdown(name, options, default, callback)
    local holder = create("Frame", {
        Size = UDim2.new(1, -8, 0, 56),
        BackgroundColor3 = Config.Secondary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, ContentHolder)
    corner(holder, 6)
    stroke(holder, Color3.fromRGB(50, 50, 50), 1)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local selected = default or options[1]
    local display = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 26),
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        Text = selected,
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 12,
    }, holder)
    corner(display, 4)

    local open = false
    local list = create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 54),
        BackgroundColor3 = Config.Background,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, holder)
    corner(list, 4)
    create("UIListLayout", { Padding = UDim.new(0, 2) }, list)

    display.MouseButton1Click:Connect(function()
        open = not open
        Services.TweenService:Create(holder, TweenInfo.new(0.2), {
            Size = open and UDim2.new(1, -8, 0, 56 + math.min(#options * 22, 110)) or UDim2.new(1, -8, 0, 56)
        }):Play()
        Services.TweenService:Create(list, TweenInfo.new(0.2), {
            Size = open and UDim2.new(1, -20, 0, math.min(#options * 22, 110)) or UDim2.new(1, -20, 0, 0)
        }):Play()
    end)

    for _, opt in ipairs(options) do
        local ob = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = opt,
            TextColor3 = Config.Text,
            Font = Config.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, list)
        ob.MouseButton1Click:Connect(function()
            selected = opt
            display.Text = opt
            open = false
            Services.TweenService:Create(holder, TweenInfo.new(0.2), { Size = UDim2.new(1, -8, 0, 56) }):Play()
            Services.TweenService:Create(list, TweenInfo.new(0.2), { Size = UDim2.new(1, -20, 0, 0) }):Play()
            if callback then pcall(callback, opt) end
        end)
    end
    return holder
end

-- ============ ESP ============
local function getESP(plr)
    return ESPObjects[plr]
end

local function applyHighlight(plr, color)
    local char = plr.Character
    if not char then return end
    local existing = Highlights[plr]
    if existing then existing:Destroy() end
    local h = create("Highlight", {
        FillColor = color,
        FillTransparency = State.ESPTransparency,
        OutlineColor = color,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        Adornee = char,
        Parent = ScreenGui,
    })
    Highlights[plr] = h
end

local function applyLabel(plr, text, color)
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local existing = ESPObjects[plr]
    if existing then existing:Destroy() end
    local bb = create("BillboardGui", {
        Size = UDim2.fromOffset(120, 24),
        StudsOffset = Vector3.new(0, 2.5, 0),
        AlwaysOnTop = true,
        Adornee = head,
        Parent = ScreenGui,
    })
    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextScaled = true,
        TextStrokeTransparency = 0,
    }, bb)
    ESPObjects[plr] = bb
end

local function refreshESP(plr)
    if not plr.Character then
        if Highlights[plr] then Highlights[plr]:Destroy(); Highlights[plr] = nil end
        if ESPObjects[plr] then ESPObjects[plr]:Destroy(); ESPObjects[plr] = nil end
        return
    end

    local color = nil
    local text = nil

    if plr == findMurderer() and State.ESP.Murderer then
        color = Color3.fromRGB(255, 30, 30); text = "Murderer"
    elseif plr == findSheriff() and State.ESP.Sheriff then
        color = Color3.fromRGB(30, 120, 255); text = "Sheriff"
    elseif State.ESP.Innocent and plr ~= findMurderer() and plr ~= findSheriff() then
        color = Color3.fromRGB(30, 220, 60); text = "Innocent"
    end

    if State.ESP.Players and color then
        applyHighlight(plr, color)
        if State.ShowLabels then
            applyLabel(plr, text, color)
        else
            if ESPObjects[plr] then ESPObjects[plr]:Destroy(); ESPObjects[plr] = nil end
        end
    else
        if Highlights[plr] then Highlights[plr]:Destroy(); Highlights[plr] = nil end
        if ESPObjects[plr] then ESPObjects[plr]:Destroy(); ESPObjects[plr] = nil end
    end
end

local function fullESPClear()
    for plr, h in pairs(Highlights) do h:Destroy() end
    for plr, e in pairs(ESPObjects) do e:Destroy() end
    Highlights = {}
    ESPObjects = {}
end

-- Item ESP (Gun/Coins/Traps) using tags
local ItemESP = {}
local function clearItemESP()
    for _, obj in ipairs(ItemESP) do
        pcall(function() obj:Destroy() end)
    end
    ItemESP = {}
end

local function refreshItemESP()
    clearItemESP()
    if not (State.ESP.Gun or State.ESP.Coins or State.ESP.Traps) then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if State.ESP.Gun and obj.Name == "GunDrop" and obj:IsA("Model") then
            local h = create("Highlight", {
                FillColor = Color3.fromRGB(255, 220, 30),
                FillTransparency = 0.4,
                OutlineColor = Color3.fromRGB(255, 220, 30),
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                Adornee = obj,
                Parent = ScreenGui,
            })
            table.insert(ItemESP, h)
        elseif State.ESP.Coins and obj.Name == "Coin_Server" and obj:IsA("BasePart") then
            local h = create("Highlight", {
                FillColor = Color3.fromRGB(255, 200, 0),
                FillTransparency = 0.5,
                OutlineColor = Color3.fromRGB(255, 200, 0),
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                Adornee = obj,
                Parent = ScreenGui,
            })
            table.insert(ItemESP, h)
        elseif State.ESP.Traps and obj.Name == "Trap" and obj:IsA("BasePart") then
            local h = create("Highlight", {
                FillColor = Color3.fromRGB(255, 100, 0),
                FillTransparency = 0.4,
                OutlineColor = Color3.fromRGB(255, 100, 0),
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                Adornee = obj,
                Parent = ScreenGui,
            })
            table.insert(ItemESP, h)
        end
    end
end

-- ============ TARGETING ============
local function getTarget()
    local murderer = findMurderer()
    local sheriff = findSheriff()

    if State.TargetPriority == "Murderer" and murderer then return murderer end
    if State.TargetPriority == "Sheriff" and sheriff then return sheriff end

    local closest, dist = nil, math.huge
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and d < dist then
                    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                    local dx, dy = screenPos.X - cx, screenPos.Y - cy
                    if math.sqrt(dx * dx + dy * dy) <= State.FOVRadius then
                        closest = plr
                        dist = d
                    end
                end
            end
        end
    end
    return closest
end

local function predictPosition(plr)
    local char = plr.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    if State.Prediction then
        local vel = hrp.AssemblyLinearVelocity
        local ping = LP:GetNetworkPing() * 1000
        local mult = State.PingComp and (1 + ping / 1000) or 1
        return hrp.Position + vel * 0.15 * mult
    end
    return hrp.Position
end

-- ============ SILENT AIM HOOK ============
local mt = getrawmetatable and getrawmetatable(game)
local oldNamecall = nil
if mt and setreadonly and hookmetamethod and getnamecallmethod then
    setreadonly(mt, false)
    oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if State.SilentAim and (method == "FireServer" or method == "InvokeServer") then
            if self.Name == "Shoot" or self.Name == "KnifeThrown" or self.Name == "Throw" or self.Name == "Stab" then
                local target = getTarget()
                if target then
                    local pos = predictPosition(target)
                    if pos then
                        if method == "FireServer" then
                            if self.Name == "Shoot" or self.Name == "KnifeThrown" or self.Name == "Throw" then
                                args[#args] = pos
                            end
                        end
                    end
                end
            end
        end
        return oldNamecall(self, table.unpack(args))
    end)
    setreadonly(mt, true)
end

-- ============ AUTO SHOOT / KNIFE ============
local autoShootRunning = false
task.spawn(function()
    while true do
        task.wait(0.15)
        if State.AutoShoot and isSheriff(LP) then
            local target = getTarget()
            if target then
                local char = LP.Character
                if char and char:FindFirstChild("Gun") then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local trgHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                    if root and trgHrp then
                        if not State.WallCheck then
                            safeFire(char.Gun:FindFirstChild("Shoot"), CFrame.new(root.Position), CFrame.new(predictPosition(target) or trgHrp.Position))
                        else
                            local ray = Ray.new(root.Position, (trgHrp.Position - root.Position).Unit * 500)
                            local hit = workspace:FindPartOnRay(ray, char)
                            if hit and hit.Parent == target.Character then
                                safeFire(char.Gun:FindFirstChild("Shoot"), CFrame.new(root.Position), CFrame.new(predictPosition(target) or trgHrp.Position))
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if State.AutoKnife and isMurderer(LP) then
            local target = getTarget()
            if target and target.Character then
                local char = LP.Character
                local trgHrp = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                if trgHrp and myRoot then
                    local dist = (trgHrp.Position - myRoot.Position).Magnitude
                    if dist <= State.KillAuraDist then
                        local knife = char:FindFirstChild("Knife") or LP.Backpack:FindFirstChild("Knife")
                        if knife then
                            if knife.Parent ~= char then
                                pcall(function() char.Humanoid:EquipTool(knife) end)
                            end
                            safeFire(knife:FindFirstChild("Throw"), CFrame.new(myRoot.Position), CFrame.new(predictPosition(target) or trgHrp.Position))
                        end
                    end
                end
            end
        end
    end
end)

-- ============ FLY ============
local FlyBV, FlyBG
local flyConn
local function startFly()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    FlyBV = create("BodyVelocity", { MaxForce = Vector3.new(1e5,1e5,1e5), Velocity = Vector3.zero }, hrp)
    FlyBG = create("BodyGyro", { MaxTorque = Vector3.new(1e5,1e5,1e5), P = 1000, D = 50, CFrame = hrp.CFrame }, hrp)
    if flyConn then flyConn:Disconnect() end
    flyConn = Services.RunService.RenderStepped:Connect(function()
        local c = LP.Character
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local move = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
        FlyBV.Velocity = move * State.FlySpeed
        FlyBG.CFrame = Camera.CFrame
    end)
end

local function stopFly()
    if FlyBV then FlyBV:Destroy(); FlyBV = nil end
    if FlyBG then FlyBG:Destroy(); FlyBG = nil end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
end

-- ============ NOCLIP ============
local noclipConn
local function setNoclip(enabled)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if not enabled then return end
    noclipConn = Services.RunService.Stepped:Connect(function()
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

-- ============ INFINITE JUMP ============
track(Services.UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end))

-- ============ FULLBRIGHT ============
local savedLighting = nil
local function setFullbright(on)
    if on then
        if not savedLighting then
            savedLighting = {
                Ambient = Services.Lighting.Ambient,
                OutdoorAmbient = Services.Lighting.OutdoorAmbient,
                Brightness = Services.Lighting.Brightness,
                ClockTime = Services.Lighting.ClockTime,
                FogEnd = Services.Lighting.FogEnd,
                GlobalShadows = Services.Lighting.GlobalShadows,
            }
        end
        Services.Lighting.Ambient = Color3.fromRGB(200,200,200)
        Services.Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
        Services.Lighting.Brightness = 3
        Services.Lighting.ClockTime = 12
        Services.Lighting.FogEnd = 1e6
        Services.Lighting.GlobalShadows = false
    else
        if savedLighting then
            for k, v in pairs(savedLighting) do Services.Lighting[k] = v end
            savedLighting = nil
        end
    end
end

-- ============ ANTI AFK ============
track(LP.Idled:Connect(function()
    if State.AntiAFK then
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end
end))

-- ============ GOD MODE (LOCAL) ============
local godConn
local function setGodMode(on)
    if godConn then godConn:Disconnect(); godConn = nil end
    if not on then return end
    godConn = Services.RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
end

-- ============ AUTO FARM ============
local function getMap()
    for _, o in ipairs(workspace:GetChildren()) do
        if o:FindFirstChild("CoinContainer") or (o:FindFirstChild("Spawns") and o.Name == "Map") then return o end
    end
    return nil
end

local function getClosestCoin()
    local map = getMap()
    if not map then return nil end
    local cc = map:FindFirstChild("CoinContainer")
    if not cc then return nil end
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, c in ipairs(cc:GetChildren()) do
        if c:IsA("BasePart") then
            local d = (c.Position - hrp.Position).Magnitude
            if d < dist then closest = c; dist = d end
        end
    end
    return closest
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoFarm and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if State.FarmMode == "Coin" or State.FarmMode == "Nearest" then
                    local coin = getClosestCoin()
                    if coin then
                        pcall(function()
                            LP.Character:MoveTo(coin.Position)
                        end)
                    end
                end
                if State.FarmMode == "Gun" then
                    local map = getMap()
                    if map then
                        local gun = map:FindFirstChild("GunDrop")
                        if gun then
                            pcall(function() LP.Character:MoveTo(gun:GetPivot().Position) end)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto grab gun
track(workspace.DescendantAdded:Connect(function(obj)
    if State.AutoGrabGun and obj.Name == "GunDrop" and LP.Character then
        task.wait(0.1)
        pcall(function() LP.Character:MoveTo(obj:GetPivot().Position) end)
    end
end))

-- Auto end round (visual notification only, safe)
-- Skipped to avoid remote spam.

-- ============ FLING ============
local function flingPlayer(target)
    if not target or not target.Character then return end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local trgRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not trgRoot then return end

    local originalCFrame = myRoot.CFrame
    local bv = create("BodyVelocity", {
        Velocity = Vector3.new(9e7, 9e7, 9e7),
        MaxForce = Vector3.new(1e9, 1e9, 1e9),
    }, myRoot)
    myRoot.CFrame = trgRoot.CFrame
    task.wait(0.1)
    bv:Destroy()
    myRoot.CFrame = originalCFrame
end

-- ============ SETTINGS / UNLOAD ============
getgenv().AETHER_UNLOAD = function()
    if mt and oldNamecall then
        pcall(function()
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end)
    end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    fullESPClear()
    clearItemESP()
    stopFly()
    setNoclip(false)
    setFullbright(false)
    setGodMode(false)
    if ScreenGui then ScreenGui:Destroy() end
    getgenv().AETHER_LOADED = false
end

-- ============ TABS ============
local Tabs = {}
local activeTab = nil

local function setTab(name, builder)
    if activeTab == name then return end
    activeTab = name
    header.Text = name
    clearContent()
    for tname, tdata in pairs(Tabs) do
        Services.TweenService:Create(tdata.btn, TweenInfo.new(0.2), {
            BackgroundColor3 = tname == name and Config.Accent or Config.Secondary
        }):Play()
    end
    builder()
end

local function registerTab(name, builder)
    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Config.Secondary,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = Config.Text,
        Font = Config.Font,
        TextSize = 13,
    }, TabHolder)
    corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        setTab(name, builder)
    end)
    Tabs[name] = { btn = btn, builder = builder }
    return btn
end

-- ============ TAB BUILDERS ============

local function buildMain()
    addSection("Auto Farm")
    addToggle("Auto Farm", State.AutoFarm, function(v) State.AutoFarm = v end)
    addDropdown("Farm Mode", {"Nearest", "Coin", "Gun"}, State.FarmMode, function(v) State.FarmMode = v end)
    addToggle("Auto Grab Gun", State.AutoGrabGun, function(v) State.AutoGrabGun = v end)
    addSection("Round")
    addToggle("Auto End Round (visual only)", false, function(v) end)
    addButton("Teleport To Lobby", function()
        local lobby = workspace:FindFirstChild("Lobby")
        if lobby and LP.Character then
            local spawn = lobby:FindFirstChildWhichIsA("SpawnLocation")
            if spawn then LP.Character:MoveTo(spawn.Position) end
        end
    end)
    addButton("Teleport To Map", function()
        local map = getMap()
        if map and LP.Character then
            local spawns = map:FindFirstChild("Spawns")
            if spawns then
                local list = spawns:GetChildren()
                if #list > 0 then
                    LP.Character:MoveTo(list[math.random(1, #list)].Position)
                end
            end
        end
    end)
end

local function buildTarget()
    addSection("Combat")
    addToggle("Silent Aim", State.SilentAim, function(v) State.SilentAim = v end)
    addToggle("Auto Shoot Murderer", State.AutoShoot, function(v) State.AutoShoot = v end)
    addToggle("Auto Knife (Closest)", State.AutoKnife, function(v) State.AutoKnife = v end)
    addDropdown("Target Priority", {"Nearest", "Murderer", "Sheriff"}, State.TargetPriority, function(v) State.TargetPriority = v end)
    addSlider("FOV Radius", 50, 800, State.FOVRadius, function(v) State.FOVRadius = v end)
    addSlider("Kill Aura Distance", 5, 50, State.KillAuraDist, function(v) State.KillAuraDist = v end)
    addToggle("Wall Check", State.WallCheck, function(v) State.WallCheck = v end)
    addToggle("Prediction", State.Prediction, function(v) State.Prediction = v end)
    addToggle("Ping Compensation", State.PingComp, function(v) State.PingComp = v end)
    addSection("Quick Actions")
    addButton("Shoot Murderer (once)", function()
        local m = findMurderer()
        if not m then return end
        local target = m
        local char = LP.Character
        if not char then return end
        if not char:FindFirstChild("Gun") then
            local gun = LP.Backpack:FindFirstChild("Gun")
            if gun then
                pcall(function() char.Humanoid:EquipTool(gun) end)
                task.wait(0.2)
            end
        end
        local gun = char:FindFirstChild("Gun")
        if not gun then return end
        local trgHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not trgHrp then return end
        local pos = predictPosition(target) or trgHrp.Position
        safeFire(gun:FindFirstChild("Shoot"), CFrame.new(char.HumanoidRootPart.Position), CFrame.new(pos))
    end)
    addButton("Throw Knife (closest)", function()
        if not isMurderer(LP) then return end
        local target = getTarget()
        if not target then return end
        local char = LP.Character
        if not char then return end
        if not char:FindFirstChild("Knife") then
            local knife = LP.Backpack:FindFirstChild("Knife")
            if knife then
                pcall(function() char.Humanoid:EquipTool(knife) end)
                task.wait(0.2)
            end
        end
        local knife = char:FindFirstChild("Knife")
        if not knife then return end
        local trgHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not trgHrp then return end
        local pos = predictPosition(target) or trgHrp.Position
        safeFire(knife:FindFirstChild("Throw"), CFrame.new(char.HumanoidRootPart.Position), CFrame.new(pos))
    end)
end

local function buildMisc()
    addSection("Movement")
    addToggle("Fly", State.Fly, function(v) State.Fly = v; if v then startFly() else stopFly() end end)
    addSlider("Fly Speed", 10, 200, State.FlySpeed, function(v) State.FlySpeed = v end)
    addToggle("Speed", State.Speed, function(v)
        State.Speed = v
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v and State.SpeedValue or 16 end
        end
    end)
    addSlider("Walk Speed", 16, 120, State.SpeedValue, function(v)
        State.SpeedValue = v
        if State.Speed and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end)
    addToggle("Jump Power", State.JumpPower, function(v)
        State.JumpPower = v
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v and State.JumpValue or 50 end
        end
    end)
    addSlider("Jump Power Value", 50, 200, State.JumpValue, function(v)
        State.JumpValue = v
        if State.JumpPower and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end)
    addToggle("Infinite Jump", State.InfiniteJump, function(v) State.InfiniteJump = v end)
    addToggle("Noclip", State.Noclip, function(v) State.Noclip = v; setNoclip(v) end)
    addSection("Visuals")
    addToggle("Fullbright", State.Fullbright, function(v) State.Fullbright = v; setFullbright(v) end)
    addButton("FPS Boost", function()
        Services.Lighting.GlobalShadows = false
        Services.Lighting.FogEnd = 1e6
        for _, v in ipairs(Services.Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v.Enabled = false end
        end
    end)
    addSection("Utility")
    addToggle("Anti-AFK", State.AntiAFK, function(v) State.AntiAFK = v end)
    addButton("Server Hop", function()
        local servers = {}
        pcall(function()
            local req = request or http_request or syn and syn.request
            if req then
                local res = req({ Url = "https://games.roblox.com/v1/games/66654135/servers/Public?sortOrder=Asc&limit=100" })
                local data = Services.HttpService:JSONDecode(res.Body)
                for _, s in ipairs(data.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(servers, s.id)
                    end
                end
            end
        end)
        if #servers > 0 then
            pcall(function()
                Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LP)
            end)
        end
    end)
end

local function buildRoles()
    addSection("Player ESP")
    addToggle("Enable Player ESP", State.ESP.Players, function(v) State.ESP.Players = v; for _, p in ipairs(Services.Players:GetPlayers()) do refreshESP(p) end end)
    addToggle("Show Murderer", State.ESP.Murderer, function(v) State.ESP.Murderer = v end)
    addToggle("Show Sheriff", State.ESP.Sheriff, function(v) State.ESP.Sheriff = v end)
    addToggle("Show Innocent", State.ESP.Innocent, function(v) State.ESP.Innocent = v end)
    addToggle("Show Labels", State.ShowLabels, function(v) State.ShowLabels = v end)
    addSlider("ESP Transparency", 0, 1, State.ESPTransparency, function(v) State.ESPTransparency = v end)
    addSection("Item ESP")
    addToggle("Gun ESP", State.ESP.Gun, function(v) State.ESP.Gun = v; refreshItemESP() end)
    addToggle("Coin ESP", State.ESP.Coins, function(v) State.ESP.Coins = v; refreshItemESP() end)
    addToggle("Trap ESP", State.ESP.Traps, function(v) State.ESP.Traps = v; refreshItemESP() end)
    addSection("Actions")
    addButton("Clear ESP", function() fullESPClear(); clearItemESP() end)
    addButton("Copy Murderer Name", function()
        local m = findMurderer()
        if m then setclipboard(m.Name) end
    end)
    addButton("Copy Sheriff Name", function()
        local s = findSheriff()
        if s then setclipboard(s.Name) end
    end)
end

local function buildPlayer()
    addSection("Player Actions")
    addInput("Target Username", "Enter name", function(text)
        local target = Services.Players:FindFirstChild(text)
        if not target then
            for _, p in ipairs(Services.Players:GetPlayers()) do
                if p.DisplayName:lower():find(text:lower()) or p.Name:lower():find(text:lower()) then
                    target = p; break
                end
            end
        end
        if target then
            getgenv().AETHER_TARGET = target
        end
    end)
    addButton("Teleport to Target", function()
        local t = getgenv().AETHER_TARGET
        if t and t.Character and LP.Character then
            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
            if hrp then LP.Character:MoveTo(hrp.Position + Vector3.new(0, 3, 0)) end
        end
    end)
    addButton("Spectate Target", function()
        local t = getgenv().AETHER_TARGET
        if t and t.Character then
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end)
    addButton("Stop Spectating", function()
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end)
    addButton("Fling Target", function()
        local t = getgenv().AETHER_TARGET
        if t then flingPlayer(t) end
    end)
    addSection("Self")
    addToggle("God Mode (Local)", State.GodMode, function(v) State.GodMode = v; setGodMode(v) end)
end

local function buildSettings()
    addSection("Interface")
    addButton("Toggle UI (Ctrl+Y)", function()
        Main.Visible = not Main.Visible
    end)
    addSection("Info")
    addSection("Aether v" .. Config.Version)
    addButton("Unload Aether", function()
        getgenv().AETHER_UNLOAD()
    end, Color3.fromRGB(120, 20, 20))
end

registerTab("Main", buildMain)
registerTab("Target", buildTarget)
registerTab("Misc", buildMisc)
registerTab("Roles", buildRoles)
registerTab("Player", buildPlayer)
registerTab("Settings", buildSettings)

-- Keybind
track(Services.UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Y and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        Main.Visible = not Main.Visible
    end
end))

-- ESP refresh loop
track(Services.RunService.Heartbeat:Connect(function()
    if State.ESP.Players then
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LP then
                pcall(refreshESP, p)
            end
        end
    end
end))

-- Item ESP periodic refresh (every 3s)
task.spawn(function()
    while true do
        task.wait(3)
        if State.ESP.Gun or State.ESP.Coins or State.ESP.Traps then
            pcall(refreshItemESP)
        end
    end
end)

-- Character respawn handlers
track(LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    if State.Fly then stopFly(); startFly() end
    if State.Noclip then setNoclip(true) end
end))

track(Services.Players.PlayerRemoving:Connect(function(plr)
    if Highlights[plr] then Highlights[plr]:Destroy(); Highlights[plr] = nil end
    if ESPObjects[plr] then ESPObjects[plr]:Destroy(); ESPObjects[plr] = nil end
end))

-- Initial tab
setTab("Main", buildMain)

-- Notification
local notif = create("TextLabel", {
    Size = UDim2.fromOffset(300, 40),
    Position = UDim2.new(0.5, -150, 0, -50),
    BackgroundColor3 = Config.Accent,
    BorderSizePixel = 0,
    Text = "Aether v" .. Config.Version .. " loaded.",
    TextColor3 = Config.Text,
    Font = Config.Font,
    TextSize = 14,
}, ScreenGui)
corner(notif, 6)
Services.TweenService:Create(notif, TweenInfo.new(0.4), { Position = UDim2.new(0.5, -150, 0, 20) }):Play()
task.delay(4, function()
    Services.TweenService:Create(notif, TweenInfo.new(0.4), { Position = UDim2.new(0.5, -150, 0, -50) }):Play()
    task.wait(0.5)
    notif:Destroy()
end)

print("[Aether] v" .. Config.Version .. " loaded.")
