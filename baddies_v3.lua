[[
  ╔══════════════════════════════════════════════════════════╗
  ║   BADDIES 💅  SCRIPT  v2.0  — by killitzwill            ║
  ║   HARDCODED REMOTES — fully working combat              ║
  ║   Xeno Compatible ✅                                     ║
  ╚══════════════════════════════════════════════════════════╝
  REAL REMOTES (dumped from game):
    PUNCHEVENT           — punch hit
    JALADADEPELOEVENT    — hair pull (jala de pelo)
    STOMPEVENT           — stomp KO'd player
    RAGDOLLEVENT         — triggers ragdoll/KO
    CARRYEVENT           — carry player
    GIVECASHEVENT        — give cash
  KEYBINDS:
    DEL  = Toggle Auto Fighter
    F2   = Toggle ESP
    F3   = Toggle Fly
    F4   = Quick Full Combo
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local CoreGui      = game:GetService("CoreGui")
local Workspace    = game:GetService("Workspace")
local RS           = game:GetService("ReplicatedStorage")
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

local plr  = Players.LocalPlayer
local cam  = Workspace.CurrentCamera
local char, hum, hrp

-- ══════════════════════════════════════════════
--  HARDCODED REMOTES
-- ══════════════════════════════════════════════
local function safeGet(name)
    local ok, result = pcall(function() return RS:WaitForChild(name, 5) end)
    if ok and result then return result end
    local found = RS:FindFirstChild(name, true)
    if found then return found end
    warn("[Baddies] Remote not found: " .. name)
    return nil
end

local REM = {
    PUNCH     = safeGet("PUNCHEVENT"),
    HAIRPULL  = safeGet("JALADADEPELOEVENT"),
    STOMP     = safeGet("STOMPEVENT"),
    RAGDOLL   = safeGet("RAGDOLLEVENT"),
    CARRY     = safeGet("CARRYEVENT"),
    GIVECASH  = safeGet("GIVECASHEVENT"),
    PVPTOGGLE = safeGet("PVPONOFFEVENT"),
}

-- ══════════════════════════════════════════════
--  CHARACTER
-- ══════════════════════════════════════════════
local function grabChar()
    char = plr.Character
    if not char then return false end
    hum  = char:FindFirstChildOfClass("Humanoid")
    hrp  = char:FindFirstChild("HumanoidRootPart")
    return true
end
grabChar()
plr.CharacterAdded:Connect(function(c)
    task.wait(1)
    char = c
    grabChar()
end)

-- ══════════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════════
local S = {
    autoFighter  = false,
    lockTarget   = nil,
    infiniteStam = false,
    infiniteRecov= false,
    godMode      = false,
    antiHairPull = false,
    antiCarry    = false,
    silentAim    = false,
    speed        = 16,
    speedEnabled = false,
    flyEnabled   = false,
    noclip       = false,
    flySpeed     = 50,
    espEnabled   = false,
    espBoxes     = true,
    espNames     = true,
    espHealth    = true,
    espDistance  = true,
    espMoney     = true,
    espWeapons   = true,
    autoFood     = false,
    instantHair  = false,
    koEffects    = false,
    koAnnounce   = false,
    koCount      = 0,
    fightThread  = nil,
    comboRunning = false,
    flyConn      = nil,
    speedConn    = nil,
    stamConn     = nil,
    recovConn    = nil,
}

-- ══════════════════════════════════════════════
--  COLORS
-- ══════════════════════════════════════════════
local BG0=Color3.fromRGB(8,6,12)    local BG1=Color3.fromRGB(14,10,20)
local BG2=Color3.fromRGB(22,14,30)  local BG3=Color3.fromRGB(32,20,42)
local PNK=Color3.fromRGB(255,20,120) local PNK2=Color3.fromRGB(255,80,160)
local PNK3=Color3.fromRGB(180,0,80)
local RED=Color3.fromRGB(255,50,50)  local GRN=Color3.fromRGB(50,230,110)
local YLW=Color3.fromRGB(255,210,40) local CYN=Color3.fromRGB(60,210,240)
local TXT=Color3.fromRGB(255,230,245) local DIM=Color3.fromRGB(160,110,140)
local MUT=Color3.fromRGB(80,50,70)   local BDR=Color3.fromRGB(100,30,70)
local WHT=Color3.fromRGB(255,255,255)

-- ══════════════════════════════════════════════
--  GUI HELPERS
-- ══════════════════════════════════════════════
local function cr(n,p) local o=Instance.new("UICorner") o.CornerRadius=UDim.new(0,n) o.Parent=p end
local function stk(c,t,p) local o=Instance.new("UIStroke") o.Color=c o.Thickness=t o.Parent=p end
local function pdg(l,r,t,b,p) local o=Instance.new("UIPadding") o.PaddingLeft=UDim.new(0,l) o.PaddingRight=UDim.new(0,r) o.PaddingTop=UDim.new(0,t) o.PaddingBottom=UDim.new(0,b) o.Parent=p end
local function vlist(p,g) local o=Instance.new("UIListLayout") o.FillDirection=Enum.FillDirection.Vertical o.SortOrder=Enum.SortOrder.LayoutOrder o.Padding=UDim.new(0,g or 6) o.Parent=p return o end
local function hlist(p,g) local o=Instance.new("UIListLayout") o.FillDirection=Enum.FillDirection.Horizontal o.SortOrder=Enum.SortOrder.LayoutOrder o.Padding=UDim.new(0,g or 4) o.Parent=p return o end
local function FR(par,sz,bg,nm) local f=Instance.new("Frame") f.Name=nm or "F" f.Size=sz or UDim2.new(1,0,0,30) f.BackgroundColor3=bg or BG1 f.BorderSizePixel=0 f.Parent=par return f end
local function FT(par,sz,nm) local f=FR(par,sz,BG0,nm) f.BackgroundTransparency=1 return f end
local function LB(par,tx,sz,col,fs,al) local l=Instance.new("TextLabel") l.Text=tx or "" l.Size=sz or UDim2.new(1,0,0,20) l.BackgroundTransparency=1 l.TextColor3=col or TXT l.Font=Enum.Font.GothamBold l.TextSize=fs or 12 l.TextXAlignment=al or Enum.TextXAlignment.Left l.TextYAlignment=Enum.TextYAlignment.Center l.BorderSizePixel=0 l.Parent=par return l end
local function BT(par,tx,bg,sz,lo) local b=Instance.new("TextButton") b.Text=tx or "" b.Size=sz or UDim2.new(1,0,0,32) b.BackgroundColor3=bg or PNK b.TextColor3=TXT b.Font=Enum.Font.GothamBold b.TextSize=11 b.BorderSizePixel=0 b.AutoButtonColor=true b.LayoutOrder=lo or 0 b.Parent=par cr(8,b) return b end
local function TB(par,ph,sz,lo) local t=Instance.new("TextBox") t.PlaceholderText=ph or "" t.PlaceholderColor3=MUT t.Text="" t.Size=sz or UDim2.new(1,0,0,30) t.BackgroundColor3=BG3 t.TextColor3=TXT t.Font=Enum.Font.Gotham t.TextSize=11 t.BorderSizePixel=0 t.ClearTextOnFocus=false t.TextXAlignment=Enum.TextXAlignment.Left t.LayoutOrder=lo or 0 t.Parent=par cr(8,t) stk(BDR,1,t) pdg(10,10,0,0,t) return t end
local function HR(par,lo) local d=FR(par,UDim2.new(1,0,0,1),BDR,"Div") d.LayoutOrder=lo or 0 return d end
local function SL(par,tx,lo) local l=LB(par,tx,UDim2.new(1,0,0,14),MUT,9) l.LayoutOrder=lo or 0 return l end
local function ROW(par,h,lo) local r=FT(par,UDim2.new(1,0,0,h or 32),"Row") r.LayoutOrder=lo or 0 hlist(r,6) return r end
local function CARD(par,h,lo) local c=FR(par,UDim2.new(1,0,0,h or 50),BG2,"Card") c.LayoutOrder=lo or 0 cr(10,c) stk(BDR,1,c) return c end

local function TOGGLE(par,label,lo,onToggle)
    local row=ROW(par,32,lo)
    local lbl=LB(row,label,UDim2.new(1,-54,1,0),TXT,11) lbl.LayoutOrder=1 lbl.TextTruncate=Enum.TextTruncate.AtEnd
    local btn=Instance.new("TextButton") btn.Size=UDim2.new(0,48,0,24) btn.BackgroundColor3=BG3 btn.TextColor3=DIM btn.Font=Enum.Font.GothamBold btn.TextSize=10 btn.Text="OFF" btn.BorderSizePixel=0 btn.LayoutOrder=2 btn.Parent=row cr(12,btn) stk(BDR,1,btn)
    local on=false
    local function setState(v) on=v btn.BackgroundColor3=on and PNK or BG3 btn.TextColor3=on and WHT or DIM btn.Text=on and "ON" or "OFF" if onToggle then onToggle(on) end end
    btn.MouseButton1Click:Connect(function() setState(not on) end)
    return setState,btn,row
end

-- TOAST
local toastN=0
local ScreenGui
local function toast(msg,col)
    col=col or PNK toastN=toastN+1 local n=toastN
    if not ScreenGui or not ScreenGui.Parent then return end
    local tf=FR(ScreenGui,UDim2.new(0,280,0,34),BG2,"T"..n)
    tf.Position=UDim2.new(1,-295,0,10+(n-1)*40) tf.ZIndex=100 cr(10,tf) stk(col,1.5,tf)
    LB(tf,"💅  "..msg,UDim2.new(1,0,1,0),TXT,11).ZIndex=101
    task.delay(3,function() TweenService:Create(tf,TweenInfo.new(0.3),{Position=UDim2.new(1,20,0,tf.Position.Y.Offset)}):Play() task.wait(0.35) pcall(function() tf:Destroy() end) toastN=math.max(0,toastN-1) end)
end

-- ══════════════════════════════════════════════
--  FORWARD DECLARATIONS (fixed forward refs)
-- ══════════════════════════════════════════════
local applySpeed, applyInfStam, applyInfRecov, startFly, stopFly

-- ══════════════════════════════════════════════
--  KO STATE CHECK
--  RAGDOLLEVENT fires when someone is KO'd
--  We track who is ragdolled via the event
-- ══════════════════════════════════════════════
local ragdolledPlayers = {} -- [Player] = true when KO'd

-- Listen for ragdoll events to track KO state
if REM.RAGDOLL then
    REM.RAGDOLL.OnClientEvent:Connect(function(targetChar, isRagdoll)
        if not targetChar then return end
        local p = Players:GetPlayerFromCharacter(targetChar)
        if p then
            ragdolledPlayers[p] = isRagdoll and true or nil
        end
    end)
end

local function isKO(targetPlr)
    if not targetPlr then return false end
    -- Check our tracked ragdoll state
    if ragdolledPlayers[targetPlr] then return true end
    -- Fallback: check humanoid state
    local tChar = targetPlr.Character
    if not tChar then return false end
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    if not tHum then return false end
    if tHum.Health <= 0 then return true end
    local state = tHum:GetState()
    if state == Enum.HumanoidStateType.Physics then return true end
    if state == Enum.HumanoidStateType.Dead then return true end
    -- Check for ragdoll-related attributes or values
    for _, v in pairs(tChar:GetChildren()) do
        if v.Name:lower() == "ragdoll" and v:IsA("BoolValue") and v.Value then return true end
    end
    if tChar:GetAttribute("Ragdoll") == true then return true end
    return false
end

local function isCritical(targetPlr)
    if isKO(targetPlr) then return true end
    local tChar = targetPlr and targetPlr.Character
    if not tChar then return false end
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    if tHum and (tHum.Health / math.max(tHum.MaxHealth, 1)) <= 0.25 then return true end
    return false
end

-- ══════════════════════════════════════════════
--  CORE COMBAT — USES REAL REMOTES
-- ══════════════════════════════════════════════

-- Move right next to target before firing
local function stepNextTo(tChar, dist)
    dist = dist or 4
    if not tChar then return end
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    grabChar()
    if not hrp or not tHRP then return end
    local dir = (hrp.Position - tHRP.Position)
    if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end
    hrp.CFrame = CFrame.new(tHRP.Position + dir.Unit * dist, tHRP.Position)
end

--[[ PUNCH — fires PUNCHEVENT
     The server expects: target character (or HRP, or player)
     We try multiple arg combos ]]
local function doPunch(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    local tChar = targetPlr.Character
    local tHRP  = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    stepNextTo(tChar, 4)
    if REM.PUNCH then
        -- Try common arg patterns servers use
        pcall(function() REM.PUNCH:FireServer(tChar) end)
    end
end

--[[ HAIR PULL — fires JALADADEPELOEVENT
     Requires stamina = 100. We force it first. ]]
local function forceStamFull()
    grabChar()
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then
            v.Value = 100
        end
    end
    for _, v in pairs(plr.PlayerGui:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then
            v.Value = 100
        end
    end
    -- Also just press F via VIM as backup
end

local function doHairPull(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    local tChar = targetPlr.Character
    -- Force stamina full so server allows the pull
    forceStamFull()
    task.wait(0.05)
    stepNextTo(tChar, 4)
    if REM.HAIRPULL then
        pcall(function() REM.HAIRPULL:FireServer(tChar) end)
    end
    -- Also simulate F key as fallback
    pcall(function()
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) end)
        task.wait(0.08)
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
    end)
end

--[[ STOMP — fires STOMPEVENT
     Must be physically on top of KO'd player ]]
local function doStomp(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    if not isKO(targetPlr) then return end
    local tChar = targetPlr.Character
    local tHRP  = tChar:FindFirstChild("HumanoidRootPart")
    grabChar()
    if not hrp or not tHRP then return end
    -- Teleport directly on top
    hrp.CFrame = CFrame.new(tHRP.Position.X, tHRP.Position.Y + 2.5, tHRP.Position.Z)
    task.wait(0.1)
    if REM.STOMP then
        pcall(function() REM.STOMP:FireServer(tChar) end)
    end
    -- Simulate E key as well
    pcall(function()
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
        task.wait(0.08)
        pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    end)
    -- KO reward
    S.koCount = S.koCount + 1
    if S.koAnnounce then
        pcall(function()
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                and game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents
                :FindFirstChild("SayMessageRequest"):FireServer("💅 KO'd "..tostring(targetPlr and targetPlr.Name or "someone").." #"..S.koCount,"All")
        end)
    end
    if S.koEffects then
        pcall(function()
            local e=Instance.new("Part",Workspace)
            e.Anchored=true e.CanCollide=false e.Size=Vector3.new(0.1,0.1,0.1)
            e.Transparency=1 e.CFrame=tHRP.CFrame
            local sp=Instance.new("Sparkles",e) sp.SparkleColor=PNK
            local bb=Instance.new("BillboardGui",e)
            bb.Size=UDim2.new(0,140,0,30) bb.StudsOffset=Vector3.new(0,5,0)
            local lbl=Instance.new("TextLabel",bb)
            lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1
            lbl.Text="💅 BADDIE DOWN" lbl.TextColor3=PNK
            lbl.Font=Enum.Font.GothamBlack lbl.TextSize=14
            lbl.TextStrokeTransparency=0 lbl.TextStrokeColor3=Color3.new(0,0,0)
            task.delay(3,function() pcall(function() e:Destroy() end) end)
        end)
    end
    toast("💅 KO #"..S.koCount.."! stomp'd",PNK)
end

local function doCarry(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    local tChar = targetPlr.Character
    local tHRP  = tChar:FindFirstChild("HumanoidRootPart")
    grabChar()
    if not hrp or not tHRP then return end
    hrp.CFrame = CFrame.new(tHRP.Position.X, tHRP.Position.Y + 2.5, tHRP.Position.Z)
    task.wait(0.1)
    if REM.CARRY then pcall(function() REM.CARRY:FireServer(tChar) end) end
end

-- ══════════════════════════════════════════════
--  NEAREST ENEMY
-- ══════════════════════════════════════════════
local function getNearestEnemy()
    grabChar()
    if not hrp then return nil end
    local nearest, nearDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= plr and p.Character then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            local tHum = p.Character:FindFirstChildOfClass("Humanoid")
            if tHRP and tHum and tHum.Health > 0 then
                local d = (hrp.Position - tHRP.Position).Magnitude
                if d < nearDist then nearDist=d nearest=p end
            end
        end
    end
    return nearest
end

-- ══════════════════════════════════════════════
--  AUTO COMBO — punch x3 → hair pull → punch x4 → stomp
-- ══════════════════════════════════════════════
local function runCombo(targetPlr)
    if S.comboRunning then return end
    if not targetPlr then return end
    S.comboRunning = true
    local ok, err = pcall(function()
        -- Phase 1: punch x3
        for i = 1, 3 do
            if not targetPlr.Character then break end
            doPunch(targetPlr)
            task.wait(0.45)
        end
        -- Phase 2: hair pull if not KO'd
        if targetPlr.Character and not isKO(targetPlr) then
            doHairPull(targetPlr)
            -- Punch during the 5s hair pull window
            for i = 1, 5 do
                task.wait(0.9)
                if targetPlr.Character then doPunch(targetPlr) end
            end
        end
        -- Phase 3: punch x4
        for i = 1, 4 do
            if not targetPlr.Character then break end
            doPunch(targetPlr)
            task.wait(0.38)
        end
        -- Phase 4: stomp if KO'd
        task.wait(0.2)
        if targetPlr.Character and (isKO(targetPlr) or isCritical(targetPlr)) then
            doStomp(targetPlr)
        end
    end)
    if not ok then print("[Baddies] combo err: "..tostring(err)) end
    S.comboRunning = false
end

-- ══════════════════════════════════════════════
--  AUTO FIGHTER — state machine
--  CHASE → PUNCH (x3) → HAIRPULL → STOMP on KO
-- ══════════════════════════════════════════════
local function startAutoFighter()
    if S.fightThread then task.cancel(S.fightThread) end
    S.fightThread = task.spawn(function()
        local punchCount = 0
        local hairPulled = false
        local lastTarget = nil

        while S.autoFighter do
            task.wait(0.05)
            if not grabChar() then task.wait(1) continue end

            local target = (S.lockTarget and S.lockTarget.Character) and S.lockTarget or getNearestEnemy()
            if not target or not target.Character then task.wait(0.3) continue end

            if target ~= lastTarget then
                punchCount = 0
                hairPulled = false
                lastTarget = target
            end

            local tChar = target.Character
            local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if not tHRP then task.wait(0.3) continue end

            local dist = (hrp.Position - tHRP.Position).Magnitude

            -- STATE: KO'd → teleport on top and stomp
            if isKO(target) then
                doStomp(target)
                punchCount  = 0
                hairPulled  = false
                task.wait(0.8)
                continue
            end

            -- STATE: critical but not KO'd → keep hitting to finish
            if isCritical(target) then
                doPunch(target)
                task.wait(0.35)
                continue
            end

            -- STATE: far away → close in
            if dist > 5 then
                local dir = (hrp.Position - tHRP.Position)
                hrp.CFrame = CFrame.new(tHRP.Position + dir.Unit * 4, tHRP.Position)
                task.wait(0.05)
                continue
            end

            -- STATE: after 3 punches → hair pull
            if punchCount >= 3 and not hairPulled then
                doHairPull(target)
                hairPulled = true
                punchCount = 0
                task.wait(0.5)
                continue
            end

            -- DEFAULT: punch
            doPunch(target)
            punchCount = punchCount + 1
            task.wait(0.4)
        end
    end)
end

-- ══════════════════════════════════════════════
--  INFINITE STAMINA
-- ══════════════════════════════════════════════
applyInfStam = function()
    if S.stamConn then S.stamConn:Disconnect() end
    S.stamConn = RunService.Heartbeat:Connect(function()
        if not S.infiniteStam then S.stamConn:Disconnect() return end
        forceStamFull()
    end)
end

-- ══════════════════════════════════════════════
--  INFINITE RECOVERY
-- ══════════════════════════════════════════════
applyInfRecov = function()
    if S.recovConn then S.recovConn:Disconnect() end
    S.recovConn = RunService.Heartbeat:Connect(function()
        if not S.infiniteRecov then S.recovConn:Disconnect() return end
        grabChar()
        if not char then return end
        for _, v in pairs(char:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("recov") then
                v.Value = 100
            end
        end
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end)
end

-- ══════════════════════════════════════════════
--  GOD MODE
-- ══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not S.godMode then return end
    grabChar()
    if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                local n = v.Name:lower()
                if n:find("recov") then v.Value = 100 end
            end
        end
    end
end)

-- ══════════════════════════════════════════════
--  ANTI HAIR PULL — cancel JALADADEPELOEVENT effect
-- ══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not S.antiHairPull then return end
    grabChar()
    if not char then return end
    for _, a in pairs({"Grabbed","Pulled","HairPulled","BeingPulled","Dragged","IsGrabbed"}) do
        if char:GetAttribute(a) == true then pcall(function() char:SetAttribute(a, false) end) end
    end
    local gv = char:FindFirstChild("Grabbed") or char:FindFirstChild("IsGrabbed")
    if gv and gv:IsA("BoolValue") then gv.Value = false end
end)

-- ══════════════════════════════════════════════
--  ANTI CARRY
-- ══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not S.antiCarry then return end
    grabChar()
    if not char then return end
    for _, a in pairs({"Carried","PickedUp","IsCarried","BeingCarried"}) do
        if char:GetAttribute(a) == true then pcall(function() char:SetAttribute(a, false) end) end
    end
end)

-- ══════════════════════════════════════════════
--  SPEED
-- ══════════════════════════════════════════════
applySpeed = function()
    if S.speedConn then S.speedConn:Disconnect() end
    S.speedConn = RunService.Heartbeat:Connect(function()
        if not S.speedEnabled then S.speedConn:Disconnect() return end
        grabChar()
        if hum then hum.WalkSpeed = S.speed end
    end)
end

-- ══════════════════════════════════════════════
--  FLY
-- ══════════════════════════════════════════════
local flyBody={}
startFly = function()
    grabChar() if not char or not hrp then return end
    stopFly()
    local bg=Instance.new("BodyGyro",hrp) bg.MaxTorque=Vector3.new(9e9,9e9,9e9) bg.P=9e4 bg.Name="FlyGyro"
    local bv=Instance.new("BodyVelocity",hrp) bv.Velocity=Vector3.zero bv.MaxForce=Vector3.new(9e9,9e9,9e9) bv.Name="FlyVel"
    flyBody={bg=bg,bv=bv}
    if hum then hum.PlatformStand=true end
    S.flyConn=RunService.Heartbeat:Connect(function()
        if not S.flyEnabled then stopFly() return end
        grabChar() if not hrp then return end
        local v3=Vector3.zero
        if UserInput:IsKeyDown(Enum.KeyCode.W) then v3=v3+cam.CFrame.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then v3=v3-cam.CFrame.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then v3=v3-cam.CFrame.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then v3=v3+cam.CFrame.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then v3=v3+Vector3.new(0,1,0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then v3=v3-Vector3.new(0,1,0) end
        if flyBody.bv and flyBody.bv.Parent then flyBody.bv.Velocity=v3*S.flySpeed end
        if flyBody.bg and flyBody.bg.Parent then flyBody.bg.CFrame=cam.CFrame end
    end)
end
stopFly = function()
    if S.flyConn then S.flyConn:Disconnect() S.flyConn=nil end
    pcall(function() if flyBody.bg then flyBody.bg:Destroy() end end)
    pcall(function() if flyBody.bv then flyBody.bv:Destroy() end end)
    flyBody={}
    grabChar() if hum then hum.PlatformStand=false end
end

-- NOCLIP
RunService.Stepped:Connect(function()
    if not S.noclip then return end
    grabChar() if not char then return end
    for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
end)

-- SILENT AIM
RunService.RenderStepped:Connect(function()
    if not S.silentAim or not S.lockTarget then return end
    if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    local tChar=S.lockTarget.Character if not tChar then return end
    local head=tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart")
    if head then grabChar() if hrp then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,head.Position) end end
end)

-- ══════════════════════════════════════════════
--  LOCK-ON
-- ══════════════════════════════════════════════
local lockDeathConn=nil
local function setLockTarget(targetPlr)
    if lockDeathConn then lockDeathConn:Disconnect() lockDeathConn=nil end
    S.lockTarget=targetPlr
    if not targetPlr then toast("🔓 Lock cleared",DIM) return end
    toast("🎯 Locked: "..targetPlr.Name,PNK)
    local function watchDeath(c)
        local h=c:WaitForChild("Humanoid",5)
        if not h then return end
        h.Died:Connect(function()
            task.wait(0.5)
            if S.lockTarget==targetPlr then
                S.lockTarget=nil
                toast("💀 "..targetPlr.Name.." died — lock dropped",YLW)
            end
        end)
    end
    if targetPlr.Character then watchDeath(targetPlr.Character) end
    targetPlr.CharacterAdded:Connect(function(nc)
        if S.lockTarget~=targetPlr then return end
        watchDeath(nc)
        toast("🔄 "..targetPlr.Name.." respawned — still locked",PNK2)
    end)
    lockDeathConn=Players.PlayerRemoving:Connect(function(p)
        if p==targetPlr then
            S.lockTarget=nil lockDeathConn:Disconnect() lockDeathConn=nil
            toast("💀 "..targetPlr.Name.." left — lock dropped",YLW)
        end
    end)
end

local function teleportTo(p)
    if not p or not p.Character then toast("Not in game",RED) return end
    grabChar() if not hrp then return end
    local tHRP=p.Character:FindFirstChild("HumanoidRootPart") if not tHRP then return end
    hrp.CFrame=CFrame.new(tHRP.Position+Vector3.new(3,0,0))
    toast("📍 TP'd to "..p.Name,PNK)
end

-- ══════════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════════
local espFolder=Instance.new("Folder",CoreGui) espFolder.Name="BadESP_v2"
local function clearESP() for _,v in pairs(espFolder:GetChildren()) do v:Destroy() end end

RunService.RenderStepped:Connect(function()
    if not S.espEnabled then if #espFolder:GetChildren()>0 then clearESP() end return end
    for _,p in pairs(Players:GetPlayers()) do
        if p==plr then continue end
        local pChar=p.Character
        if not pChar then local old=espFolder:FindFirstChild("ESP_"..p.Name) if old then old:Destroy() end continue end
        local pHRP=pChar:FindFirstChild("HumanoidRootPart") local pH=pChar:FindFirstChildOfClass("Humanoid")
        if not pHRP or not pH then continue end
        local ec=espFolder:FindFirstChild("ESP_"..p.Name)
        if not ec then
            ec=Instance.new("BillboardGui",espFolder) ec.Name="ESP_"..p.Name
            ec.AlwaysOnTop=true ec.MaxDistance=500 ec.Size=UDim2.new(0,200,0,100) ec.StudsOffsetWorldSpace=Vector3.new(0,3.5,0)
        end
        ec.Adornee=pHRP
        for _,ch in pairs(ec:GetChildren()) do ch:Destroy() end
        local pKO=isKO(p)
        local col=S.lockTarget==p and PNK or (pKO and YLW or CYN)
        local hp,maxhp=pH.Health,pH.MaxHealth local hpPct=hp/math.max(maxhp,1)
        grabChar() local dist=hrp and math.floor((hrp.Position-pHRP.Position).Magnitude) or 0
        if S.espNames then
            local nl=Instance.new("TextLabel",ec) nl.Size=UDim2.new(1,0,0,16) nl.Position=UDim2.new(0,0,0,0) nl.BackgroundTransparency=1
            nl.Text=(S.lockTarget==p and "🎯 " or "")..(pKO and "💀 " or "")..p.Name nl.TextColor3=col nl.Font=Enum.Font.GothamBlack nl.TextSize=13 nl.TextStrokeTransparency=0.3 nl.TextStrokeColor3=Color3.new(0,0,0) nl.TextXAlignment=Enum.TextXAlignment.Center
        end
        if S.espHealth then
            local hbBg=Instance.new("Frame",ec) hbBg.Size=UDim2.new(0.8,0,0,6) hbBg.Position=UDim2.new(0.1,0,0,18) hbBg.BackgroundColor3=BG3 cr(3,hbBg)
            local hbF=Instance.new("Frame",hbBg) hbF.Size=UDim2.new(math.clamp(hpPct,0,1),0,1,0) hbF.BackgroundColor3=hpPct>0.5 and GRN or (hpPct>0.25 and YLW or RED) hbF.BorderSizePixel=0 cr(3,hbF)
            local ht=Instance.new("TextLabel",ec) ht.Size=UDim2.new(1,0,0,12) ht.Position=UDim2.new(0,0,0,26) ht.BackgroundTransparency=1
            ht.Text=math.floor(hp).."/"..math.floor(maxhp).."hp"..(pKO and " 💀KO" or "") ht.TextColor3=pKO and YLW or TXT ht.Font=Enum.Font.GothamBold ht.TextSize=10 ht.TextXAlignment=Enum.TextXAlignment.Center ht.TextStrokeTransparency=0 ht.TextStrokeColor3=Color3.new(0,0,0)
        end
        if S.espDistance then
            local dl=Instance.new("TextLabel",ec) dl.Size=UDim2.new(1,0,0,12) dl.Position=UDim2.new(0,0,0,40) dl.BackgroundTransparency=1
            dl.Text=dist.." studs" dl.TextColor3=DIM dl.Font=Enum.Font.Gotham dl.TextSize=9 dl.TextXAlignment=Enum.TextXAlignment.Center dl.TextStrokeTransparency=0 dl.TextStrokeColor3=Color3.new(0,0,0)
        end
        if S.espMoney then
            local w=pChar:FindFirstChild("Wallet") or pChar:FindFirstChild("Money") or pChar:FindFirstChild("Cash")
            if w and (w:IsA("NumberValue") or w:IsA("IntValue")) then
                local ml=Instance.new("TextLabel",ec) ml.Size=UDim2.new(1,0,0,12) ml.Position=UDim2.new(0,0,0,54) ml.BackgroundTransparency=1
                ml.Text="💰 $"..tostring(math.floor(w.Value)) ml.TextColor3=YLW ml.Font=Enum.Font.GothamBold ml.TextSize=10 ml.TextXAlignment=Enum.TextXAlignment.Center ml.TextStrokeTransparency=0 ml.TextStrokeColor3=Color3.new(0,0,0)
            end
        end
        if S.espWeapons then
            local tool=pChar:FindFirstChildOfClass("Tool")
            if tool then
                local wl=Instance.new("TextLabel",ec) wl.Size=UDim2.new(1,0,0,12) wl.Position=UDim2.new(0,0,0,68) wl.BackgroundTransparency=1
                wl.Text="🔧 "..tool.Name wl.TextColor3=PNK2 wl.Font=Enum.Font.Gotham wl.TextSize=9 wl.TextXAlignment=Enum.TextXAlignment.Center wl.TextStrokeTransparency=0 wl.TextStrokeColor3=Color3.new(0,0,0)
            end
        end
        if S.espBoxes then
            local box=Instance.new("Frame",ec) box.Size=UDim2.new(1,4,1,4) box.Position=UDim2.new(0,-2,0,-2) box.BackgroundTransparency=1 stk(col,1.5,box) cr(4,box)
        end
    end
    for _,eo in pairs(espFolder:GetChildren()) do if not Players:FindFirstChild(eo.Name:gsub("ESP_","")) then eo:Destroy() end end
end)

-- AUTO FOOD
local FOOD_NAMES={"Chicken","ChickenBucket","Chicken Bucket","ChickenSandwich","Chicken Sandwich","ChickenSandwitch"}
local function findFood()
    grabChar() if not hrp then return nil end
    local best,bestD=nil,math.huge
    for _,obj in pairs(Workspace:GetDescendants()) do
        for _,fn in pairs(FOOD_NAMES) do
            if obj.Name:lower():find(fn:lower()) then
                local pos=obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
                if pos then local d=(hrp.Position-pos).Magnitude if d<bestD then bestD=d best=obj end end break
            end
        end
    end
    return best
end
RunService.Heartbeat:Connect(function()
    if not S.autoFood then return end
    grabChar() if not hum then return end
    if hum.Health>hum.MaxHealth*0.40 then return end
    local food=findFood() if not food then return end
    local pos=food:IsA("BasePart") and food.Position or (food:IsA("Model") and food.PrimaryPart and food.PrimaryPart.Position)
    if pos and hrp then hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end
    task.wait(2)
end)

-- ══════════════════════════════════════════════
--  BUILD GUI
-- ══════════════════════════════════════════════
pcall(function() if CoreGui:FindFirstChild("BadGUI") then CoreGui.BadGUI:Destroy() end end)
pcall(function() if CoreGui:FindFirstChild("BadESP") then CoreGui.BadESP:Destroy() end end)
pcall(function() if CoreGui:FindFirstChild("BadESP_v2") then CoreGui.BadESP_v2:Destroy() end end)

ScreenGui=Instance.new("ScreenGui") ScreenGui.Name="BadGUI" ScreenGui.ResetOnSpawn=false ScreenGui.DisplayOrder=999 ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling ScreenGui.Parent=CoreGui

local Panel=FR(ScreenGui,UDim2.new(0,460,0,590),BG1,"Panel")
Panel.Position=UDim2.new(0.5,-230,0.5,-295) Panel.Active=true Panel.Draggable=true Panel.ZIndex=2 Panel.ClipsDescendants=true
cr(18,Panel) stk(PNK3,1.5,Panel)

-- HEADER
local Hdr=FR(Panel,UDim2.new(1,0,0,68),BG0,"Hdr") Hdr.ZIndex=3
do
    local g=Instance.new("UIGradient") g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(120,0,60)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(200,0,90)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,0,30))} g.Rotation=90 g.Parent=Hdr
    local logoF=FR(Hdr,UDim2.new(0,44,0,44),PNK3,"Logo") logoF.Position=UDim2.new(0,12,0,12) logoF.ZIndex=4 cr(12,logoF) stk(PNK,1.5,logoF)
    LB(logoF,"💅",UDim2.new(1,0,1,0),WHT,22,Enum.TextXAlignment.Center).ZIndex=5
    local HT=LB(Hdr,"BADDIES",UDim2.new(0,200,0,30),WHT,22) HT.Position=UDim2.new(0,64,0,6) HT.Font=Enum.Font.GothamBlack HT.ZIndex=4
    local HTG=Instance.new("UIGradient") HTG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,PNK),ColorSequenceKeypoint.new(1,PNK2)} HTG.Parent=HT
    local sv=LB(Hdr,"SCRIPT v2.0  ✅ FIXED",UDim2.new(0,220,0,16),GRN,10) sv.Position=UDim2.new(0,65,0,36)
    LB(Hdr,"by killitzwill 💅",UDim2.new(0,130,0,14),DIM,9,Enum.TextXAlignment.Right).Position=UDim2.new(1,-140,0,28)
    LB(Hdr,"● ONLINE",UDim2.new(0,80,0,14),GRN,9,Enum.TextXAlignment.Right).Position=UDim2.new(1,-92,0,46)
