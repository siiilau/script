-- SIIILAU MODE BALAP v6 | K = Menu | F = Speed | R = Hide | G = Moonwalk
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local LP=Players.LocalPlayer

local DEF_WS=17
local DEF_JP=52.5

local S={Speed=false,SpeedV=17.25,Jump=false,JumpV=51.5,Bright=false,Hide=false,
Clean=false,FPS=false,Cross=false,Moon=false,Spin=false,Held=false}
local vis=false

local DFL={B=Lighting.Brightness,C=Lighting.ClockTime,A=Lighting.Ambient,OA=Lighting.OutdoorAmbient,GS=Lighting.GlobalShadows}
local savedFX={}

local parent=LP:FindFirstChild("PlayerGui")
pcall(function() if gethui then parent=gethui() end end)
if not parent then pcall(function() parent=game:FindFirstChildOfClass("CoreGui") end) end

local function notify(t)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="SIIILAU BALAP",Text=t,Duration=2}) end)
end

--========== GUI =========--
local gui=Instance.new("ScreenGui")
gui.Name="SiiilauBalap"
gui.ResetOnSpawn=false
gui.DisplayOrder=999
gui.Parent=parent

local fr=Instance.new("Frame")
fr.Size=UDim2.new(0,310,0,440)
fr.Position=UDim2.new(0,30,0,80)
fr.BackgroundColor3=Color3.fromRGB(18,18,24)
fr.BorderSizePixel=0
fr.Visible=false
fr.Parent=gui
Instance.new("UICorner",fr).CornerRadius=UDim.new(0,8)

local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,34)
tb.BackgroundColor3=Color3.fromRGB(28,28,38)
tb.BorderSizePixel=0
tb.Parent=fr
Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)

local tt=Instance.new("TextLabel")
tt.Size=UDim2.new(1,0,1,0)
tt.BackgroundTransparency=1
tt.Text="🏎️ SIIILAU MODE BALAP  [K]"
tt.TextColor3=Color3.fromRGB(255,215,0)
tt.Font=Enum.Font.GothamBold
tt.TextSize=14
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

local sc=Instance.new("ScrollingFrame")
sc.Position=UDim2.new(0,6,0,40)
sc.Size=UDim2.new(1,-12,1,-46)
sc.BackgroundTransparency=1
sc.BorderSizePixel=0
sc.ScrollBarThickness=4
sc.CanvasSize=UDim2.new(0,0,0,780)
sc.Parent=fr
local lay=Instance.new("UIListLayout",sc)
lay.Padding=UDim.new(0,4)
lay.SortOrder=Enum.SortOrder.LayoutOrder

--========== KOMPONEN =========--
local UI={}

local function header(txt)
    local h=Instance.new("TextLabel")
    h.Size=UDim2.new(1,0,0,26)
    h.BackgroundTransparency=1
    h.Text=txt
    h.TextColor3=Color3.fromRGB(255,255,255)
    h.Font=Enum.Font.GothamBold
    h.TextSize=15
    h.LayoutOrder=#sc:GetChildren()
    h.Parent=sc
end

local function toggle(name,key,onCB)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,32)
    row.BackgroundColor3=Color3.fromRGB(30,30,38)
    row.BorderSizePixel=0
    row.LayoutOrder=#sc:GetChildren()
    row.Parent=sc
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-90,1,0)
    lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=name
    lbl.TextColor3=Color3.fromRGB(225,225,230)
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=14
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,64,0,24)
    btn.Position=UDim2.new(1,-70,0,4)
    btn.BackgroundColor3=Color3.fromRGB(190,50,50)
    btn.Text="OFF"
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=13
    btn.BorderSizePixel=0
    btn.AutoButtonColor=true
    btn.Parent=row
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local st=false
    local function set(v)
        st=v
        if v then
            btn.Text="ON"
            btn.BackgroundColor3=Color3.fromRGB(0,190,90)
        else
            btn.Text="OFF"
            btn.BackgroundColor3=Color3.fromRGB(190,50,50)
        end
        S[key]=v
        if onCB then pcall(onCB,v) end
    end
    btn.MouseButton1Click:Connect(function() set(not st) end)
    UI[key]=set
    return set
end

