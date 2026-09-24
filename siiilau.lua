-- SIIILAU MODE BALAP v17 | AUTO-GUARD EDITION | K = Menu | F = Speed | R = Hide | G = Moonwalk
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local LP=Players.LocalPlayer

local DEF_WS=17
local DEF_JP=52.5

local S={Speed=false,SpeedV=17.25,Jump=false,JumpV=51.5,Bright=false,Hide=false,
Clean=false,FPS=false,Cross=false,Moon=false,ClockV=12}
local vis=false

local DFL={B=Lighting.Brightness,C=Lighting.ClockTime,A=Lighting.Ambient,OA=Lighting.OutdoorAmbient,GS=Lighting.GlobalShadows}
local savedFX={} local savedMats={}
local cleanConn=nil local fpsConn=nil local fpsLightConn=nil
local hideConns={}

local parent=LP:FindFirstChild("PlayerGui")
pcall(function() if gethui then parent=gethui() end end)
if not parent then pcall(function() parent=game:FindFirstChildOfClass("CoreGui") end) end

local function notify(t)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="SIIILAU",Text=t,Duration=2}) end)
end

local function angleLerp(a,b,t)
    local diff=(b-a+math.pi)%(2*math.pi)-math.pi
    return a+diff*t
end

--========== TEMA ==========--
local C_BG=Color3.fromRGB(13,9,22)
local C_ROW=Color3.fromRGB(28,22,46)
local C_ROW2=Color3.fromRGB(22,17,38)
local C_ON=Color3.fromRGB(0,175,200)
local C_OFF=Color3.fromRGB(172,25,58)
local C_MINUS=Color3.fromRGB(56,45,88)
local C_GOLD=Color3.fromRGB(255,220,80)
local C_PURPLE=Color3.fromRGB(165,110,250)
local C_TXT=Color3.fromRGB(235,230,245)

local gui=Instance.new("ScreenGui")
gui.Name="SiiilauBalap"
gui.ResetOnSpawn=false
gui.DisplayOrder=999
gui.Parent=parent

local fr=Instance.new("Frame")
fr.Size=UDim2.new(0,175,0,350)
fr.Position=UDim2.new(0,25,0,60)
fr.BackgroundColor3=C_BG
fr.BorderSizePixel=0
fr.Visible=false
fr.Parent=gui
Instance.new("UICorner",fr).CornerRadius=UDim.new(0,10)
local border=Instance.new("UIStroke",fr)
border.Color=C_PURPLE
border.Thickness=1.5
border.Transparency=0.15

local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,28)
tb.BackgroundColor3=Color3.fromRGB(20,14,34)
tb.BorderSizePixel=0
tb.Parent=fr
Instance.new("UICorner",tb).CornerRadius=UDim.new(0,10)

local logo=Instance.new("Frame")
logo.Size=UDim2.new(0,20,0,20)
logo.Position=UDim2.new(0,4,0,4)
logo.BackgroundColor3=Color3.fromRGB(10,6,18)
logo.Parent=tb
Instance.new("UICorner",logo).CornerRadius=UDim.new(1,0)
local lstroke=Instance.new("UIStroke",logo)
lstroke.Color=C_PURPLE
lstroke.Thickness=1
local sTxt=Instance.new("TextLabel")
sTxt.Size=UDim2.new(1,0,1,0)
sTxt.BackgroundTransparency=1
sTxt.Text="S"
sTxt.TextColor3=Color3.fromRGB(240,240,250)
sTxt.Font=Enum.Font.GothamBlack
sTxt.TextSize=12
sTxt.Parent=logo

local tt=Instance.new("TextLabel")
tt.Size=UDim2.new(1,-28,1,0)
tt.Position=UDim2.new(0,26,0,0)
tt.BackgroundTransparency=1
tt.RichText=true
tt.Text="🏎️ <font color=\"#FFDC50\">SIIILAU</font> <font color=\"#9A93A8\">[K]</font>"
tt.Font=Enum.Font.GothamBold
tt.TextSize=11
tt.TextXAlignment=Enum.TextXAlignment.Left
tt.Parent=tb

local dragging=false local dragStart=nil local startPos=nil
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true dragStart=i.Position startPos=fr.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        fr.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)

