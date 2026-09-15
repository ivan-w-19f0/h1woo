-- ====================== EBY V TYZ ======================
local _S = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

_S.MOUSE_BUTTON_TYPES = {
    [Enum.UserInputType.MouseButton1] = "LMB",
    [Enum.UserInputType.MouseButton2] = "RMB",
    [Enum.UserInputType.MouseButton3] = "MMB",
}
MOUSE_BUTTON_TYPES = _S.MOUSE_BUTTON_TYPES

function getBindName(b)
    if not b then return "Не назначен" end
    if MOUSE_BUTTON_TYPES[b] then return MOUSE_BUTTON_TYPES[b] end
    if typeof(b) == "EnumItem" and b.EnumType == Enum.KeyCode then return b.Name end
    return tostring(b)
end
function isBindMatch(b, i)
    if not b then return false end
    if MOUSE_BUTTON_TYPES[b] then return i.UserInputType == b end
    return i.KeyCode == b
end

_S.MOD_USERNAMES = { ['boomffa_mod']=true, ['boomffaadmin']=true, ['boomffa_admin']=true, ['boomffa_staff']=true, ['boom_moderator']=true, ['boomgamemod']=true }
_S.MOD_SYMBOLS = { '✅','☑️','👑','⭐','🛡️','✨','🌟','⚡','🔱','💎','🏆','🎖️' }
_S.MOD_GROUP_IDS = { 925309458, 33991282, 7431102 }
_S.MOD_MIN_RANK = 50
_S.alertSoundId = 6753645454
_S.activeESP = {}
_S.MOD_STORAGE_FILE = "ukussia_mods_list.txt"
_S.savedMods = {}
_S.PlayerRoles = {}

local function loadSavedMods()
    pcall(function()
        if readfile then
            local c = readfile(_S.MOD_STORAGE_FILE)
            if c and c ~= "" then _S.savedMods = HttpService:JSONDecode(c) end
        end
    end)
end
local function saveMods()
    pcall(function()
        if writefile then writefile(_S.MOD_STORAGE_FILE, HttpService:JSONEncode(_S.savedMods)) end
    end)
end
loadSavedMods()
local function addModToSaved(u, n, r)
    if not _S.savedMods[u] then
        _S.savedMods[u] = { name = n, role = r or "Reported", date = os.date("%Y-%m-%d %H:%M") }
        saveMods() return true
    end
    return false
end

_S.WeaponsEnabled = { ["[Knife]"]=false, ["[Shotgun]"]=true, ["[TacticalShotgun]"]=true, ["[Revolver]"]=true, ["[Double-Barrel SG]"]=true, ["[Pistol]"]=true, ["[SMG]"]=true, ["[Rifle]"]=true, ["[Sniper]"]=true, ["[Deagle]"]=true }
_S.AmmoName = "Ammo"
_S.Monitoring = false
_S.StarterPlayers = {}
_S.LastAmmoPerTool = {}
_S.AutoShootRandomDelay = true
_S.AutoShootMinDelay = 0.05
_S.AutoShootMaxDelay = 0.15
_S.AutoShootBurstShots = 1
_S.AutoShootBurstDelay = 0.02
_S.DelayBeforeShot = 0.01

_S.AimLockLockedTarget = nil
_S.AimLockEnabled = false
_S.AimLockSmooth = 10
_S.AimLockConnection = nil
_S.AimLockBindKey = nil
_S.AimLockBindMode = "Toggle"
_S.WaitingForAimLockBind = false
_S.AimLockFOVEnabled = false
_S.AimLockFOV = 150
_S.ShowAimLockFOVCircle = false
_S.AimLockRoleFilter = "Both"
_S.AimLockSkipWall = false
_S.AimLockSkipFriends = true
_S.AimLockPreciseMode = true
_S.AimLockAutoFire = false
_S.AimLockAlwaysRMB = false
_S.AimLockFireDelay = 0.03

_S.MouseLockEnabled = false
_S.MouseLockBindKey = nil
_S.MouseLockBindMode = "Hold"
_S.MouseLockConnection = nil
_S.MouseLockLockedTarget = nil
_S.MouseLockSmooth = 0.65
_S.MouseLockFOVEnabled = false
_S.MouseLockFOV = 150
_S.ShowMouseLockFOVCircle = false
_S.MouseLockRoleFilter = "Both"
_S.MouseLockSkipWall = false
_S.MouseLockSkipFriends = true
_S.WaitingForMouseLockBind = false

_S.FastRevolverEnabled = false
_S.FastShotEnabled = false
_S.FastRevolverDelay = 0.01
_S.FastShotDelay = 0.001

-- HITBOX (реальный с визуальным квадратом)
_S.HitboxEnabled = false
_S.HitboxSize = 10 -- общий размер (1-75)
_S.HitboxTransparency = 1 -- 0 = видно, 1 = невидимо
_S.HitboxColor = Color3.fromRGB(255, 50, 50)
_S.HitboxSkipFriends = true
_S.OriginalPartSizes = {} -- [part] = {Size, Transparency, Color, Material, CanCollide, Massless}

_S.DefaultPlayerRole = "Target"
_S.AutoReloadEnabled = false
_S.AutoReloadDelay = 0.15
_S.ReloadCooldown = {}
_S.TripleShotEnabled = false
_S.FastGunEnabled = false
_S.FastGunDelay = 0.05
_S.FastGunConnection = nil
_S._FastGunHolding = false
_S.NoclipConnection = nil

-- ========== ПРОВЕРКА ЖИВОСТИ ==========
local function IsPlayerAlive(player)
    if not player then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return false end
    if not hum.Health or hum.Health <= 0 then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    if hum:GetState() == Enum.HumanoidStateType.Ragdoll then return false end
    if hum.PlatformStand then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return false end
    if head.Position.Y < hrp.Position.Y - 0.3 then return false end
    return true
end

local function GetDefaultRole() return _S.DefaultPlayerRole or "Target" end
local function GetPlayerRole(player) return _S.PlayerRoles and _S.PlayerRoles[player.UserId] or GetDefaultRole() end
local function IsModerator(player) return _S.savedMods[player.UserId] ~= nil end
local function IsLegitTarget(player)
    if not player or player == LocalPlayer or IsModerator(player) then return false end
    if not IsPlayerAlive(player) then return false end
    local role = GetPlayerRole(player)
    return role == "Target" or role == "Priority"
end
local function IsAimLockTarget(player)
    if not player or player == LocalPlayer or IsModerator(player) then return false end
    if not IsPlayerAlive(player) then return false end
    local role = GetPlayerRole(player)
    if _S.AimLockRoleFilter == "Target" then return role == "Target"
    elseif _S.AimLockRoleFilter == "Priority" then return role == "Priority"
    else return role == "Target" or role == "Priority" end
end
local function IsMouseLockTarget(player)
    if not player or player == LocalPlayer or IsModerator(player) then return false end
    if not IsPlayerAlive(player) then return false end
    local role = GetPlayerRole(player)
    if _S.MouseLockRoleFilter == "Target" then return role == "Target"
    elseif _S.MouseLockRoleFilter == "Priority" then return role == "Priority"
    else return role == "Target" or role == "Priority" end
end
local function IsFriend(player)
    if not player then return false end
    if player == LocalPlayer then return true end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return true end
    local ok, f = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    return ok and f
end

-- ========== HITBOX: реальный размер Head/Torso, визуально квадрат ==========
local function applyHitbox(plr)
    if not plr or plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end
    local parts = {}
    local head = char:FindFirstChild("Head")
    if head then table.insert(parts, head) end
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso")
    if torso then table.insert(parts, torso) end

    for _, part in ipairs(parts) do
        if not _S.OriginalPartSizes[part] then
            _S.OriginalPartSizes[part] = {
                Size = part.Size,
                Transparency = part.Transparency,
                Color = part.Color,
                Material = part.Material,
                CanCollide = part.CanCollide,
                Massless = part.Massless,
            }
        end
        pcall(function()
            local s = _S.HitboxSize
            part.Size = Vector3.new(s, s, s)
            part.Transparency = _S.HitboxTransparency
            if _S.HitboxTransparency < 1 then
                part.Color = _S.HitboxColor
                part.Material = Enum.Material.ForceField
            end
            part.CanCollide = false
            part.Massless = true
        end)
    end
end

local function resetHitbox(plr)
    if not plr or plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if _S.OriginalPartSizes[part] then
            local d = _S.OriginalPartSizes[part]
            pcall(function()
                part.Size = d.Size
                part.Transparency = d.Transparency
                part.Color = d.Color
                part.Material = d.Material
                part.CanCollide = d.CanCollide
                part.Massless = d.Massless
            end)
            _S.OriginalPartSizes[part] = nil
        end
    end
end

local function updateAllHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if _S.HitboxEnabled then applyHitbox(plr) else resetHitbox(plr) end
        end
    end
end

task.spawn(function()
    while task.wait(0.15) do
        if _S.HitboxEnabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if (_S.HitboxSkipFriends and IsFriend(plr)) or not IsLegitTarget(plr) then
                        resetHitbox(plr)
                    else
                        applyHitbox(plr)
                    end
                end
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then resetHitbox(plr) end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(resetHitbox)
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.4)
        if _S.HitboxEnabled and IsLegitTarget(plr) then applyHitbox(plr) end
    end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(0.4)
            if _S.HitboxEnabled and IsLegitTarget(plr) then applyHitbox(plr) end
        end)
    end
end

-- ========== TRIGGERBOT ==========
_S.TriggerbotEnabled = false
_S.TriggerbotConnection = nil
_S.TriggerbotDelay = 0.0001
_S.TriggerbotRMBOnly = false
_S.CheckWall = false
_S.CheckFriend = false
_S.WaitingForTriggerBind = false

