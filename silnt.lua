-- Roblox Silent Aim / ESP / Speed / Teleport Script (Fixed)

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Wait for LocalPlayer
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- Wait for PlayerGui
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("Failed to find PlayerGui")
    return
end

-- Show notification
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Script Loaded",
        Text = "GUI Loaded! Press RightShift to toggle",
        Duration = 5
    })
end)

-- Get GunHandler module and hook aim function
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunHandler = require(ReplicatedStorage.Modules.GunHandler)
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Settings
local AimTarget = "Head"
local OriginalGetAim = GunHandler.getAim
_G.FOV_RADIUS = 1000
_G.RevolverBypass = false
_G.WallCheck = false
_G.ESP_Boxes = false
_G.ESP_Names = false
_G.ESP_Color = Color3.fromRGB(255, 153, 170)
_G.Speed_Enabled = false
_G.Speed_Value = 50
_G.Speed_Key = Enum.KeyCode.X
_G.Speed_ToggleEnabled = false

local OriginalWalkSpeed = 16
local LastSpeedEnabled = false

-- Bullet spread manipulation
local BulletSpread = {
    Enabled = true,
    Amount = 100
}

-- MacSploit compatible hook - use the return value of hookfunction as the original
local OriginalRandom = nil

-- Define the hook function first
local function HookedRandom(...)
    local args = {...}
    
    -- Check if this is being called from the game (not our script)
    if not checkcaller() then
        -- Check for spread patterns (-0.05 to 0.05 is typical recoil/spread)
        if #args == 2 and args[1] == -0.05 and args[2] == 0.05 then
            if BulletSpread.Enabled then
                -- Use OriginalRandom which is set below
                local result = OriginalRandom(args[1], args[2])
                return result * (BulletSpread.Amount / 100)
            end
        end
    end
    
    -- Call the original
    return OriginalRandom(...)
end

-- Apply hook and capture the REAL original
OriginalRandom = hookfunction(math.random, HookedRandom)

-- Get target part from character
local function GetTargetPart(character)
    local closestPart = nil
    local closestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    local targetNames = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"}
    
    for _, name in pairs(targetNames) do
        local part = character:FindFirstChild(name)
        if part then
            local pos, onScreen = Camera:WorldToScreenPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPart = part
                end
            end
        end
    end
    
    return closestPart or character:FindFirstChild("HumanoidRootPart")
end

-- Silent Aim target acquisition
local function GetSilentAimTarget()
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local target = nil
    local closestDist = _G.FOV_RADIUS
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart
            
            if AimTarget == "Head" then
                targetPart = GetTargetPart(player.Character)
            elseif AimTarget == "Torso" then
                targetPart = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
            elseif AimTarget == "HumanoidRootPart" then
                targetPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
            elseif AimTarget == "LeftArm" then
                targetPart = player.Character:FindFirstChild("LeftUpperArm") or player.Character:FindFirstChild("Left Arm")
            elseif AimTarget == "RightArm" then
                targetPart = player.Character:FindFirstChild("RightUpperArm") or player.Character:FindFirstChild("Right Arm")
            elseif AimTarget == "LeftLeg" then
                targetPart = player.Character:FindFirstChild("LeftUpperLeg") or player.Character:FindFirstChild("Left Leg")
            elseif AimTarget == "RightLeg" then
                targetPart = player.Character:FindFirstChild("RightUpperLeg") or player.Character:FindFirstChild("Right Leg")
            else
                targetPart = player.Character:FindFirstChild("Head")
            end
            
            if targetPart then
                local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
if dist < closestDist then
                        if _G.WallCheck then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                            
                            local direction = (targetPart.Position - Camera.CFrame.Position).Unit * 500
                            local result = workspace:Raycast(Camera.CFrame.Position, direction, raycastParams)
                            
                            if result and result.Instance then
                                if result.Instance:IsDescendantOf(player.Character) then
                                    closestDist = dist
                                    target = targetPart
                                end
                            end
                        else
                            closestDist = dist
                            target = targetPart
                        end
                    end
                end
            end
        end
    end
    
    return target
end

-- Hook getAim for silent aim
GunHandler.getAim = function(origin, maxDist)
    if _G.RevolverBypass then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and (tool.Name == "Revolver" or tool.Name == "Gun") then
            return OriginalGetAim(origin, maxDist)
        end
    end
    
    local target = GetSilentAimTarget()
    if target then
        local direction = (target.Position - origin).Unit
        local distance = (target.Position - origin).Magnitude
        return direction, math.min(distance, maxDist or 200)
    end
    
    return OriginalGetAim(origin, maxDist)
end