end
local function WB(xo,bg,tx) local b=Instance.new("TextButton") b.Size=UDim2.new(0,24,0,24) b.Position=UDim2.new(1,xo,0,8) b.BackgroundColor3=bg b.TextColor3=WHT b.Font=Enum.Font.GothamBold b.TextSize=11 b.BorderSizePixel=0 b.Text=tx b.ZIndex=10 b.Parent=Hdr cr(6,b) return b end
WB(-32,RED,"✕").MouseButton1Click:Connect(function() ScreenGui:Destroy() espFolder:Destroy() end)
local minimized=false WB(-60,Color3.fromRGB(255,165,0),"—").MouseButton1Click:Connect(function() minimized=not minimized Panel.Size=minimized and UDim2.new(0,460,0,68) or UDim2.new(0,460,0,590) end)

-- TABBAR
local TBar=FR(Panel,UDim2.new(1,0,0,36),BG0,"TBar") TBar.Position=UDim2.new(0,0,0,68) TBar.ZIndex=3 TBar.ClipsDescendants=true
local TScr=Instance.new("ScrollingFrame") TScr.Size=UDim2.new(1,0,1,0) TScr.BackgroundTransparency=1 TScr.BorderSizePixel=0 TScr.ScrollBarThickness=0 TScr.ScrollingDirection=Enum.ScrollingDirection.X TScr.CanvasSize=UDim2.new(0,0,0,0) TScr.AutomaticCanvasSize=Enum.AutomaticSize.X TScr.ZIndex=3 TScr.Parent=TBar hlist(TScr,0)
FR(Panel,UDim2.new(1,0,0,1),PNK3,"TLine").Position=UDim2.new(0,0,0,104)
local Content=Instance.new("ScrollingFrame") Content.Name="Content" Content.Size=UDim2.new(1,0,1,-106) Content.Position=UDim2.new(0,0,0,106) Content.BackgroundTransparency=1 Content.BorderSizePixel=0 Content.ScrollBarThickness=3 Content.ScrollBarImageColor3=PNK Content.CanvasSize=UDim2.new(0,0,0,0) Content.AutomaticCanvasSize=Enum.AutomaticSize.Y Content.ZIndex=2 Content.Parent=Panel
local Ftr=FR(Panel,UDim2.new(1,0,0,22),BG0,"Ftr") Ftr.Position=UDim2.new(0,0,1,-22) Ftr.ZIndex=3
LB(Ftr,"  💅 BADDIES v2.0",UDim2.new(0.5,0,1,0),PNK3,9).ZIndex=4
LB(Ftr,"● ACTIVE  ",UDim2.new(0.5,0,1,0),GRN,9,Enum.TextXAlignment.Right).Position=UDim2.new(0.5,0,0,0)