local function GetPlayerFromPart(part)
    if not part then return nil end
    local m = part:FindFirstAncestorWhichIsA("Model") if not m then return nil end
    if m:FindFirstChildWhichIsA("Humanoid") then
        for _, plr in pairs(Players:GetPlayers()) do if plr.Character == m then return plr end end
    end
    return nil
end
local function HasLineOfSight(tp)
    if not tp then return false end
    local c = LocalPlayer.Character if not c then return false end
    local o = Camera.CFrame.Position
    local d = (tp.Position - o)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {c}
    p.IgnoreWater = true
    local r = workspace:Raycast(o, d.Unit * (d.Magnitude + 1), p)
    if not r then return true end
    local hp = GetPlayerFromPart(r.Instance)
    if hp and hp.Character == tp:FindFirstAncestorWhichIsA("Model") then return true end
    return false
end
local function UpdateTriggerbot()
    if _S.TriggerbotConnection then _S.TriggerbotConnection:Disconnect() _S.TriggerbotConnection = nil end
    if _S.TriggerbotEnabled then
        _S.TriggerbotConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if not tool or not _S.WeaponsEnabled[tool.Name] then return end
                if _S.TriggerbotRMBOnly and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
                local m = LocalPlayer:GetMouse()
                local t = m.Target
                if t then
                    local tp = t.Parent local tpl = nil
                    while tp and tp ~= game do
                        if tp:IsA("Model") and tp:FindFirstChildOfClass("Humanoid") then
                            for _, plr in pairs(Players:GetPlayers()) do if plr.Character == tp then tpl = plr break end end
                            break
                        end
                        tp = tp.Parent
                    end
                    if tpl and tpl ~= LocalPlayer then
                        if not IsLegitTarget(tpl) then return end
                        if _S.CheckWall and not HasLineOfSight(t) then return end
                        task.wait(_S.TriggerbotDelay)
                        mouse1press() task.wait(0.02 + math.random()*0.03) mouse1release()
                    end
                end
            end)
        end)
    end
end

_S.SelectHostKey1 = Enum.KeyCode.F1
_S.SelectHostKey2 = Enum.KeyCode.Z
_S.ToggleEmojiKey1 = Enum.KeyCode.F1
_S.ToggleEmojiKey2 = Enum.KeyCode.K
_S.emojiKey1Down = false
_S.emojiKey2Down = false
_S.AllowFriendsAsHost = true
_S.ShowTargetEmoji = true
_S.key1Down = false
_S.key2Down = false
_S.AutoShotToggleBtn = nil

_S.Theme = {
    Background = Color3.fromRGB(0,0,0), TopBar = Color3.fromRGB(5,5,5),
    Section = Color3.fromRGB(14,14,18), TabInactive = Color3.fromRGB(18,18,22),
    TabActive = Color3.fromRGB(30,20,45), Accent = Color3.fromRGB(110,60,180),
    ToggleOn = Color3.fromRGB(12,12,16), ToggleOff = Color3.fromRGB(8,8,10),
    SliderFill = Color3.fromRGB(240,240,245), SliderKnob = Color3.fromRGB(200,200,210),
    CloseBtn = Color3.fromRGB(20,20,25), BindBtn = Color3.fromRGB(75,40,130),
    PlayerBtn = Color3.fromRGB(18,18,22),
    TitleText = Color3.fromRGB(220,210,240), LabelText = Color3.fromRGB(200,195,220),
    SectionTitle = Color3.fromRGB(150,110,210),
}
_S.VisualColors = {
    RoleESP = { Target=Color3.fromRGB(255,60,60), Priority=Color3.fromRGB(255,140,0), Friend=Color3.fromRGB(60,220,120), Neutral=Color3.fromRGB(160,160,180) },
    ModESP = { Text=Color3.fromRGB(255,100,100), Box=Color3.fromRGB(255,50,50), Tracer=Color3.fromRGB(255,0,0) }
}

local AUTO_RELOAD_COOLDOWN = 1.2
local function SimulateReload(tool)
    if not tool or not tool.Parent then return end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end
local function CheckAutoReload()
    if not _S.AutoReloadEnabled then return end
    local char = LocalPlayer.Character if not char then return end
    local tool = char:FindFirstChildOfClass("Tool") if not tool then return end
    if not _S.WeaponsEnabled[tool.Name] then return end
    local ammo = tool:FindFirstChild(_S.AmmoName) if not ammo or not ammo:IsA("IntValue") then return end
    local now = tick()
    local k = tostring(tool).."_"..tool.Name
    if _S.ReloadCooldown[k] and (now - _S.ReloadCooldown[k]) < AUTO_RELOAD_COOLDOWN then return end
    if ammo.Value == 0 then
        _S.ReloadCooldown[k] = now
        task.spawn(function() task.wait(0.15) SimulateReload(tool) end)
    end
end
local function SimulateClick()
    pcall(function()
        if _S.AutoShootRandomDelay then
            task.wait(_S.AutoShootMinDelay + math.random() * (_S.AutoShootMaxDelay - _S.AutoShootMinDelay))
        else
            task.wait(_S.DelayBeforeShot * (0.7 + math.random() * 0.6))
        end
        mouse1press() task.wait(0.02 + math.random()*0.03) mouse1release()
    end)
end
local function CheckShot()
    if not _S.Monitoring then return end
    local active = #_S.StarterPlayers > 0 and _S.StarterPlayers or {}
    for _, sp in ipairs(active) do
        if not IsLegitTarget(sp) then continue end
        local char = sp.Character if not char then continue end
        local tool = char:FindFirstChildOfClass("Tool") if not tool then continue end
        if not _S.WeaponsEnabled[tool.Name] then continue end
        local ammo = tool:FindFirstChild(_S.AmmoName) if not ammo then continue end
        local cur = ammo.Value local prev = _S.LastAmmoPerTool[tool]
        if prev and cur < prev then SimulateClick() end
        _S.LastAmmoPerTool[tool] = cur
    end
end

local aimLockFovCircle = Drawing.new("Circle")
aimLockFovCircle.Visible = false aimLockFovCircle.Thickness = 1.5
aimLockFovCircle.Color = Color3.fromRGB(180,100,255) aimLockFovCircle.Filled = false aimLockFovCircle.NumSides = 64
local mouseLockFovCircle = Drawing.new("Circle")
mouseLockFovCircle.Visible = false mouseLockFovCircle.Thickness = 1.5
mouseLockFovCircle.Color = Color3.fromRGB(0,200,255) mouseLockFovCircle.Filled = false mouseLockFovCircle.NumSides = 64

local function GetHeadAimPoint(t)
    if not t or not t.Character then return nil end
    local h = t.Character:FindFirstChild("Head")
    if not h then return nil end
    return h.Position + Vector3.new(0, 0.15, 0)
end
local function GetClosestTargetForAim()
    local c, d = nil, _S.AimLockFOVEnabled and _S.AimLockFOV or math.huge
    local mp = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAimLockTarget(p) and p.Character then
            if _S.AimLockSkipFriends and IsFriend(p) then continue end
            local h = p.Character:FindFirstChild("Head")
            if h then
                if _S.AimLockSkipWall and not HasLineOfSight(h) then continue end
                local sp, on = Camera:WorldToViewportPoint(h.Position)
                if on then
                    local dd = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if dd < d then d = dd c = p end
                end
            end
        end
    end
    return c
end
local function AutoFireAimLock(t)
    if not _S.AimLockAutoFire or not t then return end
    local h = t.Character and t.Character:FindFirstChild("Head")
    if not h then return end
    local sp, on = Camera:WorldToViewportPoint(h.Position)
    if not on then return end
    local ml = UserInputService:GetMouseLocation()
    if (Vector2.new(sp.X, sp.Y) - ml).Magnitude < 25 then
        pcall(function() mouse1press() task.wait(_S.AimLockFireDelay) mouse1release() end)
    end
end
local function UpdateAimLock()
    if not _S.AimLockEnabled then _S.AimLockLockedTarget = nil aimLockFovCircle.Visible = false return end
    if _S.ShowAimLockFOVCircle then
        aimLockFovCircle.Position = UserInputService:GetMouseLocation()
        aimLockFovCircle.Radius = _S.AimLockFOV
        aimLockFovCircle.Visible = true
    else aimLockFovCircle.Visible = false end
    if not _S.AimLockAlwaysRMB and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        _S.AimLockLockedTarget = nil return
    end
    local valid = false
    if _S.AimLockLockedTarget and _S.AimLockLockedTarget.Parent and _S.AimLockLockedTarget.Character and IsAimLockTarget(_S.AimLockLockedTarget) then
        local t = _S.AimLockLockedTarget
        local isF = IsFriend(t)
        local h = t.Character:FindFirstChild("Head")
        local los = h and (not _S.AimLockSkipWall or HasLineOfSight(h))
        if (not _S.AimLockSkipFriends or not isF) and los and h then valid = true end
    end
    if not valid then _S.AimLockLockedTarget = GetClosestTargetForAim() end
    local t = _S.AimLockLockedTarget
    if t and t.Character then
        local ap = GetHeadAimPoint(t)
        if ap then
            local cf = CFrame.new(Camera.CFrame.Position, ap)
            if _S.AimLockPreciseMode then Camera.CFrame = cf
            else Camera.CFrame = Camera.CFrame:Lerp(cf, 1 / math.max(_S.AimLockSmooth, 8)) end
            AutoFireAimLock(t)
        end
    end