local holder=Instance.new("Frame")
holder.Position=UDim2.new(0,5,0,31)
holder.Size=UDim2.new(1,-10,1,-36)
holder.BackgroundTransparency=1
holder.Parent=fr
local lay=Instance.new("UIListLayout",holder)
lay.Padding=UDim.new(0,2)
lay.SortOrder=Enum.SortOrder.LayoutOrder

--========== KOMPONEN ==========--
local UI={}

local function header(txt)
    local h=Instance.new("TextLabel")
    h.Size=UDim2.new(1,0,0,14)
    h.BackgroundTransparency=1
    h.Text=txt
    h.TextColor3=Color3.fromRGB(255,255,255)
    h.Font=Enum.Font.GothamBold
    h.TextSize=10
    h.LayoutOrder=#holder:GetChildren()
    h.Parent=holder
end

local function toggle(name,key,onCB)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,19)
    row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0
    row.LayoutOrder=#holder:GetChildren()
    row.Parent=holder
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-52,1,0)
    lbl.Position=UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=name
    lbl.TextColor3=C_TXT
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,42,0,14)
    btn.Position=UDim2.new(1,-47,0,2.5)
    btn.BackgroundColor3=C_OFF
    btn.Text="OFF"
    btn.TextColor3=Color3.fromRGB(255,235,240)
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=9
    btn.BorderSizePixel=0
    btn.Parent=row
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local st=false
    local function set(v)
        st=v
        if v then btn.Text="ON" btn.BackgroundColor3=C_ON
        else btn.Text="OFF" btn.BackgroundColor3=C_OFF end
        S[key]=v
        if onCB then pcall(onCB,v) end
    end
    btn.MouseButton1Click:Connect(function() set(not st) end)
    UI[key]=set
    return set
end

local function valueRow(name,min,max,def,key,fmt)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,18)
    row.BackgroundColor3=C_ROW2
    row.BorderSizePixel=0
    row.LayoutOrder=#holder:GetChildren()
    row.Parent=holder
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,42,1,0)
    lbl.Position=UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=name
    lbl.TextColor3=Color3.fromRGB(200,195,215)
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=9
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local val=Instance.new("TextLabel")
    val.Size=UDim2.new(0,40,1,0)
    val.Position=UDim2.new(0,48,0,0)
    val.BackgroundTransparency=1
    val.Text=string.format(fmt or "%.2f",def)
    val.TextColor3=C_GOLD
    val.Font=Enum.Font.GothamBold
    val.TextSize=10
    val.TextXAlignment=Enum.TextXAlignment.Left
    val.Parent=row

    local function mkBtn(txt,x,fn)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,34,0,13)
        b.Position=UDim2.new(0,x,0,2.5)
        b.BackgroundColor3=C_MINUS
        b.Text=txt
        b.TextColor3=Color3.fromRGB(255,255,255)
        b.Font=Enum.Font.GothamBold
        b.TextSize=9
        b.BorderSizePixel=0
        b.Parent=row
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function()
            local v=fn(S[key])
            v=math.floor(v/0.25+0.5)*0.25
            v=math.clamp(v,min,max)
            S[key]=v
            val.Text=string.format(fmt or "%.2f",v)
            notify(name..": "..v)
        end)
    end
    mkBtn("−.25",96,function(v) return v-0.25 end)
    mkBtn("+.25",132,function(v) return v+0.25 end)
end

--========== CLEAN PARTICLES (event + re-check otomatis) ==========--
local function isEffect(o)
    return o:IsA("ParticleEmitter") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Trail") or o:IsA("Sparkles")
end
local function cleanON()
    for _,o in pairs(workspace:GetDescendants()) do
        if isEffect(o) then o.Enabled=false end
    end
    cleanConn=workspace.DescendantAdded:Connect(function(o)
        task.wait()
        if o and o.Parent and isEffect(o) then o.Enabled=false end
    end)
end
local function cleanOFF()
    if cleanConn then cleanConn:Disconnect() cleanConn=nil end
    for _,o in pairs(workspace:GetDescendants()) do
        if isEffect(o) then o.Enabled=true end
    end
end

