-- BINTANGHUB V47 | Violence District
-- Source Code Skillcheck (Skeepl) + Toggle

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    AutoSkillEnabled = false, 
    ESP_Survivor = false, ESP_Killer = false, ESP_Gen = false,
    Fullbright = false, NoClip = false
}

-- ==========================================
-- 1. BINTANGHUB UI
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "BINTANGHUB | V47",
   LoadingTitle = "BINTANGHUB",
   LoadingSubtitle = "Real Skillcheck Source",
   KeySystem = false, Theme = "Crimson"
})

local TabSurvivor = Window:CreateTab("Survivor", 4483362458)
local TabESP = Window:CreateTab("ESP & Visuals", 4483362458)

TabSurvivor:CreateSection("Auto Skillcheck (Skeepl)")
TabSurvivor:CreateToggle({Name = "Enable Auto Skillcheck", CurrentValue = false, Callback = function(v) 
    Config.AutoSkillEnabled = v 
end})

TabESP:CreateSection("Player ESP")
TabESP:CreateToggle({Name = "ESP Survivor (Hijau)", CurrentValue = false, Callback = function(v) Config.ESP_Survivor = v end})
TabESP:CreateToggle({Name = "ESP Killer (Merah)", CurrentValue = false, Callback = function(v) Config.ESP_Killer = v end})

TabESP:CreateSection("Visuals")
TabESP:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) 
    Config.Fullbright = v
    Lighting.Brightness = v and 3 or 1
    Lighting.ClockTime = v and 14 or 0
end})

-- ==========================================
-- 2. AUTO SKILLCHECK LOGIC (SOURCE CODE SKEEPL)
-- ==========================================
-- Logika di bawah ini diambil dari source code open-source 'skeepl'
-- Dia ngecek properti 'Rotation' dari GUI jarum, bukan nebak delay.

local vim = game:GetService("VirtualInputManager")
local isHitting = false

local function GetSkillcheckFrame()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    -- Cari Frame/ImageLabel yang biasanya jadi wadah skillcheck
    for _, gui in pairs(pg:GetDescendants()) do
        if (gui.Name:lower():find("skill") or gui.Name:lower():find("check") or gui.Name:lower():find("minigame")) and gui.Visible then
            return gui
        end
    end
    return nil
end

local function CheckForSkillcheck()
    if not Config.AutoSkillEnabled or isHitting then return end
    
    local skillGui = GetSkillcheckFrame()
    if not skillGui then return end
    
    -- Cari jarum di dalam GUI (biasanya ImageLabel yang muter)
    for _, obj in pairs(skillGui:GetDescendants()) do
        if obj:IsA("ImageLabel") then
            -- Skeepl ngecek apakah jarum ada di posisi tengah (Rotation mendekati 0 / 180 / 360)
            -- Karena jarum muter, kita cek nilai Rotation-nya
            local rot = math.abs(obj.Rotation)
            
            -- Toleransi sudut (misal 10 derajat dari tengah)
            if rot < 10 or rot > 350 or (rot > 170 and rot < 190) then
                isHitting = true
                vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                task.wait(0.5)
                isHitting = false
                break
            end
        end
    end
end

-- ==========================================
-- 3. ESP RENDER
-- ==========================================
local espCache = {}
local function ApplyHighlight(obj, color)
    if not obj then return end
    local hl = Instance.new("Highlight")
    hl.Name = "BH_Highlight"
    hl.Adornee = obj
    hl.FillColor = color
    hl.FillTransparency = 0.4
    hl.OutlineColor = color
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    return hl
end

local function IsKiller(plr)
    local char = plr.Character
    if not char then return false end
    if plr.Team and (plr.Team.Name:lower():find("killer")) then return true end
    if char:FindFirstChildWhichIsA("Tool") then return true end
    return false
end

RunService.RenderStepped:Connect(function()
    CheckForSkillcheck()

    -- Player ESP
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local isKiller = IsKiller(plr)
                local active = (isKiller and Config.ESP_Killer) or (not isKiller and Config.ESP_Survivor)
                
                if active then
                    local color = isKiller and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(40, 255, 40)
                    if not espCache[plr] or not espCache[plr].Parent then espCache[plr] = ApplyHighlight(char, color) end
                    espCache[plr].Enabled = true
                elseif espCache[plr] then 
                    espCache[plr].Enabled = false 
                end
            end
        end
    end

    -- Object ESP (Generator)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            local isGen = Config.ESP_Gen and (n:find("gen") or n:find("fuse") or n:find("repair"))
            if isGen then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    if not espCache[obj] then espCache[obj] = ApplyHighlight(obj, Color3.fromRGB(255, 255, 0)) end
                    espCache[obj].Enabled = true
                end
            elseif espCache[obj] and not isGen then
                if espCache[obj]:IsA("Highlight") then espCache[obj].Enabled = false end
            end
        end
    end
end)

-- Visuals
task.spawn(function()
    while task.wait(0.1) do
        if Config.Fullbright then Lighting.Brightness = 3; Lighting.ClockTime = 14 end
    end
end)

print("[BINTANGHUB V47] Source Skillcheck Injected.")
