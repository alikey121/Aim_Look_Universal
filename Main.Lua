local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local Config = {
    AimEnabled = false,  -- CORREGIDO: Empieza desactivado     
    FOVSize = 150,             
    ShowFOV = false,          
    Whitelist = {},       
    UILocked = false,
    SpyEnabled = false 
}

local LookActive = false
local currentLookTarget = nil
local DropdownConnections = {}
local SpyConnections = {} 

if CoreGui:FindFirstChild("JsLikeBetaMenu") then
    CoreGui.JsLikeBetaMenu:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JsLikeBetaMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true -- CORRECCIÓN CRUCIAL: Centra todo ignorando el desfase de Roblox
ScreenGui.Parent = CoreGui

-- PUNTITO CENTRAL (REFERENCIA DE MIRA - CORREGIDO A 4x4)
local CenterDot = Instance.new("Frame")
CenterDot.Name = "CenterDot"
CenterDot.AnchorPoint = Vector2.new(0.5, 0.5)
CenterDot.Position = UDim2.new(0.5, 0, 0.5, 0)
CenterDot.Size = UDim2.new(0, 4, 0, 4) -- Ajustado a 4x4 píxeles como pediste
CenterDot.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
CenterDot.BorderSizePixel = 0
CenterDot.Visible = false
CenterDot.Parent = ScreenGui

Instance.new("UICorner", CenterDot).CornerRadius = UDim.new(1, 0) 

local DotStroke = Instance.new("UIStroke")
DotStroke.Color = Color3.fromRGB(255, 30, 30) 
DotStroke.Thickness = 1
DotStroke.Parent = CenterDot

-- Capa Base FOV: Sombra Negra
local FOVCircleBlack = Instance.new("Frame")
FOVCircleBlack.Name = "FOVCircleBlack"
FOVCircleBlack.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircleBlack.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircleBlack.BackgroundTransparency = 1
FOVCircleBlack.Visible = false
FOVCircleBlack.Parent = ScreenGui
Instance.new("UICorner", FOVCircleBlack).CornerRadius = UDim.new(1, 0)

local StrokeBlack = Instance.new("UIStroke")
StrokeBlack.Color = Color3.fromRGB(0, 0, 0)
StrokeBlack.Thickness = 3.5
StrokeBlack.Parent = FOVCircleBlack

-- Capa Superior FOV: Línea Neón Roja
local FOVCircleRed = Instance.new("Frame")
FOVCircleRed.Name = "FOVCircleRed"
FOVCircleRed.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircleRed.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircleRed.BackgroundTransparency = 1
FOVCircleRed.Visible = false
FOVCircleRed.Parent = ScreenGui
Instance.new("UICorner", FOVCircleRed).CornerRadius = UDim.new(1, 0)

local StrokeRed = Instance.new("UIStroke")
StrokeRed.Color = Color3.fromRGB(255, 30, 30)
StrokeRed.Thickness = 1.5
StrokeRed.Parent = FOVCircleRed

local function updateFOVVisual()
    local diameter = Config.FOVSize * 2
    
    FOVCircleBlack.Size = UDim2.new(0, diameter, 0, diameter)
    FOVCircleBlack.Visible = Config.ShowFOV
    
    FOVCircleRed.Size = UDim2.new(0, diameter, 0, diameter)
    FOVCircleRed.Visible = Config.ShowFOV
    
    CenterDot.Visible = Config.ShowFOV
end

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

-- Botones circulares
local function createCircularButton(name, pos, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 50, 50)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.Active = true
    btn.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) 
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    makeMobileDraggable(btn)
    return btn
end

local MainToggleButton = createCircularButton("Js", UDim2.new(0, 20, 0, 150), "Js")
local LookButton = createCircularButton("Look", UDim2.new(0, 20, 0, 220), "Look")

LookButton.Size = UDim2.new(0, 60, 0, 60)
LookButton.Visible = false -- CORREGIDO: Empieza totalmente oculto en la ejecución

-- Panel Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 310) 
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(230, 0, 0)
PanelStroke.Thickness = 2
PanelStroke.Parent = MainFrame

-- Barra superior
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 12)

