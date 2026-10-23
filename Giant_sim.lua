-- ===== CONFIG =====
getgenv().BtnFarm = getgenv().BtnFarm or {}
local C = getgenv().BtnFarm
C.Enabled    = true
C.Interval   = 30
C.Prompts    = { "", "", "", "" }  -- se llenan desde la UI
C.SettleTime = 0.25
C.StepDelay  = 0.3
C.HeightOff  = 3
C.UseFire    = false
-- ==================

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

getgenv().BtnFarmRun = (getgenv().BtnFarmRun or 0) + 1
local runId = getgenv().BtnFarmRun

local function resolvePath(path)
    local obj = game
    for seg in string.gmatch(path, "[^%.]+") do
        local nxt = obj:FindFirstChild(seg)
        if not nxt and obj == game then
            local ok, svc = pcall(game.GetService, game, seg)
            nxt = ok and svc or nil
        end
        if not nxt then return nil end
        obj = nxt
    end
    return obj
end

local function getPromptPos(prompt)
    local p = prompt.Parent
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("Model") then return p:GetPivot().Position end
    return nil
end

local function getHRP()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function activate(prompt)
    if C.UseFire and fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.05)
        prompt:InputHoldEnd()
    end
end

local function cycle()
    local hrp = getHRP()
    if not hrp then return end
    local origin = hrp.CFrame

    for i, path in ipairs(C.Prompts) do
        if runId ~= getgenv().BtnFarmRun then break end
        if path and path ~= "" then
            local prompt = resolvePath(path)
            if prompt and prompt:IsA("ProximityPrompt") then
                local pos = getPromptPos(prompt)
                hrp = getHRP()
                if not (pos and hrp) then break end
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, C.HeightOff, 0))
                task.wait(C.SettleTime)
                activate(prompt)
                task.wait(C.StepDelay)
            else
                warn("[BtnFarm] Prompt " .. i .. " no encontrado: " .. tostring(path))
            end
        end
    end

    local hrp2 = getHRP()
    if hrp2 then hrp2.CFrame = origin end
end

task.spawn(function()
    while runId == getgenv().BtnFarmRun do
        local t = 0
        while t < C.Interval and runId == getgenv().BtnFarmRun do
            task.wait(0.25)
            t += 0.25
        end
        if runId ~= getgenv().BtnFarmRun then break end
        if C.Enabled then
            local ok, err = pcall(cycle)
            if not ok then warn("[BtnFarm] " .. tostring(err)) end
        end
    end
end)

-- ===== UI (Obsidian) =====
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Button Farm",
    Footer = "v1",
    ToggleKeybind = Enum.KeyCode.RightControl,
})

local Tab = Window:AddTab("Main", "house")
local Box = Tab:AddLeftGroupbox("Auto botón")

Box:AddToggle("BtnFarm_Enabled", {
    Text = "Activar",
    Default = C.Enabled,
    Callback = function(v) C.Enabled = v end,
})

Box:AddSlider("BtnFarm_Interval", {
    Text = "Intervalo (s)",
    Default = C.Interval, Min = 5, Max = 600, Rounding = 0,
    Callback = function(v) C.Interval = v end,
})

Box:AddSlider("BtnFarm_Settle", {
    Text = "Espera tras TP (s)",
    Default = C.SettleTime, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) C.SettleTime = v end,
})

Box:AddSlider("BtnFarm_Step", {
    Text = "Espera entre botones (s)",
    Default = C.StepDelay, Min = 0, Max = 2, Rounding = 2,
    Callback = function(v) C.StepDelay = v end,
})

Box:AddToggle("BtnFarm_UseFire", {
    Text = "Usar fireproximityprompt",
    Default = C.UseFire,
    Callback = function(v) C.UseFire = v end,
})

for i = 1, 4 do
    Box:AddInput("BtnFarm_Path" .. i, {
        Text = "Botón " .. i,
        Default = C.Prompts[i] or "",
        Placeholder = "Workspace.….ProximityPrompt",
        Finished = true,
        Callback = function(v) C.Prompts[i] = v end,
    })
end

Box:AddButton({
    Text = "Probar ahora",
    Func = function()
        task.spawn(function()
            local ok, err = pcall(cycle)
            if not ok then warn("[BtnFarm] " .. tostring(err)) end
        end)
    end,
})

Library:OnUnload(function()
    getgenv().BtnFarmRun = (getgenv().BtnFarmRun or 0) + 1
end)