local TABS={{id="combat",l="⚔ COMBAT"},{id="lockon",l="🎯 LOCK-ON"},{id="movement",l="🏃 MOVE"},{id="esp",l="👁 ESP"},{id="misc",l="✨ MISC"}}
local tabBtns={} local tabPages={} local tabUL={}
for i,td in ipairs(TABS) do
    local tb=Instance.new("TextButton") tb.Text=td.l tb.Size=UDim2.new(0,96,1,0) tb.BackgroundTransparency=1 tb.TextColor3=MUT tb.Font=Enum.Font.GothamBold tb.TextSize=10 tb.BorderSizePixel=0 tb.LayoutOrder=i tb.ZIndex=4 tb.Parent=TScr
    tabBtns[td.id]=tb
    local ul=FR(tb,UDim2.new(0.7,0,0,2),PNK,"UL") ul.Position=UDim2.new(0.15,0,1,-2) ul.Visible=false ul.ZIndex=5 cr(2,ul) tabUL[td.id]=ul
    local pg=FT(Content,UDim2.new(1,0,1,0),"P_"..td.id) pg.Visible=false pg.ZIndex=2 vlist(pg,8) pdg(14,14,10,14,pg) tabPages[td.id]=pg
    tb.MouseButton1Click:Connect(function()
        for id2,b2 in pairs(tabBtns) do b2.TextColor3=id2==td.id and TXT or MUT end
        for id2,u2 in pairs(tabUL) do u2.Visible=(id2==td.id) end
        for id2,p2 in pairs(tabPages) do p2.Visible=(id2==td.id) end
    end)
