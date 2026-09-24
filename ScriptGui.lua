-- SPEED GLITCH MINI GUI – CLEAN + BOOST (Executor Safe)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- CONFIG
local DEFAULT_WALKSPEED = 16
local BASE_GLITCH_SPEED = 200
local BOOST_GLITCH_SPEED = 500
local BOOST_JUMP = 100
local BOOST_TIME = 8

local enabled = true
local boosting = false
local conn

-- limpar GUI antiga
pcall(function()
    CoreGui.SpeedMiniUI:Destroy()
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedMiniUI"
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 230, 0, 150)
frame.Position = UDim2.new(0.5, -115, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.Active = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- DRAG
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = frame.Position
    end
end)
frame.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- TOP BAR
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1, 0, 0, 32)
top.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Speed Glitch"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- BOTÕES TOP
local function topButton(txt, x, color)
    local b = Instance.new("TextButton", top)
    b.Size = UDim2.new(0, 24, 0, 24)
    b.Position = UDim2.new(1, x, 0, 4)
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = color
    b.TextSize = 14
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    return b
end

local minimize = topButton("-", -54, Color3.fromRGB(90,90,90))
local close = topButton("X", -28, Color3.fromRGB(170,60,60))

-- BOTÕES PRINCIPAIS
local function mainButton(text, y, color)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, -24, 0, 36)
    b.Position = UDim2.new(0, 12, 0, y)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 15
    b.BackgroundColor3 = color
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    return b
end

local toggle = mainButton("SPEED: ON", 46, Color3.fromRGB(0,120,255))
local boostBtn = mainButton("BOOST (F)", 90, Color3.fromRGB(255,120,0))

-- MINIMIZAR
local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggle.Visible = not minimized
    boostBtn.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,230,0,32) or UDim2.new(0,230,0,150)
end)

-- FECHAR
close.MouseButton1Click:Connect(function()
    if conn then conn:Disconnect() end
    gui:Destroy()
end)

-- FUNÇÃO PARA ATUALIZAR O BOTÃO DE TOGGLE
local function updateToggleButton()
    toggle.Text = enabled and "SPEED: ON" or "SPEED: OFF"
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(0,120,255) or Color3.fromRGB(150,60,60)
end

-- TOGGLE SPEED (BOTÃO)
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    updateToggleButton()
end)

-- TOGGLE SPEED (TECLA R) - NOVA FUNCIONALIDADE
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        updateToggleButton()
        
        -- Feedback visual rápido
        local originalColor = toggle.BackgroundColor3
        toggle.BackgroundColor3 = Color3.new(1, 1, 1) -- Fica branco
        task.delay(0.1, function()
            updateToggleButton()
        end)
    end
end)

-- FUNÇÃO DO CONTADOR
local function startCountdown()
    local timeLeft = BOOST_TIME
    local originalText = "BOOST (F)"
    local originalColor = boostBtn.BackgroundColor3
    
    -- Mudar cor para indicar que está ativo
    boostBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
    
    -- Criar loop do contador
    local countdownConnection
    countdownConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if boosting then
            timeLeft = timeLeft - deltaTime
            
            if timeLeft <= 0 then
                -- Resetar botão
                boostBtn.Text = originalText
                boostBtn.BackgroundColor3 = originalColor
                boosting = false
                countdownConnection:Disconnect()
            else
                -- Atualizar texto com o tempo restante (arredondado para 1 casa decimal)
                boostBtn.Text = string.format("BOOST: %.1fs", math.max(0, timeLeft))
            end
        else
            -- Se o boost foi desativado manualmente
            boostBtn.Text = originalText
            boostBtn.BackgroundColor3 = originalColor
            if countdownConnection then
                countdownConnection:Disconnect()
            end
        end
    end)
end

-- BOOST FUNÇÃO
local function activateBoost(hum)
    if boosting then return end
    boosting = true

    local oldJump = hum.JumpPower
    hum.JumpPower = BOOST_JUMP
    
    -- Iniciar contador
    startCountdown()

    task.spawn(function()
        task.wait(BOOST_TIME)
        if boosting then
            hum.JumpPower = oldJump
            boosting = false
        end
    end)
end

-- BOOST (BOTÃO)
boostBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        activateBoost(char.Humanoid)
    end
end)

-- BOOST (TECLA F)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            activateBoost(char.Humanoid)
        end
    end
end)