-- GUI Setup - PARENT TO PlayerGui NOT StarterGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SilentAimGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Safer parenting with fallback
local success = pcall(function()
    ScreenGui.Parent = PlayerGui
end)

if not success then
    warn("Failed to parent GUI to PlayerGui, trying CoreGui...")
    ScreenGui.Parent = game:GetService("CoreGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 240, 243)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true -- Ensure visible
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

-- Draggable functionality
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)

local DragHandle = Instance.new("Frame")
DragHandle.Name = "DragHandle"
DragHandle.Size = UDim2.new(0, 20, 1, 0)
DragHandle.Position = UDim2.new(1, -20, 0, 0)
DragHandle.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
DragHandle.BorderSizePixel = 0
DragHandle.Parent = Sidebar

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 20)
Title.Text = "Silent Aim"
Title.TextColor3 = Color3.fromRGB(214, 115, 131)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Sidebar

-- Welcome text
local WelcomeText = Instance.new("TextLabel")
WelcomeText.Name = "WelcomeText"
WelcomeText.Size = UDim2.new(0, 300, 0, 40)
WelcomeText.Position = UDim2.new(0, 185, 0, 20)
WelcomeText.Text = "Welcome, " .. LocalPlayer.Name
WelcomeText.TextColor3 = Color3.fromRGB(186, 92, 107)
WelcomeText.TextSize = 24
WelcomeText.Font = Enum.Font.GothamBold
WelcomeText.BackgroundTransparency = 1
WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
WelcomeText.Parent = MainFrame

-- Content container
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(0, 375, 0, 285)
Content.Position = UDim2.new(0, 185, 0, 75)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Tab pages
local Pages = {
    SilentAim = Instance.new("Frame"),
    ESP = Instance.new("Frame"),
    Speed = Instance.new("Frame"),
    Teleport = Instance.new("Frame")
}

for name, page in pairs(Pages) do
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundColor3 = Color3.fromRGB(255, 245, 251)
    page.BorderSizePixel = 0
    page.Visible = (name == "SilentAim")
    page.Parent = Content
    Instance.new("UICorner", page).CornerRadius = UDim.new(0, 12)
end

-- Tab buttons
local TabButtons = {}
local TabNames = {"Silent Aim", "ESP", "Speed", "Teleport"}
local TabKeys = {"SilentAim", "ESP", "Speed", "Teleport"}

local function SwitchTab(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for key, button in pairs(TabButtons) do
        if key == tabName then
            button.BackgroundColor3 = Color3.fromRGB(255, 200, 213)
            button.TextColor3 = Color3.fromRGB(214, 115, 131)
        else
            button.BackgroundColor3 = Color3.fromRGB(255, 230, 235)
            button.TextColor3 = Color3.fromRGB(230, 165, 178)
        end
    end
end

for i, name in ipairs(TabNames) do
    local key = TabKeys[i]
    local button = Instance.new("TextButton")
    button.Name = key .. "Tab"
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.new(0, 10, 0, 75 + ((i-1) * 42))
    button.Text = "  " .. name
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.BackgroundColor3 = Color3.fromRGB(255, 230, 235)
    button.TextColor3 = Color3.fromRGB(230, 165, 178)
    button.Parent = Sidebar
    
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    TabButtons[key] = button
    
    button.MouseButton1Click:Connect(function()
        SwitchTab(key)
    end)
end

SwitchTab("SilentAim")

-- Helper function for section headers
local function CreateSection(parent, text)
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, -30, 0, 30)
    header.Position = UDim2.new(0, 15, 0, 10)
    header.Text = text
    header.TextColor3 = Color3.fromRGB(255, 115, 131)
    header.TextSize = 15
    header.Font = Enum.Font.GothamBold
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = parent
    
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(1, -30, 0, 1)
    underline.Position = UDim2.new(0, 15, 0, 40)
    underline.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
    underline.BorderSizePixel = 0
    underline.Parent = parent
    
    Instance.new("UICorner", underline).CornerRadius = UDim.new(1, 0)
end

-- Silent Aim Page
CreateSection(Pages.SilentAim, "Silent Aim Configuration")

local Desc = Instance.new("TextLabel")
Desc.Name = "Description"
Desc.Size = UDim2.new(1, -30, 0, 50)
Desc.Position = UDim2.new(0, 15, 0, 55)
Desc.Text = "Configure silent aim settings for automatic targeting"
Desc.TextColor3 = Color3.fromRGB(214, 115, 131)
Desc.TextSize = 14
Desc.Font = Enum.Font.Gotham
Desc.BackgroundTransparency = 1
Desc.TextXAlignment = Enum.TextXAlignment.Left
Desc.Parent = Pages.SilentAim