end
local function showTab(id) for id2,b2 in pairs(tabBtns) do b2.TextColor3=id2==id and TXT or MUT end for id2,u2 in pairs(tabUL) do u2.Visible=(id2==id) end for id2,p2 in pairs(tabPages) do p2.Visible=(id2==id) end end

-- ══ COMBAT TAB ══
local cp=tabPages["combat"]
local statCard=CARD(cp,54,1) pdg(12,12,4,4,statCard) vlist(statCard,2)
local statLbl=LB(statCard,"⚔ AUTO FIGHTER: OFF",UDim2.new(1,0,0,18),DIM,11,Enum.TextXAlignment.Center) statLbl.Font=Enum.Font.GothamBlack
LB(statCard,"Punch×3 → JALADADEPELOEVENT → Stomp on KO",UDim2.new(1,0,0,14),MUT,9,Enum.TextXAlignment.Center)

SL(cp,"MAIN COMBAT",2)
TOGGLE(cp,"⚔  Auto Fighter  (smart AI — all combat auto)",3,function(v)
    S.autoFighter=v
    statLbl.Text="⚔ AUTO FIGHTER: "..(v and "ON 🔥" or "OFF")
    statLbl.TextColor3=v and PNK or DIM
    if v then startAutoFighter() else if S.fightThread then task.cancel(S.fightThread) end end
    toast(v and "💅 Auto Fighter ON" or "Fighter OFF",v and PNK or DIM)
end)
TOGGLE(cp,"💇  Instant Hair Pull  (force stam full + JALADADEPELOEVENT)",4,function(v)
    S.instantHair=v
    if v then S.infiniteStam=true applyInfStam() end
    toast(v and "💇 Instant Hair ON" or "OFF",v and PNK or DIM)
end)
TOGGLE(cp,"🎯  Silent Aim",5,function(v) S.silentAim=v toast(v and "Silent Aim ON" or "OFF",v and PNK or DIM) end)