--========== FPS BOOST (event + guard post-effect baru) ==========--
local function fpsON()
    Lighting.GlobalShadows=false
    for _,o in pairs(Lighting:GetChildren()) do
        if o:IsA("PostEffect") then
            if savedFX[o]==nil then savedFX[o]=o.Enabled end
            o.Enabled=false
        end
    end
    for _,o in pairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Parent then
            savedMats[o]=o.Material
            o.Material=Enum.Material.SmoothPlastic
        end
    end
    fpsConn=workspace.DescendantAdded:Connect(function(o)
        task.wait()
        if o and o.Parent and o:IsA("BasePart") then
            savedMats[o]=o.Material
            o.Material=Enum.Material.SmoothPlastic
        end
    end)
    -- post-effect baru yang ditambahkan game langsung dimatikan
    fpsLightConn=Lighting.ChildAdded:Connect(function(o)
        task.wait()
        if o and o:IsA("PostEffect") then
            if savedFX[o]==nil then savedFX[o]=o.Enabled end
            o.Enabled=false
        end
    end)
end
local function fpsOFF()
    if fpsConn then fpsConn:Disconnect() fpsConn=nil end
    if fpsLightConn then fpsLightConn:Disconnect() fpsLightConn=nil end
    Lighting.GlobalShadows=DFL.GS
    for o,e in pairs(savedFX) do pcall(function() o.Enabled=e end) end
    savedFX={}
    for o,m in pairs(savedMats) do pcall(function() if o.Parent then o.Material=m end end) end
    savedMats={}
end

--========== CROSSHAIR ==========--
local function crossON()
    local old=parent:FindFirstChild("SiiCross") if old then old:Destroy() end
    local cg=Instance.new("ScreenGui")
    cg.Name="SiiCross"
    cg.ResetOnSpawn=false
    cg.IgnoreGuiInset=true
    cg.Parent=parent
    local ring=Instance.new("Frame")
    ring.Size=UDim2.new(0,16,0,16)
    ring.Position=UDim2.new(0.5,-8,0.5,-8)
    ring.BackgroundTransparency=1
    ring.Parent=cg
    local rc=Instance.new("UICorner",ring) rc.CornerRadius=UDim.new(1,0)
    local st=Instance.new("UIStroke",ring)
    st.Color=Color3.fromRGB(0,255,120)
    st.Thickness=1.5
    st.Transparency=0.3
    local dot=Instance.new("Frame")
    dot.Size=UDim2.new(0,3,0,3)
    dot.Position=UDim2.new(0.5,-1.5,0.5,-1.5)
    dot.BackgroundColor3=Color3.fromRGB(0,255,120)
    dot.BorderSizePixel=0
    dot.Parent=ring
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
end
local function crossOFF()
    local old=parent:FindFirstChild("SiiCross") if old then old:Destroy() end
end

--========== HIDE PLAYERS ==========--
local function watchChar(plr)
    local char=plr.Character
    if char then
        for _,o in pairs(char:GetDescendants()) do
            if o:IsA("BasePart") or o:IsA("Decal") then o.LocalTransparencyModifier=1
            elseif o:IsA("BillboardGui") then o.Enabled=false end
        end
        hideConns[plr]=char.DescendantAdded:Connect(function(o)
            task.wait()
            if S.Hide and o and o.Parent then
                if o:IsA("BasePart") or o:IsA("Decal") then o.LocalTransparencyModifier=1
                elseif o:IsA("BillboardGui") then o.Enabled=false end
            end
        end)
    end
end
local function hideON()
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=LP then
            watchChar(plr)
            plr.CharacterAdded:Connect(function()
                task.wait(0.3)
                if S.Hide then
                    if hideConns[plr] then hideConns[plr]:Disconnect() end
                    watchChar(plr)
                end
            end)
        end
    end
    hideConns.__new=Players.PlayerAdded:Connect(function(plr)
        task.wait(1)
        if S.Hide then
            watchChar(plr)
            plr.CharacterAdded:Connect(function()
                task.wait(0.3)
                if S.Hide then
                    if hideConns[plr] then hideConns[plr]:Disconnect() end
                    watchChar(plr)
                end
            end)
        end
    end)