end
local function GetClosestTargetForMouseLock()
    local c, d = nil, _S.MouseLockFOVEnabled and _S.MouseLockFOV or math.huge
    local mp = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsMouseLockTarget(p) and p.Character then
            if _S.MouseLockSkipFriends and IsFriend(p) then continue end
            local h = p.Character:FindFirstChild("Head")
            if h then
                if _S.MouseLockSkipWall and not HasLineOfSight(h) then continue end
                local sp, on = Camera:WorldToViewportPoint(h.Position)
                if on then
                    local dd = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if dd < d then d = dd c = p end
                end
            end
        end
    end
    return c
end
local function UpdateMouseLock()
    if not _S.MouseLockEnabled then _S.MouseLockLockedTarget = nil mouseLockFovCircle.Visible = false return end
    if _S.ShowMouseLockFOVCircle then
        mouseLockFovCircle.Position = UserInputService:GetMouseLocation()
        mouseLockFovCircle.Radius = _S.MouseLockFOV
        mouseLockFovCircle.Visible = true
    else mouseLockFovCircle.Visible = false end
    local valid = false
    if _S.MouseLockLockedTarget and _S.MouseLockLockedTarget.Parent and _S.MouseLockLockedTarget.Character and IsMouseLockTarget(_S.MouseLockLockedTarget) then
        local t = _S.MouseLockLockedTarget
        local isF = IsFriend(t)
        local h = t.Character:FindFirstChild("Head")
        local los = h and (not _S.MouseLockSkipWall or HasLineOfSight(h))
        if (not _S.MouseLockSkipFriends or not isF) and los and h then valid = true end
    end
    if not valid then _S.MouseLockLockedTarget = GetClosestTargetForMouseLock() end
    local t = _S.MouseLockLockedTarget
    if not t or not t.Character then return end
    local ap = GetHeadAimPoint(t)
    if not ap then return end
    local sp, on = Camera:WorldToViewportPoint(ap)
    if not on then return end
    local ml = UserInputService:GetMouseLocation()
    local dx = sp.X - ml.X local dy = sp.Y - ml.Y
    local sx = dx * _S.MouseLockSmooth local sy = dy * _S.MouseLockSmooth
    if math.abs(sx) < 0.5 and math.abs(sy) < 0.5 then return end
    local mv = false
    pcall(function() mousemoverel(sx, sy) mv = true end)
    if not mv then pcall(function() mousemove(sx, sy) end) end
end
local function GetClosestPlayerToCrosshair()
    local ml = UserInputService:GetMouseLocation()
    local c, d = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local sp, on = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if on then
                local dd = (Vector2.new(sp.X, sp.Y) - ml).Magnitude
                if dd < d then d = dd c = p end
            end
        end
    end
    return c
end

_S.HostEmojis = {}
local HOST_EMOJI = "🎯"
local function RemoveEmojiForPlayer(plr)
    if _S.HostEmojis[plr.UserId] then pcall(function() _S.HostEmojis[plr.UserId]:Destroy() end) _S.HostEmojis[plr.UserId] = nil end
end
local function RemoveEmoji() for _, g in pairs(_S.HostEmojis) do pcall(function() g:Destroy() end) end _S.HostEmojis = {} end
local function AttachEmojiToPlayer(plr)
    if not plr or not _S.ShowTargetEmoji then return end
    RemoveEmojiForPlayer(plr)
    local s = 0
    for i, p in ipairs(_S.StarterPlayers) do if p == plr then s = i break end end
    if s == 0 then return end
    local char = plr.Character
    if not char then plr.CharacterAdded:Once(function() task.wait(0.5) local f=false for _,p in ipairs(_S.StarterPlayers) do if p==plr then f=true break end end if f then AttachEmojiToPlayer(plr) end end) return end
    local head = char:WaitForChild("Head", 3) if not head then return end
    local bg = Instance.new("BillboardGui") bg.Name = "TargetEmoji_"..plr.UserId bg.Adornee = head
    bg.Size = UDim2.new(0, 60, 0, 60) bg.StudsOffset = Vector3.new(0, 2.5, 0) bg.AlwaysOnTop = true
    bg.ResetOnSpawn = false bg.Parent = game.CoreGui
    local l = Instance.new("TextLabel", bg)
    l.Size = UDim2.new(1,0,1,0) l.BackgroundTransparency = 1 l.Text = HOST_EMOJI
    l.TextColor3 = Color3.fromRGB(255,215,0) l.TextScaled = true l.Font = Enum.Font.Legacy
    l.TextStrokeTransparency = 0 l.TextStrokeColor3 = Color3.new(0,0,0)
    _S.HostEmojis[plr.UserId] = bg
end
local function RefreshAllHostEmojis() for _,g in pairs(_S.HostEmojis) do pcall(function() g:Destroy() end) end _S.HostEmojis = {} for _,p in ipairs(_S.StarterPlayers) do AttachEmojiToPlayer(p) end end
local function AddHost(plr)
    if #_S.StarterPlayers >= 3 then return false end
    for _, p in ipairs(_S.StarterPlayers) do if p == plr then return false end end
    table.insert(_S.StarterPlayers, plr) AttachEmojiToPlayer(plr) return true
end
local function RemoveHost(plr)
    for i, p in ipairs(_S.StarterPlayers) do if p == plr then table.remove(_S.StarterPlayers, i) RemoveEmojiForPlayer(plr) break end end
    RefreshAllHostEmojis()
end
Players.PlayerRemoving:Connect(function(plr) RemoveHost(plr) end)
Players.PlayerAdded:Connect(function(plr)
    if not _S.PlayerRoles[plr.UserId] then _S.PlayerRoles[plr.UserId] = GetDefaultRole() end
end)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if isBindMatch(_S.SelectHostKey1, inp) then _S.key1Down = true end
    if isBindMatch(_S.SelectHostKey2, inp) then _S.key2Down = true end
    if isBindMatch(_S.ToggleEmojiKey1, inp) then _S.emojiKey1Down = true end
    if isBindMatch(_S.ToggleEmojiKey2, inp) then _S.emojiKey2Down = true end
    if _S.emojiKey1Down and _S.emojiKey2Down then
        _S.ShowTargetEmoji = not _S.ShowTargetEmoji
        if _S.ShowTargetEmoji then RefreshAllHostEmojis() else RemoveEmoji() end
    end
    if _S.key1Down and _S.key2Down then
        local c = GetClosestPlayerToCrosshair()
        if c then
            if #_S.StarterPlayers > 0 and _S.StarterPlayers[1] == c then RemoveHost(c) _S.LastAmmoPerTool = {}
            else if _S.AllowFriendsAsHost or not IsFriend(c) then if AddHost(c) then _S.LastAmmoPerTool = {} end end end
        end
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if isBindMatch(_S.SelectHostKey1, inp) then _S.key1Down = false end
    if isBindMatch(_S.SelectHostKey2, inp) then _S.key2Down = false end
    if isBindMatch(_S.ToggleEmojiKey1, inp) then _S.emojiKey1Down = false end
    if isBindMatch(_S.ToggleEmojiKey2, inp) then _S.emojiKey2Down = false end
end)

local function playAlertSound()
    local s = Instance.new("Sound") s.SoundId = "rbxassetid://".._S.alertSoundId s.Volume = 10 s.Parent = workspace s:Play()
    game:GetService("Debris"):AddItem(s, 6)
end
local function hasModSymbols(n) for _, s in ipairs(_S.MOD_SYMBOLS) do if string.find(n, s) then return true end end return false end
local function isBoomFFAMod(p)
    if _S.MOD_USERNAMES[p.Name:lower()] or _S.MOD_USERNAMES[p.DisplayName:lower()] then return true, "Known Mod" end
    if hasModSymbols(p.Name) or hasModSymbols(p.DisplayName) then return true, "Mod Symbol" end
    for _, g in ipairs(_S.MOD_GROUP_IDS) do
        local ok, inG = pcall(function() return p:IsInGroup(g) end)
        if ok and inG then
            local rkOk, rk = pcall(function() return p:GetRankInGroup(g) end)
            local rlOk, rl = pcall(function() return p:GetRoleInGroup(g) end)
            if rkOk and rk >= _S.MOD_MIN_RANK then return true, (rlOk and rl or "GroupMember").." [Rank:"..tostring(rk).."]" end
        end
    end
    return false, nil
end
_S.modVisualEnabled = true
_S.modDetectorEnabled = true
local function clearModESPForPlayer(p)
    local d = _S.activeESP[p]
    if d then
        if d.label then pcall(function() d.label.Visible = false if d.label.Remove then d.label:Remove() end end) end
        if d.box then pcall(function() d.box.Visible = false if d.box.Remove then d.box:Remove() end end) end
        if d.tracer then pcall(function() d.tracer.Visible = false if d.tracer.Remove then d.tracer:Remove() end end) end
        _S.activeESP[p] = nil
    end
end
local function createModESP(p, r)
    clearModESPForPlayer(p)
    local label = Drawing.new("Text")
    label.Visible = false label.Center = true label.Outline = true label.Size = 18 label.Color = _S.VisualColors.ModESP.Text label.Font = 3
    local box = Drawing.new("Square") box.Visible = false box.Thickness = 2 box.Color = _S.VisualColors.ModESP.Box box.Filled = false
    local tr = Drawing.new("Line") tr.Visible = false tr.Thickness = 1.5 tr.Color = _S.VisualColors.ModESP.Tracer
    _S.activeESP[p] = { label = label, box = box, tracer = tr, role = r, isMod = true }
    if r == "Reported" then addModToSaved(p.UserId, p.Name, "Reported") end
