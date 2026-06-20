local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    AimEnabled = false,   
    Whitelist = {},       -- Guardará los jugadores ignorados por el Aim
    SpyEnabled = false,
    UILocked = false      
}

local AimLockActive = false
local currentTarget = nil
local aimLoopConnection = nil
local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("JsLikeBetaMenu") then
    CoreGui.JsLikeBetaMenu:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JsLikeBetaMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = CoreGui

local function makeMobileDraggable(gui)
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Config.UILocked then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and not Config.UILocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    gui.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function createCircularButton(name, pos, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 0, 0)
    btn.TextSize = 20
    btn.Font = Enum.Font.SourceSansBold
    btn.Active = true
    btn.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) 
    corner.Parent = btn

    makeMobileDraggable(btn)
    return btn
end

local MainToggleButton = createCircularButton("Js", UDim2.new(0, 20, 0, 150), "Js")
local AimButton = createCircularButton("Aim", UDim2.new(0, 20, 0, 220), "Aim")
AimButton.Visible = false 

-- Ajustamos el tamaño del menú para albergar la whitelist cómodamente
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 210)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -105)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

MainToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 35)
TabBar.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Js Like Beta - Panel Config"
TitleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TabBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- [CONFIG AIM]
local AimSwitchLabel = Instance.new("TextLabel")
AimSwitchLabel.Size = UDim2.new(0, 180, 0, 30)
AimSwitchLabel.Position = UDim2.new(0, 15, 0, 15)
AimSwitchLabel.BackgroundTransparency = 1
AimSwitchLabel.Text = "Habilitar Botón Aim"
AimSwitchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AimSwitchLabel.TextXAlignment = Enum.TextXAlignment.Left
AimSwitchLabel.Font = Enum.Font.SourceSans
AimSwitchLabel.TextSize = 16
AimSwitchLabel.Parent = ContentFrame

local AimSwitchBG = Instance.new("TextButton")
AimSwitchBG.Size = UDim2.new(0, 50, 0, 26)
AimSwitchBG.Position = UDim2.new(0, 240, 0, 17)
AimSwitchBG.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
AimSwitchBG.Text = "OFF"
AimSwitchBG.TextColor3 = Color3.fromRGB(255, 0, 0)
AimSwitchBG.Font = Enum.Font.SourceSansBold
AimSwitchBG.TextSize = 12
AimSwitchBG.Parent = ContentFrame
Instance.new("UICorner", AimSwitchBG).CornerRadius = UDim.new(0, 4)

AimSwitchBG.MouseButton1Click:Connect(function()
    Config.AimEnabled = not Config.AimEnabled
    if Config.AimEnabled then
        AimSwitchBG.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        AimSwitchBG.Text = "ON"
        AimSwitchBG.TextColor3 = Color3.fromRGB(255, 255, 255)
        AimButton.Visible = true
    else
        AimSwitchBG.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        AimSwitchBG.Text = "OFF"
        AimSwitchBG.TextColor3 = Color3.fromRGB(255, 0, 0)
        AimButton.Visible = false
        AimLockActive = false
        AimButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        AimButton.TextColor3 = Color3.fromRGB(255, 0, 0)
        if aimLoopConnection then aimLoopConnection:Disconnect() aimLoopConnection = nil end
        currentTarget = nil
    end
end)

-- [CONFIG BLOQUEAR UI]
local LockUiLabel = Instance.new("TextLabel")
LockUiLabel.Size = UDim2.new(0, 180, 0, 30)
LockUiLabel.Position = UDim2.new(0, 15, 0, 50)
LockUiLabel.BackgroundTransparency = 1
LockUiLabel.Text = "Bloquear UI"
LockUiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
LockUiLabel.TextXAlignment = Enum.TextXAlignment.Left
LockUiLabel.Font = Enum.Font.SourceSans
LockUiLabel.TextSize = 16
LockUiLabel.Parent = ContentFrame

local LockUiToggle = Instance.new("TextButton")
LockUiToggle.Size = UDim2.new(0, 50, 0, 26)
LockUiToggle.Position = UDim2.new(0, 240, 0, 52)
LockUiToggle.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
LockUiToggle.Text = "OFF"
LockUiToggle.TextColor3 = Color3.fromRGB(255, 0, 0)
LockUiToggle.Font = Enum.Font.SourceSansBold
LockUiToggle.TextSize = 14
LockUiToggle.Parent = ContentFrame
Instance.new("UICorner", LockUiToggle).CornerRadius = UDim.new(0, 4)