-- SPEED GLITCH FAKE
local function setup(char)
    local hum = char:WaitForChild("Humanoid")
    if conn then conn:Disconnect() end

    conn = RunService.RenderStepped:Connect(function()
        if not enabled then 
            hum.WalkSpeed = DEFAULT_WALKSPEED
            return 
        end

        local state = hum:GetState()
        local inAir = state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall

        local speed = boosting and BOOST_GLITCH_SPEED or BASE_GLITCH_SPEED

        if inAir and hum.MoveDirection.Magnitude > 0 then
            hum.WalkSpeed = speed
            if boosting then
                hum.JumpPower = BOOST_JUMP
            end
        else
            hum.WalkSpeed = DEFAULT_WALKSPEED
            if not boosting and hum.JumpPower == BOOST_JUMP then
                hum.JumpPower = 50
            end
        end
    end)
end

-------------------------------------------------------------
-- Setup inicial
player.CharacterAdded:Connect(setup)
if player.Character then 
    setup(player.Character) 
end

-- Notificação inicial
print("Speed Glitch Carregado!")
print("[R] - Ativar/Desativar Speed")
print("[F] - Ativar Boost (8s)")
print("Clique e arraste a GUI para mover")

-- ============================================
-- SHADERS LOADER - COM CONFIRMAÇÃO
-- Igual ao shaders.lua mas com popup de confirmação
-- ============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- URL do script de shaders (MESMO DO SEU EXEMPLO)
local SHADERS_SCRIPT_URL = "https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua"

-- ============================================
-- FUNÇÃO PARA EXECUTAR OS SHADERS
-- ============================================
local function executeShadersScript()
    print("🔄 Carregando shaders do GitHub...")
    
    -- EXATAMENTE O MESMO CÓDIGO DO SEU EXEMPLO
    loadstring(game:HttpGet(SHADERS_SCRIPT_URL))()
    
    print("✅ Shaders executados com sucesso!")
end