-- Revolver Bypass Toggle
local RevolverBtn = Instance.new("TextButton")
RevolverBtn.Name = "RevolverBtn"
RevolverBtn.Size = UDim2.new(0, 50, 0, 22)
RevolverBtn.Position = UDim2.new(1, -65, 0, 59)
RevolverBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
RevolverBtn.Text = "OFF"
RevolverBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RevolverBtn.Font = Enum.Font.GothamBold
RevolverBtn.TextSize = 11
RevolverBtn.Parent = Pages.SilentAim

Instance.new("UICorner", RevolverBtn).CornerRadius = UDim.new(0, 6)

RevolverBtn.MouseButton1Click:Connect(function()
    _G.RevolverBypass = not _G.RevolverBypass
    if _G.RevolverBypass then
        RevolverBtn.Text = "ON"
        RevolverBtn.BackgroundColor3 = Color3.fromRGB(255, 153, 170)
    else
        RevolverBtn.Text = "OFF"
        RevolverBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
    end
end)

-- Wall Check Toggle
local WallCheckLabel = Instance.new("TextLabel")
WallCheckLabel.Name = "WallCheckLabel"
WallCheckLabel.Size = UDim2.new(0, 150, 0, 30)
WallCheckLabel.Position = UDim2.new(0, 15, 0, 95)
WallCheckLabel.Text = "Wall Check"
WallCheckLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
WallCheckLabel.TextSize = 13
WallCheckLabel.Font = Enum.Font.Gotham
WallCheckLabel.BackgroundTransparency = 1
WallCheckLabel.TextXAlignment = Enum.TextXAlignment.Left
WallCheckLabel.Parent = Pages.SilentAim

local WallCheckBtn = Instance.new("TextButton")
WallCheckBtn.Name = "WallCheckBtn"
WallCheckBtn.Size = UDim2.new(0, 50, 0, 22)
WallCheckBtn.Position = UDim2.new(1, -65, 0, 99)
WallCheckBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
WallCheckBtn.Text = "OFF"
WallCheckBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WallCheckBtn.Font = Enum.Font.GothamBold
WallCheckBtn.TextSize = 11
WallCheckBtn.Parent = Pages.SilentAim

Instance.new("UICorner", WallCheckBtn).CornerRadius = UDim.new(0, 6)

WallCheckBtn.MouseButton1Click:Connect(function()
    _G.WallCheck = not _G.WallCheck
    if _G.WallCheck then
        WallCheckBtn.Text = "ON"
        WallCheckBtn.BackgroundColor3 = Color3.fromRGB(255, 153, 170)
    else
        WallCheckBtn.Text = "OFF"
        WallCheckBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
    end
end)

-- FOV Slider
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Name = "FOVLabel"
FOVLabel.Size = UDim2.new(1, -30, 0, 20)
FOVLabel.Position = UDim2.new(0, 15, 0, 135)
FOVLabel.Text = "FOV Radius: 1000"
FOVLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
FOVLabel.TextSize = 13
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Parent = Pages.SilentAim

local FOVSlider = Instance.new("Frame")
FOVSlider.Name = "FOVSlider"
FOVSlider.Size = UDim2.new(1, -30, 0, 6)
FOVSlider.Position = UDim2.new(0, 15, 0, 165)
FOVSlider.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
FOVSlider.BorderSizePixel = 0
FOVSlider.Parent = Pages.SilentAim

Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(1, 0)

local FOVHandle = Instance.new("TextButton")
FOVHandle.Name = "FOVHandle"
FOVHandle.Size = UDim2.new(0, 14, 0, 14)
FOVHandle.Position = UDim2.new(1, -7, 0.5, -7) -- 1000/1000 = 1
FOVHandle.BackgroundColor3 = Color3.fromRGB(255, 153, 170)
FOVHandle.BorderSizePixel = 0
FOVHandle.Text = ""
FOVHandle.Parent = FOVSlider

Instance.new("UICorner", FOVHandle).CornerRadius = UDim.new(1, 0)

-- Bullet Spread Slider
local SpreadLabel = Instance.new("TextLabel")
SpreadLabel.Name = "SpreadLabel"
SpreadLabel.Size = UDim2.new(1, -30, 0, 20)
SpreadLabel.Position = UDim2.new(0, 15, 0, 185)
SpreadLabel.Text = "Bullet Spread: 100"
SpreadLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
SpreadLabel.TextSize = 13
SpreadLabel.Font = Enum.Font.Gotham
SpreadLabel.BackgroundTransparency = 1
SpreadLabel.TextXAlignment = Enum.TextXAlignment.Left
SpreadLabel.Parent = Pages.SilentAim