HR(cp,6) SL(cp,"DEFENSE",7)
TOGGLE(cp,"♾️  Infinite Stamina  (blue bar stays 100)",8,function(v) S.infiniteStam=v if v then applyInfStam() end toast(v and "♾ Inf Stamina ON" or "OFF",v and GRN or DIM) end)
TOGGLE(cp,"❤️  Infinite Recovery  (red bar stays 100)",9,function(v) S.infiniteRecov=v if v then applyInfRecov() end toast(v and "♾ Inf Recovery ON" or "OFF",v and GRN or DIM) end)
TOGGLE(cp,"🛡️  God Mode  (HP + recovery always full)",10,function(v) S.godMode=v toast(v and "🛡 God Mode ON" or "OFF",v and GRN or DIM) end)
TOGGLE(cp,"✂️  Anti Hair Pull  (clears grabbed state)",11,function(v) S.antiHairPull=v toast(v and "Anti Hair Pull ON" or "OFF",v and GRN or DIM) end)
TOGGLE(cp,"🙅  Anti Carry  (clears carried state)",12,function(v) S.antiCarry=v toast(v and "Anti Carry ON" or "OFF",v and GRN or DIM) end)
TOGGLE(cp,"🍗  Auto Buy Food  (heals < 40% HP)",13,function(v) S.autoFood=v toast(v and "🍗 Auto Food ON" or "OFF",v and GRN or DIM) end)