local function valueRow(name,min,max,def,key)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,30)
    row.BackgroundColor3=Color3.fromRGB(24,24,32)
    row.BorderSizePixel=0
    row.LayoutOrder=#sc:GetChildren()
    row.Parent=sc
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,60,1,0)
    lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=name
    lbl.TextColor3=Color3.fromRGB(180,180,195)
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local val=Instance.new("TextLabel")
    val.Size=UDim2.new(0,60,1,0)
    val.Position=UDim2.new(0,70,0,0)
    val.BackgroundTransparency=1
    val.Text=string.format("%.2f",def)
    val.TextColor3=Color3.fromRGB(255,215,0)
    val.Font=Enum.Font.GothamBold
    val.TextSize=14
    val.TextXAlignment=Enum.TextXAlignment.Left
    val.Parent=row

    local function mkBtn(txt,x,fn)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,74,0,22)
        b.Position=UDim2.new(0,x,0,4)
        b.BackgroundColor3=Color3.fromRGB(50,50,68)
        b.Text=txt
        b.TextColor3=Color3.fromRGB(255,255,255)
        b.Font=Enum.Font.GothamBold
        b.TextSize=13
        b.BorderSizePixel=0
        b.AutoButtonColor=true
        b.Parent=row
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function()
            local v=fn(S[key])
            v=math.floor(v/0.25+0.5)*0.25
            v=math.clamp(v,min,max)
            S[key]=v
            val.Text=string.format("%.2f",v)
            notify(name..": "..v)
        end)
    end
    mkBtn("− 0.25",150,function(v) return v-0.25 end)
    mkBtn("+ 0.25",228,function(v) return v+0.25 end)
end

--========== ISI MENU =========--
header("⚡ MOVEMENT")

toggle("Speed Hack  [F]","Speed",function(on)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h and not on then h.WalkSpeed=DEF_WS end
    notify("Speed: "..(on and ("ON "..S.SpeedV) or ("OFF (reset "..DEF_WS..")")))
end)
valueRow("Speed",17.25,23.5,17.25,"SpeedV")

toggle("Jump Power","Jump",function(on)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h and not on then h.JumpPower=DEF_JP end
    notify("Jump: "..(on and ("ON "..S.JumpV) or ("OFF (reset "..DEF_JP..")")))
end)
valueRow("Jump",51.5,70,51.5,"JumpV")

header("👁 VISUALS")

toggle("Auto Brightness","Bright",function(on)
    if on then
        Lighting.Brightness=2
        Lighting.Ambient=Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient=Color3.fromRGB(110,110,110)
    else
        Lighting.Brightness=DFL.B
        Lighting.Ambient=DFL.A
        Lighting.OutdoorAmbient=DFL.OA
    end
    notify("Auto Brightness: "..(on and "ON" or "OFF"))
end)

toggle("Hide Players  [R]","Hide",function(on)
    if not on then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                for _,o in pairs(p.Character:GetDescendants()) do
                    if o:IsA("BasePart") or o:IsA("Decal") then o.LocalTransparencyModifier=0
                    elseif o:IsA("BillboardGui") then o.Enabled=true end
                end
            end
        end
    end
    notify("Hide Players: "..(on and "ON" or "OFF"))
end)