local SpreadSlider = Instance.new("Frame")
SpreadSlider.Name = "SpreadSlider"
SpreadSlider.Size = UDim2.new(1, -30, 0, 6)
SpreadSlider.Position = UDim2.new(0, 15, 0, 215)
SpreadSlider.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
SpreadSlider.BorderSizePixel = 0
SpreadSlider.Parent = Pages.SilentAim

Instance.new("UICorner", SpreadSlider).CornerRadius = UDim.new(1, 0)

local SpreadHandle = Instance.new("TextButton")
SpreadHandle.Name = "SpreadHandle"
SpreadHandle.Size = UDim2.new(0, 14, 0, 14)
SpreadHandle.Position = UDim2.new(1, -7, 0.5, -7) -- 100/100 = 1
SpreadHandle.BackgroundColor3 = Color3.fromRGB(255, 153, 170)
SpreadHandle.BorderSizePixel = 0
SpreadHandle.Text = ""
SpreadHandle.Parent = SpreadSlider

Instance.new("UICorner", SpreadHandle).CornerRadius = UDim.new(1, 0)

-- Target Selection
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "TargetLabel"
TargetLabel.Size = UDim2.new(0, 150, 0, 20)
TargetLabel.Position = UDim2.new(0, 15, 0, 240)
TargetLabel.Text = "Target Part: Head"
TargetLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
TargetLabel.TextSize = 13
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.BackgroundTransparency = 1
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Pages.SilentAim

local TargetDropdown = Instance.new("TextButton")
TargetDropdown.Name = "TargetDropdown"
TargetDropdown.Size = UDim2.new(0, 130, 0, 26)
TargetDropdown.Position = UDim2.new(1, -145, 0, 238)
TargetDropdown.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
TargetDropdown.Text = "Head ▼"
TargetDropdown.TextColor3 = Color3.fromRGB(186, 92, 107)
TargetDropdown.Font = Enum.Font.GothamBold
TargetDropdown.TextSize = 12
TargetDropdown.ZIndex = 5
TargetDropdown.Parent = Pages.SilentAim

Instance.new("UICorner", TargetDropdown).CornerRadius = UDim.new(0, 6)

local TargetList = Instance.new("ScrollingFrame")
TargetList.Name = "TargetList"
TargetList.Size = UDim2.new(0, 130, 0, 100)
TargetList.Position = UDim2.new(1, -145, 0, 268)
TargetList.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
TargetList.BorderSizePixel = 0
TargetList.Visible = false
TargetList.ZIndex = 6
TargetList.CanvasSize = UDim2.new(0, 0, 0, 215)
TargetList.ScrollBarThickness = 3
TargetList.Parent = Pages.SilentAim

Instance.new("UICorner", TargetList).CornerRadius = UDim.new(0, 6)

local TargetOptions = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}

for i, option in ipairs(TargetOptions) do
    local btn = Instance.new("TextButton")
    btn.Name = option .. "Btn"
    btn.Size = UDim2.new(1, -8, 0, 26)
    btn.Position = UDim2.new(0, 4, 0, ((i-1) * 28) + 4)
    btn.BackgroundColor3 = Color3.fromRGB(255, 240, 251)
    btn.Text = option
    btn.TextColor3 = Color3.fromRGB(186, 92, 107)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.ZIndex = 7
    btn.Parent = TargetList
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        AimTarget = option
        TargetDropdown.Text = option .. " ▼"
        TargetList.Visible = false
    end)
end

TargetDropdown.MouseButton1Click:Connect(function()
    TargetList.Visible = not TargetList.Visible
end)

-- ESP Page
CreateSection(Pages.ESP, "ESP Configuration")

local ESPBoxesLabel = Instance.new("TextLabel")
ESPBoxesLabel.Name = "ESPBoxesLabel"
ESPBoxesLabel.Size = UDim2.new(0, 150, 0, 30)
ESPBoxesLabel.Position = UDim2.new(0, 15, 0, 55)
ESPBoxesLabel.Text = "Show Boxes"
ESPBoxesLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
ESPBoxesLabel.TextSize = 13
ESPBoxesLabel.Font = Enum.Font.Gotham
ESPBoxesLabel.BackgroundTransparency = 1
ESPBoxesLabel.TextXAlignment = Enum.TextXAlignment.Left
ESPBoxesLabel.Parent = Pages.ESP

local ESPBoxesBtn = Instance.new("TextButton")
ESPBoxesBtn.Name = "ESPBoxesBtn"
ESPBoxesBtn.Size = UDim2.new(0, 50, 0, 22)
ESPBoxesBtn.Position = UDim2.new(1, -65, 0, 59)
ESPBoxesBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
ESPBoxesBtn.Text = "OFF"
ESPBoxesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPBoxesBtn.Font = Enum.Font.GothamBold
ESPBoxesBtn.TextSize = 11
ESPBoxesBtn.Parent = Pages.ESP