end
local function updateModESP()
    if not _S.modVisualEnabled then
        for _, d in pairs(_S.activeESP) do if d then if d.label then d.label.Visible = false end if d.box then d.box.Visible = false end if d.tracer then d.tracer.Visible = false end end end
        return
    end
    for p, d in pairs(_S.activeESP) do
        if p and p.Parent and p.Character and p.Character:FindFirstChild("Head") and d.isMod then
            local h = p.Character.Head
            local rp = p.Character:FindFirstChild("HumanoidRootPart") or h
            local hu = p.Character:FindFirstChildOfClass("Humanoid")
            local alive = hu and hu.Health > 0
            local sp, on = Camera:WorldToViewportPoint(h.Position)
            if on and alive then
                d.label.Position = Vector2.new(sp.X, sp.Y-30)
                d.label.Text = "🚨 MOD: "..p.Name.." ["..d.role.."]"
                d.label.Visible = true
                if d.box then
                    local hp = Camera:WorldToViewportPoint(h.Position + Vector3.new(0, 0.5, 0))
                    local fp = Camera:WorldToViewportPoint(rp.Position - Vector3.new(0, 3, 0))
                    local bh = math.max(math.abs(hp.Y - fp.Y), 10) local bw = bh / 2
                    d.box.Size = Vector2.new(bw, bh) d.box.Position = Vector2.new(hp.X - bw/2, hp.Y - bh*0.1)
                    d.box.Visible = true
                end
                if d.tracer then
                    local rpp = Camera:WorldToViewportPoint(rp.Position)
                    d.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    d.tracer.To = Vector2.new(rpp.X, rpp.Y) d.tracer.Visible = true
                end
            else
                d.label.Visible = false
                if d.box then d.box.Visible = false end
                if d.tracer then d.tracer.Visible = false end
            end
        else
            if d then
                if d.label then pcall(function() d.label.Visible = false if d.label.Remove then d.label:Remove() end end) end
                if d.box then pcall(function() d.box.Visible = false if d.box.Remove then d.box:Remove() end end) end
                if d.tracer then pcall(function() d.tracer.Visible = false if d.tracer.Remove then d.tracer:Remove() end end) end
            end
            _S.activeESP[p] = nil
        end
    end
end
local function detectMods()
    if not _S.modDetectorEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if _S.savedMods[p.UserId] then
                if not _S.activeESP[p] or not _S.activeESP[p].isMod then createModESP(p, "Saved [".._S.savedMods[p.UserId].date.."]") end
            else
                local isM, rd = isBoomFFAMod(p)
                if isM then if not _S.activeESP[p] or not _S.activeESP[p].isMod then createModESP(p, rd or "Staff") end end
            end
        end
    end
end
Players.PlayerRemoving:Connect(function(p) clearModESPForPlayer(p) end)
task.spawn(function() task.wait(1) detectMods() updateModESP() end)

local frc = nil
local function startFastRevolver()
    if frc then frc:Disconnect() end
    frc = RunService.Heartbeat:Connect(function()
        if not _S.FastRevolverEnabled then return end
        local char = LocalPlayer.Character if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool or tool.Name ~= "[Revolver]" then return end
        local ammo = tool:FindFirstChild(_S.AmmoName)
        if not ammo or not ammo:IsA("IntValue") then return end
        if ammo.Value <= 0 then return end
        pcall(function() mouse1press() task.wait(_S.FastRevolverDelay) mouse1release() end)
    end)
end
startFastRevolver()

local _lfs = 0
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not _S.FastShotEnabled then return end
    local char = LocalPlayer.Character if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    if tool.Name ~= "[Revolver]" and tool.Name ~= "[Double-Barrel SG]" then return end
    local ammo = tool:FindFirstChild(_S.AmmoName)
    if not ammo or not ammo:IsA("IntValue") then return end
    local n = tick()
    if n - _lfs < 0.25 then return end
    _lfs = n
    local count = ammo.Value
    if count <= 0 then return end
    task.spawn(function()
        for i = 1, count do pcall(function() mouse1click() end) if _S.FastShotDelay > 0 then task.wait(_S.FastShotDelay) end end
    end)
end)

-- ====================== GUI ======================
local gui = Instance.new("ScreenGui")
gui.Name = "EBY_V_TYZ" gui.ResetOnSpawn = false gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = o end
local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(820, 520) main.Position = UDim2.new(0.5, -410, 0.5, -260)
main.AnchorPoint = Vector2.new(0.5, 0.5) main.BackgroundColor3 = _S.Theme.Background
main.BorderSizePixel = 0 main.ClipsDescendants = true corner(main, 14)

local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,56) top.BackgroundColor3 = _S.Theme.TopBar corner(top, 14)
local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1,-70,1,0) title.Position = UDim2.fromOffset(16,0) title.BackgroundTransparency = 1
title.Text = "EBY V TYZ" title.Font = Enum.Font.GothamSemibold title.TextSize = 20
title.TextColor3 = _S.Theme.TitleText title.TextXAlignment = Enum.TextXAlignment.Left
title.Active = false
local closeBtn = Instance.new("TextButton", top)
closeBtn.Size = UDim2.fromOffset(36,36) closeBtn.Position = UDim2.new(1,-46,0,10)
closeBtn.Text = "×" closeBtn.Font = Enum.Font.GothamBold closeBtn.TextSize = 24
closeBtn.TextColor3 = Color3.fromRGB(180,180,190) closeBtn.BackgroundColor3 = _S.Theme.CloseBtn corner(closeBtn, 18)
local dr, ds, sp = false, nil, nil
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dr = true ds = input.Position sp = main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dr = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dr and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - ds
        main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
end)

local tabsFrame = Instance.new("Frame", main)
tabsFrame.Position = UDim2.fromOffset(14,64) tabsFrame.Size = UDim2.new(0,140,1,-78) tabsFrame.BackgroundTransparency = 1
local tl = Instance.new("UIListLayout", tabsFrame) tl.Padding = UDim.new(0,6) tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", tabsFrame).PaddingTop = UDim.new(0,8)
local pages = Instance.new("Frame", main)
pages.Position = UDim2.fromOffset(170,64) pages.Size = UDim2.new(1,-184,1,-78)
pages.BackgroundTransparency = 1 pages.ClipsDescendants = true
local function createPage()
    local p = Instance.new("ScrollingFrame", pages)
    p.Size = UDim2.new(1,0,1,0) p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.ScrollBarThickness = 3 p.ScrollBarImageColor3 = _S.Theme.Accent
    p.BackgroundTransparency = 1 p.Visible = false p.Position = UDim2.new(0, 20, 0, 0)
    local l = Instance.new("UIListLayout", p) l.Padding = UDim.new(0,12)
    local pad = Instance.new("UIPadding", p) pad.PaddingTop = UDim.new(0,8) pad.PaddingLeft = UDim.new(0,8) pad.PaddingRight = UDim.new(0,8)
    return p
end
local cp, isw = nil, false
local function switchToPage(np)
    if np == cp or isw then return end
    isw = true
    local function showNew()
        np.Position = UDim2.new(0, 18, 0, 0) np.Visible = true
        TweenService:Create(np, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        task.delay(0.05, function() isw = false end) cp = np
    end
    if cp then
        local old = cp
        local t = TweenService:Create(old, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0, -18, 0, 0)})
        t:Play()
        t.Completed:Connect(function() old.Visible = false old.Position = UDim2.new(0, 20, 0, 0) showNew() end)
    else showNew() isw = false end
end
local HH, SG = 36, 8
local function createSection(parent, text)
    local w = Instance.new("Frame", parent)
    w.BackgroundTransparency = 1 w.Size = UDim2.new(1, 0, 0, HH) w.ClipsDescendants = true
    local h = Instance.new("TextButton", w)
    h.Size = UDim2.new(1, 0, 0, HH) h.Position = UDim2.new(0, 0, 0, 0)
    h.BackgroundColor3 = _S.Theme.Section h.Text = "" h.AutoButtonColor = false corner(h, 10)
    local lbl = Instance.new("TextLabel", h)
    lbl.Size = UDim2.new(1,-40,1,0) lbl.Position = UDim2.fromOffset(12,0) lbl.BackgroundTransparency = 1
    lbl.Text = text lbl.Font = Enum.Font.GothamSemibold lbl.TextSize = 14
    lbl.TextColor3 = _S.Theme.SectionTitle lbl.TextXAlignment = Enum.TextXAlignment.Left
    local ar = Instance.new("TextLabel", h)
    ar.Size = UDim2.new(0,24,1,0) ar.Position = UDim2.new(1,-34,0,0) ar.BackgroundTransparency = 1
    ar.Text = "▼" ar.Font = Enum.Font.GothamBold ar.TextSize = 20 ar.TextColor3 = _S.Theme.SectionTitle ar.Rotation = -90
    local c = Instance.new("Frame", w)
    c.BackgroundTransparency = 1 c.Position = UDim2.new(0, 0, 0, HH + SG)
    c.Size = UDim2.new(1, 0, 0, 0) c.AutomaticSize = Enum.AutomaticSize.Y
    local cl = Instance.new("UIListLayout", c) cl.Padding = UDim.new(0, 12)
    local cp2 = Instance.new("UIPadding", c)
    cp2.PaddingLeft = UDim.new(0, 8) cp2.PaddingRight = UDim.new(0, 8)
    cp2.PaddingTop = UDim.new(0, 4) cp2.PaddingBottom = UDim.new(0, 8)
    local io, am = false, nil
    local function op()
        io = true if am then am:Cancel() end task.wait()
        am = TweenService:Create(w, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, HH + SG + c.AbsoluteSize.Y) }) am:Play()
        TweenService:Create(ar, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 0}):Play()
    end
    local function cl2()
        io = false if am then am:Cancel() end
        am = TweenService:Create(w, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, HH) }) am:Play()
        TweenService:Create(ar, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Rotation = -90}):Play()
    end
    h.MouseButton1Click:Connect(function() if io then cl2() else op() end end)
    return c
end

