-- Zero Teleport Hub — V2.1 (Bugfix + Hardening + Persistence)
-- Features: Teleport players/games, Server Hop, Fly, Noclip, Bring/Freeze, toggles, Save/Load config, safe loops, cleanup
-- Works with common executors (Synapse / KRNL / ArceusX). Use at your own risk.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- Helper: safe get Character primary part
local function getRootCFrame(player)
    if not player or not player.Character then return nil end
    local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("PrimaryPart")
    if root and root.CFrame then return root.CFrame end
    return nil
end

-- Config / toggles
local SETTINGS = {
    Fly = false,
    Noclip = false,
    Rainbow = false,
    FlySpeed = 60,
    WalkSpeed = 16,
    JumpPower = 50,
}

-- Persistence: store JSON in CoreGui as StringValue
local function saveConfig()
    local ok, json = pcall(function() return HttpService:JSONEncode(SETTINGS) end)
    if not ok then return end
    local sv = CoreGui:FindFirstChild("ZeroHubConfig")
    if not sv then
        sv = Instance.new("StringValue")
        sv.Name = "ZeroHubConfig"
        sv.Parent = CoreGui
    end
    sv.Value = json
end

local function loadConfig()
    local sv = CoreGui:FindFirstChild("ZeroHubConfig")
    if sv and sv.Value and sv.Value ~= "" then
        local ok, data = pcall(function() return HttpService:JSONDecode(sv.Value) end)
        if ok and type(data) == "table" then
            for k,v in pairs(data) do SETTINGS[k] = v end
        end
    end
end

-- Load existing config if present
loadConfig()

-- Cleanup existing GUI
if CoreGui:FindFirstChild("ZeroHub") then
    CoreGui:FindFirstChild("ZeroHub"):Destroy()
end

-- Connections tracking for cleanup
local CONNECTIONS = {}

local function track(conn)
    if conn then table.insert(CONNECTIONS, conn) end
end

local function disconnectAll()
    for _, c in ipairs(CONNECTIONS) do
        pcall(function() c:Disconnect() end)
    end
    CONNECTIONS = {}
end

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ZeroHub"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 420, 0, 420)
frame.Position = UDim2.new(0.5, -210, 0.5, -210)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,44)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "🚀 ZeroHub V2.1 — Fixed & Hardened"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)

local tabHolder = Instance.new("Frame", frame)
tabHolder.Size = UDim2.new(1,0,0,36)
tabHolder.Position = UDim2.new(0,0,0,44)
tabHolder.BackgroundTransparency = 1

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, -16, 1, -104)
content.Position = UDim2.new(0,8,0,92)
content.BackgroundColor3 = Color3.fromRGB(14,14,14)
Instance.new("UICorner", content).CornerRadius = UDim.new(0,8)