Instance.new("UICorner", ESPBoxesBtn).CornerRadius = UDim.new(0, 6)

ESPBoxesBtn.MouseButton1Click:Connect(function()
    _G.ESP_Boxes = not _G.ESP_Boxes
    ESPBoxesBtn.Text = (_G.ESP_Boxes and "ON") or "OFF"
    ESPBoxesBtn.BackgroundColor3 = (_G.ESP_Boxes and Color3.fromRGB(255, 153, 170)) or Color3.fromRGB(235, 230, 232)
end)

local ESPNamesLabel = Instance.new("TextLabel")
ESPNamesLabel.Name = "ESPNamesLabel"
ESPNamesLabel.Size = UDim2.new(0, 150, 0, 30)
ESPNamesLabel.Position = UDim2.new(0, 15, 0, 95)
ESPNamesLabel.Text = "Show Names"
ESPNamesLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
ESPNamesLabel.TextSize = 13
ESPNamesLabel.Font = Enum.Font.Gotham
ESPNamesLabel.BackgroundTransparency = 1
ESPNamesLabel.TextXAlignment = Enum.TextXAlignment.Left
ESPNamesLabel.Parent = Pages.ESP

local ESPNamesBtn = Instance.new("TextButton")
ESPNamesBtn.Name = "ESPNamesBtn"
ESPNamesBtn.Size = UDim2.new(0, 50, 0, 22)
ESPNamesBtn.Position = UDim2.new(1, -65, 0, 99)
ESPNamesBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
ESPNamesBtn.Text = "OFF"
ESPNamesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPNamesBtn.Font = Enum.Font.GothamBold
ESPNamesBtn.TextSize = 11
ESPNamesBtn.Parent = Pages.ESP

Instance.new("UICorner", ESPNamesBtn).CornerRadius = UDim.new(0, 6)

ESPNamesBtn.MouseButton1Click:Connect(function()
    _G.ESP_Names = not _G.ESP_Names
    ESPNamesBtn.Text = (_G.ESP_Names and "ON") or "OFF"
    ESPNamesBtn.BackgroundColor3 = (_G.ESP_Names and Color3.fromRGB(255, 153, 170)) or Color3.fromRGB(235, 230, 232)
end)

local ESPColorLabel = Instance.new("TextLabel")
ESPColorLabel.Name = "ESPColorLabel"
ESPColorLabel.Size = UDim2.new(1, -30, 0, 20)
ESPColorLabel.Position = UDim2.new(0, 15, 0, 135)
ESPColorLabel.Text = "ESP Color"
ESPColorLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
ESPColorLabel.TextSize = 13
ESPColorLabel.Font = Enum.Font.Gotham
ESPColorLabel.BackgroundTransparency = 1
ESPColorLabel.TextXAlignment = Enum.TextXAlignment.Left
ESPColorLabel.Parent = Pages.ESP

local Colors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(0, 220, 255),
    Color3.fromRGB(255, 0, 255),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 170, 0),
    Color3.fromRGB(170, 0, 255),
    Color3.fromRGB(255, 255, 255)
}

for i, color in ipairs(Colors) do
    local btn = Instance.new("TextButton")
    btn.Name = "ColorBtn" .. i
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.Position = UDim2.new(0, 15 + (((i-1) % 5) * 34), 0, 160 + (math.floor((i-1) / 5) * 34))
    btn.BackgroundColor3 = color
    btn.Text = ""
    btn.Parent = Pages.ESP
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    if color ~= Color3.fromRGB(255, 255, 255) then
        stroke.Transparency = 0.6
    end
    
    btn.MouseButton1Click:Connect(function()
        _G.ESP_Color = color
    end)
end

-- Speed Page
CreateSection(Pages.Speed, "Speed Configuration")

local SpeedToggleLabel = Instance.new("TextLabel")
SpeedToggleLabel.Name = "SpeedToggleLabel"
SpeedToggleLabel.Size = UDim2.new(0, 150, 0, 30)
SpeedToggleLabel.Position = UDim2.new(0, 15, 0, 55)
SpeedToggleLabel.Text = "Speed Toggle"
SpeedToggleLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
SpeedToggleLabel.TextSize = 13
SpeedToggleLabel.Font = Enum.Font.Gotham
SpeedToggleLabel.BackgroundTransparency = 1
SpeedToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedToggleLabel.Parent = Pages.Speed