local pageLegit = createPage() local pageMisc = createPage() local pagePlayerList = createPage()
local pageMovement = createPage() local pageVisual = createPage() local pageMouse = createPage()
local allTabs = {}
local function createTab(name, page)
    local b = Instance.new("TextButton", tabsFrame)
    b.Size = UDim2.new(1,-12,0,40) b.BackgroundColor3 = _S.Theme.TabInactive
    b.Text = name b.Font = Enum.Font.GothamSemibold b.TextColor3 = Color3.fromRGB(190,190,210)
    b.TextSize = 14 b.AutoButtonColor = false corner(b,10)
    local st = Instance.new("UIStroke", b) st.Color = Color3.fromRGB(70,70,100) st.Thickness = 1.4 st.Transparency = 0.65
    local ind = Instance.new("Frame", b) ind.Size = UDim2.new(0,4,0.5,0) ind.Position = UDim2.new(0,-2,0.25,0) ind.BackgroundColor3 = _S.Theme.Accent corner(ind,2) ind.Visible = false
    local function setActive(a)
        if a then
            TweenService:Create(b, TweenInfo.new(0.22), {BackgroundColor3 = _S.Theme.TabActive, TextColor3 = Color3.fromRGB(240,240,255)}):Play()
            st.Transparency = 0.2 st.Color = _S.Theme.Accent ind.Visible = true
        else
            TweenService:Create(b, TweenInfo.new(0.22), {BackgroundColor3 = _S.Theme.TabInactive, TextColor3 = Color3.fromRGB(190,190,210)}):Play()
            st.Transparency = 0.65 st.Color = Color3.fromRGB(70,70,100) ind.Visible = false
        end
    end
    table.insert(allTabs, {Page = page, SetActive = setActive})
    b.MouseButton1Click:Connect(function()
        for _, t in ipairs(allTabs) do t.SetActive(false) end setActive(true) switchToPage(page)
    end)
end
createTab("Legit", pageLegit) createTab("Mouse", pageMouse) createTab("Misc", pageMisc)
createTab("Players", pagePlayerList) createTab("Move", pageMovement) createTab("Visual", pageVisual)

local function createToggle(parent, text, def, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,50) f.BackgroundColor3 = _S.Theme.Section corner(f,10)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-85,1,0) l.Position = UDim2.fromOffset(12,0) l.BackgroundTransparency = 1
    l.Text = text l.TextColor3 = _S.Theme.LabelText l.TextSize = 15 l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left l.TextTruncate = Enum.TextTruncate.AtEnd
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0,60,0,30) btn.Position = UDim2.new(1,-72,0.5,-15)
    btn.BackgroundColor3 = def and _S.Theme.ToggleOn or _S.Theme.ToggleOff
    btn.Text = def and "ON" or "OFF" btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextSize = 14 corner(btn,15)
    local v = def
    local function setVal(n, s)
        v = n btn.Text = v and "ON" or "OFF"
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = v and _S.Theme.ToggleOn or _S.Theme.ToggleOff}):Play()
        if not s and cb then cb(v) end
    end
    btn.MouseButton1Click:Connect(function() setVal(not v) end)
    return f, btn, setVal