local scroll = Instance.new("ScrollingFrame", content)
scroll.Size = UDim2.new(1, -12, 1, -12)
scroll.Position = UDim2.new(0,6,0,6)
scroll.CanvasSize = UDim2.new(0,0,3,0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1

local tabs = {"Players","Games","Tools","Visuals","Admin","Settings"}
local tabButtons = {}

for i,name in ipairs(tabs) do
    local btn = Instance.new("TextButton", tabHolder)
    btn.Size = UDim2.new(0, 70, 1, 0)
    btn.Position = UDim2.new(0, (i-1)*70, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    tabButtons[name] = btn
end

local function clearScroll()
    for _, child in ipairs(scroll:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

-- Utility to add a button
local function addButton(text, callback)
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.Position = UDim2.new(0,6,0, (#scroll:GetChildren()-1) * 40)
    btn.BackgroundColor3 = Color3.fromRGB(36,36,36)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(245,245,245)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return btn
end

-- Players tab
local function loadPlayers()
    clearScroll()
    local y = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local lbl = Instance.new("TextLabel", scroll)
            lbl.Size = UDim2.new(1, -12, 0, 30)
            lbl.Position = UDim2.new(0,6,0,y)
            lbl.BackgroundTransparency = 1
            lbl.Text = p.Name
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(230,230,230)

            local tpBtn = Instance.new("TextButton", scroll)
            tpBtn.Size = UDim2.new(0, 120, 0, 28)
            tpBtn.Position = UDim2.new(1, -126, 0, y)
            tpBtn.AnchorPoint = Vector2.new(1,0)
            tpBtn.Text = "Teleport"
            tpBtn.Font = Enum.Font.Gotham
            tpBtn.TextSize = 12
            tpBtn.BackgroundColor3 = Color3.fromRGB(42,42,42)
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0,6)
            tpBtn.MouseButton1Click:Connect(function()
                local ok, cf = pcall(getRootCFrame, p)
                if ok and cf and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                    -- safe teleport via CFrame set
                    pcall(function()
                        LocalPlayer.Character:SetPrimaryPartCFrame(cf + Vector3.new(0,3,0))
                    end)
                else
                    -- fallback: notify
                    warn("Failed to teleport to", p.Name)
                end
            end)
            y = y + 36
        end
    end
    addButton("🔁 Refresh Players", loadPlayers)
end

-- Games tab (join known places + server hop)
local knownGames = {
    {"Brookhaven 🏡", 4924922222},
    {"Blox Fruits 🍇", 2753915549},
    {"Arsenal 🔫", 286090429},
    {"Doors 🚪", 6516141723},
}

local function joinPlace(placeId)
    if not placeId then return end
    local success, err = pcall(function()
        TeleportService:Teleport(tonumber(placeId), LocalPlayer)
    end)
    if not success then warn("Teleport failed:", err) end
end

local function serverHop(placeId)
    -- NOTE: requires HttpGet; robust pcall and fallback
    if not placeId then return end
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res then warn("Server hop http failed") return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data or not data.data then warn("Server hop decode failed") return end
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers and server.id then
            local sOk, sErr = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
            end)
            if sOk then return end
            warn("TeleportToPlaceInstance failed:", sErr)
        end
    end
    warn("No suitable server found or teleports failed.")
end

local function loadGames()
    clearScroll()
    for _, g in ipairs(knownGames) do
        local name, id = g[1], g[2]
        addButton("Join " .. name, function() joinPlace(id) end)
    end
    addButton("🌐 Server Hop Current Place", function()
        -- attempt server hop for current placeId
        pcall(function() serverHop(game.PlaceId) end)
    end)
end

-- Tools tab: Fly, Noclip, Speed, Jump, Reset
local flyLoop
local noclipConn
local function startFly()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    SETTINGS.Fly = true
    saveConfig()
    if flyLoop and flyLoop.running then return end

    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Parent = root

    flyLoop = { running = true }
    spawn(function()
        while SETTINGS.Fly and flyLoop.running and root.Parent do
            local cam = workspace.CurrentCamera
            local forward = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end

            local velocity = moveDir.Unit * (SETTINGS.FlySpeed or 50)
            if moveDir.Magnitude == 0 then
                bv.Velocity = Vector3.new(0,0,0)
            else
                bv.Velocity = Vector3.new(velocity.X, velocity.Y, velocity.Z)
            end
            RunService.Heartbeat:Wait()
        end
        -- cleanup
        pcall(function() bv:Destroy() end)
        flyLoop.running = false
        SETTINGS.Fly = false
        saveConfig()
    end)
end

local function stopFly()
    SETTINGS.Fly = false
    flyLoop.running = false
    saveConfig()
end

local function startNoclip()
    SETTINGS.Noclip = true
    saveConfig()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                end
            end
        end
    end)
    track(noclipConn)
end

local function stopNoclip()
    SETTINGS.Noclip = false
    saveConfig()
    if noclipConn then
        pcall(function() noclipConn:Disconnect() end)
        noclipConn = nil
    end
    -- attempt to restore CanCollide to true for character parts (best-effort)
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
end

-- Visuals
local rainbowCoroutine
local function startRainbow()
    if rainbowCoroutine then return end
    SETTINGS.Rainbow = true
    saveConfig()
    rainbowCoroutine = coroutine.create(function()
        while SETTINGS.Rainbow do
            for i = 0, 1, 0.02 do
                if not SETTINGS.Rainbow then break end
                local color = Color3.fromHSV(i, 1, 1)
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Parent then
                        pcall(function()
                            -- body colors may not exist; set Head or use HumanoidRootPart color change as fallback
                            local head = LocalPlayer.Character:FindFirstChild("Head")
                            if head and head:IsA("BasePart") then head.Color = color end
                        end)
                    end
                end
                RunService.RenderStepped:Wait()
            end
            -- small wait to avoid tight loop
            wait(0.05)
        end
        rainbowCoroutine = nil
    end)
    coroutine.resume(rainbowCoroutine)
end

local function stopRainbow()
    SETTINGS.Rainbow = false
    saveConfig()
end

-- Admin tools: Bring / Freeze / Unfreeze / Explode visual
local function bringAll()
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    local base = LocalPlayer.Character.PrimaryPart.CFrame
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.PrimaryPart then
            pcall(function()
                p.Character:SetPrimaryPartCFrame(base + Vector3.new(math.random(-6,6),0,math.random(-6,6)))
            end)
        end
    end
end

local frozenPlayers = {}
local function freezeAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.PrimaryPart then
            pcall(function()
                local root = p.Character.PrimaryPart
                root.Anchored = true
                frozenPlayers[p.UserId] = root
            end)
        end
    end
end

local function unfreezeAll()
    for userId, root in pairs(frozenPlayers) do
        pcall(function() if root and root.Parent then root.Anchored = false end end)
        frozenPlayers[userId] = nil
    end
end

local function visualExplodeAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character.PrimaryPart then
            pcall(function()
                local ex = Instance.new("Explosion")
                ex.Position = p.Character.PrimaryPart.Position
                ex.Parent = workspace
                -- cleanup shortly after
                game:GetService("Debris"):AddItem(ex, 2)
            end)
        end
    end
end

-- Settings UI loader
local function loadSettingsUI()
    clearScroll()
    addButton("Save Config", function() saveConfig() end)
    addButton("Load Config", function() loadConfig() end)
    addButton("Close & Cleanup", function()
        -- stop toggles and disconnect
        stopFly()
        stopNoclip()
        stopRainbow()
        unfreezeAll()
        disconnectAll()
        pcall(function() gui:Destroy() end)
    end)
end

-- Load tabs binding
local tabLoaders = {
    Players = loadPlayers,
    Games = loadGames,
    Tools = function()
        clearScroll()
        addButton("Toggle Fly (F to move, LeftCtrl descend, Space ascend)", function()
            if SETTINGS.Fly then stopFly() else startFly() end
        end)
        addButton("Toggle Noclip", function()
            if SETTINGS.Noclip then stopNoclip() else startNoclip() end
        end)
        addButton("Set Fly Speed to 60 (default)", function() SETTINGS.FlySpeed = 60; saveConfig() end)
        addButton("Set WalkSpeed to 66 (fast)", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 66
            end
            SETTINGS.WalkSpeed = 66; saveConfig()
        end)
        addButton("Reset WalkSpeed/JumpPower to defaults", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = (SETTINGS.WalkSpeed or 16)
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = (SETTINGS.JumpPower or 50)
            end
            SETTINGS.WalkSpeed = 16; SETTINGS.JumpPower = 50; saveConfig()
        end)
    end,
    Visuals = function()
        clearScroll()
        addButton("Toggle Rainbow Effect", function()
            if SETTINGS.Rainbow then stopRainbow() else startRainbow() end
        end)
        addButton("Fullbright (soft)", function()
            local lighting = game:GetService("Lighting")
            pcall(function()
                lighting.Brightness = 2
                lighting.ClockTime = 14
                lighting.FogEnd = 1e6
            end)
        end)
    end,
    Admin = function()
        clearScroll()
        addButton("Bring All Players", bringAll)
        addButton("Freeze All Players", freezeAll)
        addButton("Unfreeze All Players", unfreezeAll)
        addButton("Visual Explode All", visualExplodeAll)
    end,
    Settings = loadSettingsUI,
}

-- Tab button bindings
for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for _,b in pairs(tabButtons) do pcall(function() b.BackgroundColor3 = Color3.fromRGB(30,30,30) end) end
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        local loader = tabLoaders[name]
        if loader then pcall(loader) end
    end)
end

-- Default tab
tabButtons["Players"].BackgroundColor3 = Color3.fromRGB(60,60,60)
loadPlayers()

-- Keybind: close on RightShift, toggle Fly with F (only when running)
track(UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if gameProcessed then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        -- toggle gui visibility
        gui.Enabled = not gui.Enabled
    elseif inp.KeyCode == Enum.KeyCode.F and SETTINGS.Fly then
        -- handled by fly system (movement)
    end
end))

-- Ensure character changes reapply default speeds & re-run noclip if active
track(Players.LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.WalkSpeed = SETTINGS.WalkSpeed or 16; hum.JumpPower = SETTINGS.JumpPower or 50 end)
    end
    if SETTINGS.Noclip then startNoclip() end
end))

-- Finalize: save config on script end
saveConfig()

print("✅ ZeroHub V2.1 loaded — bugfixes & improvements applied.")