local SpeedToggleBtn = Instance.new("TextButton")
SpeedToggleBtn.Name = "SpeedToggleBtn"
SpeedToggleBtn.Size = UDim2.new(0, 50, 0, 22)
SpeedToggleBtn.Position = UDim2.new(1, -65, 0, 59)
SpeedToggleBtn.BackgroundColor3 = Color3.fromRGB(235, 230, 232)
SpeedToggleBtn.Text = "OFF"
SpeedToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedToggleBtn.Font = Enum.Font.GothamBold
SpeedToggleBtn.TextSize = 11
SpeedToggleBtn.Parent = Pages.Speed

Instance.new("UICorner", SpeedToggleBtn).CornerRadius = UDim.new(0, 6)

SpeedToggleBtn.MouseButton1Click:Connect(function()
    _G.Speed_ToggleEnabled = not _G.Speed_ToggleEnabled
    SpeedToggleBtn.Text = (_G.Speed_ToggleEnabled and "ON") or "OFF"
    SpeedToggleBtn.BackgroundColor3 = (_G.Speed_ToggleEnabled and Color3.fromRGB(255, 153, 170)) or Color3.fromRGB(235, 230, 232)
    if not _G.Speed_ToggleEnabled then
        _G.Speed_Enabled = false
    end
end)

local SpeedKeyLabel = Instance.new("TextLabel")
SpeedKeyLabel.Name = "SpeedKeyLabel"
SpeedKeyLabel.Size = UDim2.new(0, 150, 0, 30)
SpeedKeyLabel.Position = UDim2.new(0, 15, 0, 95)
SpeedKeyLabel.Text = "Speed Keybind"
SpeedKeyLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
SpeedKeyLabel.TextSize = 13
SpeedKeyLabel.Font = Enum.Font.Gotham
SpeedKeyLabel.BackgroundTransparency = 1
SpeedKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedKeyLabel.Parent = Pages.Speed

local SpeedKeyBtn = Instance.new("TextButton")
SpeedKeyBtn.Name = "SpeedKeyBtn"
SpeedKeyBtn.Size = UDim2.new(0, 70, 0, 22)
SpeedKeyBtn.Position = UDim2.new(1, -85, 0, 99)
SpeedKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 204, 213)
SpeedKeyBtn.Text = "Press Key"
SpeedKeyBtn.TextColor3 = Color3.fromRGB(214, 115, 131)
SpeedKeyBtn.Font = Enum.Font.GothamBold
SpeedKeyBtn.TextSize = 11
SpeedKeyBtn.Parent = Pages.Speed

Instance.new("UICorner", SpeedKeyBtn).CornerRadius = UDim.new(0, 6)

local waitingForKey = false
SpeedKeyBtn.MouseButton1Click:Connect(function()
    waitingForKey = true
    SpeedKeyBtn.Text = "Waiting..."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if waitingForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        _G.Speed_Key = input.KeyCode
        SpeedKeyBtn.Text = "Key: " .. input.KeyCode.Name
        waitingForKey = false
    end
end)

local SpeedValueLabel = Instance.new("TextLabel")
SpeedValueLabel.Name = "SpeedValueLabel"
SpeedValueLabel.Size = UDim2.new(1, -30, 0, 30)
SpeedValueLabel.Position = UDim2.new(0, 15, 0, 135)
SpeedValueLabel.Text = "Speed Value: 50"
SpeedValueLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
SpeedValueLabel.TextSize = 13
SpeedValueLabel.Font = Enum.Font.Gotham
SpeedValueLabel.BackgroundTransparency = 1
SpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedValueLabel.Parent = Pages.Speed

local SpeedSlider = Instance.new("Frame")
SpeedSlider.Name = "SpeedSlider"
SpeedSlider.Size = UDim2.new(1, -30, 0, 6)
SpeedSlider.Position = UDim2.new(0, 15, 0, 165)
SpeedSlider.BackgroundColor3 = Color3.fromRGB(255, 228, 232)
SpeedSlider.BorderSizePixel = 0
SpeedSlider.Parent = Pages.Speed

Instance.new("UICorner", SpeedSlider).CornerRadius = UDim.new(1, 0)



local SpeedHandle = Instance.new("TextButton")
SpeedHandle.Name = "SpeedHandle"
SpeedHandle.Size = UDim2.new(0, 14, 0, 14)
SpeedHandle.Position = UDim2.new(0, -7, 0.5, -7) -- Start at 0 (50 speed)
SpeedHandle.BackgroundColor3 = Color3.fromRGB(255, 153, 170)
SpeedHandle.BorderSizePixel = 0
SpeedHandle.Text = ""
SpeedHandle.Parent = SpeedSlider

Instance.new("UICorner", SpeedHandle).CornerRadius = UDim.new(1, 0)

-- Teleport Page - FIXED: Was parented to Pages.Speed, now Pages.Teleport
CreateSection(Pages.Teleport, "Teleport to Player")