end
local function createSlider(parent, text, min, max, def, step, fmt, cb)
    if not cb then cb = function() end end
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,70) f.BackgroundColor3 = _S.Theme.Section corner(f,10)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,0,0,20) lbl.Position = UDim2.fromOffset(12,5) lbl.BackgroundTransparency = 1
    lbl.Text = text..": "..string.format(fmt or "%.2f", def) lbl.TextColor3 = Color3.fromRGB(180,180,200)
    lbl.TextSize = 14 lbl.Font = Enum.Font.Gotham lbl.TextXAlignment = Enum.TextXAlignment.Left
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(1,-24,0,8) bar.Position = UDim2.fromOffset(12,35) bar.BackgroundColor3 = Color3.fromRGB(60,60,70) corner(bar,4)
    local fl = Instance.new("Frame", bar)
    fl.Size = UDim2.new((def-min)/(max-min),0,1,0) fl.BackgroundColor3 = _S.Theme.SliderFill corner(fl,4)
    local kn = Instance.new("TextButton", bar)
    kn.Size = UDim2.new(0,20,0,20) kn.Position = UDim2.new((def-min)/(max-min),-10,0.5,-10)
    kn.BackgroundColor3 = _S.Theme.SliderKnob kn.Text = "" corner(kn,10)
    local drag = false
    local function onMove(i)
        if not drag then return end
        pcall(function()
            local bp = bar.AbsolutePosition local bs = bar.AbsoluteSize
            if bs.X == 0 then return end
            local rel = math.clamp((i.Position.X - bp.X) / bs.X, 0, 1)
            kn.Position = UDim2.new(rel,-10,0.5,-10)
            fl.Size = UDim2.new(rel,0,1,0)
            local val = min + rel * (max - min)
            val = math.floor(val / step + 0.5) * step
            val = math.clamp(val, min, max)
            lbl.Text = text..": "..string.format(fmt or "%.2f", val)
            pcall(cb, val)
        end)
    end
    kn.MouseButton1Down:Connect(function() drag = true end)
    UserInputService.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then onMove(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
end

-- HITBOX UI
local hitboxContent = createSection(pageLegit, "Hitbox Expander")
local hbInfo = Instance.new("Frame", hitboxContent)
hbInfo.Size = UDim2.new(1,0,0,56) hbInfo.BackgroundColor3 = Color3.fromRGB(15,30,15) corner(hbInfo, 8)
local hbInfoLbl = Instance.new("TextLabel", hbInfo)
hbInfoLbl.Size = UDim2.new(1,-12,1,0) hbInfoLbl.Position = UDim2.fromOffset(6,0) hbInfoLbl.BackgroundTransparency = 1
hbInfoLbl.Text = "🎯 Увеличивает РЕАЛЬНУЮ голову/тело в квадрат.\nРазмер до 75. Прозрачность 0 = видно, 1 = невидимо.\nРаботает ТОЛЬКО на Target/Priority." hbInfoLbl.TextColor3 = Color3.fromRGB(100,255,100) hbInfoLbl.Font = Enum.Font.Gotham hbInfoLbl.TextSize = 11 hbInfoLbl.TextWrapped = true

createToggle(hitboxContent, "🎯 Enable Hitbox", _S.HitboxEnabled, function(v)
    _S.HitboxEnabled = v
    if not v then
        for _, plr in ipairs(Players:GetPlayers()) do resetHitbox(plr) end
    else
        updateAllHitboxes()
    end
end)
createSlider(hitboxContent, "Size (studs)", 1, 75, _S.HitboxSize, 0.5, "%.1f", function(v)
    _S.HitboxSize = v updateAllHitboxes()
end)
createSlider(hitboxContent, "Прозрачность (0=видно, 1=невидимо)", 0, 1, _S.HitboxTransparency, 0.05, "%.2f", function(v)
    _S.HitboxTransparency = v updateAllHitboxes()
end)

local hbPR = Instance.new("Frame", hitboxContent)
hbPR.Size = UDim2.new(1,0,0,40) hbPR.BackgroundTransparency = 1
local hbP1 = Instance.new("TextButton", hbPR)
hbP1.Size = UDim2.new(0.32,0,1,0) hbP1.Position = UDim2.new(0,0,0,0)
hbP1.BackgroundColor3 = Color3.fromRGB(60,60,80) hbP1.Text = "Невидимо"
hbP1.TextColor3 = Color3.new(1,1,1) hbP1.Font = Enum.Font.GothamBold hbP1.TextSize = 12 corner(hbP1, 8)
hbP1.MouseButton1Click:Connect(function()
    _S.HitboxTransparency = 1 updateAllHitboxes()
end)
local hbP2 = Instance.new("TextButton", hbPR)
hbP2.Size = UDim2.new(0.32,0,1,0) hbP2.Position = UDim2.new(0.34,0,0,0)
hbP2.BackgroundColor3 = Color3.fromRGB(60,60,80) hbP2.Text = "Полупрозр."
hbP2.TextColor3 = Color3.new(1,1,1) hbP2.Font = Enum.Font.GothamBold hbP2.TextSize = 12 corner(hbP2, 8)
hbP2.MouseButton1Click:Connect(function()
    _S.HitboxTransparency = 0.6 updateAllHitboxes()
end)
local hbP3 = Instance.new("TextButton", hbPR)
hbP3.Size = UDim2.new(0.32,0,1,0) hbP3.Position = UDim2.new(0.68,0,0,0)
hbP3.BackgroundColor3 = Color3.fromRGB(60,60,80) hbP3.Text = "Макс (75)"
hbP3.TextColor3 = Color3.new(1,1,1) hbP3.Font = Enum.Font.GothamBold hbP3.TextSize = 12 corner(hbP3, 8)
hbP3.MouseButton1Click:Connect(function()
    _S.HitboxSize = 75 _S.HitboxTransparency = 0.7
    updateAllHitboxes()
end)
createToggle(hitboxContent, "Не работает на друзей", _S.HitboxSkipFriends, function(v) _S.HitboxSkipFriends = v end)

-- TriggerBot
local tb = createSection(pageLegit, "TriggerBot")
createToggle(tb, "TriggerBot", _S.TriggerbotEnabled, function(v) _S.TriggerbotEnabled = v UpdateTriggerbot() end)
createToggle(tb, "Only RMB", _S.TriggerbotRMBOnly, function(v) _S.TriggerbotRMBOnly = v end)
createSlider(tb, "Delay (сек)", 0, 0.1, _S.TriggerbotDelay, 0.001, "%.3f", function(v) _S.TriggerbotDelay = v end)
createToggle(tb, "Проверка стен", _S.CheckWall, function(v) _S.CheckWall = v end)
createToggle(tb, "Не стрелять в друзей", _S.CheckFriend, function(v) _S.CheckFriend = v end)

local aimContent = createSection(pageLegit, "Aim")
local _, autoBtn = createToggle(aimContent, "AutoShot", _S.Monitoring, function(v) _S.Monitoring = v end)
_S.AutoShotToggleBtn = autoBtn
createToggle(aimContent, "Random Delay", _S.AutoShootRandomDelay, function(v) _S.AutoShootRandomDelay = v end)
createSlider(aimContent, "Min Delay (мс)", 1, 1000, _S.AutoShootMinDelay * 1000, 1, "%.0f ms", function(v) _S.AutoShootMinDelay = v / 1000 end)
createSlider(aimContent, "Max Delay (мс)", 1, 1000, _S.AutoShootMaxDelay * 1000, 1, "%.0f ms", function(v) _S.AutoShootMaxDelay = v / 1000 end)

local alContent = createSection(pageLegit, "AimLock")
createToggle(alContent, "AimLock", _S.AimLockEnabled, function(v)
    _S.AimLockEnabled = v
    if v then if not _S.AimLockConnection then _S.AimLockConnection = RunService.RenderStepped:Connect(UpdateAimLock) end
    else _S.AimLockLockedTarget = nil aimLockFovCircle.Visible = false if _S.AimLockConnection then _S.AimLockConnection:Disconnect() _S.AimLockConnection = nil end end
end)
createToggle(alContent, "⚡ Precise", _S.AimLockPreciseMode, function(v) _S.AimLockPreciseMode = v end)
createToggle(alContent, "🔫 AutoFire", _S.AimLockAutoFire, function(v) _S.AimLockAutoFire = v end)
createSlider(alContent, "Fire Delay", 0.01, 0.5, _S.AimLockFireDelay, 0.01, "%.2f", function(v) _S.AimLockFireDelay = v end)
createToggle(alContent, "Всегда активен", _S.AimLockAlwaysRMB, function(v) _S.AimLockAlwaysRMB = v end)
createSlider(alContent, "Smooth", 1, 50, _S.AimLockSmooth, 1, "%.0f", function(v) _S.AimLockSmooth = v end)
createToggle(alContent, "FOV", _S.AimLockFOVEnabled, function(v) _S.AimLockFOVEnabled = v end)
createSlider(alContent, "FOV (пикс)", 10, 800, _S.AimLockFOV, 5, "%.0f", function(v) _S.AimLockFOV = v end)
createToggle(alContent, "Не работает за стеной", _S.AimLockSkipWall, function(v) _S.AimLockSkipWall = v end)
createToggle(alContent, "Не работает на друзей", _S.AimLockSkipFriends, function(v) _S.AimLockSkipFriends = v end)

local gunContent = createSection(pageLegit, "Gun")
for wpn, en in pairs(_S.WeaponsEnabled) do createToggle(gunContent, wpn, en, function(v) _S.WeaponsEnabled[wpn] = v end) end
createToggle(gunContent, "AUTO RELOAD", _S.AutoReloadEnabled, function(v) _S.AutoReloadEnabled = v end)

local fastContent = createSection(pageLegit, "Fast Weapons")
createToggle(fastContent, "🔫 Fast Revolver", _S.FastRevolverEnabled, function(v) _S.FastRevolverEnabled = v end)
createSlider(fastContent, "Fast Revolver Delay (мс)", 1, 100, _S.FastRevolverDelay * 1000, 1, "%.0f", function(v) _S.FastRevolverDelay = v / 1000 end)
createToggle(fastContent, "💥 Fast Shot", _S.FastShotEnabled, function(v) _S.FastShotEnabled = v end)
createSlider(fastContent, "Fast Shot Delay (мс)", 0, 50, _S.FastShotDelay * 1000, 1, "%.0f", function(v) _S.FastShotDelay = v / 1000 end)

-- Mouse
local mouseContent = createSection(pageMouse, "Mouse Lock")
createToggle(mouseContent, "Mouse Lock", false, function(v)
    _S.MouseLockEnabled = v
    if v then if not _S.MouseLockConnection then _S.MouseLockConnection = RunService.RenderStepped:Connect(UpdateMouseLock) end
    else _S.MouseLockLockedTarget = nil mouseLockFovCircle.Visible = false if _S.MouseLockConnection then _S.MouseLockConnection:Disconnect() _S.MouseLockConnection = nil end end
end)
local mbC = Instance.new("Frame", mouseContent)
mbC.Size = UDim2.new(1,0,0,50) mbC.BackgroundColor3 = _S.Theme.Section corner(mbC, 10)
local mb = Instance.new("TextButton", mbC)
mb.Size = UDim2.new(0,150,0,34) mb.Position = UDim2.new(0.5,-75,0.5,-17)
mb.BackgroundColor3 = Color3.fromRGB(40,40,55) mb.Text = "Бинд: не назначен"
mb.TextColor3 = Color3.new(1,1,1) mb.Font = Enum.Font.GothamBold mb.TextSize = 13 corner(mb, 8)
mb.MouseButton1Click:Connect(function() _S.WaitingForMouseLockBind = true mb.Text = "Нажми клавишу..." end)
createSlider(mouseContent, "Smoothness", 0.15, 1.0, _S.MouseLockSmooth, 0.05, "%.2f", function(v) _S.MouseLockSmooth = v end)
createToggle(mouseContent, "FOV", _S.MouseLockFOVEnabled, function(v) _S.MouseLockFOVEnabled = v end)
createSlider(mouseContent, "FOV (пикс)", 10, 800, _S.MouseLockFOV, 5, "%.0f", function(v) _S.MouseLockFOV = v end)
createToggle(mouseContent, "Не работает за стеной", _S.MouseLockSkipWall, function(v) _S.MouseLockSkipWall = v end)
createToggle(mouseContent, "Не работает на друзей", _S.MouseLockSkipFriends, function(v) _S.MouseLockSkipFriends = v end)

-- Visual
local roleEspObjects = {}
local roleEspActive = false
local roleEspSettings = { ShowTarget=true, ShowPriority=true, ShowFriend=true, ShowNeutral=false, ShowNames=true, ShowBox=true, ShowTracers=false, ShowDistance=true, ShowHealthBar=true }
local function clearRoleESPForPlayer(player)
    local o = roleEspObjects[player.UserId]
    if o then
        if o.gui then o.gui:Destroy() end
        if o.box then pcall(function() o.box:Remove() end) end
        if o.boxOutline then pcall(function() o.boxOutline:Remove() end) end
        if o.tracer then pcall(function() o.tracer.Visible = false o.tracer:Remove() end) end
        if o.hbar then pcall(function() o.hbar:Remove() end) end
        if o.hbarOutline then pcall(function() o.hbarOutline:Remove() end) end
        roleEspObjects[player.UserId] = nil
    end
end
local function clearAllRoleESP() for _, p in pairs(Players:GetPlayers()) do clearRoleESPForPlayer(p) end end
local function shouldShowRoleESP(player)
    if player == LocalPlayer or IsModerator(player) then return false end
    if not IsPlayerAlive(player) then return false end
    local role = GetPlayerRole(player)
    if role == "Target" and roleEspSettings.ShowTarget then return true end
    if role == "Priority" and roleEspSettings.ShowPriority then return true end
    if role == "Friend" and roleEspSettings.ShowFriend then return true end
    if role == "Neutral" and roleEspSettings.ShowNeutral then return true end
    return false
end
local function createRoleESPForPlayer(player)
    clearRoleESPForPlayer(player)
    if not shouldShowRoleESP(player) then return end
    roleEspObjects[player.UserId] = {}
    local o = roleEspObjects[player.UserId]
    local g = Instance.new("ScreenGui") g.Name = "RoleESP_"..player.Name g.IgnoreGuiInset = true g.ResetOnSpawn = false g.Parent = game.CoreGui
    local nl = Instance.new("TextLabel") nl.Size = UDim2.new(0,180,0,20) nl.BackgroundTransparency = 1 nl.Font = Enum.Font.GothamBold nl.TextSize = 14 nl.TextStrokeTransparency = 0 nl.TextStrokeColor3 = Color3.new(0,0,0) nl.TextXAlignment = Enum.TextXAlignment.Center nl.Visible = false nl.Parent = g
    local dl = Instance.new("TextLabel") dl.Size = UDim2.new(0,180,0,16) dl.BackgroundTransparency = 1 dl.Font = Enum.Font.Gotham dl.TextSize = 12 dl.TextStrokeTransparency = 0 dl.TextStrokeColor3 = Color3.new(0,0,0) dl.TextXAlignment = Enum.TextXAlignment.Center dl.Visible = false dl.Parent = g
    local box = Drawing.new("Square") box.Visible = false box.Filled = false box.Thickness = 2
    local boxOutline = Drawing.new("Square") boxOutline.Visible = false boxOutline.Filled = false boxOutline.Thickness = 4 boxOutline.Color = Color3.new(0,0,0)
    local tracer = Drawing.new("Line") tracer.Visible = false tracer.Thickness = 1.5
    local hbar = Drawing.new("Square") hbar.Visible = false hbar.Filled = true
    local hbarOutline = Drawing.new("Square") hbarOutline.Visible = false hbarOutline.Filled = false hbarOutline.Color = Color3.new(0,0,0) hbarOutline.Thickness = 2
    o.gui = g o.nameLabel = nl o.distLabel = dl o.box = box o.boxOutline = boxOutline o.tracer = tracer o.hbar = hbar o.hbarOutline = hbarOutline
end
local function updateRoleESPForPlayer(player)
    local o = roleEspObjects[player.UserId] if not o then return end
    if not shouldShowRoleESP(player) then
        if o.nameLabel then o.nameLabel.Visible = false end if o.distLabel then o.distLabel.Visible = false end
        if o.box then o.box.Visible = false end if o.boxOutline then o.boxOutline.Visible = false end
        if o.tracer then o.tracer.Visible = false end if o.hbar then o.hbar.Visible = false end if o.hbarOutline then o.hbarOutline.Visible = false end
        return
    end
    local char = player.Character if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rp = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    local hd = char:FindFirstChild("Head")
    if not rp then return end
    local rc = _S.VisualColors.RoleESP[GetPlayerRole(player)] or Color3.fromRGB(160,160,180)
    local rSP, rOn = Camera:WorldToViewportPoint(rp.Position)
    local nSP, nOn = Camera:WorldToViewportPoint(rp.Position + Vector3.new(0, 2.5, 0))
    local dist = (Camera.CFrame.Position - rp.Position).Magnitude
    if o.nameLabel then
        if roleEspSettings.ShowNames and nOn then
            local role = GetPlayerRole(player)
            local icons = {Target="🎯", Priority="⚡", Friend="💚", Neutral="⚪"}
            o.nameLabel.Text = (icons[role] or "").." "..player.Name
            o.nameLabel.TextColor3 = rc
            o.nameLabel.Position = UDim2.new(0, nSP.X - 90, 0, nSP.Y - 28)
            o.nameLabel.Visible = true
        else o.nameLabel.Visible = false end
    end
    if o.distLabel then
        if roleEspSettings.ShowDistance and nOn then
            o.distLabel.Text = string.format("%.0f m", dist) o.distLabel.TextColor3 = rc
            o.distLabel.Position = UDim2.new(0, nSP.X - 90, 0, nSP.Y - 12) o.distLabel.Visible = true
        else o.distLabel.Visible = false end
    end
    if hd and rOn then
        local hp = Camera:WorldToViewportPoint(hd.Position + Vector3.new(0, 0.5, 0))
        local fp = Camera:WorldToViewportPoint(rp.Position - Vector3.new(0, 3, 0))
        local bh = math.max(math.abs(hp.Y - fp.Y), 10) local bw = bh / 2
        local bx = hp.X - bw / 2 local by = hp.Y - bh * 0.1
        if roleEspSettings.ShowBox then
            o.box.Size = Vector2.new(bw, bh) o.box.Position = Vector2.new(bx, by) o.box.Color = rc o.box.Transparency = 1 o.box.Visible = true
            o.boxOutline.Size = o.box.Size o.boxOutline.Position = o.box.Position o.boxOutline.Transparency = 1 o.boxOutline.Visible = true
        else o.box.Visible = false o.boxOutline.Visible = false end
        if roleEspSettings.ShowHealthBar and hum then
            local mh = math.max(hum.MaxHealth or 1, 1) local hr = math.clamp(hum.Health/mh,0,1) local hbh = bh * hr
            local hc = Color3.fromRGB(math.floor((1-hr)*255), math.floor(hr*220), 50)
            o.hbar.Size = Vector2.new(3, hbh) o.hbar.Position = Vector2.new(bx-7, by+(bh-hbh)) o.hbar.Color = hc o.hbar.Transparency = 1 o.hbar.Visible = true
            o.hbarOutline.Size = Vector2.new(3, bh) o.hbarOutline.Position = Vector2.new(bx-7, by) o.hbarOutline.Transparency = 1 o.hbarOutline.Visible = true
        else o.hbar.Visible = false o.hbarOutline.Visible = false end
    else
        if o.box then o.box.Visible = false end if o.boxOutline then o.boxOutline.Visible = false end
        if o.hbar then o.hbar.Visible = false end if o.hbarOutline then o.hbarOutline.Visible = false end
    end
    if roleEspSettings.ShowTracers and rOn then
        o.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        o.tracer.To = Vector2.new(rSP.X, rSP.Y) o.tracer.Color = rc o.tracer.Transparency = 1 o.tracer.Visible = true
    else if o.tracer then o.tracer.Visible = false end end
end
local rfc = 0
RunService.RenderStepped:Connect(function()
    if not roleEspActive then return end
    rfc = rfc + 1 if rfc % 2 ~= 0 then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not roleEspObjects[p.UserId] then createRoleESPForPlayer(p) end
            updateRoleESPForPlayer(p)
        end
    end
end)
Players.PlayerRemoving:Connect(clearRoleESPForPlayer)
local RoleESPGroup = createSection(pageVisual, "🎯 Role ESP")
createToggle(RoleESPGroup, "Enable Role ESP", false, function(s) roleEspActive = s if not s then clearAllRoleESP() end end)
createToggle(RoleESPGroup, "🎯 Target", true, function(v) roleEspSettings.ShowTarget = v end)
createToggle(RoleESPGroup, "⚡ Priority", true, function(v) roleEspSettings.ShowPriority = v end)
createToggle(RoleESPGroup, "💚 Friend", true, function(v) roleEspSettings.ShowFriend = v end)
createToggle(RoleESPGroup, "⚪ Neutral", false, function(v) roleEspSettings.ShowNeutral = v end)
createToggle(RoleESPGroup, "Имена", true, function(v) roleEspSettings.ShowNames = v end)
createToggle(RoleESPGroup, "Box", true, function(v) roleEspSettings.ShowBox = v end)
createToggle(RoleESPGroup, "Трейсеры", false, function(v) roleEspSettings.ShowTracers = v end)
createToggle(RoleESPGroup, "Дистанция", true, function(v) roleEspSettings.ShowDistance = v end)
createToggle(RoleESPGroup, "HP бар", true, function(v) roleEspSettings.ShowHealthBar = v end)

-- Players
local playersContent = createSection(pagePlayerList, "Players")
local dRF = Instance.new("Frame", playersContent)
dRF.Size = UDim2.new(1,0,0,60) dRF.BackgroundColor3 = _S.Theme.Section corner(dRF,10)
local dRL = Instance.new("TextLabel", dRF)
dRL.Size = UDim2.new(0,120,1,0) dRL.Position = UDim2.fromOffset(10,0) dRL.BackgroundTransparency = 1
dRL.Text = "Роль по умолч.:" dRL.TextColor3 = _S.Theme.LabelText dRL.Font = Enum.Font.GothamSemibold dRL.TextSize = 13 dRL.TextWrapped = true
local dRO = {"Target", "Priority", "Friend", "Neutral"}
local dRC = {Target=Color3.fromRGB(200,50,50), Priority=Color3.fromRGB(220,130,0), Friend=Color3.fromRGB(50,180,90), Neutral=Color3.fromRGB(120,120,140)}
local dRB = {}
for i, role in ipairs(dRO) do
    local btn = Instance.new("TextButton", dRF)
    btn.Size = UDim2.new(0,56,0,32) btn.Position = UDim2.new(0, 130 + (i-1)*62, 0.5, -16)
    btn.BackgroundColor3 = dRC[role] btn.Text = role btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextSize = 12 corner(btn, 8)
    local st = Instance.new("UIStroke", btn) st.Color = Color3.fromRGB(255,255,255) st.Thickness = 2
    st.Transparency = (role == _S.DefaultPlayerRole) and 0 or 1
    table.insert(dRB, {btn=btn, stroke=st, role=role})
    btn.MouseButton1Click:Connect(function()
        _S.DefaultPlayerRole = role
        for _, r in ipairs(dRB) do r.stroke.Transparency = (r.role == role) and 0 or 1 end
    end)
end
local bulkFrame = Instance.new("Frame", playersContent)
bulkFrame.Size = UDim2.new(1,0,0,50) bulkFrame.BackgroundColor3 = _S.Theme.Section corner(bulkFrame,10)
local bl = Instance.new("TextLabel", bulkFrame)
bl.Size = UDim2.new(0,80,1,0) bl.Position = UDim2.fromOffset(10,0) bl.BackgroundTransparency = 1
bl.Text = "Все игроки:" bl.TextColor3 = _S.Theme.LabelText bl.Font = Enum.Font.GothamSemibold bl.TextSize = 13
local BR = { {label="🎯 T",role="Target",color=Color3.fromRGB(200,50,50)}, {label="⚡ P",role="Priority",color=Color3.fromRGB(220,130,0)}, {label="💚 F",role="Friend",color=Color3.fromRGB(50,180,90)}, {label="⚪ N",role="Neutral",color=Color3.fromRGB(120,120,140)} }
for i, def in ipairs(BR) do
    local btn = Instance.new("TextButton", bulkFrame)
    btn.Size = UDim2.new(0,58,0,32) btn.Position = UDim2.new(0, 82 + (i-1)*64, 0.5, -16)
    btn.BackgroundColor3 = def.color btn.Text = def.label btn.TextColor3 = Color3.new(1,1,1) btn.Font = Enum.Font.GothamBold btn.TextSize = 12 corner(btn, 8)
    local cr = def.role
    btn.MouseButton1Click:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then _S.PlayerRoles[plr.UserId] = cr end end
    end)