end
local function hideOFF()
    for _,conn in pairs(hideConns) do pcall(function() conn:Disconnect() end) end
    hideConns={}
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character then
            for _,o in pairs(plr.Character:GetDescendants()) do
                if o:IsA("BasePart") or o:IsA("Decal") then o.LocalTransparencyModifier=0
                elseif o:IsA("BillboardGui") then o.Enabled=true end
            end
        end
    end
end

--========== MOONWALK (2 lapisan, sama seperti v16) ==========--
local moonYaw=nil
local moonConns={}

local function applyMoon(dt)
    if not S.Moon then return end
    local ch=LP.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if not h or not root then return end
    if h.Sit then return end
    if h.AutoRotate~=false then h.AutoRotate=false end
    local cam=workspace.CurrentCamera
    if not cam then return end
    local lv=cam.CFrame.LookVector
    local flat=Vector3.new(lv.X,0,lv.Z)
    if flat.Magnitude<0.001 then return end
    flat=flat.Unit
    local target=math.atan2(-flat.X,-flat.Z)+math.pi
    if moonYaw==nil then moonYaw=target end
    local diff=(target-moonYaw+math.pi)%(2*math.pi)-math.pi
    moonYaw=moonYaw+diff*math.clamp(dt*15,0,1)
    root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,moonYaw,0)
end

local function moonON()
    for _,c in pairs(moonConns) do pcall(function() c:Disconnect() end) end
    moonConns={}
    moonYaw=nil
    table.insert(moonConns,RS.RenderStepped:Connect(function() applyMoon(1/60) end))
    table.insert(moonConns,RS.Heartbeat:Connect(function() applyMoon(1/60) end))
    applyMoon(1)
end
local function moonOFF()
    for _,c in pairs(moonConns) do pcall(function() c:Disconnect() end) end
    moonConns={}
    moonYaw=nil
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.AutoRotate=true end
end

--========== ISI MENU ==========--
header("⚡ MOVEMENT")

toggle("Speed Hack [F]","Speed",function(on)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h and not on then h.WalkSpeed=DEF_WS end
    notify("Speed: "..(on and ("ON "..S.SpeedV) or "OFF"))
end)
valueRow("Speed",17.25,23.5,17.25,"SpeedV")

toggle("Jump Power","Jump",function(on)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h and not on then h.JumpPower=DEF_JP end
    notify("Jump: "..(on and ("ON "..S.JumpV) or "OFF"))
end)
valueRow("Jump",51.5,70,51.5,"JumpV")

toggle("Crosshair","Cross",function(on)
    if on then crossON() else crossOFF() end
    notify("Crosshair: "..(on and "ON" or "OFF"))
end)

toggle("Moonwalk [G]","Moon",function(on)
    if on then moonON() else moonOFF() end
    notify("Moonwalk: "..(on and "ON (badan 180°)" or "OFF"))
end)

header("👁 VISUALS")

-- AUTO BRIGHTNESS: sekarang GUARD — waktu DIKUNCI ke jam pilihan,
-- game mengubah malam/hujan apapun → langsung dikembalikan terang
toggle("Auto Brightness","Bright",function(on)
    if on then
        Lighting.ClockTime=S.ClockV
        Lighting.Brightness=2
        Lighting.Ambient=Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient=Color3.fromRGB(110,110,110)
        notify("Brightness ON! Waktu dikunci jam "..S.ClockV)
    else
        Lighting.Brightness=DFL.B
        Lighting.Ambient=DFL.A
        Lighting.OutdoorAmbient=DFL.OA
        Lighting.ClockTime=DFL.C
        notify("Brightness: OFF")
    end
end)
-- Jam kunci siang: 6-18, default 12 (siang terang)
valueRow("Jam",6,18,12,"ClockV","%.2f")

toggle("Hide Players [R]","Hide",function(on)
    if on then hideON() else hideOFF() end
    notify("Hide: "..(on and "ON" or "OFF"))
end)

toggle("Clean Particles","Clean",function(on)
    if on then cleanON() else cleanOFF() end
    notify("Clean: "..(on and "ON" or "OFF"))
end)

toggle("FPS Boost","FPS",function(on)
    if on then fpsON() else fpsOFF() end
    notify("FPS Boost: "..(on and "ON" or "OFF"))
end)