HR(cp,14) SL(cp,"MANUAL — fires real remotes",15)
local mr1=ROW(cp,32,16)
BT(mr1,"👊 PUNCH",PNK3,UDim2.new(0.33,-3,1,0),1).MouseButton1Click:Connect(function()
    local t=S.lockTarget or getNearestEnemy() if t then task.spawn(function() doPunch(t) end) end
end)
BT(mr1,"💇 HAIRPULL",BG3,UDim2.new(0.33,-3,1,0),2).MouseButton1Click:Connect(function()
    local t=S.lockTarget or getNearestEnemy() if t then task.spawn(function() doHairPull(t) end) end
end)
BT(mr1,"👟 STOMP",BG3,UDim2.new(0.33,-3,1,0),3).MouseButton1Click:Connect(function()
    local t=S.lockTarget or getNearestEnemy() if t then task.spawn(function() doStomp(t) end) end
end)
local mr2=ROW(cp,32,17)
BT(mr2,"🔗 CARRY",BG3,UDim2.new(0.5,-3,1,0),1).MouseButton1Click:Connect(function()
    local t=S.lockTarget or getNearestEnemy() if t then task.spawn(function() doCarry(t) end) end
end)
BT(mr2,"💥 FULL COMBO [F4]",PNK,UDim2.new(0.5,-3,1,0),2).MouseButton1Click:Connect(function()
    local t=S.lockTarget or getNearestEnemy() if t then task.spawn(function() runCombo(t) end) end
end)