-- ============================================
-- JANELA DE CONFIRMAÇÃO
-- ============================================
local function showShadersConfirmation()
    -- Remover janelas antigas
    if player.PlayerGui:FindFirstChild("ShadersConfirmationGUI") then
        player.PlayerGui.ShadersConfirmationGUI:Destroy()
    end
    
    -- Criar GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShadersConfirmationGUI"
    gui.Parent = player.PlayerGui
    gui.ResetOnSpawn = false
    
    -- Overlay escuro
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.Parent = gui
    
    -- Janela principal
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.new(0, 450, 0, 300)
    mainWindow.Position = UDim2.new(0.5, -225, 0.5, -150)
    mainWindow.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainWindow.BorderSizePixel = 0
    mainWindow.Parent = gui
    
    -- Título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleBar.Parent = mainWindow
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "⚠️ SHADERS"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 100)
    titleText.Font = Enum.Font.GothamBlack
    titleText.TextSize = 22
    titleText.Parent = titleBar
    
    -- Ícone
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 80, 0, 80)
    icon.Position = UDim2.new(0.5, -40, 0.2, -40)
    icon.Image = "rbxassetid://3926305904" -- Ícone de efeitos
    icon.ImageRectOffset = Vector2.new(964, 444)
    icon.ImageRectSize = Vector2.new(36, 36)
    icon.BackgroundTransparency = 1
    icon.Parent = mainWindow
    
    -- Mensagem principal
    local messageText = Instance.new("TextLabel")
    messageText.Name = "MessageText"
    messageText.Size = UDim2.new(1, -40, 0, 80)
    messageText.Position = UDim2.new(0, 20, 0, 100)
    messageText.BackgroundTransparency = 1
    messageText.Text = "DESEJA EXECUTAR SHADERS?\n\SHADERS aplicará efeitos visuais avançados no jogo."
    messageText.TextColor3 = Color3.fromRGB(200, 200, 255)
    messageText.Font = Enum.Font.Gotham
    messageText.TextSize = 18
    messageText.TextWrapped = true
    messageText.Parent = mainWindow
    
    -- Aviso de segurança
    local warningText = Instance.new("TextLabel")
    warningText.Name = "WarningText"
    warningText.Size = UDim2.new(1, -40, 0, 40)
    warningText.Position = UDim2.new(0, 20, 0, 180)
    warningText.BackgroundTransparency = 1
    warningText.Text = "⚠️ AVISO: pode não ser seguro OBS: maioria dos casos nunca ocorreu mal funcionamento"
    warningText.TextColor3 = Color3.fromRGB(255, 100, 100)
    warningText.Font = Enum.Font.Gotham
    warningText.TextSize = 12
    warningText.TextWrapped = true
    warningText.Parent = mainWindow
    
    -- Container dos botões
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -40, 0, 60)
    buttonContainer.Position = UDim2.new(0, 20, 1, -70)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mainWindow
    
    -- Botão NÃO (Esquerda)
    local btnNo = Instance.new("TextButton")
    btnNo.Name = "BtnNo"
    btnNo.Size = UDim2.new(0, 160, 0, 50)
    btnNo.Position = UDim2.new(0, 0, 0, 0)
    btnNo.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnNo.TextColor3 = Color3.new(1, 1, 1)
    btnNo.Text = "❌ NÃO"
    btnNo.Font = Enum.Font.GothamBold
    btnNo.TextSize = 18
    btnNo.Parent = buttonContainer
    
    -- Botão SIM (Direita)
    local btnYes = Instance.new("TextButton")
    btnYes.Name = "BtnYes"
    btnYes.Size = UDim2.new(0, 160, 0, 50)
    btnYes.Position = UDim2.new(1, -160, 0, 0)
    btnYes.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    btnYes.TextColor3 = Color3.new(1, 1, 1)
    btnYes.Text = "✅ SIM"
    btnYes.Font = Enum.Font.GothamBold
    btnYes.TextSize = 18
    btnYes.Parent = buttonContainer
    
    -- ============================================
    -- FUNCIONALIDADES DOS BOTÕES
    -- ============================================
    
    -- Função para fechar a janela
    local function closeWindow()
        TweenService:Create(mainWindow, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -225, -1, -150)
        }):Play()
        
        TweenService:Create(overlay, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.3)
        gui:Destroy()
    end
    
    -- Botão NÃO
    btnNo.MouseButton1Click:Connect(function()
        print("❌ Shaders cancelados pelo usuário")
        closeWindow()
    end)
    
    -- Botão SIM
    btnYes.MouseButton1Click:Connect(function()
        print("✅ Executando shaders...")
        
        -- Mudar texto do botão
        btnYes.Text = "🔄 CARREGANDO..."
        btnYes.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        
        -- Fechar janela
        closeWindow()
        
        -- Executar o script de shaders
        task.wait(0.5)
        
        local success, errorMessage = pcall(function()
            executeShadersScript()
        end)
        
        if not success then
            warn("❌ Erro ao executar shaders:", errorMessage)
            
            -- Mostrar erro
            local errorGui = Instance.new("ScreenGui")
            errorGui.Parent = player.PlayerGui
            
            local errorFrame = Instance.new("Frame")
            errorFrame.Size = UDim2.new(0, 300, 0, 150)
            errorFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
            errorFrame.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
            errorFrame.Parent = errorGui
            
            local errorText = Instance.new("TextLabel")
            errorText.Size = UDim2.new(1, -20, 1, -20)
            errorText.Position = UDim2.new(0, 10, 0, 10)
            errorText.Text = "❌ ERRO\n\nFalha ao carregar shaders:\n" .. tostring(errorMessage)
            errorText.TextColor3 = Color3.new(1, 1, 1)
            errorText.Font = Enum.Font.Gotham
            errorText.TextSize = 14
            errorText.TextWrapped = true
            errorText.Parent = errorFrame
            
            task.wait(3)
            errorGui:Destroy()
        end
    end)
    
    -- Efeitos hover
    btnNo.MouseEnter:Connect(function()
        TweenService:Create(btnNo, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(220, 70, 70)
        }):Play()
    end)
    
    btnNo.MouseLeave:Connect(function()
        TweenService:Create(btnNo, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        }):Play()
    end)
    
    btnYes.MouseEnter:Connect(function()
        TweenService:Create(btnYes, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(70, 220, 70)
        }):Play()
    end)
    
    btnYes.MouseLeave:Connect(function()
        TweenService:Create(btnYes, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        }):Play()
    end)
    
    -- Animar entrada
    mainWindow.Position = UDim2.new(0.5, -225, -1, -150)
    overlay.BackgroundTransparency = 1
    
    TweenService:Create(overlay, TweenInfo.new(0.5), {
        BackgroundTransparency = 0.6
    }):Play()
    
    TweenService:Create(mainWindow, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -225, 0.5, -150)
    }):Play()
end

-- ============================================
-- INICIAR TUDO
-- ============================================
print("=========================================")
print("🎨 PShade Ultimate - Loader")
print("📋 Versão: 1.0")
print("🌐 URL: " .. SHADERS_SCRIPT_URL)
print("=========================================")

-- Mostrar confirmação automaticamente
showShadersConfirmation()

-- Opcional: Também criar atalho no chat
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "PShade Ultimate",
    Text = "Janela de confirmação aberta!",
    Duration = 3,
    Icon = "rbxassetid://3926305904"
})