end

local PlayerListFrame = Instance.new("ScrollingFrame", playersContent)
PlayerListFrame.Size = UDim2.new(1,-20,0,360) PlayerListFrame.BackgroundColor3 = Color3.fromRGB(28,28,36)
PlayerListFrame.ScrollBarThickness = 4 PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y corner(PlayerListFrame, 8)
local RC = {Target=Color3.fromRGB(255,60,60), Priority=Color3.fromRGB(255,160,0), Friend=Color3.fromRGB(60,220,120), Neutral=Color3.fromRGB(160,160,180)}
local RI = {Target="🎯", Priority="⚡", Friend="💚", Neutral="⚪"}
local function GPR(p) return _S.PlayerRoles[p.UserId] or GetDefaultRole() end
local function CycleRole(p)
    local c = GPR(p)
    local roles = {"Neutral", "Target", "Priority", "Friend"}
    local nr = "Neutral"
    for i, r in ipairs(roles) do if r == c then nr = roles[(i % #roles) + 1] break end end
    _S.PlayerRoles[p.UserId] = nr
end
local function UpdatePlayerList()
    for _, c in ipairs(PlayerListFrame:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
    local y = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local pr = GPR(plr)
            local pc = RC[pr] or RC.Neutral
            local pi = RI[pr] or "⚪"
            local cont = Instance.new("Frame", PlayerListFrame)
            cont.Size = UDim2.new(1,-10,0,52) cont.Position = UDim2.new(0,5,0,y)
            cont.BackgroundColor3 = _S.Theme.PlayerBtn corner(cont,8)
            local rb = Instance.new("Frame", cont)
            rb.Size = UDim2.new(0,4,1,-8) rb.Position = UDim2.new(0,2,0,4) rb.BackgroundColor3 = pc corner(rb,2)
            local ril = Instance.new("TextLabel", cont)
            ril.Size = UDim2.new(0,22,0,22) ril.Position = UDim2.new(0,8,0.5,-11) ril.BackgroundTransparency = 1 ril.Text = pi ril.TextScaled = true ril.Font = Enum.Font.GothamBold
            local rbtn = Instance.new("TextButton", cont)
            rbtn.Size = UDim2.new(0,80,0,26) rbtn.Position = UDim2.new(0,34,0.5,-13)
            rbtn.BackgroundColor3 = pc rbtn.Text = pr rbtn.TextColor3 = Color3.new(1,1,1) rbtn.Font = Enum.Font.GothamBold rbtn.TextSize = 12 corner(rbtn, 8)
            local cp = plr
            rbtn.MouseButton1Click:Connect(function()
                CycleRole(cp)
                local nr = GPR(cp) local nc = RC[nr] or RC.Neutral
                rbtn.BackgroundColor3 = nc rbtn.Text = nr rb.BackgroundColor3 = nc
                ril.Text = RI[nr] or "⚪"
            end)
            local nl = Instance.new("TextLabel", cont)
            nl.Size = UDim2.new(1,-100,0,22) nl.Position = UDim2.new(0,128,0,5) nl.BackgroundTransparency = 1
            nl.Text = (plr.DisplayName ~= plr.Name and plr.DisplayName or plr.Name)
            nl.TextColor3 = Color3.new(1,1,1)
            nl.Font = Enum.Font.GothamSemibold nl.TextSize = 14 nl.TextXAlignment = Enum.TextXAlignment.Left nl.TextTruncate = Enum.TextTruncate.AtEnd
            y = y+56
        end
    end
    PlayerListFrame.CanvasSize = UDim2.new(0,0,0,y)
end
UpdatePlayerList()
Players.PlayerAdded:Connect(function(plr)
    if not _S.PlayerRoles[plr.UserId] then _S.PlayerRoles[plr.UserId] = GetDefaultRole() end
    task.wait(0.5) UpdatePlayerList()
end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) UpdatePlayerList() end)
spawn(function() while task.wait(3) do UpdatePlayerList() end end)

-- Misc
local uc = createSection(pageMisc, "Utilities")
createToggle(uc, "Chat Spy", false, function(s)
    if s then
        if TextChatService:FindFirstChild('ChatWindowConfiguration') then TextChatService.ChatWindowConfiguration.Enabled = true end
        if TextChatService:FindFirstChild('ChatInputBarConfiguration') then TextChatService.ChatInputBarConfiguration.Enabled = true end
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    else
        if TextChatService:FindFirstChild('ChatWindowConfiguration') then TextChatService.ChatWindowConfiguration.Enabled = false end
        if TextChatService:FindFirstChild('ChatInputBarConfiguration') then TextChatService.ChatInputBarConfiguration.Enabled = false end
    end
end)

-- Move
local flyEnabled = false local flySpeed = 50 local flyConnection = nil
local flyBodyVelocity, flyBodyGyro = nil, nil
local function stopFly()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if flyBodyVelocity and flyBodyVelocity.Parent then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro and flyBodyGyro.Parent then flyBodyGyro:Destroy() flyBodyGyro = nil end
    local char = LocalPlayer.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = false end end
end
local function startFly()
    flyEnabled = true
    local char = LocalPlayer.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    flyBodyVelocity = Instance.new("BodyVelocity") flyBodyVelocity.Velocity = Vector3.zero flyBodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5) flyBodyVelocity.Parent = hrp
    flyBodyGyro = Instance.new("BodyGyro") flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5) flyBodyGyro.P = 1e4 flyBodyGyro.CFrame = hrp.CFrame flyBodyGyro.Parent = hrp
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        local camCF = workspace.CurrentCamera.CFrame local md = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then md = md + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then md = md - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then md = md - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then md = md + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then md = md - Vector3.new(0,1,0) end
        if flyBodyVelocity and flyBodyVelocity.Parent then flyBodyVelocity.Velocity = md.Magnitude > 0 and md.Unit * flySpeed or Vector3.zero end
        if flyBodyGyro and flyBodyGyro.Parent then flyBodyGyro.CFrame = camCF end
    end)