local TeleportLabel = Instance.new("TextLabel")
TeleportLabel.Name = "TeleportLabel"
TeleportLabel.Size = UDim2.new(1, -30, 0, 30)
TeleportLabel.Position = UDim2.new(0, 15, 0, 55)
TeleportLabel.Text = "Enter player name:"
TeleportLabel.TextColor3 = Color3.fromRGB(214, 115, 131)
TeleportLabel.TextSize = 13
TeleportLabel.Font = Enum.Font.Gotham
TeleportLabel.BackgroundTransparency = 1
TeleportLabel.TextXAlignment = Enum.TextXAlignment.Left
TeleportLabel.Parent = Pages.Teleport

local TeleportInput = Instance.new("TextBox")
TeleportInput.Name = "TeleportInput"
TeleportInput.Size = UDim2.new(1, -30, 0, 32)
TeleportInput.Position = UDim2.new(0, 15, 0, 90)
TeleportInput.BackgroundColor3 = Color3.fromRGB(255, 228, 235)
TeleportInput.Text = ""
TeleportInput.PlaceholderText = "Player name..."
TeleportInput.TextColor3 = Color3.fromRGB(186, 107, 123)
TeleportInput.PlaceholderColor3 = Color3.fromRGB(230, 170, 180)
TeleportInput.Font = Enum.Font.Gotham
TeleportInput.TextSize = 12
TeleportInput.Parent = Pages.Teleport

Instance.new("UICorner", TeleportInput).CornerRadius = UDim.new(0, 6)

local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Name = "TeleportBtn"
TeleportBtn.Size = UDim2.new(1, -120, 0, 30)
TeleportBtn.Position = UDim2.new(0, 15, 0, 135)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(255, 153, 170)
TeleportBtn.Text = "Teleport"
TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportBtn.Font = Enum.Font.GothamBold
TeleportBtn.TextSize = 13
TeleportBtn.Parent = Pages.Teleport -- FIXED: Was Pages.Speed

Instance.new("UICorner", TeleportBtn).CornerRadius = UDim.new(0, 6)

-- Slider functionality
local FOVConnection, SpreadConnection, SpeedConnection

local function UpdateFOV(input)
    local pos = math.clamp((input.Position.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
    FOVHandle.Position = UDim2.new(pos, -7, 0.5, -7)
    local value = math.round(pos * 1000)
    FOVLabel.Text = "FOV Radius: " .. tostring(value)
    _G.FOV_RADIUS = value
end

local function UpdateSpread(input)
    local pos = math.clamp((input.Position.X - SpreadSlider.AbsolutePosition.X) / SpreadSlider.AbsoluteSize.X, 0, 1)
    SpreadHandle.Position = UDim2.new(pos, -7, 0.5, -7)
    local value = math.round(pos * 100)
    SpreadLabel.Text = "Bullet Spread: " .. tostring(value)
    BulletSpread.Amount = value
end

local function UpdateSpeed(input)
    local pos = math.clamp((input.Position.X - SpeedSlider.AbsolutePosition.X) / SpeedSlider.AbsoluteSize.X, 0, 1)
    SpeedHandle.Position = UDim2.new(pos, -7, 0.5, -7)
    local value = math.round(50 + (pos * 950))
    SpeedValueLabel.Text = "Speed Value: " .. tostring(value)
    _G.Speed_Value = value
end

FOVHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        FOVConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                UpdateFOV(input)
            end
        end)
    end
end)

SpreadHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        SpreadConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                UpdateSpread(input)
            end
        end)
    end
end)

SpeedHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        SpeedConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                UpdateSpeed(input)
            end
        end)
    end
end)

-- Speed toggle input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == _G.Speed_Key and not waitingForKey and _G.Speed_ToggleEnabled then
        _G.Speed_Enabled = not _G.Speed_Enabled
    end
end)