toggle("Clean Particles","Clean",function(on)
    if not on then
        for _,o in pairs(workspace:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Trail") or o:IsA("Sparkles") then o.Enabled=true end
        end
        Lighting.ClockTime=DFL.C
    else
        Lighting.ClockTime=8
    end
    notify("Clean Particles: "..(on and "ON" or "OFF"))
end)

toggle("FPS Boost","FPS",function(on)
    for _,o in pairs(Lighting:GetChildren()) do
        if o:IsA("PostEffect") then
            if on and savedFX[o]==nil then savedFX[o]=o.Enabled end
            pcall(function() o.Enabled=on and false or (savedFX[o]==nil and true or savedFX[o]) end)
        end
    end
    if on then
        pcall(function() settings().Rendering.QualityLevel=1 end)
        Lighting.GlobalShadows=false
    else
        Lighting.GlobalShadows=DFL.GS
    end
    notify("FPS Boost: "..(on and "ON" or "OFF"))
end)

header("🤣 FUN / SEPUH")

toggle("Crosshair","Cross",function(on)
    local old=parent:FindFirstChild("SiiCross") if old then old:Destroy() end
    if on then
        local cg=Instance.new("ScreenGui")
        cg.Name="SiiCross"
        cg.ResetOnSpawn=false
        cg.Parent=parent
        for _,v in pairs({{0,-10,2,20},{0,10,2,20},{-10,0,20,2},{10,0,20,2}}) do
            local l=Instance.new("Frame")
            l.BackgroundColor3=Color3.fromRGB(0,255,80)
            l.BorderSizePixel=0
            l.Size=UDim2.new(0,v[3],0,v[4])
            l.Position=UDim2.new(0.5,v[1]-(v[3]==2 and 1 or 0),0.5,v[2]-(v[4]==2 and 1 or 0))
            l.Parent=cg
        end
    end
    notify("Crosshair: "..(on and "ON" or "OFF"))
end)

toggle("Moonwalk  [tahan G]","Moon",function(on)
    if not on then
        local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.AutoRotate=true end
    end
    notify("Moonwalk: "..(on and "ON" or "OFF"))
end)

toggle("Slow Spin (Sepuh)","Spin",function(on)
    notify("Slow Spin: "..(on and "ON" or "OFF"))
end)

header("🗑 SYSTEM")

local rst=Instance.new("TextButton")
rst.Size=UDim2.new(1,0,0,36)
rst.BackgroundColor3=Color3.fromRGB(200,45,45)
rst.Text="✖ DESTROY & RESET"
rst.TextColor3=Color3.fromRGB(255,255,255)
rst.Font=Enum.Font.GothamBold
rst.TextSize=14
rst.BorderSizePixel=0
rst.LayoutOrder=#sc:GetChildren()
rst.Parent=sc
Instance.new("UICorner",rst).CornerRadius=UDim.new(0,6)
rst.MouseButton1Click:Connect(function()
    for _,k in pairs({"Speed","Jump","Bright","Hide","Clean","FPS","Cross","Moon","Spin"}) do
        if UI[k] then UI[k](false) end
    end
    Lighting.Brightness=DFL.B Lighting.ClockTime=DFL.C
    Lighting.Ambient=DFL.A Lighting.OutdoorAmbient=DFL.OA Lighting.GlobalShadows=DFL.GS
    workspace.Gravity=196.2
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=16 h.JumpPower=50 h.AutoRotate=true end
    for _,o in pairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Trail") or o:IsA("Sparkles") then o.Enabled=true end
    end
    for o,e in pairs(savedFX) do pcall(function() o.Enabled=e end) end
    local old=parent:FindFirstChild("SiiCross") if old then old:Destroy() end
    pcall(function() settings().Rendering.QualityLevel=10 end)
    gui:Destroy()
    notify("Semua direset & UI dihancurkan")
end)

--========== LOOP =========--
RS.Heartbeat:Connect(function()
    local ch=LP.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    if h then
        if S.Speed then h.WalkSpeed=S.SpeedV end
        if S.Jump then
            h.UseJumpPower=true
            h.JumpPower=S.JumpV
        end
    end
    if S.Hide then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                for _,o in pairs(p.Character:GetDescendants()) do
                    if o:IsA("BasePart") or o:IsA("Decal") then o.LocalTransparencyModifier=1
                    elseif o:IsA("BillboardGui") then o.Enabled=false end
                end
            end
        end
    end
    if S.Spin and ch and ch:FindFirstChild("HumanoidRootPart") then
        ch.HumanoidRootPart.CFrame=ch.HumanoidRootPart.CFrame*CFrame.Angles(0,math.rad(1.5),0)
    end
end)

task.spawn(function()
    while gui.Parent do
        if S.Clean then
            for _,o in pairs(workspace:GetDescendants()) do
                if o:IsA("ParticleEmitter") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Trail") or o:IsA("Sparkles") then
                    o.Enabled=false
                end
            end
        end
        task.wait(0.4)
    end
end)

--========== HOTKEY (K, F, R, G saja) =========--
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
        S.Held=true
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.G then
        S.Held=false
        local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h and S.Moon then h.AutoRotate=true end
    end
end)

task.spawn(function()
    while gui.Parent do
        if S.Moon and S.Held then
            local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then
                h.AutoRotate=false
                local anim=h:FindFirstChildOfClass("Animator")
                if anim then
                    for _,t in pairs(anim:GetPlayingAnimationTracks()) do
                        t:AdjustSpeed(-1.5)
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

notify("SIIILAU MODE BALAP loaded! K = menu")
