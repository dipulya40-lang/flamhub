-- Flam Hub Native UI (Фикс смены бинда + Отключение при закрытии)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Удаление предыдущей копии меню при перезапуске
if CoreGui:FindFirstChild("FlamTPNative") then
    CoreGui.FlamTPNative:Destroy()
end

-- Создание ScreenGui с защитой
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlamTPNative"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- Переменные
local tpDistance = 50
local tpKey = Enum.KeyCode.V
local isBinding = false
local inputConnection = nil

-- Функция полного закрытия скрипта и отписки от клавиш
local function destroyScript()
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
    ScreenGui:Destroy()
end

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 185)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -92)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Шапка окна
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "  FLAM HUB — Wall TP"
TitleLabel.Size = UDim2.new(1, -75, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Parent = TitleBar

-- Кнопка Свернуть (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Text = "-"
MinimizeBtn.Size = UDim2.new(0, 36, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -72, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 22
MinimizeBtn.Parent = TitleBar

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Кнопка Закрыть (X) — Отключает скрипт полностью
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 36, 1, 0)
CloseBtn.Position = UDim2.new(1, -36, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(destroyScript)

-- 1. Поле ввода дистанции
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, -20, 0, 34)
InputFrame.Position = UDim2.new(0, 10, 0, 44)
InputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
InputFrame.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = InputFrame

local InputLabel = Instance.new("TextLabel")
InputLabel.Text = "  Дистанция (Studs):"
InputLabel.Size = UDim2.new(0.6, 0, 1, 0)
InputLabel.BackgroundTransparency = 1
InputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InputLabel.Font = Enum.Font.SourceSans
InputLabel.TextXAlignment = Enum.TextXAlignment.Left
InputLabel.TextSize = 14
InputLabel.Parent = InputFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(0.35, -5, 0.75, 0)
TextBox.Position = UDim2.new(0.62, 0, 0.125, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.Text = tostring(tpDistance)
TextBox.Font = Enum.Font.SourceSansBold
TextBox.TextSize = 14
TextBox.Parent = InputFrame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 4)
BoxCorner.Parent = TextBox

TextBox.FocusLost:Connect(function()
    local num = tonumber(TextBox.Text)
    if num then
        tpDistance = num
    else
        TextBox.Text = tostring(tpDistance)
    end
end)

-- 2. Кнопка смены бинда
local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Size = UDim2.new(1, -20, 0, 34)
KeybindBtn.Position = UDim2.new(0, 10, 0, 84)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
KeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
KeybindBtn.Font = Enum.Font.SourceSans
KeybindBtn.TextSize = 14
KeybindBtn.Text = "  Назначен Бинд: [ " .. tpKey.Name .. " ]"
KeybindBtn.TextXAlignment = Enum.TextXAlignment.Left
KeybindBtn.Parent = MainFrame

local KeybindCorner = Instance.new("UICorner")
KeybindCorner.CornerRadius = UDim.new(0, 6)
KeybindCorner.Parent = KeybindBtn

KeybindBtn.MouseButton1Click:Connect(function()
    isBinding = true
    KeybindBtn.Text = "  [ Нажмите новую клавишу... ]"
    KeybindBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
end)

-- Функция Телепортации
local function doTeleport()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -tpDistance)
    end
end

-- 3. Кнопка выполнения телепорта
local TpButton = Instance.new("TextButton")
TpButton.Size = UDim2.new(1, -20, 0, 38)
TpButton.Position = UDim2.new(0, 10, 0, 132)
TpButton.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
TpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TpButton.Font = Enum.Font.SourceSansBold
TpButton.TextSize = 15
TpButton.Text = "Телепортироваться"
TpButton.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = TpButton

TpButton.MouseButton1Click:Connect(doTeleport)

-- Обработка событий клавиатуры
inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Режим записи нового бинда
    if isBinding then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            tpKey = input.KeyCode
            KeybindBtn.Text = "  Назначен Бинд: [ " .. tpKey.Name .. " ]"
            KeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            isBinding = false
        end
        return
    end

    -- Открытие/свертывание меню на клавишу INSERT
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
        return
    end

    -- Нажатие ТЕКУЩЕГО бинда для телепорта
    if not gameProcessed and input.KeyCode == tpKey then
        doTeleport()
    end
end)