local rst=Instance.new("TextButton")
rst.Size=UDim2.new(1,0,0,20)
rst.BackgroundColor3=Color3.fromRGB(205,38,48)
rst.Text="destroy & reset"
rst.TextColor3=Color3.fromRGB(255,225,228)
rst.Font=Enum.Font.GothamBold
rst.TextSize=11
rst.BorderSizePixel=0
rst.LayoutOrder=#holder:GetChildren()
rst.Parent=holder
Instance.new("UICorner",rst).CornerRadius=UDim.new(0,6)
rst.MouseButton1Click:Connect(function()
    moonOFF()
    for _,k in pairs({"Speed","Jump","Bright","Hide","Clean","FPS","Cross","Moon"}) do
        if UI[k] then UI[k](false) end
    end
    Lighting.Brightness=DFL.B Lighting.ClockTime=DFL.C
    Lighting.Ambient=DFL.A Lighting.OutdoorAmbient=DFL.OA Lighting.GlobalShadows=DFL.GS
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=16 h.JumpPower=50 h.AutoRotate=true end
    for o,e in pairs(savedFX) do pcall(function() o.Enabled=e end) end
    for o,m in pairs(savedMats) do pcall(function() if o.Parent then o.Material=m end end) end
    crossOFF()
    gui:Destroy()
    notify("Direset & dihancurkan")
end)

local wm=Instance.new("TextLabel")
wm.Size=UDim2.new(1,0,0,16)
wm.BackgroundTransparency=1
wm.Text="— Siiilau —"
wm.TextColor3=Color3.fromRGB(160,150,180)
wm.Font=Enum.Font.GothamBold
wm.TextSize=10
wm.LayoutOrder=#holder:GetChildren()
wm.Parent=holder

--========== LOOP RINGAN (Speed & Jump) ==========--
RS.Heartbeat:Connect(function()
    if not (S.Speed or S.Jump) then return end
    local ch=LP.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if S.Speed then h.WalkSpeed=S.SpeedV end
    if S.Jump then
        h.UseJumpPower=true
        h.JumpPower=S.JumpV
    end
end)

--========== GUARD LOOP (SATU loop untuk semua guard otomatis) ==========
-- Brightness : dicek tiap 0.5 dtk → jam/brightness/ambient dikunci
-- Clean      : dicek tiap 3 dtk → efek yang di-enable ulang game dimatikan lagi
-- FPS        : dicek tiap 5 dtk → post-effect & material baru dirapikan lagi
task.spawn(function()
    local t=0
    while gui.Parent do
        task.wait(0.5)
        t=t+0.5
        -- GUARD BRIGHTNESS + JAM (kunci waktu)
        if S.Bright then
            if math.abs(Lighting.ClockTime-S.ClockV)>0.3 then Lighting.ClockTime=S.ClockV end
            Lighting.Brightness=2
            Lighting.Ambient=Color3.fromRGB(70,70,70)
            Lighting.OutdoorAmbient=Color3.fromRGB(110,110,110)
        end
        -- GUARD CLEAN (re-check 3 dtk, hanya saat ON)
        if S.Clean and t%3<0.5 then
            for _,o in pairs(workspace:GetDescendants()) do
                if isEffect(o) and o.Enabled then o.Enabled=false end
            end
        end
        -- GUARD FPS (re-check 5 dtk, hanya saat ON)
        if S.FPS and t%5<0.5 then
            Lighting.GlobalShadows=false
            for _,o in pairs(Lighting:GetChildren()) do
                if o:IsA("PostEffect") and o.Enabled then
                    if savedFX[o]==nil then savedFX[o]=true end
                    o.Enabled=false
                end
            end
        end
    end
end)

--========== HOTKEY (K, F, R, G) ==========--
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    local k=i.KeyCode
    if k==Enum.KeyCode.K then
        vis=not vis
        fr.Visible=vis
    elseif k==Enum.KeyCode.F then
        if UI.Speed then UI.Speed(not S.Speed) end
    elseif k==Enum.KeyCode.R then
        if UI.Hide then UI.Hide(not S.Hide) end
    elseif k==Enum.KeyCode.G then
        if UI.Moon then UI.Moon(not S.Moon) end
    end
end)

notify("SIIILAU v17 loaded! K = menu")