local LineFix = Instance.new("Frame")
LineFix.Size = UDim2.new(1, 0, 0, 10)
LineFix.Position = UDim2.new(0, 0, 1, -10)
LineFix.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
LineFix.BorderSizePixel = 0
LineFix.Parent = TabBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Js Like Beta  //  Panel"
TitleLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TabBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -40)
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Lógica del ESP (Spy)
local function createSpyTag(player)
    if player == LocalPlayer then return end
    
    local function setupCharacter(char)
        if char:FindFirstChild("SpyTag") then char.SpyTag:Destroy() end
        local head = char:WaitForChild("Head", 5)
        if not head then return end
        
        local bb = Instance.new("BillboardGui")
        bb.Name = "SpyTag"
        bb.Size = UDim2.new(0, 150, 0, 30)
        bb.AlwaysOnTop = true
        bb.Adornee = head
        bb.StudsOffset = Vector3.new(0, 1.2, 0) 
        bb.Parent = char
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = player.Name
        text.TextColor3 = Color3.fromRGB(255, 50, 50) 
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.Parent = bb
        
        -- AÑADIDO: Contorno negro para legibilidad
        local textStroke = Instance.new("UIStroke")
        textStroke.Color = Color3.fromRGB(0, 0, 0)
        textStroke.Thickness = 2
        textStroke.Parent = text
    end

    if player.Character then task.spawn(setupCharacter, player.Character) end
    local conn = player.CharacterAdded:Connect(setupCharacter)
    SpyConnections[player] = conn
end

local function removeSpyTags()
    for player, conn in pairs(SpyConnections) do
        if conn then conn:Disconnect() end
        if player.Character and player.Character:FindFirstChild("SpyTag") then
            player.Character.SpyTag:Destroy()
        end
    end
    table.clear(SpyConnections)
end

-- Creador de Toggles
local function createToggle(labelName, yPos, startState, callback)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 30)
    lbl.Position = UDim2.new(0, 20, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelName
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = ContentFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 22)
    btn.Position = UDim2.new(0, 265, 0, yPos + 4)
    btn.BackgroundColor3 = startState and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(30, 30, 30)
    btn.Text = startState and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = ContentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = startState and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(60, 60, 60)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local newState = btn.Text == "OFF"
        btn.Text = newState and "ON" or "OFF"
        btn.BackgroundColor3 = newState and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(30, 30, 30)
        btnStroke.Color = newState and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(60, 60, 60)
        callback(newState)
    end)
    return btn
end

-- Toggles del Panel
createToggle("Bloquear UI", 10, false, function(state)
    Config.UILocked = state
end)

createToggle("Spy (ESP)", 45, false, function(state)
    Config.SpyEnabled = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do createSpyTag(p) end
        table.insert(DropdownConnections, Players.PlayerAdded:Connect(createSpyTag))
    else
        removeSpyTags()
        for _, conn in ipairs(DropdownConnections) do if conn then conn:Disconnect() end end
        table.clear(DropdownConnections)
    end
end)

-- CORREGIDO: Ahora inicia en false para que empiece limpio al ejecutar
createToggle("Habilitar Botón Look", 80, false, function(state)
    Config.AimEnabled = state
    LookButton.Visible = state
end)

createToggle("Mostrar Círculo FOV", 115, false, function(state)
    Config.ShowFOV = state
    updateFOVVisual()
end)

-- Slider de Radio FOV
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0, 120, 0, 20)
SliderLabel.Position = UDim2.new(0, 20, 0, 160)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "Radio FOV: 150"
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.TextSize = 13
SliderLabel.Parent = ContentFrame

local SliderBG = Instance.new("Frame")
SliderBG.Size = UDim2.new(0, 140, 0, 6)
SliderBG.Position = UDim2.new(0, 170, 0, 167)
SliderBG.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SliderBG.Parent = ContentFrame
Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.35, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(230, 0, 0)
SliderFill.Parent = SliderBG
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderBtn = Instance.new("TextButton")
SliderBtn.Size = UDim2.new(0, 14, 0, 14)
SliderBtn.Position = UDim2.new(0.35, -7, 0.5, -7)
SliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderBtn.Text = ""
SliderBtn.Parent = SliderBG
Instance.new("UICorner", SliderBtn).CornerRadius = UDim.new(1, 0)

local draggingSlider = false
SliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = input.Position.X
        local sliderX = SliderBG.AbsolutePosition.X
        local sliderWidth = SliderBG.AbsoluteSize.X
        local percentage = math.clamp((mousePos - sliderX) / sliderWidth, 0, 1)
        
        SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        SliderBtn.Position = UDim2.new(percentage, -7, 0.5, -7)
        
        Config.FOVSize = math.round(percentage * 390) + 10
        SliderLabel.Text = "Radio FOV: " .. tostring(Config.FOVSize)
        updateFOVVisual()
    end
