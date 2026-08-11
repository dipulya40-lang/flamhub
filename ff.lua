local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "flam hub",
    SubTitle = "Beta",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "sword" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Lighting = Window:AddTab({ Title = "Lighting", Icon = "sun" }),
    Performance = Window:AddTab({ Title = "Performance", Icon = "zap" }),
    Teleports = Window:AddTab({ Title = "Teleports", Icon = "map-pin" }),
    World = Window:AddTab({ Title = "World", Icon = "globe" }),
    Scripts = Window:AddTab({ Title = "Scripts", Icon = "terminal" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local VirtualUser = game:GetService("VirtualUser")
local Mouse = LocalPlayer:GetMouse()

local espEnabled = false
local cornersEspEnabled = false
local hpBarEspEnabled = false
local teamCheckEnabled = false 
local includeSelfEnabled = false 

local visualSpinbotEnabled = false
local nonVisualSpinbotEnabled = false
local spinSpeed = 50

local noclipEnabled = false
local speedHackEnabled = false
local walkSpeedValue = 16
local jumpPowerEnabled = false
local jumpPowerValue = 50
local infiniteJumpEnabled = false

local gravityEnabled = false
local customGravityValue = 50
local originalGravity = workspace.Gravity

local fovChangerEnabled = false
local customFovValue = 70
local originalCameraFov = Camera.FieldOfView

local antiAfkEnabled = false

local flyingOrbsEnabled = false
local orbCount = 20
local orbSize = 3
local currentOrbColor = Color3.fromRGB(0, 255, 200)
local orbShapeType = "Ball"
local activeOrbs = {}
local orbFolder = nil

-- Телепортация и Waypoints
local savedWaypoint = nil
local ctrlClickTpEnabled = false
local selectedTargetPlayer = nil

local aimbotEnabled = false
local aimbotFov = 150
local fovVisibleEnabled = false 
local sensitivity = 3
local isHoldingQ = false
local lockedTarget = nil
local fovColor = Color3.fromRGB(255, 170, 0)

local spamText = "привет всем от flam hub!"
local spamDelay = 1.5
local isSpamming = false

local espConnections = {}
local nameTagConnections = {}
local cornerDrawings = {}
local hpBarDrawings = {}

-- Переменные цветов и прозрачности
local currentEnemyEspColor = Color3.fromRGB(255, 50, 50)      
local currentSelfEspColor = Color3.fromRGB(0, 150, 255)       
local currentEnemyOutlineColor = Color3.fromRGB(150, 180, 255) 
local currentSelfOutlineColor = Color3.fromRGB(255, 255, 255) 
local fillTransparencyVal = 0.2                         

local themes = {
    ["Default"] = { Enemy = Color3.fromRGB(255, 50, 50), Self = Color3.fromRGB(0, 150, 255), EnemyOutline = Color3.fromRGB(150, 180, 255), SelfOutline = Color3.fromRGB(255, 255, 255), Orb = Color3.fromRGB(0, 255, 200) },
    ["Cyberpunk"] = { Enemy = Color3.fromRGB(255, 0, 127), Self = Color3.fromRGB(0, 255, 120), EnemyOutline = Color3.fromRGB(0, 255, 255), SelfOutline = Color3.fromRGB(255, 255, 0), Orb = Color3.fromRGB(255, 230, 0) },
    ["BloodMoon"] = { Enemy = Color3.fromRGB(255, 50, 50), Self = Color3.fromRGB(255, 120, 0), EnemyOutline = Color3.fromRGB(255, 50, 50), SelfOutline = Color3.fromRGB(255, 255, 255), Orb = Color3.fromRGB(255, 0, 0) },
    ["Matrix"] = { Enemy = Color3.fromRGB(0, 255, 60), Self = Color3.fromRGB(100, 255, 100), EnemyOutline = Color3.fromRGB(0, 255, 60), SelfOutline = Color3.fromRGB(200, 255, 200), Orb = Color3.fromRGB(50, 255, 100) },
    ["Sunset"] = { Enemy = Color3.fromRGB(255, 100, 50), Self = Color3.fromRGB(255, 100, 50), EnemyOutline = Color3.fromRGB(255, 150, 200), SelfOutline = Color3.fromRGB(255, 220, 100), Orb = Color3.fromRGB(255, 128, 0) },
    ["Neon"] = { Enemy = Color3.fromRGB(0, 255, 255), Self = Color3.fromRGB(255, 0, 255), EnemyOutline = Color3.fromRGB(255, 255, 255), SelfOutline = Color3.fromRGB(0, 255, 0), Orb = Color3.fromRGB(0, 255, 255) }
}

local function applyTheme(themeName)
    local theme = themes[themeName]
    if theme then
        currentEnemyEspColor = theme.Enemy
        currentSelfEspColor = theme.Self
        currentEnemyOutlineColor = theme.EnemyOutline
        currentSelfOutlineColor = theme.SelfOutline
        currentOrbColor = theme.Orb
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("FlamESP") then
                local isSelf = (player == LocalPlayer)
                player.Character.FlamESP.FillColor = isSelf and currentSelfEspColor or currentEnemyEspColor
                player.Character.FlamESP.OutlineColor = isSelf and currentSelfOutlineColor or currentEnemyOutlineColor
            end
        end
    end
end

local function isTeammate(player)
    if not teamCheckEnabled then return false end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    return false
end

local function isFirstPerson()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return false end
    return (Camera.CFrame.Position - LocalPlayer.Character.Head.Position).Magnitude <= 3.5
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then isHoldingQ = true; lockedTarget = nil end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then isHoldingQ = false; lockedTarget = nil end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if ctrlClickTpEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hitPos = Mouse.Hit
            if hitPos then
                char.HumanoidRootPart.CFrame = CFrame.new(hitPos.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

local fovDrawing = Drawing.new("Circle")
fovDrawing.Visible = false
fovDrawing.Radius = aimbotFov
fovDrawing.Color = fovColor
fovDrawing.Thickness = 1.5
fovDrawing.Filled = false
fovDrawing.Transparency = 0.8

local function sendChatMessage(message)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(message) end
        else
            local defaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if defaultChatSystemChatEvents then
                local sayMessageRequest = defaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if sayMessageRequest then sayMessageRequest:FireServer(message, "All") end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if isSpamming then
            sendChatMessage(spamText)
            task.wait(spamDelay)
        else
            task.wait(0.2)
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space and infiniteJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    if gravityEnabled then workspace.Gravity = customGravityValue end

    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if speedHackEnabled then humanoid.WalkSpeed = walkSpeedValue end
            if jumpPowerEnabled then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = jumpPowerValue
            end
        end
    end
end)

local function clearOrbs()
    if orbFolder then orbFolder:Destroy(); orbFolder = nil end
    activeOrbs = {}
end

local function updateOrbs()
    clearOrbs()
    if not flyingOrbsEnabled then return end

    orbFolder = Instance.new("Folder")
    orbFolder.Name = "FlamFlyingOrbs"
    orbFolder.Parent = workspace

    local rootPos = Vector3.new(0, 5, 0)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        rootPos = LocalPlayer.Character.HumanoidRootPart.Position
    end

    math.randomseed(tick())
    for i = 1, orbCount do
        local part = Instance.new("Part")
        if orbShapeType == "Ball" then
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(orbSize, orbSize, orbSize)
            part.Transparency = 0.3
            part.Material = Enum.Material.Neon
        else
            part.Shape = Enum.PartType.Block
            part.Size = Vector3.new(orbSize, orbSize, orbSize)
            part.Transparency = 1 
            part.CanCollide = false
            
            local selectionBox = Instance.new("SelectionBox")
            selectionBox.Name = "SelectionBox"
            selectionBox.Adornee = part
            selectionBox.Color3 = currentOrbColor
            selectionBox.LineThickness = 0.03
            selectionBox.Parent = part
        end
        
        part.Color = currentOrbColor
        part.Anchored = true
        part.CanCollide = false
        
        local rx = math.random(-30, 30)
        local ry = math.random(1, 15)
        local rz = math.random(-30, 30)
        
        part.Position = rootPos + Vector3.new(rx, ry, rz)
        part.Parent = orbFolder

        table.insert(activeOrbs, {
            Part = part,
            BaseOffset = Vector3.new(rx, ry, rz),
            SpeedX = math.random(8, 20) * 0.1,
            SpeedY = math.random(8, 20) * 0.1,
            SpeedZ = math.random(8, 20) * 0.1,
            Seed = math.random(1, 100)
        })
    end
end

-- Логика отрисовки Corners и HP Bar через Drawing API
local function removeCornersAndHp()
    for _, lines in pairs(cornerDrawings) do
        for _, line in pairs(lines) do line:Remove() end
    end
    cornerDrawings = {}
    for _, bars in pairs(hpBarDrawings) do
        for _, bar in pairs(bars) do bar:Remove() end
    end
    hpBarDrawings = {}
end

RunService.RenderStepped:Connect(function()
    local screenSize = Camera.ViewportSize
    local centerScreen = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    
    fovDrawing.Position = centerScreen
    fovDrawing.Visible = fovVisibleEnabled

    if fovChangerEnabled then Camera.FieldOfView = customFovValue end

    -- Очистка старых линий рамок/уголков перед перерисовкой
    for _, lines in pairs(cornerDrawings) do
        for _, line in pairs(lines) do line.Visible = false end
    end
    for _, bars in pairs(hpBarDrawings) do
        for _, bar in pairs(bars) do bar.Visible = false end
    end

    if cornersEspEnabled or hpBarEspEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
                if not (not includeSelfEnabled and player == LocalPlayer) and not isTeammate(player) then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local rootPart = player.Character.HumanoidRootPart
                        local head = player.Character.Head
                        
                        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local legPos, legOnScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                        
                        if rootOnScreen then
                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height / 2
                            local x = rootPos.X - width / 2
                            local y = headPos.Y
                            
                            -- Отрисовка Corners (Уголки)
                            if cornersEspEnabled then
                                if not cornerDrawings[player] then
                                    local lines = {}
                                    for i = 1, 16 do
                                        local l = Drawing.new("Line")
                                        l.Thickness = 1.5
                                        l.Color = currentEnemyEspColor
                                        table.insert(lines, l)
                                    end
                                    cornerDrawings[player] = lines
                                end
                                
                                local lines = cornerDrawings[player]
                                local len = width / 4
                                local hLen = height / 4
                                
                                local idx = 1
                                local function makeCorner(x1, y1, x2, y2)
                                    lines[idx].From = Vector2.new(x1, y1)
                                    lines[idx].To = Vector2.new(x2, y2)
                                    lines[idx].Color = currentEnemyEspColor
                                    lines[idx].Visible = true
                                    idx = idx + 1
                                end
                                
                                makeCorner(x, y, x + len, y)
                                makeCorner(x, y, x, y + hLen)
                                makeCorner(x + width, y, x + width - len, y)
                                makeCorner(x + width, y, x + width, y + hLen)
                                makeCorner(x, y + height, x + len, y + height)
                                makeCorner(x, y + height, x, y + height - hLen)
                                makeCorner(x + width, y + height, x + width - len, y + height)
                                makeCorner(x + width, y + height, x + width, y + height - hLen)
                            end
                            
                            -- Отрисовка HP Bar
                            if hpBarEspEnabled then
                                if not hpBarDrawings[player] then
                                    hpBarDrawings[player] = {
                                        Bg = Drawing.new("Line"),
                                        Bar = Drawing.new("Line")
                                    }
                                    hpBarDrawings[player].Bg.Thickness = 3
                                    hpBarDrawings[player].Bar.Thickness = 1.5
                                end
                                
                                local bars = hpBarDrawings[player]
                                local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                                local barHeight = height * healthPercent
                                
                                bars.Bg.From = Vector2.new(x - 6, y + height)
                                bars.Bg.To = Vector2.new(x - 6, y)
                                bars.Bg.Color = Color3.fromRGB(0, 0, 0)
                                bars.Bg.Visible = true
                                
                                bars.Bar.From = Vector2.new(x - 6, y + height)
                                bars.Bar.To = Vector2.new(x - 6, y + height - barHeight)
                                bars.Bar.Color = Color3.fromRGB(0, 255, 0)
                                bars.Bar.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local head = LocalPlayer.Character:FindFirstChild("Head")
        
        local isSitting = humanoid and (humanoid.Sit or humanoid.SeatPart ~= nil)
        local fpCheck = isFirstPerson()

        if visualSpinbotEnabled and not isSitting and not fpCheck and head then
            local camLook = Camera.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
            if flatLook.Magnitude > 0 then
                local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + flatLook)
                rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame * CFrame.Angles(0, tick() * spinSpeed % (math.pi * 2), 0), 0.5)
            end
        end

        if nonVisualSpinbotEnabled and not isSitting and not fpCheck then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end

    if flyingOrbsEnabled and #activeOrbs > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPos = LocalPlayer.Character.HumanoidRootPart.Position
        local t = tick()
        for _, orbData in ipairs(activeOrbs) do
            if orbData.Part and orbData.Part.Parent then
                local p = orbData.Part
                local base = orbData.BaseOffset
                local targetPos = rootPos + base + Vector3.new(
                    math.sin(t * orbData.SpeedX + orbData.Seed) * 3,
                    math.cos(t * orbData.SpeedY + orbData.Seed) * 2,
                    math.sin(t * orbData.SpeedZ + orbData.Seed) * 3
                )
                p.Position = p.Position:Lerp(targetPos, 0.1)
            end
        end
    end

    if not aimbotEnabled or not isHoldingQ then lockedTarget = nil; return end

    if lockedTarget and (isTeammate(lockedTarget) or not lockedTarget.Character) then lockedTarget = nil end

    if lockedTarget and lockedTarget.Character then
        local humanoid = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
        local head = lockedTarget.Character:FindFirstChild("Head")
        if humanoid and humanoid.Health > 0 and head and not isTeammate(lockedTarget) then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local targetPos2D = Vector2.new(screenPoint.X, screenPoint.Y)
                local diff = targetPos2D - centerScreen
                if mousemoverel then mousemoverel(diff.X / sensitivity, diff.Y / sensitivity) end
                return
            end
        end
    end

    local closestTargetPlayer = nil
    local shortestDistance = aimbotFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and not isTeammate(player) then
                local head = player.Character.Head
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distance = (centerScreen - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestTargetPlayer = player
                    end
                end
            end
        end
    end

    if closestTargetPlayer then lockedTarget = closestTargetPlayer end
end)

local function updateEspColors()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("FlamESP") then
            local isSelf = (player == LocalPlayer)
            player.Character.FlamESP.FillColor = isSelf and currentSelfEspColor or currentEnemyEspColor
            player.Character.FlamESP.OutlineColor = isSelf and currentSelfOutlineColor or currentEnemyOutlineColor
            player.Character.FlamESP.FillTransparency = fillTransparencyVal
        end
    end
end

local function addEsp(player)
    if player == LocalPlayer and not includeSelfEnabled then return end
    local function setupCharacter(char)
        if char:FindFirstChild("FlamESP") or (player ~= LocalPlayer and isTeammate(player)) then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "FlamESP"
        highlight.Adornee = char
        highlight.Parent = char
        local isSelf = (player == LocalPlayer)
        highlight.FillColor = isSelf and currentSelfEspColor or currentEnemyEspColor
        highlight.OutlineColor = isSelf and currentSelfOutlineColor or currentEnemyOutlineColor
        highlight.FillTransparency = fillTransparencyVal
        highlight.OutlineTransparency = 0
    end
    if player.Character then setupCharacter(player.Character) end
    table.insert(espConnections, player.CharacterAdded:Connect(setupCharacter))
end

local function removeEsp()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("FlamESP") then player.Character.FlamESP:Destroy() end
    end
    for _, conn in ipairs(espConnections) do conn:Disconnect() end
    espConnections = {}
end

local function refreshEsp()
    removeEsp()
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do addEsp(player) end
        table.insert(espConnections, Players.PlayerAdded:Connect(addEsp))
    end
end

local function addNameTag(player)
    if player == LocalPlayer then return end
    local function setupTag(char)
        if isTeammate(player) then return end
        local head = char:WaitForChild("Head", 5)
        if not head or head:FindFirstChild("FlamNameTag") then return end
        local billBoard = Instance.new("BillboardGui")
        billBoard.Name = "FlamNameTag"
        billBoard.Adornee = head
        billBoard.Size = UDim2.new(0, 200, 0, 50)
        billBoard.StudsOffset = Vector3.new(0, 2.5, 0)
        billBoard.AlwaysOnTop = true
        billBoard.Parent = head
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billBoard
        table.insert(nameTagConnections, RunService.RenderStepped:Connect(function()
            if not char or not char:FindFirstChild("Head") or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return end
            local distance = math.floor((LocalPlayer.Character.Head.Position - head.Position).Magnitude)
            textLabel.Text = player.Name .. " [" .. distance .. "m]"
        end))
    end
    if player.Character then setupTag(player.Character) end
    table.insert(nameTagConnections, player.CharacterAdded:Connect(setupTag))
end

local function removeNameTags()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local tag = player.Character.Head:FindFirstChild("FlamNameTag")
            if tag then tag:Destroy() end
        end
    end
    for _, conn in ipairs(nameTagConnections) do conn:Disconnect() end
    nameTagConnections = {}
end

-- === НАПОЛНЕНИЕ ВКЛАДОК ===

-- Visuals Tab (Бывший Main)
Tabs.Visuals:AddParagraph({ Title = "ESP Settings", Content = "Настройка визуального подсвета игроков" })

Tabs.Visuals:AddToggle("EspToggle", { Title = "Player Chams (ESP)", Default = false }):OnChanged(function(state)
    espEnabled = state
    refreshEsp()
end)

Tabs.Visuals:AddToggle("CornersToggle", { Title = "ESP Corners", Default = false }):OnChanged(function(state)
    cornersEspEnabled = state
    if not state then removeCornersAndHp() end
end)

Tabs.Visuals:AddToggle("HpBarToggle", { Title = "ESP HP Bar", Default = false }):OnChanged(function(state)
    hpBarEspEnabled = state
    if not state then removeCornersAndHp() end
end)

Tabs.Visuals:AddToggle("SelfEspToggle", { Title = "Include Self", Default = false }):OnChanged(function(state)
    includeSelfEnabled = state
    refreshEsp()
end)

Tabs.Visuals:AddToggle("TeamCheckToggle", { Title = "Team Check", Default = false }):OnChanged(function(state)
    teamCheckEnabled = state
    refreshEsp()
end)

Tabs.Visuals:AddToggle("NameTagsToggle", { Title = "NameTags & Distance", Default = false }):OnChanged(function(state)
    if state then
        for _, p in ipairs(Players:GetPlayers()) do addNameTag(p) end
    else
        removeNameTags()
    end
end)

Tabs.Visuals:AddColorpicker("EnemyColorPicker", { Title = "Enemy Color", Default = Color3.fromRGB(255, 50, 50) }):OnChanged(function(color)
    currentEnemyEspColor = color
    updateEspColors()
end)

Tabs.Visuals:AddSlider("FillTransparencySlider", { Title = "Fill Transparency", Default = 0.2, Min = 0, Max = 1, Rounding = 1 }):OnChanged(function(value)
    fillTransparencyVal = value
    updateEspColors()
end)

Tabs.Visuals:AddToggle("FovChangerToggle", { Title = "FOV Changer", Default = false }):OnChanged(function(state)
    fovChangerEnabled = state
    if not state then Camera.FieldOfView = originalCameraFov end
end)

Tabs.Visuals:AddSlider("CameraFovSlider", { Title = "Camera FOV", Default = 70, Min = 30, Max = 120, Rounding = 0 }):OnChanged(function(value)
    customFovValue = value
end)

Tabs.Visuals:AddToggle("OrbsToggle", { Title = "Flying Orbs", Default = false }):OnChanged(function(state)
    flyingOrbsEnabled = state
    updateOrbs()
end)

Tabs.Visuals:AddDropdown("OrbShapeDropdown", { Title = "Orb Shape", Values = { "Ball", "BoxWire" }, Default = 1 }):OnChanged(function(val)
    orbShapeType = val
    if flyingOrbsEnabled then updateOrbs() end
end)

Tabs.Visuals:AddColorpicker("OrbColorPicker", { Title = "Orb Color", Default = Color3.fromRGB(0, 255, 200) }):OnChanged(function(color)
    currentOrbColor = color
    if flyingOrbsEnabled then
        for _, orbData in ipairs(activeOrbs) do
            if orbData.Part then
                orbData.Part.Color = currentOrbColor
                local sb = orbData.Part:FindFirstChild("SelectionBox")
                if sb then sb.Color3 = currentOrbColor end
            end
        end
    end
end)

Tabs.Visuals:AddSlider("OrbSizeSlider", { Title = "Orb Size", Default = 3, Min = 1, Max = 10, Rounding = 1 }):OnChanged(function(value)
    orbSize = value
    if flyingOrbsEnabled then updateOrbs() end
end)

Tabs.Visuals:AddSlider("OrbCountSlider", { Title = "Orb Count", Default = 20, Min = 5, Max = 100, Rounding = 0 }):OnChanged(function(value)
    orbCount = value
    if flyingOrbsEnabled then updateOrbs() end
end)


-- Combat Tab (Только чистый бой и спинботы)
Tabs.Combat:AddToggle("AimbotToggle", { Title = "Aimbot (Hold Q)", Default = false }):OnChanged(function(state)
    aimbotEnabled = state
end)

Tabs.Combat:AddToggle("FovVisibleToggle", { Title = "Show FOV Circle", Default = false }):OnChanged(function(state)
    fovVisibleEnabled = state
end)

Tabs.Combat:AddSlider("FovSizeSlider", { Title = "FOV Size", Description = "Радиус захвата цели", Default = 150, Min = 50, Max = 300, Rounding = 0 }):OnChanged(function(value)
    aimbotFov = value
    fovDrawing.Radius = value
end)

Tabs.Combat:AddToggle("VisualSpinbot", { Title = "Visual Spinbot", Default = false }):OnChanged(function(state)
    visualSpinbotEnabled = state
end)

Tabs.Combat:AddToggle("NonVisualSpinbot", { Title = "Real Spinbot", Default = false }):OnChanged(function(state)
    nonVisualSpinbotEnabled = state
end)

Tabs.Combat:AddSlider("SpinSpeedSlider", { Title = "Spin Speed", Default = 50, Min = 10, Max = 200, Rounding = 0 }):OnChanged(function(value)
    spinSpeed = value
end)


-- Movement Tab
Tabs.Movement:AddToggle("SpeedHackToggle", { Title = "SpeedHack", Default = false }):OnChanged(function(state)
    speedHackEnabled = state
end)

Tabs.Movement:AddSlider("WalkSpeedSlider", { Title = "WalkSpeed Value", Default = 16, Min = 16, Max = 200, Rounding = 0 }):OnChanged(function(value)
    walkSpeedValue = value
end)

Tabs.Movement:AddToggle("JumpPowerToggle", { Title = "JumpPower Mod", Default = false }):OnChanged(function(state)
    jumpPowerEnabled = state
end)

Tabs.Movement:AddSlider("JumpPowerSlider", { Title = "JumpPower Value", Default = 50, Min = 50, Max = 300, Rounding = 0 }):OnChanged(function(value)
    jumpPowerValue = value
end)

Tabs.Movement:AddToggle("InfiniteJumpToggle", { Title = "Infinite Jump", Default = false }):OnChanged(function(state)
    infiniteJumpEnabled = state
end)

Tabs.Movement:AddToggle("GravityToggle", { Title = "Gravity Changer", Default = false }):OnChanged(function(state)
    gravityEnabled = state
    if not state then workspace.Gravity = originalGravity end
end)

Tabs.Movement:AddSlider("GravitySlider", { Title = "Gravity Value", Default = 50, Min = 0, Max = 300, Rounding = 0 }):OnChanged(function(value)
    customGravityValue = value
end)

Tabs.Movement:AddToggle("NoclipToggle", { Title = "NoClip (Walls)", Default = false }):OnChanged(function(state)
    noclipEnabled = state
end)


-- Lighting Tab
Tabs.Lighting:AddParagraph({ Title = "Lighting Settings", Content = "Настройка освещения в игре" })

Tabs.Lighting:AddToggle("FullbrightToggle", { Title = "Fullbright (Без темноты)", Default = false }):OnChanged(function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)

Tabs.Lighting:AddSlider("ClockTimeSlider", { Title = "Fixed Time (Часы)", Default = 12, Min = 0, Max = 24, Rounding = 1 }):OnChanged(function(val)
    Lighting.ClockTime = val
end)


-- Performance Tab
Tabs.Performance:AddParagraph({ Title = "Performance Utilities", Content = "Инструменты производительности" })

Tabs.Performance:AddButton({
    Title = "Delete All Particles",
    Description = "Удалить все партиклы и эффекты частиц на карте",
    Callback = function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v:Destroy()
            end
        end
        Fluent:Notify({ Title = "Performance", Content = "Все партиклы удалены!", Duration = 3 })
    end
})


-- Teleports Tab
local function getPlayerNames()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then table.insert(list, "Нет игроков") end
    return list
end

local playerDropdown = Tabs.Teleports:AddDropdown("PlayerTpDropdown", { Title = "Select Player", Values = getPlayerNames(), Default = 1 })
playerDropdown:OnChanged(function(val)
    selectedTargetPlayer = val
end)

Players.PlayerAdded:Connect(function()
    playerDropdown:SetValues(getPlayerNames())
end)
Players.PlayerRemoving:Connect(function()
    playerDropdown:SetValues(getPlayerNames())
end)

Tabs.Teleports:AddButton({
    Title = "Teleport to Player",
    Description = "Телепортироваться к выбранному игроку",
    Callback = function()
        if selectedTargetPlayer and selectedTargetPlayer ~= "Нет игроков" then
            local target = Players:FindFirstChild(selectedTargetPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end
})

Tabs.Teleports:AddButton({
    Title = "Save Position",
    Description = "Сохранить текущую позицию",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            savedWaypoint = char.HumanoidRootPart.CFrame
            Fluent:Notify({ Title = "Teleports", Content = "Позиция успешно сохранена!", Duration = 3 })
        end
    end
})

Tabs.Teleports:AddButton({
    Title = "Load Position",
    Description = "Вернуться на сохраненную позицию",
    Callback = function()
        if savedWaypoint then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = savedWaypoint
                Fluent:Notify({ Title = "Teleports", Content = "Телепортация на сохраненную точку!", Duration = 3 })
            end
        else
            Fluent:Notify({ Title = "Teleports", Content = "Сначала сохраните позицию!", Duration = 3 })
        end
    end
})

Tabs.Teleports:AddToggle("CtrlClickTpToggle", { Title = "Ctrl + Click TP", Default = false }):OnChanged(function(state)
    ctrlClickTpEnabled = state
end)


-- World Tab
Tabs.World:AddSlider("TimeSlider", { Title = "Time Changer (ClockTime)", Default = 12, Min = 0, Max = 24, Rounding = 1 }):OnChanged(function(value)
    Lighting.ClockTime = value
end)


-- Scripts Tab (Теперь тут и Anti-AFK)
Tabs.Scripts:AddToggle("AntiAfkToggle", { Title = "Anti-AFK Protection", Default = false }):OnChanged(function(state)
    antiAfkEnabled = state
end)

Tabs.Scripts:AddInput("SpamInput", { Title = "Spam Text", Default = "привет всем от flam hub!", Placeholder = "Введите текст..." }):OnChanged(function(text)
    if text ~= "" then spamText = text end
end)

Tabs.Scripts:AddToggle("SpamToggle", { Title = "Chat Spammer", Default = false }):OnChanged(function(state)
    isSpamming = state
end)

Tabs.Scripts:AddButton({
    Title = "Run AutoFarm",
    Description = "Запустить скрипт автофарма",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://pastebin.com/raw/FL1S7dg2"))() end)
    end
})

Tabs.Scripts:AddButton({
    Title = "Run Infinite Yield",
    Description = "Запустить админ-команды IY",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua"))()
    end
})


-- Settings Tab & Themes
Tabs.Settings:AddDropdown("ThemeDropdown", { Title = "Color Preset", Values = { "Default", "Cyberpunk", "BloodMoon", "Matrix", "Sunset", "Neon" }, Default = 1 }):OnChanged(function(val)
    applyTheme(val)
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("FlamHub_Fluent")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({ Title = "Flam Hub", Content = "Структура вкладок обновлена!", Duration = 5 })

Fluent.Unloaded = function()
    removeEsp()
    removeNameTags()
    removeCornersAndHp()
    clearOrbs()
    workspace.Gravity = originalGravity
    Camera.FieldOfView = originalCameraFov
    print("Flam Hub unloaded!")
end
