--// 🌀 Roblox Teleport + Player Hub UI
--// ⚙️ By Zero | Updated Version — No Errors / Smooth UI / Extra Features

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportHubUI"
ScreenGui.Parent = game.CoreGui

-- Create Main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 320)
Frame.Position = UDim2.new(0.5, -160, 0.5, -160)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- Rounded Corners
local Corner = Instance.new("UICorner", Frame)
Corner.CornerRadius = UDim.new(0, 10)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🌍 Teleport Hub — by Zero"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

-- Tabs
local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(1, 0, 0, 30)
TabHolder.Position = UDim2.new(0, 0, 0, 40)
TabHolder.BackgroundTransparency = 1
TabHolder.Parent = Frame

local Tabs = {"Players", "Games", "Extras"}
local CurrentTab = "Players"

local Buttons = {}

for i, name in ipairs(Tabs) do
	local TabButton = Instance.new("TextButton")
	TabButton.Size = UDim2.new(0, 100, 1, 0)
	TabButton.Position = UDim2.new(0, (i - 1) * 100, 0, 0)
	TabButton.Text = name
	TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	TabButton.Font = Enum.Font.Gotham
	TabButton.TextSize = 14
	TabButton.Parent = TabHolder
	Buttons[name] = TabButton
end

-- Content Frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -70)
Content.Position = UDim2.new(0, 0, 0, 70)
Content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Content.Parent = Frame

local UICorner = Instance.new("UICorner", Content)
UICorner.CornerRadius = UDim.new(0, 8)

-- Scrolling Frame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -10)
Scroll.Position = UDim2.new(0, 5, 0, 5)
Scroll.CanvasSize = UDim2.new(0, 0, 2, 0)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 5
Scroll.Parent = Content

-- Function: Refresh Players
local function RefreshPlayers()
	Scroll:ClearAllChildren()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, -10, 0, 30)
			Btn.Position = UDim2.new(0, 5, 0, (#Scroll:GetChildren() - 1) * 35)
			Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			Btn.Text = "Teleport to " .. plr.Name
			Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			Btn.Font = Enum.Font.Gotham
			Btn.TextSize = 14
			Btn.Parent = Scroll

			local corner = Instance.new("UICorner", Btn)
			corner.CornerRadius = UDim.new(0, 6)

			Btn.MouseButton1Click:Connect(function()
				LocalPlayer.Character:SetPrimaryPartCFrame(plr.Character.PrimaryPart.CFrame + Vector3.new(0, 3, 0))
			end)
		end
	end
end

-- Function: Games List
local GameList = {
	{ Name = "Brookhaven 🏡", ID = 4924922222 },
	{ Name = "Blox Fruits 🍇", ID = 2753915549 },
	{ Name = "Tower of Hell 🗼", ID = 1962086868 },
	{ Name = "Adopt Me 🐶", ID = 920587237 },
	{ Name = "Arsenal 🔫", ID = 286090429 },
}

local function ShowGames()
	Scroll:ClearAllChildren()
	for i, game in ipairs(GameList) do
		local Btn = Instance.new("TextButton")
		Btn.Size = UDim2.new(1, -10, 0, 35)
		Btn.Position = UDim2.new(0, 5, 0, (i - 1) * 40)
		Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		Btn.Text = "Join " .. game.Name
		Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		Btn.Font = Enum.Font.Gotham
		Btn.TextSize = 14
		Btn.Parent = Scroll

		local corner = Instance.new("UICorner", Btn)
		corner.CornerRadius = UDim.new(0, 6)

		Btn.MouseButton1Click:Connect(function()
			TeleportService:Teleport(game.ID, LocalPlayer)
		end)
	end
end

-- Function: Extras
local function ShowExtras()
	Scroll:ClearAllChildren()
	local ExtraBtns = {
		{Text = "💨 Speed Boost", Action = function()
			if LocalPlayer.Character then
				LocalPlayer.Character.Humanoid.WalkSpeed = 50
			end
		end},
		{Text = "🚀 Jump Boost", Action = function()
			if LocalPlayer.Character then
				LocalPlayer.Character.Humanoid.JumpPower = 120
			end
		end},
		{Text = "🔄 Reset Character", Action = function()
			LocalPlayer:LoadCharacter()
		end},
	}

	for i, ex in ipairs(ExtraBtns) do
		local Btn = Instance.new("TextButton")
		Btn.Size = UDim2.new(1, -10, 0, 35)
		Btn.Position = UDim2.new(0, 5, 0, (i - 1) * 40)
		Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		Btn.Text = ex.Text
		Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		Btn.Font = Enum.Font.Gotham
		Btn.TextSize = 14
		Btn.Parent = Scroll

		local corner = Instance.new("UICorner", Btn)
		corner.CornerRadius = UDim.new(0, 6)

		Btn.MouseButton1Click:Connect(ex.Action)
	end
end

-- Switch Tabs
for name, btn in pairs(Buttons) do
	btn.MouseButton1Click:Connect(function()
		for _, b in pairs(Buttons) do
			b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		end
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		CurrentTab = name

		if name == "Players" then
			RefreshPlayers()
		elseif name == "Games" then
			ShowGames()
		elseif name == "Extras" then
			ShowExtras()
		end
	end)
end

-- Default Tab
Buttons["Players"].BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RefreshPlayers()

print("✅ Teleport Hub UI loaded successfully!")