LockUiToggle.MouseButton1Click:Connect(function()
    Config.UILocked = not Config.UILocked
    if Config.UILocked then
        LockUiToggle.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        LockUiToggle.Text = "ON"
        LockUiToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        LockUiToggle.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        LockUiToggle.Text = "OFF"
        LockUiToggle.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- [OPCIÓN SPY MEJORADA]
local SpyLabel = Instance.new("TextLabel")
SpyLabel.Size = UDim2.new(0, 180, 0, 30)
SpyLabel.Position = UDim2.new(0, 15, 0, 85) 
SpyLabel.BackgroundTransparency = 1
SpyLabel.Text = "Opción Spy"
SpyLabel.TextColor3 = Color3.fromRGB(255, 0, 0) 
SpyLabel.Font = Enum.Font.SourceSansBold 
SpyLabel.TextSize = 18 
SpyLabel.TextXAlignment = Enum.TextXAlignment.Left
SpyLabel.Parent = ContentFrame

local SpyToggle = Instance.new("TextButton")
SpyToggle.Size = UDim2.new(0, 50, 0, 26)
SpyToggle.Position = UDim2.new(0, 240, 0, 87)
SpyToggle.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
SpyToggle.Text = "OFF"
SpyToggle.TextColor3 = Color3.fromRGB(255, 0, 0)
SpyToggle.Font = Enum.Font.SourceSansBold
SpyToggle.TextSize = 14
SpyToggle.Parent = ContentFrame
Instance.new("UICorner", SpyToggle).CornerRadius = UDim.new(0, 4)

SpyToggle.MouseButton1Click:Connect(function()
    Config.SpyEnabled = not Config.SpyEnabled
    if Config.SpyEnabled then
        SpyToggle.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        SpyToggle.Text = "ON"
        SpyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        SpyToggle.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        SpyToggle.Text = "OFF"
        SpyToggle.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- ========================================================
-- NUEVA SECCIÓN: WHITELIST DESPLEGABLE DINÁMICA
-- ========================================================
local WhitelistLabel = Instance.new("TextLabel")
WhitelistLabel.Size = UDim2.new(0, 150, 0, 30)
WhitelistLabel.Position = UDim2.new(0, 15, 0, 125)
WhitelistLabel.BackgroundTransparency = 1
WhitelistLabel.Text = "Whitelist"
WhitelistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
WhitelistLabel.Font = Enum.Font.SourceSansBold
WhitelistLabel.TextSize = 17
WhitelistLabel.TextXAlignment = Enum.TextXAlignment.Left
WhitelistLabel.Parent = ContentFrame

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(0, 110, 0, 28)
DropdownBtn.Position = UDim2.new(0, 180, 0, 126)
DropdownBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DropdownBtn.Text = "Seleccionar v"
DropdownBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
DropdownBtn.Font = Enum.Font.SourceSansBold
DropdownBtn.TextSize = 13
DropdownBtn.Parent = ContentFrame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 4)

-- Contenedor scrolleable de jugadores (ZIndex alto para sobreponerse)
local DropdownFrame = Instance.new("ScrollingFrame")
DropdownFrame.Size = UDim2.new(0, 140, 0, 100)
DropdownFrame.Position = UDim2.new(0, 150, 0, 155)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DropdownFrame.BorderSizePixel = 1
DropdownFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
DropdownFrame.Visible = false
DropdownFrame.ZIndex = 10
DropdownFrame.ScrollBarThickness = 6 -- Ajuste visual opcional para que se vea mejor
DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Se inicializa vacío
DropdownFrame.Parent = ScreenGui 

local UIList = Instance.new("UIListLayout", DropdownFrame)

-- CORRECCIÓN AQUÍ: Forzamos al Canvas a medir EXACTAMENTE lo que midan los elementos sumados
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end)