-- Teleport functionality
TeleportBtn.MouseButton1Click:Connect(function()
    local targetName = TeleportInput.Text:lower()
    if targetName ~= "" then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Name:lower():sub(1, #targetName) == targetName and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
                break
            end
        end
    end
end)

-- ESP System - BillboardGui version (MacSploit compatible)
local ESPObjects = {}

local function CreateESP(player)
    -- Clean up existing ESP
    if ESPObjects[player] then
        RemoveESP(player)
    end
    
    local objects = {
        box = nil,
        name = nil,
        connection = nil
    }
    
    -- Create BillboardGui for box
    local boxBillboard = Instance.new("BillboardGui")
    boxBillboard.Name = "ESP_Box_" .. player.Name
    boxBillboard.AlwaysOnTop = true
    boxBillboard.Size = UDim2.new(4, 0, 6, 0)
    boxBillboard.StudsOffset = Vector3.new(0, 0, 0)
    
    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "Box"
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundTransparency = 1
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = boxBillboard
    
    -- Create border lines
    local function createLine(name, pos, size)
        local line = Instance.new("Frame")
        line.Name = name
        line.BackgroundColor3 = _G.ESP_Color
        line.BorderSizePixel = 0
        line.Position = pos
        line.Size = size
        line.Parent = boxFrame
        return line
    end
    
    createLine("Top", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 2))
    createLine("Bottom", UDim2.new(0, 0, 1, -2), UDim2.new(1, 0, 0, 2))
    createLine("Left", UDim2.new(0, 0, 0, 0), UDim2.new(0, 2, 1, 0))
    createLine("Right", UDim2.new(1, -2, 0, 0), UDim2.new(0, 2, 1, 0))
    
    -- Create BillboardGui for name
    local nameBillboard = Instance.new("BillboardGui")
    nameBillboard.Name = "ESP_Name_" .. player.Name
    nameBillboard.AlwaysOnTop = true
    nameBillboard.Size = UDim2.new(0, 100, 0, 20)
    nameBillboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = _G.ESP_Color
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = nameBillboard
    
    objects.box = boxBillboard
    objects.name = nameBillboard
    
    -- Update function
    local function updateESP()
        if not player or not player.Parent then
            boxBillboard.Enabled = false
            nameBillboard.Enabled = false
            return
        end
        
        local character = player.Character
        if not character then
            boxBillboard.Enabled = false
            nameBillboard.Enabled = false
            return
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")
        
        if not hrp or not humanoid or humanoid.Health <= 0 then
            boxBillboard.Enabled = false
            nameBillboard.Enabled = false
            return
        end
        
        -- Parent to character
        if boxBillboard.Parent ~= character then
            boxBillboard.Parent = character
        end
        if nameBillboard.Parent ~= character then
            nameBillboard.Parent = character
        end
        
        -- Update visibility and color
        boxBillboard.Enabled = _G.ESP_Boxes
        nameBillboard.Enabled = _G.ESP_Names
        
        -- Update colors
        for _, child in pairs(boxFrame:GetChildren()) do
            if child:IsA("Frame") then
                child.BackgroundColor3 = _G.ESP_Color
            end
        end
        nameLabel.TextColor3 = _G.ESP_Color
    end
    
    objects.connection = RunService.RenderStepped:Connect(updateESP)
    ESPObjects[player] = objects
end

-- Cleanup function
local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].connection then
            ESPObjects[player].connection:Disconnect()
        end
        if ESPObjects[player].box then
            ESPObjects[player].box:Destroy()
        end
        if ESPObjects[player].name then
            ESPObjects[player].name:Destroy()
        end
        ESPObjects[player] = nil
    end
end

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
        player.CharacterAdded:Connect(function()
            wait(0.1)
            CreateESP(player)
        end)
    end
end

-- ESP for new players
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
        player.CharacterAdded:Connect(function()
            wait(0.1)
            CreateESP(player)
        end)
    end
end)

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Speed loop - COMPLETE REPLACEMENT
RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if _G.Speed_Enabled then
        -- Only set if different to avoid unnecessary network replication
        if humanoid.WalkSpeed ~= _G.Speed_Value then
            humanoid.WalkSpeed = _G.Speed_Value
        end
        LastSpeedEnabled = true
    else
        -- Reset to default when disabled
        if LastSpeedEnabled then
            humanoid.WalkSpeed = OriginalWalkSpeed
            LastSpeedEnabled = false
        end
    end
end)

-- Track original speed when character spawns - ADD THIS
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.1)
    local humanoid = char:WaitForChild("Humanoid", 2)
    if humanoid then
        OriginalWalkSpeed = humanoid.WalkSpeed
        -- Apply speed if enabled when respawning
        if _G.Speed_Enabled then
            humanoid.WalkSpeed = _G.Speed_Value
        end
    end
end)

-- GUI Toggle with RightShift - FIXED: Ensure it works properly
local GuiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        GuiVisible = not GuiVisible
        MainFrame.Visible = GuiVisible
        if not GuiVisible then
            TargetList.Visible = false
        end
    end
end)

-- Cleanup slider connections
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if FOVConnection then
            FOVConnection:Disconnect()
            FOVConnection = nil
        end
        if SpreadConnection then
            SpreadConnection:Disconnect()
            SpreadConnection = nil
        end
        if SpeedConnection then
            SpeedConnection:Disconnect()
            SpeedConnection = nil
        end
    end
end)

print("GUI Loaded! Press RightShift to toggle. If GUI doesn't appear, check that PlayerGui exists.")