end)

-- Botón Principal "Friends v"
local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(0, 140, 0, 28)
DropdownBtn.Position = UDim2.new(0, 170, 0, 200)
DropdownBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DropdownBtn.Text = "Friends v"
DropdownBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.TextSize = 13
DropdownBtn.Parent = ContentFrame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 6)

local dropStroke = Instance.new("UIStroke")
dropStroke.Color = Color3.fromRGB(60, 20, 20)
dropStroke.Thickness = 1
dropStroke.Parent = DropdownBtn

-- Ventana Desplegable del Dropdown
local DropdownFrame = Instance.new("ScrollingFrame")
DropdownFrame.Size = UDim2.new(0, 140, 0, 150) -- Un poco más alta para ver mejor la lista
DropdownFrame.Position = UDim2.new(0.5, 185, 0.5, -75) -- CORRECCIÓN: Posicionada a la derecha del panel
DropdownFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
DropdownFrame.BorderSizePixel = 0
DropdownFrame.Visible = false
DropdownFrame.ZIndex = 10
DropdownFrame.ScrollBarThickness = 4
DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0) 
DropdownFrame.Parent = ScreenGui 

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(200, 0, 0)
frameStroke.Thickness = 1
frameStroke.Parent = DropdownFrame
Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)

local UIList = Instance.new("UIListLayout", DropdownFrame)
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end)

-- Función para refrescar la lista de jugadores
local function RefreshWhitelistDropdown()
    for _, item in ipairs(DropdownFrame:GetChildren()) do if item:IsA("TextButton") then item:Destroy() end end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 25)
            item.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            item.BorderSizePixel = 0
            item.Text = " " .. player.Name
            item.ZIndex = 11
            item.TextColor3 = Config.Whitelist[player.Name] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
            item.Font = Config.Whitelist[player.Name] and Enum.Font.GothamBold or Enum.Font.Gotham
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.TextSize = 11
            item.Parent = DropdownFrame

            item.MouseButton1Click:Connect(function()
                if Config.Whitelist[player.Name] then
                    Config.Whitelist[player.Name] = nil
                    item.TextColor3 = Color3.fromRGB(200, 200, 200)
                    item.Font = Enum.Font.Gotham
                else
                    Config.Whitelist[player.Name] = true
                    item.TextColor3 = Color3.fromRGB(0, 255, 100)
                    item.Font = Enum.Font.GothamBold
                end
            end)
        end
    end
end

DropdownBtn.MouseButton1Click:Connect(function()
    DropdownFrame.Visible = not DropdownFrame.Visible
    if DropdownFrame.Visible then RefreshWhitelistDropdown() end
end)

MainToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if not MainFrame.Visible then 
        DropdownFrame.Visible = false 
    end
end)

-- Lógica de adquisición de objetivos
local function getTargetInFOV()
    local closestPart = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not Config.Whitelist[player.Name] then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and (not char:FindFirstChild("BodyEffects") or (char:FindFirstChild("BodyEffects") and not char.BodyEffects:FindFirstChild("K.O") or char.BodyEffects["K.O"].Value == false)) then
                local targetPart = char:FindFirstChild("Head")
                if targetPart then
                    local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(vector.X, vector.Y) - screenCenter).Magnitude
                        
                        if distance <= Config.FOVSize and distance < shortestDistance then
                            shortestDistance = distance
                            closestPart = targetPart
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

-- Sistema Look (Aimlock)
RunService.RenderStepped:Connect(function()
    if LookActive and currentLookTarget and currentLookTarget.Parent and currentLookTarget.Parent:FindFirstChild("Humanoid") and currentLookTarget.Parent.Humanoid.Health > 0 then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentLookTarget.Position)
    end
end)

LookButton.MouseButton1Click:Connect(function()
    LookActive = not LookActive
    if LookActive then
        local target = getTargetInFOV() 
        if target then
            currentLookTarget = target
            LookButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
            LookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            LookActive = false
            LookButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            LookButton.TextColor3 = Color3.fromRGB(255, 50, 50)
            currentLookTarget = nil
        end
    else
        LookButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        LookButton.TextColor3 = Color3.fromRGB(255, 50, 50)
        currentLookTarget = nil
    end
end)

updateFOVVisual()