local function RefreshWhitelistDropdown()
    for _, item in ipairs(DropdownFrame:GetChildren()) do
        if item:IsA("TextButton") then item:Destroy() end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 25)
            item.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            item.BorderSizePixel = 0
            item.Text = player.Name
            item.ZIndex = 11
            
            -- Si ya está en la whitelist se vuelve verde, si no, blanco
            if Config.Whitelist[player.Name] then
                item.TextColor3 = Color3.fromRGB(0, 255, 0)
                item.Font = Enum.Font.SourceSansBold
            else
                item.TextColor3 = Color3.fromRGB(255, 255, 255)
                item.Font = Enum.Font.SourceSans
            end
            item.TextSize = 13
            item.Parent = DropdownFrame
            
            item.MouseButton1Click:Connect(function()
                if Config.Whitelist[player.Name] then
                    Config.Whitelist[player.Name] = nil
                    item.TextColor3 = Color3.fromRGB(255, 255, 255)
                    item.Font = Enum.Font.SourceSans
                else
                    Config.Whitelist[player.Name] = true
                    item.TextColor3 = Color3.fromRGB(0, 255, 0)
                    item.Font = Enum.Font.SourceSansBold
                end
            end)
        end
    end
end

DropdownBtn.MouseButton1Click:Connect(function()
    DropdownFrame.Visible = not DropdownFrame.Visible
    if DropdownFrame.Visible then
        RefreshWhitelistDropdown()
    end
end)

-- Cerrar lista si se cierra el menú principal
MainToggleButton.MouseButton1Click:Connect(function()
    if not MainFrame.Visible then DropdownFrame.Visible = false end
end)

-- ========================================================
-- LÓGICA DE FIJACIÓN (AIMBOT CON FILTRO WHITELIST)
-- ========================================================
local function getClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not Config.Whitelist[player.Name] then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local hrp = char.HumanoidRootPart
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local distance = (Vector2.new(vector.X, vector.Y) - screenCenter).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = hrp
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function startAimTracking()
    if aimLoopConnection then aimLoopConnection:Disconnect() end
    
    aimLoopConnection = RunService.RenderStepped:Connect(function()
        if AimLockActive and currentTarget and currentTarget.Parent and currentTarget.Parent:FindFirstChild("Humanoid") and currentTarget.Parent.Humanoid.Health > 0 and not Config.Whitelist[currentTarget.Parent.Name] then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentTarget.Position)
        else
            AimLockActive = false
            AimButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            AimButton.TextColor3 = Color3.fromRGB(255, 0, 0)
            if aimLoopConnection then aimLoopConnection:Disconnect() aimLoopConnection = nil end
            currentTarget = nil
        end
    end)
end

AimButton.MouseButton1Click:Connect(function()
    if not Config.AimEnabled then return end
    AimLockActive = not AimLockActive
    
    if AimLockActive then
        local target = getClosestPlayerToCenter()
        if target then
            currentTarget = target
            AimButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            AimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            startAimTracking()
        else
            AimLockActive = false
            currentTarget = nil
        end
    else
        AimButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
        AimButton.TextColor3 = Color3.fromRGB(255, 0, 0)
        if aimLoopConnection then aimLoopConnection:Disconnect() aimLoopConnection = nil end
        currentTarget = nil
    end
end)

-- ========================================================
-- RASTREADOR SPY SAFE
-- ========================================================
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if Config.SpyEnabled then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                        local head = player.Character.Head
                        local existingTag = head:FindFirstChild("SpyTag")
                        
                        if not existingTag then
                            local billboard = Instance.new("BillboardGui")
                            billboard.Name = "SpyTag"
                            billboard.Size = UDim2.new(0, 140, 0, 26)
                            billboard.AlwaysOnTop = true
                            billboard.ExtentsOffset = Vector3.new(0, 2.2, 0)
                            billboard.Parent = head
                            
                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text = player.Name
                            label.TextColor3 = Color3.fromRGB(255, 0, 0)
                            label.TextSize = 14
                            label.Font = Enum.Font.SourceSansBold
                            label.Parent = billboard
                        else
                            existingTag.Enabled = true
                        end
                    end
                end
            else
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character and player.Character:FindFirstChild("Head") then
                        local tag = player.Character.Head:FindFirstChild("SpyTag")
                        if tag then tag.Enabled = false end
                    end
                end
            end
        end)
    end
end)