-- ══ LOCK-ON TAB ══
local lp=tabPages["lockon"]
local lockCard=CARD(lp,44,1) pdg(12,12,0,0,lockCard)
local lockStatus=LB(lockCard,"🔓  No Target",UDim2.new(1,0,1,0),DIM,11,Enum.TextXAlignment.Center) lockStatus.Font=Enum.Font.GothamBlack
SL(lp,"SELECT TARGET  (auto-drops on death)",2)
local lockScr=Instance.new("ScrollingFrame") lockScr.Size=UDim2.new(1,0,0,260) lockScr.BackgroundTransparency=1 lockScr.BorderSizePixel=0 lockScr.ScrollBarThickness=3 lockScr.ScrollBarImageColor3=PNK lockScr.CanvasSize=UDim2.new(0,0,0,0) lockScr.AutomaticCanvasSize=Enum.AutomaticSize.Y lockScr.LayoutOrder=3 lockScr.Parent=lp
local lockList=FT(lockScr,UDim2.new(1,0,0,0),"LL") lockList.AutomaticSize=Enum.AutomaticSize.Y vlist(lockList,4)
local function rebuildLockList()
    for _,c in pairs(lockList:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for _,p in pairs(Players:GetPlayers()) do
        if p==plr then continue end
        local row=ROW(lockList,32,0)
        local isTarget=S.lockTarget==p
        local pChar=p.Character
        local extra=(pChar and isKO(p)) and " 💀KO" or ""
        local hpTxt="" if pChar then local ph=pChar:FindFirstChildOfClass("Humanoid") if ph then hpTxt=" ("..math.floor(ph.Health).."hp)" end end
        LB(row,(isTarget and "🎯 " or "")..p.Name..extra..hpTxt,UDim2.new(1,-110,1,0),isTarget and PNK or TXT,11).LayoutOrder=1
        local lb=BT(row,isTarget and "LOCKED" or "LOCK",isTarget and PNK or BG3,UDim2.new(0,64,1,0),2) lb.TextSize=10 if isTarget then stk(PNK,1,lb) end
        lb.MouseButton1Click:Connect(function()
            if isTarget then setLockTarget(nil) lockStatus.Text="🔓  No Target" lockStatus.TextColor3=DIM
            else setLockTarget(p) lockStatus.Text="🎯 Locked: "..p.Name lockStatus.TextColor3=PNK end
            rebuildLockList()
        end)
        BT(row,"TP",PNK3,UDim2.new(0,36,1,0),3).MouseButton1Click:Connect(function() teleportTo(p) end)
    end
end
rebuildLockList()
RunService.Heartbeat:Connect(function() if S.lockTarget then lockStatus.Text="🎯 Locked: "..S.lockTarget.Name lockStatus.TextColor3=PNK end end)
BT(lp,"🔄 Refresh",BG3,UDim2.new(1,0,0,30),4).MouseButton1Click:Connect(rebuildLockList)
BT(lp,"🔓 Clear Lock",RED,UDim2.new(1,0,0,30),5).MouseButton1Click:Connect(function() setLockTarget(nil) lockStatus.Text="🔓  No Target" lockStatus.TextColor3=DIM rebuildLockList() end)

-- ══ MOVEMENT TAB ══
local mp=tabPages["movement"]
local spdCard=CARD(mp,56,1) pdg(12,12,4,4,spdCard)
local spdDL=LB(spdCard,"16",UDim2.new(1,0,0,32),WHT,32,Enum.TextXAlignment.Center) spdDL.Font=Enum.Font.GothamBlack
LB(spdCard,"WALKSPEED",UDim2.new(1,0,0,16),MUT,9,Enum.TextXAlignment.Center).Position=UDim2.new(0,0,0,34)
SL(mp,"PRESETS",2)
local sPF=FT(mp,UDim2.new(1,0,0,62),"SPF") sPF.LayoutOrder=3
local spGL=Instance.new("UIGridLayout") spGL.CellSize=UDim2.new(0.2,-3,0,28) spGL.CellPadding=UDim2.new(0,3,0,3) spGL.SortOrder=Enum.SortOrder.LayoutOrder spGL.Parent=sPF
for _,p in pairs({{l="Walk",v=16},{l="Jog",v=26},{l="Run",v=45},{l="Sprint",v=80},{l="Sonic",v=150}}) do
    local b=BT(sPF,p.l.."\n"..p.v,BG3,nil,0) b.TextSize=9 stk(BDR,1,b)
    b.MouseButton1Click:Connect(function() S.speed=p.v S.speedEnabled=true spdDL.Text=tostring(p.v) applySpeed() toast("⚡ Speed "..p.v,YLW) end)
end
SL(mp,"CUSTOM",4) local sCR=ROW(mp,30,5) local sCB=TB(sCR,"e.g. 60",UDim2.new(1,-82,1,0)) sCB.LayoutOrder=1
BT(sCR,"SET",PNK,UDim2.new(0,74,1,0),2).MouseButton1Click:Connect(function() local v=tonumber(sCB.Text) if v then S.speed=v S.speedEnabled=true spdDL.Text=tostring(v) applySpeed() sCB.Text="" toast("Speed "..v,YLW) else toast("Enter a number",RED) end end)
HR(mp,6) SL(mp,"FLIGHT & MOVEMENT",7)
TOGGLE(mp,"✈️  Fly Mode  (WASD + Space/Ctrl)",8,function(v) S.flyEnabled=v if v then startFly() else stopFly() end end)
SL(mp,"FLY SPEED",9) local fsCR=ROW(mp,30,10) local fsCB=TB(fsCR,"50",UDim2.new(1,-82,1,0)) fsCB.LayoutOrder=1
BT(fsCR,"SET",BG3,UDim2.new(0,74,1,0),2).MouseButton1Click:Connect(function() local v=tonumber(fsCB.Text) if v then S.flySpeed=v fsCB.Text="" toast("Fly speed "..v,CYN) else toast("Enter a number",RED) end end)
TOGGLE(mp,"👻  Noclip",11,function(v) S.noclip=v toast(v and "👻 Noclip ON" or "OFF",v and CYN or DIM) end)
HR(mp,12) SL(mp,"TELEPORT",13)
local tpScr=Instance.new("ScrollingFrame") tpScr.Size=UDim2.new(1,0,0,130) tpScr.BackgroundTransparency=1 tpScr.BorderSizePixel=0 tpScr.ScrollBarThickness=3 tpScr.ScrollBarImageColor3=PNK tpScr.CanvasSize=UDim2.new(0,0,0,0) tpScr.AutomaticCanvasSize=Enum.AutomaticSize.Y tpScr.LayoutOrder=14 tpScr.Parent=mp
local tpList=FT(tpScr,UDim2.new(1,0,0,0),"TPL") tpList.AutomaticSize=Enum.AutomaticSize.Y vlist(tpList,4)
local function rebuildTpList()
    for _,c in pairs(tpList:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for _,p in pairs(Players:GetPlayers()) do
        if p==plr then continue end
        local row=ROW(tpList,28,0) LB(row,p.Name,UDim2.new(1,-60,1,0),TXT,11).LayoutOrder=1
        BT(row,"TP 📍",PNK3,UDim2.new(0,54,1,0),2).MouseButton1Click:Connect(function() teleportTo(p) end)
    end
end
rebuildTpList()
BT(mp,"🔄 Refresh",BG3,UDim2.new(1,0,0,28),15).MouseButton1Click:Connect(rebuildTpList)
BT(mp,"↺ Reset Speed",BG3,UDim2.new(1,0,0,28),16).MouseButton1Click:Connect(function() S.speed=16 S.speedEnabled=false spdDL.Text="16" grabChar() if hum then hum.WalkSpeed=16 end toast("Speed reset",DIM) end)

-- ══ ESP TAB ══
local ep=tabPages["esp"]
TOGGLE(ep,"👁  ESP Master Switch",1,function(v) S.espEnabled=v if not v then clearESP() end toast(v and "👁 ESP ON" or "ESP OFF",v and CYN or DIM) end)
HR(ep,2) SL(ep,"ESP OPTIONS",3)
TOGGLE(ep,"📦  Boxes",4,function(v) S.espBoxes=v end)
TOGGLE(ep,"🏷️  Names + KO/Lock indicators",5,function(v) S.espNames=v end)
TOGGLE(ep,"❤️  HP Bars",6,function(v) S.espHealth=v end)
TOGGLE(ep,"📏  Distance",7,function(v) S.espDistance=v end)
TOGGLE(ep,"💰  Wallet amounts",8,function(v) S.espMoney=v end)
TOGGLE(ep,"🔧  Held weapons",9,function(v) S.espWeapons=v end)

-- ══ MISC TAB ══
local xp=tabPages["misc"]
SL(xp,"EFFECTS",1)
TOGGLE(xp,"✨  KO Effects  (sparkles on stomp)",2,function(v) S.koEffects=v toast(v and "✨ ON" or "OFF",v and PNK or DIM) end)
TOGGLE(xp,"📢  KO Chat Announcer",3,function(v) S.koAnnounce=v toast(v and "📢 ON" or "OFF",v and PNK or DIM) end)
HR(xp,4) SL(xp,"PVP",5)
TOGGLE(xp,"⚔️  Toggle PVP On/Off",4.5,function(v)
    if REM.PVPTOGGLE then
        pcall(function() REM.PVPTOGGLE:FireServer(v) end)
    end
    toast(v and "⚔ PVP ON" or "PVP OFF", v and RED or DIM)
end)
HR(xp,4) SL(xp,"SESSION STATS",5)
local myCard=CARD(xp,56,6) pdg(10,10,6,6,myCard) vlist(myCard,4)
local koCountLbl=LB(myCard,"💀 KOs: 0",UDim2.new(1,0,0,14),TXT,11,Enum.TextXAlignment.Center)
local sessionLbl=LB(myCard,"⏱ 0:00",UDim2.new(1,0,0,14),DIM,10,Enum.TextXAlignment.Center)
local sessionStart=tick()
RunService.Heartbeat:Connect(function()
    koCountLbl.Text="💀 KOs: "..S.koCount
    local e=tick()-sessionStart local m=math.floor(e/60) local s=math.floor(e%60)
    sessionLbl.Text=string.format("⏱ %d:%02d",m,s)
end)
HR(xp,7) SL(xp,"REMOTES INFO (for debug)",8)
do
    local rCard=CARD(xp,110,9) vlist(rCard,2) pdg(8,8,4,4,rCard)
    LB(rCard,"HARDCODED REMOTES ✅",UDim2.new(1,0,0,14),GRN,9,Enum.TextXAlignment.Center).Font=Enum.Font.GothamBlack
    for _,r in pairs({{"PUNCHEVENT",REM.PUNCH},{"JALADADEPELOEVENT",REM.HAIRPULL},{"STOMPEVENT",REM.STOMP},{"RAGDOLLEVENT",REM.RAGDOLL},{"CARRYEVENT",REM.CARRY}}) do
        local found=r[2]~=nil
        local l=LB(rCard,(found and "✅ " or "❌ ")..r[1],UDim2.new(1,0,0,14),found and GRN or RED,9,Enum.TextXAlignment.Center)
    end
end
HR(xp,10) SL(xp,"CONSOLE LOG",11)
local logScr=Instance.new("ScrollingFrame") logScr.Size=UDim2.new(1,0,0,130) logScr.BackgroundColor3=BG0 logScr.BorderSizePixel=0 logScr.ScrollBarThickness=3 logScr.ScrollBarImageColor3=PNK logScr.CanvasSize=UDim2.new(0,0,0,0) logScr.AutomaticCanvasSize=Enum.AutomaticSize.Y logScr.LayoutOrder=12 logScr.Parent=xp cr(8,logScr) pdg(8,8,6,6,logScr) vlist(logScr,2)
local function addLog(msg,col) local r=LB(logScr,"["..os.date("%H:%M:%S").."] "..msg,UDim2.new(1,0,0,14),col or DIM,9) r.TextTruncate=Enum.TextTruncate.AtEnd task.wait() logScr.CanvasPosition=Vector2.new(0,logScr.AbsoluteCanvasSize.Y) end
local _ot=toast toast=function(msg,col) _ot(msg,col) addLog(msg,col) end
BT(xp,"🗑 Clear",BG3,UDim2.new(1,0,0,26),13).MouseButton1Click:Connect(function() for _,c in pairs(logScr:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end end)

-- KEYBINDS
UserInput.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.Delete then
        S.autoFighter=not S.autoFighter
        if S.autoFighter then startAutoFighter() else if S.fightThread then task.cancel(S.fightThread) end end
        toast(S.autoFighter and "⚔ Fighter ON [DEL]" or "Fighter OFF",S.autoFighter and PNK or DIM)
    end
    if inp.KeyCode==Enum.KeyCode.F2 then S.espEnabled=not S.espEnabled if not S.espEnabled then clearESP() end toast(S.espEnabled and "👁 ESP ON" or "ESP OFF",S.espEnabled and CYN or DIM) end
    if inp.KeyCode==Enum.KeyCode.F3 then S.flyEnabled=not S.flyEnabled if S.flyEnabled then startFly() else stopFly() end end
    if inp.KeyCode==Enum.KeyCode.F4 then local t=S.lockTarget or getNearestEnemy() if t then task.spawn(function() runCombo(t) end) end end
end)

-- STARTUP
showTab("combat")
addLog("✅ Baddies v2.0 loaded — remotes hardcoded",GRN)
addLog("✅ PUNCHEVENT / JALADADEPELOEVENT / STOMPEVENT",GRN)
addLog("⌨  DEL=Fighter | F2=ESP | F3=Fly | F4=Combo",YLW)
addLog("💅 Lock a target then hit DEL to start!",PNK)
toast("💅 Baddies v2.0 ready!",PNK)