end
local MovementContent = createSection(pageMovement, "Движение")
LocalPlayer.CharacterAdded:Connect(function() if flyEnabled then task.wait(0.5) startFly() end end)
createToggle(MovementContent,"Fly",false,function(s) if s then startFly() else stopFly() end end)
createSlider(MovementContent,"Fly Speed",10,500,50,5,"%.0f",function(v) flySpeed=v end)
createToggle(MovementContent,"Noclip",false,function(s)
    if s then
        if _S.NoclipConnection then _S.NoclipConnection:Disconnect() end
        _S.NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character if not char then return end
            for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
        end)
    else
        if _S.NoclipConnection then _S.NoclipConnection:Disconnect() _S.NoclipConnection = nil end
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end end end
    end
end)

-- Menu
local menuOpen = false main.Visible = false
local openT = TweenService:Create(main,TweenInfo.new(0.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(820,520)})
local closeT = TweenService:Create(main,TweenInfo.new(0.34,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,0)})
local function toggleMenu()
    menuOpen = not menuOpen
    if menuOpen then main.Visible = true openT:Play()
    else closeT:Play() task.delay(0.35, function() if not menuOpen then main.Visible = false end end) end
end
closeBtn.MouseButton1Click:Connect(toggleMenu)

RunService.Heartbeat:Connect(CheckShot)
RunService.Heartbeat:Connect(CheckAutoReload)

UserInputService.InputEnded:Connect(function(i, gp)
    if gp then return end
    if _S.AimLockBindKey and _S.AimLockBindMode == "Hold" and isBindMatch(_S.AimLockBindKey, i) then
        _S.AimLockEnabled = false _S.AimLockLockedTarget = nil aimLockFovCircle.Visible = false
        if _S.AimLockConnection then _S.AimLockConnection:Disconnect() _S.AimLockConnection = nil end
    end
    if _S.MouseLockBindKey and _S.MouseLockBindMode == "Hold" and isBindMatch(_S.MouseLockBindKey, i) then
        _S.MouseLockEnabled = false _S.MouseLockLockedTarget = nil mouseLockFovCircle.Visible = false
        if _S.MouseLockConnection then _S.MouseLockConnection:Disconnect() _S.MouseLockConnection = nil end
    end
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift or i.KeyCode == Enum.KeyCode.End then toggleMenu() return end
    local function acc(v)
        if v.UserInputType == Enum.UserInputType.Keyboard then
            if v.KeyCode ~= Enum.KeyCode.Unknown then return v.KeyCode end
        elseif MOUSE_BUTTON_TYPES[v.UserInputType] then return v.UserInputType end
        return nil
    end
    local nb = acc(i)
    if _S.WaitingForAimLockBind and nb then _S.AimLockBindKey = nb _S.WaitingForAimLockBind = false return end
    if _S.WaitingForMouseLockBind and nb then
        _S.MouseLockBindKey = nb
        mb.Text = "Бинд: " .. getBindName(nb)
        mb.BackgroundColor3 = Color3.fromRGB(0,120,180)
        _S.WaitingForMouseLockBind = false
        return
    end
    if _S.AimLockBindKey and isBindMatch(_S.AimLockBindKey, i) then
        _S.AimLockEnabled = not _S.AimLockEnabled
        if _S.AimLockEnabled then if not _S.AimLockConnection then _S.AimLockConnection = RunService.RenderStepped:Connect(UpdateAimLock) end
        else _S.AimLockLockedTarget = nil aimLockFovCircle.Visible = false if _S.AimLockConnection then _S.AimLockConnection:Disconnect() _S.AimLockConnection = nil end end
    end
    if _S.MouseLockBindKey and isBindMatch(_S.MouseLockBindKey, i) then
        if _S.MouseLockBindMode == "Toggle" then
            _S.MouseLockEnabled = not _S.MouseLockEnabled
            if _S.MouseLockEnabled then if not _S.MouseLockConnection then _S.MouseLockConnection = RunService.RenderStepped:Connect(UpdateMouseLock) end
            else _S.MouseLockLockedTarget = nil mouseLockFovCircle.Visible = false if _S.MouseLockConnection then _S.MouseLockConnection:Disconnect() _S.MouseLockConnection = nil end end
        elseif _S.MouseLockBindMode == "Hold" then
            _S.MouseLockEnabled = true
            if not _S.MouseLockConnection then _S.MouseLockConnection = RunService.RenderStepped:Connect(UpdateMouseLock) end
        end
    end
end)

task.delay(0.15, function()
    main.Visible = true
    main.Size = UDim2.fromOffset(0, 0)
    openT:Play()
    task.delay(0.15, function() if allTabs[1] then allTabs[1].SetActive(true) switchToPage(pageLegit) end end)
end)

print("[EBY V TYZ] Loaded. RightShift / End — меню.")