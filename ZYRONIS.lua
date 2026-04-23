local Library = loadstring(game:HttpGet("https://pastefy.app/KkevWErG/raw"))()
workspace.FallenPartsDestroyHeight = -math.huge

local Window = Library:MakeWindow({
 Title = " ZYRONIS HUB | BROOKHAVEN RP ",
 SubTitle = "Ultimate Merged Edition - All Features",
 LoadText = "ZYRONIS Yükleniyor...",
 Flags = "ZYRONIS"
})

Window:AddMinimizeButton({
 Button = {
 Image = 'rbxassetid://76560659040388',
 BackgroundTransparency = 0,
 Size = UDim2.new(0, 35, 0, 35),
 },
 Corner = {
 CornerRadius = UDim.new(0, 100),
 },
})

-- SERVİSLER VE GLOBAL DEĞİŞKENLER
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Global Değişkenler
local selectedPlayerName = nil
local selectedLagMethod = nil
local blackHoleActive = false
local blackHoleRadius = 10
local blackHoleAngle = 1
local flyActive = false
local speedActive = false
local noclipActive = false
local infiniteJumpActive = false
local methodActive = false
local methodKill = "Bus"

_G.ESPData = {
 espEnabled = false,
 espType = "Ad + Yaş",
 selectedColor = "RGB",
 billboardGuis = {},
 highlights = {},
 lines = {},
 connections = {}
}

-- BİLGİ SEKMESİ
local InfoTab = Window:MakeTab({ Title = " Bilgi", Icon = "rbxassetid://15309138473" })

InfoTab:AddSection({ "ZYRONIS Hub Bilgisi" })
InfoTab:AddParagraph({ "Hub Adı:", " ZYRONIS HUB - BROOKHAVEN RP " })
InfoTab:AddParagraph({ "Versiyon:", "ULTIMATE MERGED 2024 FINAL" })
InfoTab:AddParagraph({ "Durum:", " Aktif & Çalışıyor" })
InfoTab:AddParagraph({ "Oyun:", "Brookhaven RP" })
InfoTab:AddParagraph({"Yürütücü:", pcall(function() return identifyexecutor and identifyexecutor() end) and (identifyexecutor and identifyexecutor() or "Bilinmiyor") or "Bilinmiyor" })

InfoTab:AddSection({ "Sunucuya Tekrar Katıl" })
InfoTab:AddButton({
 Name = " Rejoin",
 Callback = function()
 pcall(function()
 TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
 Window:Notify({
 Title = "Tekrar Katılma",
 Content = "Sunucuya tekrar katılınıyor...",
 Duration = 3
 })
 end)
 end
})

InfoTab:AddSection({ "Sunucudaki Oyuncular" })
local playerCountLabel = InfoTab:AddParagraph({ "Oyuncu Sayısı:", #game.Players:GetPlayers() })

-- Not: Paragraph dinamik guncelleme desteklemiyor, buton ile guncellenir

-- TROLL/PVP SEKMESİ
local TrollTab = Window:MakeTab({ Title = " Troll/PVP", Icon = "skull" })

-- Oyuncu Seçimi
local function getPlayerList()
 local playerList = {}
 for _, player in ipairs(Players:GetPlayers()) do
 if player ~= LocalPlayer then
 table.insert(playerList, player.Name)
 end
 end
 return playerList
end

TrollTab:AddSection({ " Hedef Oyuncu Seç" })
TrollTab:AddDropdown({
 Name = "Oyuncu Seç",
 Options = getPlayerList(),
 Default = "",
 Callback = function(v)
 selectedPlayerName = v
 Window:Notify({
 Title = " Hedef",
 Content = v .. " seçildi!",
 Duration = 2
 })
 end
})

-- ===== COUCH KILL FONKSIYONU =====
local function KillPlayerCouch()
 if not selectedPlayerName then
 Window:Notify({ Title = " Hata", Content = "Oyuncu seçilmedi", Duration = 2 })
 return
 end
 
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then
 Window:Notify({ Title = " Hata", Content = "Hedef oyuncu bulunamadı", Duration = 2 })
 return
 end

 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 local root = char:FindFirstChild("HumanoidRootPart")
 local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
 if not hum or not root or not tRoot then return end

 local originalPos = root.Position
 local sitPos = Vector3.new(145.51, -350.09, 21.58)

 pcall(function() 
 ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Clea1rTool1s"):FireServer("ClearAllTools") 
 end)
 task.wait(0.2)

 pcall(function() 
 ReplicatedStorage.RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "Couch") 
 end)
 task.wait(0.3)

 local tool = LocalPlayer.Backpack:FindFirstChild("Couch")
 if tool then tool.Parent = char end
 task.wait(0.1)

 VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
 task.wait(0.1)

 hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
 hum.PlatformStand = false
 Camera.CameraSubject = target.Character:FindFirstChild("Head") or tRoot or hum

 local align = Instance.new("BodyPosition")
 align.Name = "BringPosition"
 align.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
 align.D = 10
 align.P = 30000
 align.Position = root.Position
 align.Parent = tRoot

 task.spawn(function()
 local angle = 0
 local startTime = tick()
 while tick() - startTime < 5 and target and target.Character and target.Character:FindFirstChildOfClass("Humanoid") do
 local tHum = target.Character:FindFirstChildOfClass("Humanoid")
 if not tHum or tHum.Sit then break end

 local hrp = target.Character.HumanoidRootPart
 local adjustedPos = hrp.Position + (hrp.Velocity / 1.5)

 angle += 50
 root.CFrame = CFrame.new(adjustedPos + Vector3.new(0, 2, 0)) * CFrame.Angles(math.rad(angle), 0, 0)
 align.Position = root.Position + Vector3.new(2, 0, 0)

 task.wait()
 end

 align:Destroy()
 hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
 hum.PlatformStand = false
 Camera.CameraSubject = hum

 for _, p in pairs(char:GetDescendants()) do
 if p:IsA("BasePart") then
 pcall(function() p.AssemblyLinearVelocity = Vector3.zero end)
 p.RotVelocity = Vector3.zero
 end
 end

 task.wait(0.1)
 root.CFrame = CFrame.new(sitPos)
 task.wait(0.3)

 local tool = char:FindFirstChild("Couch")
 if tool then tool.Parent = LocalPlayer.Backpack end

 task.wait(0.01)
 pcall(function() 
 ReplicatedStorage.RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "Couch") 
 end)
 task.wait(0.2)
 root.CFrame = CFrame.new(originalPos)
 end)
end

-- ===== BRING PLAYER FONKSIYONU =====
local function BringPlayer()
 if not selectedPlayerName then
 Window:Notify({ Title = " Hata", Content = "Oyuncu seçilmedi", Duration = 2 })
 return
 end
 
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end

 local char = LocalPlayer.Character
 if not char then return end
 local root = char:FindFirstChild("HumanoidRootPart")
 local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
 if not root or not tRoot then return end

 tRoot.CFrame = root.CFrame + root.CFrame.LookVector * 3
 Window:Notify({
 Title = " Bring",
 Content = selectedPlayerName .. " getirildi!",
 Duration = 2
 })
end

-- ===== FLING OYUNCU FONKSIYONU =====
local function FlingPlayer()
 if not selectedPlayerName then
 Window:Notify({ Title = " Hata", Content = "Oyuncu seçilmedi", Duration = 2 })
 return
 end
 
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end

 local char = LocalPlayer.Character
 if not char then return end
 local root = char:FindFirstChild("HumanoidRootPart")
 local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
 if not root or not tRoot then return end

 local bodyVelocity = Instance.new("BodyVelocity")
 bodyVelocity.Velocity = Vector3.new(0, 0, 0)
 bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
 bodyVelocity.Parent = tRoot

 local function FlingSequence()
 for i = 1, 3 do
 bodyVelocity.Velocity = root.CFrame.LookVector * 300
 task.wait(0.1)
 end
 bodyVelocity:Destroy()
 end

 FlingSequence()
 Window:Notify({
 Title = " Fling",
 Content = selectedPlayerName .. " fırlatıldı!",
 Duration = 2
 })
end

-- ===== BUS/TRUCK İLE ÖL FONKSIYONU =====
local function KillWithVehicle()
 if not selectedPlayerName or not Players:FindFirstChild(selectedPlayerName) then
 Window:Notify({ Title = " Hata", Content = "Player seçilmedi", Duration = 2 })
 return
 end

 local character = LocalPlayer.Character
 local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
 if not humanoidRootPart then
 Window:Notify({ Title = " Hata", Content = "HumanoidRootPart bulunamadı", Duration = 2 })
 return
 end

 local originalPosition = humanoidRootPart.CFrame
 local vehicleType = (methodKill == "Truck") and "TowTruck" or "Bus"

 local function GetVehicle()
 local vehicles = game.Workspace:FindFirstChild("Vehicles")
 if vehicles then
 return vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
 end
 return nil
 end

 humanoidRootPart.CFrame = CFrame.new(1118.81, 75.998, -1138.61)
 task.wait(0.5)
 
 pcall(function() 
 ReplicatedStorage.RE:FindFirstChild("1Ca1r"):FireServer("PickingCar", vehicleType)
 end)
 task.wait(1)

 local vehicle = GetVehicle()
 if vehicle then
 local function TrackPlayer()
 local timeout = tick() + 20
 while tick() < timeout do
 if selectedPlayerName then
 local targetPlayer = Players:FindFirstChild(selectedPlayerName)
 if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
 local targetRoot = targetPlayer.Character.HumanoidRootPart
 vehicle:SetPrimaryPartCFrame(targetRoot.CFrame * CFrame.new(0, 0, 10))
 end
 end
 RunService.RenderStepped:Wait()
 end
 end
 spawn(TrackPlayer)
 end

 Window:Notify({
 Title = " Araç",
 Content = vehicleType .. " ile saldırı başladı!",
 Duration = 3
 })
end

-- ===== TELEPORT OYUNCU =====
local function TeleportToPlayer()
 if not selectedPlayerName or not Players:FindFirstChild(selectedPlayerName) then
 Window:Notify({ Title = " Hata", Content = "Oyuncu seçilmedi", Duration = 2 })
 return
 end

 local targetPlayer = Players:FindFirstChild(selectedPlayerName)
 local character = LocalPlayer.Character
 local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
 
 if humanoidRootPart and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
 humanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
 Window:Notify({
 Title = " Teleport",
 Content = selectedPlayerName .. " konumuna taşındı!",
 Duration = 2
 })
 end
end

-- ===== STUN OYUNCU =====
local function StunPlayer()
 if not selectedPlayerName then
 Window:Notify({ Title = " Hata", Content = "Oyuncu seçilmedi", Duration = 2 })
 return
 end

 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end

 local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
 if not tRoot then return end

 local bodyGyro = Instance.new("BodyGyro")
 bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
 bodyGyro.Parent = tRoot

 task.wait(3)
 bodyGyro:Destroy()

 Window:Notify({
 Title = " Stun",
 Content = selectedPlayerName .. " hareketsiz bırakıldı!",
 Duration = 2
 })
end

-- Troll Sekmesi Butonları
TrollTab:AddSection({ " Troll İşlemleri" })

TrollTab:AddButton({
 Name = " Couch Kill",
 Callback = function()
 KillPlayerCouch()
 end
})

TrollTab:AddButton({
 Name = "Soha Bring Player",
    Callback = function()
        BringPlayer()
    end
})

TrollTab:AddButton({
    Name = "Loop Bring BASLAT",
    Callback = function()
        StartLoopBring()
    end
})

TrollTab:AddButton({
    Name = "Loop Bring DURDUR",
    Callback = function()
        StopLoopBring()
    end
})

TrollTab:AddButton({
 Name = " Fling Player",
 Callback = function()
 FlingPlayer()
 end
})

TrollTab:AddButton({
 Name = " Teleport to Player",
 Callback = function()
 TeleportToPlayer()
 end
})

TrollTab:AddButton({
 Name = " Stun Player",
 Callback = function()
 StunPlayer()
 end
})

TrollTab:AddSection({ " Araç Kill Metodu" })

TrollTab:AddDropdown({
 Name = "Araç Tipi Seç",
 Options = {"Bus", "Truck"},
 Default = "Bus",
 Callback = function(v)
 methodKill = v
 Window:Notify({
 Title = " Araç",
 Content = "Seçilen araç: " .. v,
 Duration = 2
 })
 end
})

TrollTab:AddButton({
 Name = " Araç ile Öldür",
 Callback = function()
 KillWithVehicle()
 end
})

-- HAREKET SEKMESİ
local MovementTab = Window:MakeTab({ Title = " Hareket", Icon = "move" })

-- FLY FONKSIYONU
local flySpeed = 50
local function ToggleFly(state)
 flyActive = state
 
 if flyActive then
 local bodyVelocity = Instance.new("BodyVelocity")
 bodyVelocity.Velocity = Vector3.new(0, 0, 0)
 bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
 bodyVelocity.Parent = RootPart

 local bodyGyro = Instance.new("BodyGyro")
 bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
 bodyGyro.Parent = RootPart

 local connection
 connection = RunService.RenderStepped:Connect(function()
 if not flyActive then
 bodyVelocity:Destroy()
 bodyGyro:Destroy()
 connection:Disconnect()
 return
 end

 local moveDirection = Vector3.new(0, 0, 0)
 if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
 if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

 bodyVelocity.Velocity = (moveDirection.Magnitude > 0 and moveDirection.Unit or Vector3.zero) * flySpeed
 bodyGyro.CFrame = Camera.CFrame
 end)

 Window:Notify({
 Title = " Uçma",
 Content = "Uçma başladı!",
 Duration = 2
 })
 end
end

MovementTab:AddSection({ " Uçma" })
MovementTab:AddSlider({
 Name = "Uçma Hızı",
 Min = 1,
 Max = 200,
 Increment = 1,
 Default = 50,
 Callback = function(v)
 flySpeed = v
 end
})

MovementTab:AddToggle({
 Name = "Uçma Aç/Kapat",
 Default = false,
 Callback = function(v)
 ToggleFly(v)
 end
})

-- SPEED FONKSIYONU
local speedAmount = 30
local function ToggleSpeed(state)
 speedActive = state
 
 if speedActive then
 local connection
 connection = RunService.RenderStepped:Connect(function()
 if not speedActive or not Character or not RootPart then
 connection:Disconnect()
 return
 end

 local moveDirection = Vector3.new(0, 0, 0)
 if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end

 if moveDirection.Magnitude > 0 then
 RootPart.AssemblyLinearVelocity = (moveDirection.Magnitude > 0 and moveDirection.Unit or Vector3.zero) * speedAmount + Vector3.new(0, RootPart.AssemblyLinearVelocity.Y, 0)
 end
 end)

 Window:Notify({
 Title = " Hız",
 Content = "Hız boost açıldı!",
 Duration = 2
 })
 end
end

MovementTab:AddSection({ " Hız Boost" })
MovementTab:AddSlider({
 Name = "Hız Miktarı",
 Min = 1,
 Max = 150,
 Increment = 1,
 Default = 30,
 Callback = function(v)
 speedAmount = v
 end
})

MovementTab:AddToggle({
 Name = "Hız Boost Aç/Kapat",
 Default = false,
 Callback = function(v)
 ToggleSpeed(v)
 end
})

-- NOCLIP FONKSIYONU
local noclipConnection
local function ToggleNoclip(state)
 noclipActive = state
 
 if noclipActive then
 noclipConnection = RunService.RenderStepped:Connect(function()
 if not noclipActive or not LocalPlayer.Character then
 noclipConnection:Disconnect()
 return
 end

 local c = LocalPlayer.Character
 if not c then return end
 for _, part in pairs(c:GetDescendants()) do
 if part:IsA("BasePart") then
 part.CanCollide = false
 end
 end
 end)

 Window:Notify({
 Title = " Noclip",
 Content = "Noclip açıldı!",
 Duration = 2
 })
 else
 if noclipConnection then
 noclipConnection:Disconnect()
 end

 local c2 = LocalPlayer.Character
 if c2 then
 for _, part in pairs(c2:GetDescendants()) do
 if part:IsA("BasePart") then
 part.CanCollide = true
 end
 end
 end
 end
end

MovementTab:AddSection({ " Noclip" })
MovementTab:AddToggle({
 Name = "Noclip Aç/Kapat",
 Default = false,
 Callback = function(v)
 ToggleNoclip(v)
 end
})

-- INFINITE JUMP FONKSIYONU
local _ijConn = nil
local function SetupInfiniteJump()
 infiniteJumpActive = true
 if _ijConn then return end -- zaten bagli
 _ijConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
 if not infiniteJumpActive or gameProcessed then return end
 if input.KeyCode == Enum.KeyCode.Space then
 local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if humanoid then
 humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
 end
 end
 end)

 Window:Notify({
 Title = " Sonsuz Zıplama",
 Content = "Sonsuz zıplama açıldı!",
 Duration = 2
 })
end

MovementTab:AddSection({ " Sonsuz Zıplama" })
MovementTab:AddButton({
 Name = "Sonsuz Zıplamayı Aç",
 Callback = function()
 SetupInfiniteJump()
 end
})

-- KARARKTERİSTİK SEKMESİ (Avatar)
local CharacterTab = Window:MakeTab({ Title = " Karakter", Icon = "character" })

CharacterTab:AddSection({ " Başlık Değiştir" })

local headOptions = {
 "Cheeks Head",
 "Narrow Head",
 "Paragon Head",
 "Wide Head",
 "Baby Head",
 "Cylinder Head"
}

CharacterTab:AddDropdown({
 Name = "Başlık Seç",
 Options = headOptions,
 Default = "Cheeks Head",
 Callback = function(value)
 local headAssets = {
 ["Cheeks Head"] = 746767604,
 ["Narrow Head"] = 746774687,
 ["Paragon Head"] = 746783110,
 ["Wide Head"] = 746789881,
 ["Baby Head"] = 746796054,
 ["Cylinder Head"] = 746803227
 }

 local assetId = headAssets[value] or 746767604
 local args = {
 [1] = {
 [1] = 0,
 [2] = 0,
 [3] = 0,
 [4] = 0,
 [5] = 0,
 [6] = assetId
 }
 }

 pcall(function()
 ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
 Window:Notify({
 Title = " Başlık",
 Content = value .. " seçildi!",
 Duration = 2
 })
 end)
 end
})

CharacterTab:AddSection({ " Kız Paketi" })

CharacterTab:AddButton({
 Name = "Kız Paketi 1 Uygula",
 Callback = function()
 pcall(function()
 local args = { [1] = "BundleGirlFace" }
 ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
 Window:Notify({
 Title = " Bundle",
 Content = "Kız Paketi 1 uygulandı!",
 Duration = 2
 })
 end)
 end
})

CharacterTab:AddSection({ " Erkek Paketi" })

CharacterTab:AddButton({
 Name = "Erkek Paketi 1 Uygula",
 Callback = function()
 pcall(function()
 local args = { [1] = "BundleBoyFace" }
 ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
 Window:Notify({
 Title = " Bundle",
 Content = "Erkek Paketi 1 uygulandı!",
 Duration = 2
 })
 end)
 end
})

-- İSİM & BİO SEKMESİ
local NameTab = Window:MakeTab({ Title = " İsim & Bio", Icon = "text" })

NameTab:AddSection(" RP İsmi Değiştir")

local customName = ""
NameTab:AddTextBox({
 Name = "Yeni İsim Gir",
 Default = "",
 PlaceholderText = "İsmi buraya yazın",
 ClearText = true,
 Callback = function(value)
 customName = value
 end
})

NameTab:AddButton({
 Name = " İsim Değiştir",
 Callback = function()
 if customName ~= "" then
 pcall(function()
 ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayName", customName)
 Window:Notify({
 Title = " İsim",
 Content = "İsim: " .. customName,
 Duration = 2
 })
 end)
 else
 Window:Notify({
 Title = " Hata",
 Content = "İsim boş olamaz!",
 Duration = 2
 })
 end
 end
})

NameTab:AddSection(" Hazır İsimler")

local presetNames = {
 " ZYRONIS",
 " King",
 " Admin ",
 " Pro Player ",
 " Legend ",
 " Gamer ",
}

for _, name in ipairs(presetNames) do
 NameTab:AddButton({
 Name = name,
 Callback = function()
 pcall(function()
 ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayName", name)
 Window:Notify({
 Title = " İsim",
 Content = "İsim: " .. name,
 Duration = 2
 })
 end)
 end
 })
end

NameTab:AddSection(" RP Bio Yazı")

local customBio = ""
NameTab:AddTextBox({
 Name = "Bio Gir",
 Default = "",
 PlaceholderText = "Bio yazınızı girin",
 ClearText = true,
 Callback = function(value)
 customBio = value
 end
})

NameTab:AddButton({
 Name = " Bio Değiştir",
 Callback = function()
 if customBio ~= "" then
 pcall(function()
 ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayBio", customBio)
 Window:Notify({
 Title = " Bio",
 Content = "Bio değiştirildi!",
 Duration = 2
 })
 end)
 end
 end
})

NameTab:AddSection(" Hazır Bio Metinleri")

local presetBios = {
 "ZYRONIS Developer",
 "Professional Player",
 "Gaming Expert",
 "Admin Account",
 "VIP Member",
 "Roleplay Pro",
}

for _, bio in ipairs(presetBios) do
 NameTab:AddButton({
 Name = bio,
 Callback = function()
 pcall(function()
 ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayBio", bio)
 Window:Notify({
 Title = " Bio",
 Content = "Bio: " .. bio,
 Duration = 2
 })
 end)
 end
 })
end

-- RENKLİ İSİM SEKMESİ
local ColorNameTab = Window:MakeTab({ Title = " Renkli İsim", Icon = "color" })

ColorNameTab:AddSection(" İsim Renkleri")

local nameColorR = 255
local nameColorG = 0
local nameColorB = 0

ColorNameTab:AddSlider({
 Name = " Kırmızı",
 Min = 0,
 Max = 255,
 Increment = 1,
 Default = 255,
 Callback = function(v)
 nameColorR = v
 end
})

ColorNameTab:AddSlider({
 Name = " Yeşil",
 Min = 0,
 Max = 255,
 Increment = 1,
 Default = 0,
 Callback = function(v)
 nameColorG = v
 end
})

ColorNameTab:AddSlider({
 Name = " Mavi",
 Min = 0,
 Max = 255,
 Increment = 1,
 Default = 0,
 Callback = function(v)
 nameColorB = v
 end
})

ColorNameTab:AddButton({
 Name = " Rengi Uygula",
 Callback = function()
 pcall(function()
 local color = Color3.new(nameColorR / 255, nameColorG / 255, nameColorB / 255)
 ReplicatedStorage.RE["1RPNam1eColo1r"]:FireServer("PickingRPNameColor", color)
 Window:Notify({
 Title = " Renk",
 Content = "İsim rengi değiştirildi!",
 Duration = 2
 })
 end)
 end
})

-- KOMUTLAR SEKMESİ
local CommandsTab = Window:MakeTab({ Title = " Komutlar", Icon = "code" })

CommandsTab:AddSection(" Sistemin Komutları")

CommandsTab:AddButton({
 Name = " Oyunu Yenile (Rejoin)",
 Callback = function()
 TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
 end
})

CommandsTab:AddButton({
 Name = " Tüm Araçları Temizle",
 Callback = function()
 pcall(function()
 ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Clea1rTool1s"):FireServer("ClearAllTools")
 Window:Notify({
 Title = " Temizlik",
 Content = "Tüm araçlar temizlendi!",
 Duration = 2
 })
 end)
 end
})

CommandsTab:AddButton({
 Name = " Karakteri Yeniden Oluştur",
 Callback = function()
 if LocalPlayer.Character then
 LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
 Window:Notify({
 Title = " Karakter",
 Content = "Karakter yeniden oluşturuluyor...",
 Duration = 2
 })
 end
 end
})

CommandsTab:AddSection(" Gelişmiş Komutlar")

local currentKickMessage = "ZYRONIS HUB tarafından sunucudan ayrıldınız!"

CommandsTab:AddTextBox({
 Name = "Kick Mesajı",
 Default = "ZYRONIS HUB tarafından sunucudan ayrıldınız!",
 PlaceholderText = "Mesajı girin",
 ClearText = true,
 Callback = function(value)
 currentKickMessage = value
 end
})

CommandsTab:AddButton({
 Name = " Kendini Kick Et",
 Callback = function()
 LocalPlayer:Kick(currentKickMessage)
 end
})

-- ESP SEKMESİ
local ESPTab = Window:MakeTab({ Title = " ESP", Icon = "eye" })

ESPTab:AddSection(" ESP Ayarları")

ESPTab:AddToggle({
 Name = "ESP Aç/Kapat",
 Default = false,
 Callback = function(v)
 _G.ESPData.espEnabled = v
 if v then
 Window:Notify({
 Title = " ESP",
 Content = "ESP açıldı!",
 Duration = 2
 })
 end
 end
})

ESPTab:AddDropdown({
 Name = "ESP Tipi",
 Options = {"Ad + Yaş", "Sadece Ad", "Sadece Yaş"},
 Default = "Ad + Yaş",
 Callback = function(v)
 _G.ESPData.espType = v
 end
})

ESPTab:AddDropdown({
 Name = "Renk Seç",
 Options = {"RGB", "Kırmızı", "Yeşil", "Mavi", "Sarı"},
 Default = "RGB",
 Callback = function(v)
 _G.ESPData.selectedColor = v
 end
})

-- KARİKTER YÖNETİMİ
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
 Character = newCharacter
 Humanoid = newCharacter:WaitForChild("Humanoid")
 RootPart = newCharacter:WaitForChild("HumanoidRootPart")
 
 -- Reset edilecek değişkenler
 flyActive = false
 speedActive = false
 noclipActive = false
 infiniteJumpActive = false
end)

-- YENI OZELLIKLER - ARASTIRMADAN EKLENDI
-- Kaynak: Suki Hub (illremember), Cartola Hub,
-- Infinite Yield, open source BH scriptleri

-- Yeni global degiskenler
local orbitActive = false
local orbitConnection = nil
local orbitAngle = 0
local freezeActive = false
local freezeConnection = nil
local invisibleActive = false
local godmodeActive = false
local annoyActive = false
local annoyConnection = nil
local glitchActive = false
local glitchConnection = nil
local antiFlingActive = false
local antiFlingConn = nil
local touchFlingEnabled = false
local touchFlingConns = {}
local touchFlingPlayers = {}
local avatarCopyTarget = nil
local highlightESP = {}
local carFlyActive = false
local carFlyConn = nil

-- TROLL SEKMESINE YENI FONKSIYONLAR
local TrollTabNew = Window:MakeTab({ Title = "Troll Plus", Icon = "rbxassetid://15309138473" })

TrollTabNew:AddSection({ "Hedef Oyuncu" })
TrollTabNew:AddLabel("Not: Troll/PVP sekmesindeki secimi kullanir")

-- ORBIT - RocketPropulsion metodu (Infinite Yield'den)
TrollTabNew:AddSection({ "Orbit Player" })
TrollTabNew:AddToggle({
 Name = "Orbit Ac/Kapat",
 Default = false,
 Callback = function(v)
 orbitActive = v
 local char = LocalPlayer.Character
 if not char then return end
 local hrp = char:FindFirstChild("HumanoidRootPart")
 if not hrp then return end

 -- Onceki orbit temizle
 if hrp:FindFirstChild("Orbit") then
 hrp:FindFirstChild("Orbit"):Destroy()
 end
 if orbitConnection then orbitConnection:Disconnect() end

 if v and selectedPlayerName then
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 if not tHRP then return end

 -- RocketPropulsion ile orbit (Infinite Yield metodu)
 local rocket = Instance.new("RocketPropulsion")
 rocket.Parent = hrp
 rocket.Name = "Orbit"
 rocket.Target = tHRP
 rocket.MaxThrust = 8000
 rocket.ThrustD = 200
 rocket.ThrustP = 1000
 rocket.MaxSpeed = 60
 rocket.TargetOffset = Vector3.new(8, 0, 0)
 rocket:Fire()

 -- Offset'i dondurmek icin heartbeat loop
 orbitAngle = 0
 orbitConnection = RunService.Heartbeat:Connect(function(dt)
 if not orbitActive then
 if hrp:FindFirstChild("Orbit") then hrp:FindFirstChild("Orbit"):Destroy() end
 orbitConnection:Disconnect()
 return
 end
 if not target or not target.Character then return end
 local tHRP2 = target.Character:FindFirstChild("HumanoidRootPart")
 if not tHRP2 then return end

 orbitAngle = orbitAngle + dt * 90
 local rad = math.rad(orbitAngle)
 local offsetX = math.cos(rad) * 8
 local offsetZ = math.sin(rad) * 8
 local r = hrp:FindFirstChild("Orbit")
 if r then r.TargetOffset = Vector3.new(offsetX, 0, offsetZ) end
 end)

 Window:Notify({ Title = "Orbit", Content = selectedPlayerName .. " etrafinda donuluyor!", Duration = 2 })
 end
 end
})

-- FREEZE PLAYER - BodyVelocity + BodyPosition ile dondur (Infinite Yield cfreeze metodu)
TrollTabNew:AddSection({ "Freeze Player" })
TrollTabNew:AddToggle({
 Name = "Freeze Ac/Kapat",
 Default = false,
 Callback = function(v)
 freezeActive = v
 if not selectedPlayerName then return end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 if not tHRP then return end

 if v then
 -- Client freeze: BodyPosition ile fikir Infinite Yield'den
 local bp = Instance.new("BodyPosition")
 bp.Name = "ZyronisFreezePos"
 bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
 bp.Position = tHRP.Position
 bp.D = 1000
 bp.P = 10000
 bp.Parent = tHRP

 local bv = Instance.new("BodyVelocity")
 bv.Name = "ZyronisFreezeBV"
 bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
 bv.Velocity = Vector3.zero
 bv.Parent = tHRP

 Window:Notify({ Title = "Freeze", Content = selectedPlayerName .. " donduruldu!", Duration = 2 })
 else
 if tHRP:FindFirstChild("ZyronisFreezePos") then tHRP:FindFirstChild("ZyronisFreezePos"):Destroy() end
 if tHRP:FindFirstChild("ZyronisFreezeBV") then tHRP:FindFirstChild("ZyronisFreezeBV"):Destroy() end
 Window:Notify({ Title = "Freeze", Content = selectedPlayerName .. " serbest!", Duration = 2 })
 end
 end
})

-- ANNOY - Surekli teleport (Infinite Yield annoy metodu)
TrollTabNew:AddSection({ "Annoy (Surekli Takip)" })
TrollTabNew:AddToggle({
 Name = "Annoy Ac/Kapat",
 Default = false,
 Callback = function(v)
 annoyActive = v
 if annoyConnection then annoyConnection:Disconnect() end

 if v and selectedPlayerName then
 annoyConnection = RunService.Heartbeat:Connect(function()
 if not annoyActive then
 annoyConnection:Disconnect()
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if tHRP and myHRP then
 myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
 end
 end)
 Window:Notify({ Title = "Annoy", Content = selectedPlayerName .. " takip ediliyor!", Duration = 2 })
 end
 end
})

-- GLITCH PLAYER - Glitch efekti (Infinite Yield glitch metodu)
TrollTabNew:AddSection({ "Glitch Player" })
TrollTabNew:AddToggle({
 Name = "Glitch Ac/Kapat",
 Default = false,
 Callback = function(v)
 glitchActive = v
 if glitchConnection then glitchConnection:Disconnect() end

 if v and selectedPlayerName then
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not tHRP or not myHRP then return end

 glitchConnection = RunService.Heartbeat:Connect(function()
 if not glitchActive then
 glitchConnection:Disconnect()
 return
 end
 local t2 = Players:FindFirstChild(selectedPlayerName)
 if not t2 or not t2.Character then return end
 local th = t2.Character:FindFirstChild("HumanoidRootPart")
 local mh = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if th and mh then
 -- Ikisini birbirinin pozisyonuna isle
 local savedPos = mh.CFrame
 mh.CFrame = th.CFrame
 th.CFrame = savedPos
 end
 end)
 Window:Notify({ Title = "Glitch", Content = selectedPlayerName .. " ile glitch!", Duration = 2 })
 end
 end
})

-- VOID PLAYER - Uçuruma gonder
TrollTabNew:AddSection({ "Void (Uçuruma Gonder)" })
TrollTabNew:AddButton({
 Name = "Void Player",
 Callback = function()
 if not selectedPlayerName then
 Window:Notify({ Title = "Hata", Content = "Oyuncu secilmedi!", Duration = 2 })
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 if tHRP then
 tHRP.CFrame = CFrame.new(0, -1000, 0)
 Window:Notify({ Title = "Void", Content = selectedPlayerName .. " ucuruma gonderildi!", Duration = 2 })
 end
 end
})

-- FREEFALL - Ikisini de havaya kaldır (Infinite Yield freefall)
TrollTabNew:AddButton({
 Name = "Freefall (Ikimizi Havaya)",
 Callback = function()
 if not selectedPlayerName then return end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if tHRP and myHRP then
 local highPos = myHRP.CFrame + Vector3.new(0, 500, 0)
 tHRP.CFrame = highPos
 myHRP.CFrame = highPos + Vector3.new(2, 0, 0)
 Window:Notify({ Title = "Freefall", Content = "Ikisi de havada!", Duration = 2 })
 end
 end
})

-- TOUCH FLING - ZYRONIS HUB VERSIYONU
-- Sen dokunursun, karsindaki ucur
TrollTabNew:AddSection({ "Touch Fling" })
TrollTabNew:AddToggle({
 Name = "Touch Fling Ac/Kapat",
 Default = false,
 Callback = function(v)
 touchFlingEnabled = v

 for _, c in pairs(touchFlingConns) do c:Disconnect() end
 touchFlingConns = {}
 touchFlingPlayers = {}

 if v then
 local function connectTF(char)
 if not char then return end
 for _, part in pairs(char:GetDescendants()) do
 if part:IsA("BasePart") then
 local conn = part.Touched:Connect(function(hit)
 if not touchFlingEnabled then return end
 local hitChar = hit.Parent
 local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
 if not hitPlayer or hitPlayer == LocalPlayer then return end
 if touchFlingPlayers[hitPlayer.UserId] then return end
 touchFlingPlayers[hitPlayer.UserId] = true

 local tHRP = hitChar:FindFirstChild("HumanoidRootPart")
 local tHum = hitChar:FindFirstChildOfClass("Humanoid")
 if tHRP and tHum and tHum.Health > 0 then
 -- CFrame spin fling (Cartola Hub metodu)
 local angle = 0
 local t = 0
 local conn2
 conn2 = RunService.Heartbeat:Connect(function(dt)
 t = t + dt
 if t >= 0.4 then conn2:Disconnect() return end
 angle = angle + 35
 tHRP.CFrame = tHRP.CFrame
 * CFrame.Angles(math.rad(angle), math.rad(angle * 0.5), math.rad(angle))
 * CFrame.new(0, 0.5, 0)
 end)
 end

 task.delay(1, function()
 touchFlingPlayers[hitPlayer.UserId] = nil
 end)
 end)
 table.insert(touchFlingConns, conn)
 end
 end
 end

 connectTF(LocalPlayer.Character)
 LocalPlayer.CharacterAdded:Connect(function(c)
 c:WaitForChild("HumanoidRootPart")
 if touchFlingEnabled then task.wait(0.3) connectTF(c) end
 end)
 Window:Notify({ Title = "Touch Fling", Content = "Aktif! Birine dokun.", Duration = 2 })
 end
 end
})

-- KARAKTER / GORSEL SEKMESI
local VisualTab = Window:MakeTab({ Title = "Gorsel", Icon = "rbxassetid://15309138473" })

-- INVISIBLE - LocalTransparencyModifier ile (Infinite Yield invisible)
VisualTab:AddSection({ "Gorunmezlik" })
VisualTab:AddToggle({
 Name = "Invisible Ac/Kapat",
 Default = false,
 Callback = function(v)
 invisibleActive = v
 local char = LocalPlayer.Character
 if not char then return end

 for _, part in pairs(char:GetDescendants()) do
 if part:IsA("BasePart") then
 part.LocalTransparencyModifier = v and 1 or 0
 end
 if part:IsA("Decal") then
 part.LocalTransparencyModifier = v and 1 or 0
 end
 end

 -- Karaktere yeni part eklenince de invisible uygula
 if v then
 char.DescendantAdded:Connect(function(d)
 if invisibleActive and d:IsA("BasePart") then
 d.LocalTransparencyModifier = 1
 end
 end)
 end

 Window:Notify({ Title = "Invisible", Content = v and "Gorunmez olundu!" or "Normal gorunume donuldu!", Duration = 2 })
 end
})

-- FE GODMODE - PlatformStand ile (Infinite Yield god metodu)
VisualTab:AddSection({ "FE Godmode" })
VisualTab:AddToggle({
 Name = "Godmode Ac/Kapat",
 Default = false,
 Callback = function(v)
 godmodeActive = v
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hum then return end

 if v then
 -- PlatformStand ile hasar almama (klasik FE godmode)
 hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
 hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
 hum.BreakJointsOnDeath = false

 if not _G.godmodeConn then
            _G.godmodeConn = RunService.Heartbeat:Connect(function()
                if not godmodeActive then
                    _G.godmodeConn:Disconnect()
                    _G.godmodeConn = nil
                    return
                end
                local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health < 1 and h.Health ~= 0 then
                    h.Health = h.MaxHealth
                end
            end)
        end
 Window:Notify({ Title = "Godmode", Content = "Godmode ACIK!", Duration = 2 })
 else
 hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
 hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
 hum.BreakJointsOnDeath = true
 Window:Notify({ Title = "Godmode", Content = "Godmode KAPALI!", Duration = 2 })
 end
 end
})

-- ANTI FLING / ANTI RAGDOLL - (Roburox Anti Fling metodu)
VisualTab:AddSection({ "Anti Fling / Anti Ragdoll" })
VisualTab:AddToggle({
 Name = "Anti Fling Ac/Kapat",
 Default = false,
 Callback = function(v)
 antiFlingActive = v
 if antiFlingConn then antiFlingConn:Disconnect() end

 if v then
 antiFlingConn = RunService.Heartbeat:Connect(function()
 if not antiFlingActive then
 antiFlingConn:Disconnect()
 return
 end
 local char = LocalPlayer.Character
 if not char then return end
 local hrp = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hrp or not hum then return end

 -- Hizi sifirla (anti fling etkisi)
 if hrp.AssemblyLinearVelocity.Magnitude > 100 then
 hrp.AssemblyLinearVelocity = Vector3.zero
 end

 -- Ragdoll engelle
 hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
 pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
 end)
 Window:Notify({ Title = "Anti Fling", Content = "Anti Fling ACIK!", Duration = 2 })
 else
 local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if hum then
 hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
 hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
 end
 Window:Notify({ Title = "Anti Fling", Content = "Anti Fling KAPALI!", Duration = 2 })
 end
 end
})

-- HIGHLIGHT ESP - Instance bazli (BH scriptlerden daha iyi ESP)
VisualTab:AddSection({ "Highlight ESP" })
VisualTab:AddToggle({
 Name = "Highlight ESP Ac/Kapat",
 Default = false,
 Callback = function(v)
 -- Onceki highlight'lari temizle
 for _, h in pairs(highlightESP) do
 if h and h.Parent then h:Destroy() end
 end
 highlightESP = {}

 if v then
 local function addHighlight(plr)
 if plr == LocalPlayer then return end
 if not plr.Character then return end

 local hl = Instance.new("Highlight")
 hl.Name = "ZyronisHL"
 hl.FillColor = Color3.fromRGB(255, 0, 0)
 hl.OutlineColor = Color3.fromRGB(255, 255, 255)
 hl.FillTransparency = 0.5
 hl.OutlineTransparency = 0
 hl.Adornee = plr.Character
 hl.Parent = plr.Character
 table.insert(highlightESP, hl)

 plr.CharacterAdded:Connect(function(newChar)
 if not _G.ESPData.espEnabled then return end
 task.wait(0.5)
 local hl2 = Instance.new("Highlight")
 hl2.Name = "ZyronisHL"
 hl2.FillColor = Color3.fromRGB(255, 0, 0)
 hl2.OutlineColor = Color3.fromRGB(255, 255, 255)
 hl2.FillTransparency = 0.5
 hl2.OutlineTransparency = 0
 hl2.Adornee = newChar
 hl2.Parent = newChar
 table.insert(highlightESP, hl2)
 end)
 end

 for _, plr in pairs(Players:GetPlayers()) do addHighlight(plr) end
 Players.PlayerAdded:Connect(addHighlight)

 Window:Notify({ Title = "Highlight ESP", Content = "Highlight ESP ACIK!", Duration = 2 })
 else
 Window:Notify({ Title = "Highlight ESP", Content = "Highlight ESP KAPALI!", Duration = 2 })
 end
 end
})

-- AVATAR KOPYALA SEKMESI
-- Kaynak: Soluna Hub avatar copy metodu
local AvatarTab = Window:MakeTab({ Title = "Avatar Kopyala", Icon = "rbxassetid://15309138473" })

AvatarTab:AddSection({ "Oyuncu Avatarini Kopyala" })
AvatarTab:AddLabel("Troll/PVP sekmesindeki secimi kullanir")

AvatarTab:AddButton({
 Name = "Avatari Kopyala",
 Callback = function()
 if not selectedPlayerName then
 Window:Notify({ Title = "Hata", Content = "Oyuncu secilmedi!", Duration = 2 })
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end

 local myChar = LocalPlayer.Character
 if not myChar then return end

 -- Her vücut parcasinin rengini kopyala (Soluna Hub metodu)
 local bodyParts = {"Head", "Torso", "UpperTorso", "LowerTorso", "LeftArm", "RightArm",
 "LeftLeg", "RightLeg", "LeftUpperArm", "RightUpperArm",
 "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
 "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
 "LeftFoot", "RightFoot"}

 for _, partName in pairs(bodyParts) do
 local targetPart = target.Character:FindFirstChild(partName)
 local myPart = myChar:FindFirstChild(partName)
 if targetPart and myPart then
 myPart.Color = targetPart.Color
 myPart.Material = targetPart.Material
 end
 end

 -- Aksesuar kopyala (shirt/pants)
 pcall(function()
 for _, item in pairs(myChar:GetDescendants()) do
 if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
 item:Destroy()
 end
 end
 for _, item in pairs(target.Character:GetDescendants()) do
 if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
 item:Clone().Parent = myChar
 end
 end
 end)

 -- RP ismini kopyala
 pcall(function()
 local rpName = target.Character:FindFirstChild("RPName") or
 target.Character:FindFirstChildOfClass("BillboardGui")
 if rpName then
 ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayName", target.DisplayName)
 end
 end)

 Window:Notify({
 Title = "Avatar Kopyala",
 Content = selectedPlayerName .. " avatari kopyalandi!",
 Duration = 3
 })
 end
})

-- Kendi avatarina don
AvatarTab:AddButton({
 Name = "Orijinal Avatara Don",
 Callback = function()
 LocalPlayer:LoadCharacter()
 Window:Notify({ Title = "Avatar", Content = "Karakter sifirlanıyor...", Duration = 2 })
 end
})

-- HARITA TELEPORT SEKMESI
-- Kaynak: Brookhaven harita koordinatlarindan
local MapTab = Window:MakeTab({ Title = "Harita TP", Icon = "rbxassetid://15309138473" })

MapTab:AddSection({ "Brookhaven Konumlari" })

local locations = {
 ["Bank"] = Vector3.new(197, 17, -98),
 ["Hastane"] = Vector3.new(-185, 17, -70),
 ["Polis Merkezi"] = Vector3.new(12, 17, -290),
 ["Okul"] = Vector3.new(-282, 17, 132),
 ["Meydan"] = Vector3.new(0, 17, 0),
 ["Havaalani"] = Vector3.new(378, 17, 102),
 ["Beach"] = Vector3.new(-378, 4, -378),
 ["Dağ Tepe"] = Vector3.new(0, 200, 0),
 ["Bos Alan (Spawn)"] = Vector3.new(0, 17, 50),
 ["Gizli Yer (Yeralt)"] = Vector3.new(145, -350, 21),
}

for locationName, position in pairs(locations) do
 MapTab:AddButton({
 Name = locationName .. " Teleport",
 Callback = function()
 local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if hrp then
 hrp.CFrame = CFrame.new(position)
 Window:Notify({ Title = "Teleport", Content = locationName .. " konumuna gidildi!", Duration = 2 })
 end
 end
 })
end

-- CAR FLY - Arac ile ucma
-- Kaynak: Brookhaven arac remote eventlerinden
local CarTab = Window:MakeTab({ Title = "Arac Plus", Icon = "rbxassetid://15309138473" })

CarTab:AddSection({ "Car Fly (Aracla Uc)" })
CarTab:AddLabel("Once bir araca binmeniz gerekiyor")

local carFlySpeed = 50
CarTab:AddSlider({
 Name = "Ucus Hizi",
 Min = 10,
 Max = 200,
 Increment = 5,
 Default = 50,
 Callback = function(v) carFlySpeed = v end
})

CarTab:AddToggle({
 Name = "Car Fly Ac/Kapat",
 Default = false,
 Callback = function(v)
 carFlyActive = v
 if carFlyConn then carFlyConn:Disconnect() end

 if v then
 carFlyConn = RunService.RenderStepped:Connect(function()
 if not carFlyActive then
 carFlyConn:Disconnect()
 return
 end

 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.SeatPart == nil then return end

 local seat = hum.SeatPart
 local vehicle = seat.Parent

 -- Araci kamera yonunde ilerlet
 local moveDir = Vector3.zero
 if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
 if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

 if vehicle and vehicle.PrimaryPart then
 if moveDir.Magnitude > 0 then
 vehicle:SetPrimaryPartCFrame(
 vehicle.PrimaryPart.CFrame + (moveDir.Unit * carFlySpeed * 0.1)
 )
 end
 end
 end)
 Window:Notify({ Title = "Car Fly", Content = "Araca bin ve W/Space ile uc!", Duration = 3 })
 end
 end
})

-- ARAÇ HIZI BOOST
CarTab:AddSection({ "Arac Hiz Boost" })
local vehicleSpeedBoost = 50
CarTab:AddSlider({
 Name = "Arac Hizi",
 Min = 50,
 Max = 500,
 Increment = 10,
 Default = 50,
 Callback = function(v) vehicleSpeedBoost = v end
})

CarTab:AddToggle({
 Name = "Hiz Boost Ac/Kapat",
 Default = false,
 Callback = function(v)
 if v then
 _G.hizBoostActive = true
 if not _G.hizBoostConn then
 _G.hizBoostConn = RunService.RenderStepped:Connect(function()
 if not _G.hizBoostActive then
 _G.hizBoostConn:Disconnect()
 _G.hizBoostConn = nil
 return
 end
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.SeatPart == nil then return end
 local seat = hum.SeatPart
 if seat:IsA("VehicleSeat") then
 seat.MaxSpeed = vehicleSpeedBoost
 seat.Torque = vehicleSpeedBoost * 10
 end
 end)
 end
 Window:Notify({ Title = "Hiz Boost", Content = "Arac hiz boost aktif!", Duration = 2 })
 else
 _G.hizBoostActive = false
 if _G.hizBoostConn then
 _G.hizBoostConn:Disconnect()
 _G.hizBoostConn = nil
 end
 end
 end
})

-- BASLANGIÇ BILDIRIMI
-- DERIN ARASTIRMA - YENI OZELLIKLER v2
-- Kaynak: Soluna Hub, Infinite Yield, danyad22/FakeLag,
-- Rscripts.net open source BH toplulugu

-- Yeni degiskenler
local rgbNameActive = false
local rgbNameConn = nil
local rgbCarActive = false
local rgbCarConn = nil
local fakeLagActive = false
local fakeLagClone = nil
local fakeLagConn = nil
local spectateConn = nil
local antiSitConn = nil
local chatSpamActive = false
local hornSpamActive = false
local hornSpamConn = nil
local antiAfkConn = nil

-- RGB & OZEL ISIM SEKMESI
-- Kaynak: Soluna Hub RGB name metodu
local RGBTab = Window:MakeTab({ Title = "RGB ve Efektler", Icon = "rbxassetid://15309138473" })

-- RGB ISIM - Surekli renk degistirme
RGBTab:AddSection({ "RGB Renkli Isim" })
RGBTab:AddToggle({
 Name = "RGB Isim Ac/Kapat",
 Default = false,
 Callback = function(v)
 rgbNameActive = v
 if rgbNameConn then rgbNameConn:Disconnect() end

 if v then
 local hue = 0
 rgbNameConn = RunService.Heartbeat:Connect(function(dt)
 if not rgbNameActive then
 rgbNameConn:Disconnect()
 return
 end
 hue = (hue + dt * 0.5) % 1
 local color = Color3.fromHSV(hue, 1, 1)
 -- Brookhaven RP isim rengi remote'u
 pcall(function()
 ReplicatedStorage.RE["1RPNam1eColo1r"]:FireServer("PickingRPNameColor", color)
 end)
 end)
 Window:Notify({ Title = "RGB Isim", Content = "RGB Isim ACIK!", Duration = 2 })
 end
 end
})

-- RGB KARAKTER - Vücut renklerini RGB yap (Soluna Hub metodu)
RGBTab:AddToggle({
 Name = "RGB Karakter Ac/Kapat",
 Default = false,
 Callback = function(v)
 if v then
 _G.rgbKarActive = true
 local hue = 0
 if _G.rgbKarConn then _G.rgbKarConn:Disconnect() end
 _G.rgbKarConn = RunService.Heartbeat:Connect(function(dt)
 if not _G.rgbKarActive then
 _G.rgbKarConn:Disconnect()
 _G.rgbKarConn = nil
 return
 end
 hue = (hue + dt * 0.3) % 1
 local color = Color3.fromHSV(hue, 1, 1)
 local char = LocalPlayer.Character
 if not char then return end
 for _, part in pairs(char:GetDescendants()) do
 if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
 part.Color = color
 end
 end
 end)
 Window:Notify({ Title = "RGB Karakter", Content = "RGB Karakter ACIK!", Duration = 2 })
 else
 _G.rgbKarActive = false
 if _G.rgbKarConn then
 _G.rgbKarConn:Disconnect()
 _G.rgbKarConn = nil
 end
 end
 end
})

-- RGB ARAC (Soluna Hub RGB car efekti)
RGBTab:AddSection({ "RGB Arac" })
RGBTab:AddToggle({
 Name = "RGB Arac Ac/Kapat",
 Default = false,
 Callback = function(v)
 rgbCarActive = v
 if rgbCarConn then rgbCarConn:Disconnect() end

 if v then
 local hue = 0
 rgbCarConn = RunService.Heartbeat:Connect(function(dt)
 if not rgbCarActive then rgbCarConn:Disconnect() return end
 hue = (hue + dt * 0.4) % 1
 local color = Color3.fromHSV(hue, 1, 1)
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hum or not hum.SeatPart then return end
 local vehicle = hum.SeatPart.Parent
 if vehicle then
 for _, part in pairs(vehicle:GetDescendants()) do
 if part:IsA("BasePart") then
 part.Color = color
 end
 end
 end
 end)
 Window:Notify({ Title = "RGB Arac", Content = "RGB Arac ACIK! Araca bin.", Duration = 2 })
 end
 end
})

-- FAKE LAG - danyad22/FakeLag metodu
-- Karakter klonu ile sahte gecikme
-- Diger oyunculara sanki lag atiyormus gib gorunursun
local FakeLagTab = Window:MakeTab({ Title = "Fake Lag", Icon = "rbxassetid://15309138473" })

FakeLagTab:AddSection({ "Fake Lag (Sahte Gecikme)" })
FakeLagTab:AddLabel("Acikken diger oyunculara lagli gorunursun")
FakeLagTab:AddLabel("Ama sen normal hareket edersin")

local fakeLagDelay = 1
FakeLagTab:AddSlider({
 Name = "Lag Suresi (saniye)",
 Min = 1,
 Max = 10,
 Increment = 1,
 Default = 3,
 Callback = function(v) fakeLagDelay = v end
})

FakeLagTab:AddToggle({
 Name = "Fake Lag Ac/Kapat",
 Default = false,
 Callback = function(v)
 fakeLagActive = v

 -- Onceki klonu temizle
 if fakeLagClone then fakeLagClone:Destroy() fakeLagClone = nil end
 if fakeLagConn then fakeLagConn:Disconnect() fakeLagConn = nil end

 if v then
 local char = LocalPlayer.Character
 if not char then return end
 local hrp = char:FindFirstChild("HumanoidRootPart")
 if not hrp then return end

 -- Karakterin klonunu olustur (danyad22 metodu)
 char.Archivable = true
 fakeLagClone = char:Clone()
 fakeLagClone.Name = LocalPlayer.Name .. "_FakeLag"

 -- Klon'daki script ve humanoid'i pasif yap
 for _, d in pairs(fakeLagClone:GetDescendants()) do
 if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
 if d:IsA("BodyMover") then d:Destroy() end
 end

 local cloneHum = fakeLagClone:FindFirstChildOfClass("Humanoid")
 if cloneHum then
 cloneHum.WalkSpeed = 0
 cloneHum.JumpPower = 0
 end

 -- Klon'u Lighting'e koy (gorsel klonu orada gizle)
 fakeLagClone.Parent = game:GetService("Lighting")

 -- Gercek karakteri periyodik olarak gizle, klonu goster
 local savedPos = hrp.CFrame
 fakeLagConn = RunService.Heartbeat:Connect(function()
 if not fakeLagActive then
 fakeLagConn:Disconnect()
 return
 end

 -- Her fakeLagDelay saniyede bir pozisyonu guncelle (gecikme efekti)
 end)

 -- Ana loop: karakteri gecici olarak yukari ucar, geri doner
 task.spawn(function()
 while fakeLagActive do
 local c = LocalPlayer.Character
 local h = c and c:FindFirstChild("HumanoidRootPart")
 if h then
 savedPos = h.CFrame
 -- Yukari zıpla (karsidan gizle)
 h.CFrame = CFrame.new(
 math.random(-500,500),
 5000,
 math.random(-500,500)
 )
 task.wait(fakeLagDelay)
 if fakeLagActive and h and h.Parent then
 h.CFrame = savedPos
 end
 task.wait(0.5)
 else
 task.wait(0.1)
 end
 end
 end)

 Window:Notify({ Title = "Fake Lag", Content = "Fake Lag ACIK! Diger oyunculara lagli gorunursun.", Duration = 3 })
 else
 Window:Notify({ Title = "Fake Lag", Content = "Fake Lag KAPALI!", Duration = 2 })
 end
 end
})

-- SPECTATE - Kamera kilitleme
-- Kaynak: Infinite Yield view metodu
local SpectateTab = Window:MakeTab({ Title = "Spectate", Icon = "rbxassetid://15309138473" })

SpectateTab:AddSection({ "Oyuncu Izle (Spectate)" })
SpectateTab:AddLabel("Troll/PVP sekmesindeki oyuncu secimini kullanir")

SpectateTab:AddButton({
 Name = "Spectate Baslat",
 Callback = function()
 if not selectedPlayerName then
 Window:Notify({ Title = "Hata", Content = "Oyuncu secilmedi!", Duration = 2 })
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end

 -- Camera Subject'i hedefin Humanoid'ine ayarla (Infinite Yield view metodu)
 local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
 if targetHum then
 if Camera and targetHum then Camera.CameraSubject = targetHum end
 Camera.CameraType = Enum.CameraType.Follow
 Window:Notify({ Title = "Spectate", Content = selectedPlayerName .. " izleniyor!", Duration = 2 })
 end

 -- Respawn olursa takip et
 if spectateConn then spectateConn:Disconnect() end
 spectateConn = target.CharacterAdded:Connect(function(newChar)
 task.wait(0.5)
 local newHum = newChar:FindFirstChildOfClass("Humanoid")
 if newHum then Camera.CameraSubject = newHum end
 end)
 end
})

SpectateTab:AddButton({
 Name = "Spectate Durdur",
 Callback = function()
 if spectateConn then spectateConn:Disconnect() end
 local myChar = LocalPlayer.Character
 if myChar then
 local myHum = myChar:FindFirstChildOfClass("Humanoid")
 if myHum then
 Camera.CameraSubject = myHum
 Camera.CameraType = Enum.CameraType.Custom
 end
 end
 Window:Notify({ Title = "Spectate", Content = "Kendi kamerana donuldu!", Duration = 2 })
 end
})

-- EV / HUB YONETIMI
-- Kaynak: Soluna Hub house management
local HouseTab = Window:MakeTab({ Title = "Ev Yonetimi", Icon = "rbxassetid://15309138473" })

-- ZIL SPAM - Brookhaven zil remote event'i
HouseTab:AddSection({ "Zil Spam" })
HouseTab:AddLabel("Yakin oldugun evin ziline spam yapar")

local doorbellSpamActive = false
HouseTab:AddToggle({
 Name = "Zil Spam Ac/Kapat",
 Default = false,
 Callback = function(v)
 doorbellSpamActive = v
 if v then
 task.spawn(function()
 while doorbellSpamActive do
 -- Tum Doorbell'lari bul ve tetikle (Soluna Hub metodu)
 pcall(function()
 for _, obj in pairs(workspace:GetDescendants()) do
 if obj.Name == "Doorbell" and obj:IsA("BasePart") then
 local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if hrp and (obj.Position - hrp.Position).Magnitude < 50 then
 -- FireTouchInterest ile dokunma simule et
 firetouchinterest(hrp, obj, 0)
 firetouchinterest(hrp, obj, 1)
 end
 end
 end
 end)
 task.wait(0.1)
 end
 end)
 Window:Notify({ Title = "Zil Spam", Content = "Zil Spam ACIK!", Duration = 2 })
 end
 end
})

-- KAPI NOCLIP - Ev kapilari icinden gec
HouseTab:AddToggle({
 Name = "Kapi Noclip Ac/Kapat",
 Default = false,
 Callback = function(v)
 if v then
 _G.kapiNoclipActive = true
 if not _G.kapiNoclipConn then
 _G.kapiNoclipConn = RunService.Heartbeat:Connect(function()
 if not _G.kapiNoclipActive then
 _G.kapiNoclipConn:Disconnect()
 _G.kapiNoclipConn = nil
 return
 end
 for _, obj in pairs(workspace:GetDescendants()) do
 if (obj.Name:find("Door") or obj.Name:find("door") or obj.Name:find("Gate")) and obj:IsA("BasePart") then
 obj.CanCollide = false
 end
 end
 end)
 end
 Window:Notify({ Title = "Kapi Noclip", Content = "Ev kapilari artik gecirgen!", Duration = 2 })
 else
 _G.kapiNoclipActive = false
 if _G.kapiNoclipConn then
 _G.kapiNoclipConn:Disconnect()
 _G.kapiNoclipConn = nil
 end
 end
 end
})

-- SES OYNATICI
-- Kaynak: Soluna Hub audio control
local AudioTab = Window:MakeTab({ Title = "Ses Oynatici", Icon = "rbxassetid://15309138473" })

AudioTab:AddSection({ "Ses Oynat (Herkese)" })
AudioTab:AddLabel("Brookhaven ses remote'u ile sunucuya ses calinir")

local customAudioId = ""
AudioTab:AddTextBox({
 Name = "Ses ID Gir",
 Default = "",
 PlaceholderText = "rbxassetid://XXXXXXXXX",
 ClearText = true,
 Callback = function(v)
 customAudioId = v
 end
})

AudioTab:AddButton({
 Name = "Ses Oynat",
 Callback = function()
 if customAudioId == "" then
 Window:Notify({ Title = "Hata", Content = "Ses ID girmedin!", Duration = 2 })
 return
 end
 pcall(function()
 -- Brookhaven ses remote eventi
 local re = ReplicatedStorage:FindFirstChild("RE") or ReplicatedStorage:FindFirstChild("RemoteEvents")
 if re then
 local audioRE = re:FindFirstChild("1Mus1ic") or re:FindFirstChild("Music") or re:FindFirstChild("1Sou1nd")
 if audioRE then
 audioRE:FireServer("PlayMusic", tonumber(customAudioId))
 end
 end
 end)

 -- Lokal ses (her zaman calisir)
 local sound = Instance.new("Sound")
 sound.SoundId = "rbxassetid://" .. customAudioId:gsub("[^%d]", "")
 sound.Volume = 1
 sound.Parent = game:GetService("SoundService")
 sound:Play()

 Window:Notify({ Title = "Ses", Content = "Ses oynatiliyor!", Duration = 2 })
 end
})

AudioTab:AddButton({
 Name = "Sesi Durdur",
 Callback = function()
 for _, s in pairs(game:GetService("SoundService"):GetChildren()) do
 if s:IsA("Sound") then s:Stop() s:Destroy() end
 end
 Window:Notify({ Title = "Ses", Content = "Ses durduruldu!", Duration = 2 })
 end
})

-- Hazir Sesler
AudioTab:AddSection({ "Hazir Sesler" })
local presetSounds = {
 ["Bruh"] = "5997559",
 ["Vine Boom"] = "5153845556",
 ["Troll Song"] = "1843671730",
 ["Oof"] = "6081543219",
 ["Rizz"] = "7733732173",
}

for soundName, soundId in pairs(presetSounds) do
 AudioTab:AddButton({
 Name = soundName,
 Callback = function()
 local sound = Instance.new("Sound")
 sound.SoundId = "rbxassetid://" .. soundId
 sound.Volume = 1
 sound.Parent = game:GetService("SoundService")
 sound:Play()
 Window:Notify({ Title = "Ses", Content = soundName .. " oynatiliyor!", Duration = 2 })
 end
 })
end

-- CHAT SPAM & ARACLARI
-- Kaynak: Soluna Hub chat spambot
local ChatTab = Window:MakeTab({ Title = "Chat Araclari", Icon = "rbxassetid://15309138473" })

ChatTab:AddSection({ "Chat Spam" })

local chatSpamMsg = "ZYRONIS HUB"
local chatSpamDelay = 1
ChatTab:AddTextBox({
 Name = "Spam Mesaji",
 Default = "ZYRONIS HUB",
 PlaceholderText = "Mesaj yaz...",
 ClearText = false,
 Callback = function(v) chatSpamMsg = v end
})

ChatTab:AddSlider({
 Name = "Spam Gecikme (sn)",
 Min = 1,
 Max = 10,
 Increment = 1,
 Default = 2,
 Callback = function(v) chatSpamDelay = v end
})

ChatTab:AddToggle({
 Name = "Chat Spam Ac/Kapat",
 Default = false,
 Callback = function(v)
 chatSpamActive = v
 if v then
 task.spawn(function()
 while chatSpamActive do
 -- Roblox chat gonder
 game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") and
 pcall(function()
 game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(chatSpamMsg, "All")
 end)
 task.wait(chatSpamDelay)
 end
 end)
 Window:Notify({ Title = "Chat Spam", Content = "Chat Spam ACIK!", Duration = 2 })
 end
 end
})

-- HORN SPAM - Araç kornasindan spam
ChatTab:AddSection({ "Klakson Spam" })
ChatTab:AddToggle({
 Name = "Klakson Spam Ac/Kapat",
 Default = false,
 Callback = function(v)
 hornSpamActive = v
 if hornSpamConn then hornSpamConn:Disconnect() end

 if v then
 task.spawn(function()
 while hornSpamActive do
 pcall(function()
 local char = LocalPlayer.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 if hum and hum.SeatPart then
 -- Brookhaven klakson remote
 ReplicatedStorage.RE:FindFirstChild("1Hor1n") and
 ReplicatedStorage.RE["1Hor1n"]:FireServer("HornBeep")
 end
 end)
 task.wait(0.1)
 end
 end)
 Window:Notify({ Title = "Klakson", Content = "Klakson Spam ACIK! Araca bin.", Duration = 2 })
 end
 end
})

-- BOYUT DEGISTIR
-- Kaynak: Infinite Yield hipheight + Soluna karakter buyutme
local SizeTab = Window:MakeTab({ Title = "Boyut ve Animasyon", Icon = "rbxassetid://15309138473" })

SizeTab:AddSection({ "Karakter Boyutu" })

SizeTab:AddSlider({
 Name = "Karakter Boyutu",
 Min = 1,
 Max = 20,
 Increment = 1,
 Default = 5,
 Callback = function(v)
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then
 -- HipHeight ile boyutu ayarla (Infinite Yield hipheight metodu)
 hum.HipHeight = v * 0.3
 end
 -- Scale degistir
 pcall(function()
 for _, desc in pairs(char:GetDescendants()) do
 if desc:IsA("SpecialMesh") then
 desc.Scale = Vector3.new(v * 0.2, v * 0.2, v * 0.2)
 end
 end
 end)
 end
})

SizeTab:AddButton({
 Name = "Dev Yap (Giant)",
 Callback = function()
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then hum.HipHeight = 8 end
 Window:Notify({ Title = "Boyut", Content = "DEV oldun!", Duration = 2 })
 end
})

SizeTab:AddButton({
 Name = "Kucuk Yap (Tiny)",
 Callback = function()
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then hum.HipHeight = -0.8 end
 Window:Notify({ Title = "Boyut", Content = "KUCUK oldun!", Duration = 2 })
 end
})

SizeTab:AddButton({
 Name = "Normal Boyut",
 Callback = function()
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then hum.HipHeight = 0 end
 Window:Notify({ Title = "Boyut", Content = "Normal boyuta donuldu!", Duration = 2 })
 end
})

-- ANIMASYON DEGISTIR
SizeTab:AddSection({ "Animasyon Paketi" })

local animPacks = {
 ["Smooth"] = "507766388",
 ["Ninja"] = "507770453",
 ["Robot"] = "507766666",
 ["Zombie"] = "507770239",
 ["Superhero"] = "507770828",
 ["Vampire"] = "2707229537",
 ["Rthro"] = "2510235239",
}

for packName, packId in pairs(animPacks) do
 SizeTab:AddButton({
 Name = packName .. " Animasyon",
 Callback = function()
 pcall(function()
 local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if not hum then return end
 local animate = LocalPlayer.Character:FindFirstChild("Animate")
 if animate then
 for _, animTrack in pairs(hum:GetPlayingAnimationTracks()) do
 animTrack:Stop()
 end
 -- Animasyon paketini yukle
 local animLoader = hum:LoadAnimation(Instance.new("Animation"))
 end
 end)

 -- Roblox animasyon apisi ile yukle
 local char = LocalPlayer.Character
 if char then
 local animate = char:FindFirstChild("Animate")
 if animate then
 local walk = animate:FindFirstChild("walk")
 local run = animate:FindFirstChild("run")
 local idle = animate:FindFirstChild("idle")
 if walk and walk:FindFirstChild("WalkAnim") then
 walk.WalkAnim.AnimationId = "rbxassetid://" .. packId
 end
 if run and run:FindFirstChild("RunAnim") then
 run.RunAnim.AnimationId = "rbxassetid://" .. packId
 end
 end
 end
 Window:Notify({ Title = "Animasyon", Content = packName .. " animasyon paketi yuklendi!", Duration = 2 })
 end
 })
end

-- ANTI AFK - VirtualUser ile
-- Kaynak: Universal anti-afk scripti
local UtilTab = Window:MakeTab({ Title = "Yardimci", Icon = "rbxassetid://15309138473" })

UtilTab:AddSection({ "Anti AFK" })
UtilTab:AddToggle({
 Name = "Anti AFK Ac/Kapat",
 Default = false,
 Callback = function(v)
 if antiAfkConn then antiAfkConn:Disconnect() end
 if v then
 -- VirtualUser ile AFK engelle (universal metodu)
 local VU = game:GetService("VirtualUser")
 antiAfkConn = LocalPlayer.Idled:Connect(function()
 VU:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
 task.wait(0.1)
 VU:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
 end)
 Window:Notify({ Title = "Anti AFK", Content = "Anti AFK ACIK!", Duration = 2 })
 else
 Window:Notify({ Title = "Anti AFK", Content = "Anti AFK KAPALI!", Duration = 2 })
 end
 end
})

-- ANTI SIT - Oturmay engelle (Soluna Hub anti-sit)
UtilTab:AddSection({ "Anti Sit" })
UtilTab:AddToggle({
 Name = "Anti Sit Ac/Kapat",
 Default = false,
 Callback = function(v)
 if antiSitConn then antiSitConn:Disconnect() end
 if v then
 antiSitConn = RunService.Heartbeat:Connect(function()
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum and hum.Sit then
 hum.Sit = false
 hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
 end
 end)
 Window:Notify({ Title = "Anti Sit", Content = "Anti Sit ACIK! Artik oturulmaz.", Duration = 2 })
 else
 local char = LocalPlayer.Character
 if char then
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
 end
 Window:Notify({ Title = "Anti Sit", Content = "Anti Sit KAPALI!", Duration = 2 })
 end
 end
})

-- SERVER HOP - Bos sunucuya gecis (TeleportService ile)
UtilTab:AddSection({ "Server Hop" })
UtilTab:AddButton({
 Name = "Server Hop (Bos Sunucuya Gec)",
 Callback = function()
 Window:Notify({ Title = "Server Hop", Content = "Bos sunucu aranıyor...", Duration = 3 })
 pcall(function()
 -- Mevcut sunucu disinda bos sunucu bul
 local HttpService = game:GetService("HttpService")
 local placeId = game.PlaceId

 -- Sunucu listesini cek
 local response = game:HttpGet(
 "https://games.roblox.com/v1/games/" .. placeId ..
 "/servers/Public?sortOrder=Asc&limit=10"
 )
 local data = HttpService:JSONDecode(response)

 if data and data.data then
 for _, server in pairs(data.data) do
 -- Mevcut sunucu degil ve yer var
 if server.id ~= game.JobId and server.playing < server.maxPlayers then
 TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
 return
 end
 end
 end

 -- Bulamazsa yeni sunucu olustur
 TeleportService:Teleport(placeId, LocalPlayer)
 end)
 end
})

-- OYUNCU SAYISI LABEL
UtilTab:AddSection({ "Sunucu Bilgisi" })
UtilTab:AddButton({
 Name = "Sunucu Bilgisi Goster",
 Callback = function()
 local playerCount = #Players:GetPlayers()
 local ping = math.floor(workspace:GetRealPhysicsFPS())
 Window:Notify({
 Title = "Sunucu Bilgisi",
 Content = "Oyuncular: " .. playerCount .. " | FPS: " .. ping .. " | JobID: " .. game.JobId:sub(1,8),
 Duration = 5
 })
 end
})

-- ARACLARI GETIR / KALDIR
UtilTab:AddSection({ "Arac Yonetimi (Sunucu)" })
UtilTab:AddButton({
 Name = "Tum Araclari Getir",
 Callback = function()
 local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 -- Workspace'teki araclari bul ve getir
 for _, obj in pairs(workspace:GetDescendants()) do
 if obj:IsA("Model") and obj:FindFirstChild("VehicleSeat") then
 if obj.PrimaryPart then
 obj:SetPrimaryPartCFrame(hrp.CFrame + Vector3.new(math.random(-10,10), 0, math.random(-10,10)))
 end
 end
 end
 Window:Notify({ Title = "Araclar", Content = "Tum araclar yanına getirildi!", Duration = 2 })
 end
})

UtilTab:AddButton({
 Name = "Tum Araclari Kaldir (Client)",
 Callback = function()
 for _, obj in pairs(workspace:GetDescendants()) do
 if obj:IsA("Model") and obj:FindFirstChild("VehicleSeat") then
 obj:Destroy()
 end
 end
 Window:Notify({ Title = "Araclar", Content = "Tum araclar kaldirildi! (Sadece senin ekraninda)", Duration = 2 })
 end
})

-- BASLANGIÇ BILDIRIMI
print("ZYRONIS HUB - BROOKHAVEN RP BASARILI YUKLEME!")
Window:Notify({
 Title = "ZYRONIS HUB",
 Content = "Tum Ozellikleriyle Basariyla Yuklendi! (Ultra Edition v2)",
 Duration = 5
})

print("ZYRONIS HUB - ULTRA EDITION v2 2025")
print("Tum Ozellikler Aktif!")
print("Brookhaven RP - Iyi Eglenceler!")

-- ZYRONIS HUB - ULTRA v3 EKLEMELERI
-- Kaynak: Script-HubScripts/BrookHavenScript1.lua
-- GERCEK Brookhaven RemoteEvent isimleri kullanildi

local RE = game:GetService("ReplicatedStorage"):FindFirstChild("RE") or game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")

-- SEKME 1: FE TROLL (GERCEK REMOTE EVENTS)
local FETrollTab = Window:MakeTab({ Title = "FE Troll v3", Icon = "rbxassetid://15309138473" })

-- 1) PIGGYBACK ALL - Herkesi birbirine bindirme
FETrollTab:AddSection({ "Piggyback / Bindirme" })
FETrollTab:AddButton({
 Name = "Herkesi Birbirine Bindir",
 Callback = function()
 local RE_trigger = RE:FindFirstChild("P1layerTriggerEvent54444")
 if not RE_trigger then
 Window:Notify({ Title = "Hata", Content = "Remote bulunamadi!", Duration = 2 })
 return
 end
 for _, plr in pairs(Players:GetPlayers()) do
 if plr ~= LocalPlayer then
 pcall(function()
 RE_trigger:FireServer("Client2Client", "Request: Piggyback!", plr)
 task.wait(0.05)
 RE_trigger:FireServer("BothWantPiggyBackRide", plr)
 end)
 end
 end
 Window:Notify({ Title = "Piggyback", Content = "Tum oyuncular birbirine bindirildi!", Duration = 2 })
 end
})

-- 2) JUMP ALL - Herkesi ziplat
FETrollTab:AddButton({
 Name = "Herkesi Ziplat",
 Callback = function()
 local RE_trigger = RE:FindFirstChild("P1layerTriggerEvent54444")
 if not RE_trigger then return end
 for _, plr in pairs(Players:GetPlayers()) do
 pcall(function()
 RE_trigger:FireServer("DropButtonStopAll", plr)
 end)
 end
 Window:Notify({ Title = "Jump All", Content = "Herkes zipladi!", Duration = 2 })
 end
})

-- 3) FE SCARE ALL - Herkese korku sesi cal
FETrollTab:AddButton({
 Name = "FE Herkesi Korkut (Ses)",
 Callback = function()
 local soundRE = RE:FindFirstChild("G1unSounds12458")
 if not soundRE then return end
 pcall(function()
 soundRE:FireServer(Players, 7083236436, 1)
 end)
 -- Lokal de cal
 local s = Instance.new("Sound", workspace)
 s.SoundId = "rbxassetid://7083236436"
 s.Volume = 5
 s:Play()
 game:GetService("Debris"):AddItem(s, 5)
 Window:Notify({ Title = "Scare", Content = "Herkes korkutuldu!", Duration = 2 })
 end
})

-- 4) FE PLAY SONG (GERCEK REMOTE)
FETrollTab:AddSection({ "FE Muzik (Sunucuya)" })
local feSongId = ""
FETrollTab:AddTextBox({
 Name = "Sarki ID",
 Default = "",
 PlaceholderText = "Sarki ID gir (sadece rakam)",
 ClearText = true,
 Callback = function(v) feSongId = v:gsub("[^%d]", "") end
})

FETrollTab:AddButton({
 Name = "Sarki Sunucuya Cal",
 Callback = function()
 if feSongId == "" then
 Window:Notify({ Title = "Hata", Content = "Sarki ID gir!", Duration = 2 })
 return
 end
 local soundRE = RE:FindFirstChild("G1unSounds12458")
 pcall(function()
 if soundRE then soundRE:FireServer(Players, feSongId, 1) end
 end)
 local s = Instance.new("Sound", workspace)
 s.SoundId = "rbxassetid://" .. feSongId
 s.Volume = 1
 s.Looped = true
 s.Name = "ZyronisFEMusic"
 s:Play()
 Window:Notify({ Title = "Muzik", Content = "Sarki caliniyor: " .. feSongId, Duration = 2 })
 end
})

FETrollTab:AddButton({
 Name = "Muzigi Durdur",
 Callback = function()
 for _, s in pairs(workspace:GetChildren()) do
 if s:IsA("Sound") then s:Stop() s:Destroy() end
 end
 Window:Notify({ Title = "Muzik", Content = "Muzik durduruldu!", Duration = 2 })
 end
})

-- 5) EV MUZIGI DEGISTIR
FETrollTab:AddSection({ "Ev Muzigi Degistir" })
local houseMusicId = ""
FETrollTab:AddTextBox({
 Name = "Ev Muzik ID",
 Default = "",
 PlaceholderText = "Muzik ID gir",
 ClearText = true,
 Callback = function(v) houseMusicId = v:gsub("[^%d]", "") end
})

FETrollTab:AddButton({
 Name = "Ev Muzigini Degistir",
 Callback = function()
 if houseMusicId == "" then return end
 local houseRE = RE:FindFirstChild("PlayersHouse")
 pcall(function()
 if houseRE then houseRE:FireServer("PickingHouseMusicText", houseMusicId) end
 end)
 Window:Notify({ Title = "Ev Muzigi", Content = "Ev muzigi degistirildi!", Duration = 2 })
 end
})

-- SEKME 2: AVATAR / DIS GORUNUS
-- GERCEK U1pdateAvatar12324 remote eventi
local AvatarTab2 = Window:MakeTab({ Title = "Avatar v2", Icon = "rbxassetid://15309138473" })

-- 6) SKIN TONE DEGISTIR
AvatarTab2:AddSection({ "Ten Rengi Degistir (FE)" })
local skinTones = {
 "Light reddish violet", "Carnation Pink", "Lime green", "Pink",
 "Really Red", "Cocoa", "Rust", "Light blue", "Cyan", "White",
 "Really Black", "Dark orange", "Bright yellow", "Bright green"
}

local selectedSkin = skinTones[1]
AvatarTab2:AddDropdown({
 Name = "Ten Rengi Sec",
 Default = "Light reddish violet",
 Options = skinTones,
 Callback = function(v) selectedSkin = v end
})

AvatarTab2:AddButton({
 Name = "Ten Rengini Uygula",
 Callback = function()
 local avatarRE = RE:FindFirstChild("U1pdateAvatar12324")
 pcall(function()
 if avatarRE then avatarRE:FireServer("skintone", selectedSkin) end
 end)
 Window:Notify({ Title = "Avatar", Content = "Ten rengi: " .. selectedSkin, Duration = 2 })
 end
})

-- 7) FE RAINBOW SKIN (GERCEK REMOTE)
local rainbowSkinActive = false
AvatarTab2:AddToggle({
 Name = "FE Rainbow Skin Ac/Kapat",
 Default = false,
 Callback = function(v)
 rainbowSkinActive = v
 if v then
 task.spawn(function()
 local skins = {"Light reddish violet","Carnation Pink","Lime green","Pink","Really Red","Cocoa","Rust","Light blue"}
 local i = 1
 while rainbowSkinActive do
 local avatarRE = RE:FindFirstChild("U1pdateAvatar12324")
 if avatarRE then
 pcall(function() avatarRE:FireServer("skintone", skins[i]) end)
 end
 i = (i % #skins) + 1
 task.wait(0.5)
 end
 end)
 Window:Notify({ Title = "Rainbow Skin", Content = "FE Rainbow Skin ACIK!", Duration = 2 })
 end
 end
})

-- 8) RP ISIM DEGISTIR
AvatarTab2:AddSection({ "RP Isim & Bio" })
local rpName = ""
AvatarTab2:AddTextBox({
 Name = "RP Isim",
 Default = "",
 PlaceholderText = "Yeni RP ismin...",
 ClearText = false,
 Callback = function(v) rpName = v end
})

AvatarTab2:AddButton({
 Name = "RP Ismi Degistir",
 Callback = function()
 if rpName == "" then return end
 pcall(function()
 local nameRE = RE:FindFirstChild("1RPNam1eTex1t")
 if nameRE then nameRE:FireServer("RolePlayName", rpName) end
 end)
 Window:Notify({ Title = "RP Isim", Content = "RP ismin: " .. rpName, Duration = 2 })
 end
})

-- 9) RP ISIM RENGI (GERCEK REMOTE)
AvatarTab2:AddSection({ "RP Isim Rengi" })
local nameColors = {
 ["Kirmizi"] = Color3.fromRGB(255, 0, 0),
 ["Mavi"] = Color3.fromRGB(0, 120, 255),
 ["Yesil"] = Color3.fromRGB(0, 255, 0),
 ["Sari"] = Color3.fromRGB(255, 220, 0),
 ["Mor"] = Color3.fromRGB(180, 0, 255),
 ["Turuncu"] = Color3.fromRGB(255, 140, 0),
 ["Beyaz"] = Color3.fromRGB(255, 255, 255),
 ["Pembe"] = Color3.fromRGB(255, 100, 200),
}

for colorName, colorVal in pairs(nameColors) do
 AvatarTab2:AddButton({
 Name = colorName .. " Isim",
 Callback = function()
 pcall(function()
 local colorRE = RE:FindFirstChild("1RPNam1eColo1r")
 if colorRE then colorRE:FireServer("PickingRPNameColor", colorVal) end
 end)
 Window:Notify({ Title = "Isim Rengi", Content = colorName .. " renk uygulandi!", Duration = 2 })
 end
 })
end

-- SEKME 3: GRAVITY & FIZIK
local GravityTab = Window:MakeTab({ Title = "Fizik & Gravity", Icon = "rbxassetid://15309138473" })

-- 10) GRAVITY DEGISTIR
GravityTab:AddSection({ "Yercekim" })
GravityTab:AddSlider({
 Name = "Gravity Degeri",
 Min = 0,
 Max = 200,
 Increment = 5,
 Default = 196,
 Callback = function(v)
 workspace.Gravity = v
 end
})

GravityTab:AddButton({
 Name = "0 Gravity (Uzay)",
 Callback = function()
 workspace.Gravity = 0
 Window:Notify({ Title = "Gravity", Content = "Uzay modu! Gravity = 0", Duration = 2 })
 end
})

GravityTab:AddButton({
 Name = "Moon Gravity (Ay)",
 Callback = function()
 workspace.Gravity = 20
 Window:Notify({ Title = "Gravity", Content = "Ay cekim kuvveti!", Duration = 2 })
 end
})

GravityTab:AddButton({
 Name = "Super Gravity",
 Callback = function()
 workspace.Gravity = 500
 Window:Notify({ Title = "Gravity", Content = "Super Gravity! Ziplaman imkansiz.", Duration = 2 })
 end
})

GravityTab:AddButton({
 Name = "Normal Gravity",
 Callback = function()
 workspace.Gravity = 196
 Window:Notify({ Title = "Gravity", Content = "Normal gravity'e donuldu.", Duration = 2 })
 end
})

-- 11) TIME OF DAY DEGISTIR (Brookhaven lighting)
GravityTab:AddSection({ "Zaman / Hava" })
GravityTab:AddSlider({
 Name = "Saat (0-24)",
 Min = 0,
 Max = 24,
 Increment = 1,
 Default = 12,
 Callback = function(v)
 game:GetService("Lighting").ClockTime = v
 end
})

local weathers = {
 ["Gunduz"] = {ClockTime = 12, Brightness = 2, FogEnd = 100000},
 ["Aksam"] = {ClockTime = 18, Brightness = 0.5, FogEnd = 5000},
 ["Gece"] = {ClockTime = 0, Brightness = 0, FogEnd = 100000},
 ["Sis"] = {ClockTime = 12, Brightness = 1, FogEnd = 200},
 ["Karanlık"] = {ClockTime = 3, Brightness = 0, FogEnd = 100000},
}

for weatherName, settings in pairs(weathers) do
 GravityTab:AddButton({
 Name = weatherName .. " Modu",
 Callback = function()
 local L = game:GetService("Lighting")
 L.ClockTime = settings.ClockTime
 L.Brightness = settings.Brightness
 L.FogEnd = settings.FogEnd
 Window:Notify({ Title = "Hava", Content = weatherName .. " modu aktif!", Duration = 2 })
 end
 })
end

-- SEKME 4: YEREL OYUNCU GUCLENDIR
local PowerTab = Window:MakeTab({ Title = "Guclendir", Icon = "rbxassetid://15309138473" })

-- 12) ZIPLAMA GUCU (GERCEK Jump Power)
PowerTab:AddSection({ "Ziplama & Hiz" })
PowerTab:AddSlider({
 Name = "Jump Power",
 Min = 50,
 Max = 500,
 Increment = 10,
 Default = 50,
 Callback = function(v)
 local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if hum then hum.JumpPower = v end
 end
})

-- 13) SWIM SPEED
PowerTab:AddSlider({
 Name = "Yuzme Hizi",
 Min = 16,
 Max = 200,
 Increment = 5,
 Default = 16,
 Callback = function(v)
 local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if hum then
 -- WalkSpeed yuzme hizini da etkiler
 hum.WalkSpeed = v
 end
 end
})

-- 14) INVINCIBLE + FULL STATS
PowerTab:AddButton({
 Name = "Max Guc (Speed+Jump+God)",
 Callback = function()
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hum then return end
 hum.WalkSpeed = 100
 hum.JumpPower = 200
 hum.MaxHealth = math.huge
 hum.Health = math.huge
 hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
 Window:Notify({ Title = "Max Guc", Content = "Speed=100, Jump=200, Health=Sonsuz!", Duration = 3 })
 end
})

-- 15) HEADLESS EFFECT (lokal)
PowerTab:AddSection({ "Gorsel Efektler" })
PowerTab:AddToggle({
 Name = "Headless (Bassiz) Gorsel",
 Default = false,
 Callback = function(v)
 local char = LocalPlayer.Character
 if not char then return end
 local head = char:FindFirstChild("Head")
 if head then
 head.LocalTransparencyModifier = v and 1 or 0
 head.Transparency = v and 1 or 0
 end
 -- Yuz de gizle
 if head then
 for _, d in pairs(head:GetDescendants()) do
 if d:IsA("Decal") or d:IsA("SpecialMesh") then
 d.Transparency = v and 1 or 0
 end
 end
 end
 Window:Notify({ Title = "Headless", Content = v and "Bassiz gorunum ACIK!" or "Normal basa donuldu!", Duration = 2 })
 end
})

-- 16) KARAKTER DONDUTUR (kendi karakterini yere cakistir)
PowerTab:AddButton({
 Name = "Karakter Resetle (Respawn)",
 Callback = function()
 LocalPlayer:LoadCharacter()
 Window:Notify({ Title = "Respawn", Content = "Karakter sifirlanıyor...", Duration = 2 })
 end
})

-- 17) SUPER JUMP AUTOCLICKER
local superJumpActive = false
PowerTab:AddToggle({
 Name = "Otomatik Super Ziplama",
 Default = false,
 Callback = function(v)
 superJumpActive = v
 if v then
 task.spawn(function()
 while superJumpActive do
 local char = LocalPlayer.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 local hrp = char and char:FindFirstChild("HumanoidRootPart")
 if hum and hrp then
 hum:ChangeState(Enum.HumanoidStateType.Jumping)
 end
 task.wait(0.6)
 end
 end)
 Window:Notify({ Title = "Auto Jump", Content = "Otomatik ziplama ACIK!", Duration = 2 })
 end
 end
})

-- SEKME 5: ESP PLUS
local ESPPlusTab = Window:MakeTab({ Title = "ESP Plus", Icon = "rbxassetid://15309138473" })

-- 18) MESAFE ESP + SAGLIK BAR
ESPPlusTab:AddSection({ "BillboardGui ESP (Mesafe + HP)" })
local billboardESP = {}
local billboardActive = false

ESPPlusTab:AddToggle({
 Name = "Billboard ESP Ac/Kapat",
 Default = false,
 Callback = function(v)
 billboardActive = v

 -- Onceki billboard'lari temizle
 for _, b in pairs(billboardESP) do
 if b and b.Parent then b:Destroy() end
 end
 billboardESP = {}

 if v then
 local function makeESP(plr)
 if plr == LocalPlayer then return end

 local function attachBB(char)
 if not char then return end
 local head = char:WaitForChild("Head", 3)
 if not head then return end

 local bb = Instance.new("BillboardGui")
 bb.Name = "ZyronisESP"
 bb.AlwaysOnTop = true
 bb.Size = UDim2.new(0, 120, 0, 50)
 bb.StudsOffset = Vector3.new(0, 2, 0)
 bb.Parent = head

 local nameLbl = Instance.new("TextLabel", bb)
 nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
 nameLbl.BackgroundTransparency = 1
 nameLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
 nameLbl.TextScaled = true
 nameLbl.Font = Enum.Font.GothamBold
 nameLbl.Text = plr.Name

 local infoLbl = Instance.new("TextLabel", bb)
 infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
 infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
 infoLbl.BackgroundTransparency = 1
 infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
 infoLbl.TextScaled = true
 infoLbl.Font = Enum.Font.Gotham
 infoLbl.Text = "..."

 table.insert(billboardESP, bb)

 -- HP ve mesafe guncelle
 RunService.Heartbeat:Connect(function()
 if not billboardActive or not bb.Parent then return end
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 local tHRP = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChildOfClass("Humanoid")
 if myHRP and tHRP and hum then
 local dist = math.floor((myHRP.Position - tHRP.Position).Magnitude)
 local hp = math.floor(hum.Health)
 infoLbl.Text = "HP:" .. hp .. " | " .. dist .. "m"
 end
 end)
 end

 if plr.Character then attachBB(plr.Character) end
 plr.CharacterAdded:Connect(attachBB)
 end

 for _, plr in pairs(Players:GetPlayers()) do makeESP(plr) end
 Players.PlayerAdded:Connect(makeESP)
 Window:Notify({ Title = "ESP Plus", Content = "Billboard ESP ACIK!", Duration = 2 })
 end
 end
})

-- 19) ARAÇ ESP
ESPPlusTab:AddSection({ "Arac ESP" })
local carESP = {}
ESPPlusTab:AddToggle({
 Name = "Arac ESP Ac/Kapat",
 Default = false,
 Callback = function(v)
 for _, h in pairs(carESP) do if h and h.Parent then h:Destroy() end end
 carESP = {}

 if v then
 for _, obj in pairs(workspace:GetDescendants()) do
 if obj:IsA("Model") and obj:FindFirstChild("VehicleSeat") then
 local hl = Instance.new("Highlight")
 hl.FillColor = Color3.fromRGB(0, 200, 255)
 hl.OutlineColor = Color3.fromRGB(255, 255, 255)
 hl.FillTransparency = 0.6
 hl.Adornee = obj
 hl.Parent = obj
 table.insert(carESP, hl)
 end
 end
 Window:Notify({ Title = "Arac ESP", Content = "Tum araclar vurgulanıyor!", Duration = 2 })
 end
 end
})

-- 20) EV ESP
ESPPlusTab:AddSection({ "Ev ESP" })
local houseESP = {}
ESPPlusTab:AddToggle({
 Name = "Ev ESP Ac/Kapat",
 Default = false,
 Callback = function(v)
 for _, h in pairs(houseESP) do if h and h.Parent then h:Destroy() end end
 houseESP = {}

 if v then
 -- Brookhaven'daki ev modellerini bul
 for _, obj in pairs(workspace:GetDescendants()) do
 if obj:IsA("Model") and (
 obj.Name:find("House") or
 obj.Name:find("home") or
 obj.Name:find("Home") or
 obj:FindFirstChild("Doorbell")
 ) then
 local hl = Instance.new("Highlight")
 hl.FillColor = Color3.fromRGB(255, 200, 0)
 hl.OutlineColor = Color3.fromRGB(255, 255, 0)
 hl.FillTransparency = 0.7
 hl.Adornee = obj
 hl.Parent = obj
 table.insert(houseESP, hl)
 end
 end
 Window:Notify({ Title = "Ev ESP", Content = "Evler vurgulanıyor!", Duration = 2 })
 end
 end
})

-- SEKME 6: TELEKINESIS
-- Infinite Yield telekinesis metodu
local TeleTab = Window:MakeTab({ Title = "Telekinesis", Icon = "rbxassetid://15309138473" })

TeleTab:AddSection({ "Oyuncu Cek / It" })
TeleTab:AddLabel("Troll/PVP sekmesindeki oyuncu secimini kullanir")

-- 21) HEDEFI YANINA CEK
TeleTab:AddButton({
 Name = "Hedefi Yanima Cek",
 Callback = function()
 if not selectedPlayerName then
 Window:Notify({ Title = "Hata", Content = "Oyuncu secilmedi!", Duration = 2 })
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if tHRP and myHRP then
 tHRP.CFrame = myHRP.CFrame * CFrame.new(3, 0, 0)
 Window:Notify({ Title = "Telekinesis", Content = selectedPlayerName .. " yanına cekildı!", Duration = 2 })
 end
 end
})

-- 22) HEDEFI HAVAYA KALDIR
TeleTab:AddButton({
 Name = "Hedefi Havaya Kaldir",
 Callback = function()
 if not selectedPlayerName then return end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 if tHRP then
 local liftConn
 local t = 0
 liftConn = RunService.Heartbeat:Connect(function(dt)
 t = t + dt
 if t > 3 then liftConn:Disconnect() return end
 local th = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
 if th then th.CFrame = th.CFrame + Vector3.new(0, 1, 0) end
 end)
 Window:Notify({ Title = "Telekinesis", Content = selectedPlayerName .. " havaya kaldiriliyor!", Duration = 2 })
 end
 end
})

-- 23) HEDEFI SUREKLI TAKIP ET + ETRAFINDA DON
TeleTab:AddSection({ "Surukle / Haunt" })
local hauntActive = false
local hauntConn = nil
TeleTab:AddToggle({
 Name = "Haunt (Hayalet Takip)",
 Default = false,
 Callback = function(v)
 hauntActive = v
 if hauntConn then hauntConn:Disconnect() end
 if v and selectedPlayerName then
 local hauntAngle = 0
 hauntConn = RunService.Heartbeat:Connect(function(dt)
 if not hauntActive then hauntConn:Disconnect() return end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if tHRP and myHRP then
 hauntAngle = hauntAngle + dt * 120
 local rad = math.rad(hauntAngle)
 local offset = Vector3.new(math.cos(rad) * 4, 0, math.sin(rad) * 4)
 myHRP.CFrame = CFrame.new(tHRP.Position + offset, tHRP.Position)
 end
 end)
 Window:Notify({ Title = "Haunt", Content = selectedPlayerName .. " etrafinda donuluyor!", Duration = 2 })
 end
 end
})

-- 24) TELEPORT TO PLAYER (ANLIK)
TeleTab:AddButton({
 Name = "Oyuncuya Anlik Teleport",
 Callback = function()
 if not selectedPlayerName then return end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if tHRP and myHRP then
 myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3)
 Window:Notify({ Title = "Teleport", Content = selectedPlayerName .. " konumuna teleport!", Duration = 2 })
 end
 end
})

-- SEKME 7: WORKSPACE ARACLARI
local WorldTab = Window:MakeTab({ Title = "Dunya Araclari", Icon = "rbxassetid://15309138473" })

-- 25) FOG EFEKTI
WorldTab:AddSection({ "Sis (Fog)" })
WorldTab:AddSlider({
 Name = "Sis Yogunlugu",
 Min = 50,
 Max = 10000,
 Increment = 50,
 Default = 10000,
 Callback = function(v)
 game:GetService("Lighting").FogEnd = v
 game:GetService("Lighting").FogStart = 0
 end
})

WorldTab:AddButton({
 Name = "Maksimum Sis",
 Callback = function()
 local L = game:GetService("Lighting")
 L.FogEnd = 50
 L.FogStart = 0
 L.FogColor = Color3.fromRGB(200, 200, 200)
 Window:Notify({ Title = "Sis", Content = "Maksimum sis!", Duration = 2 })
 end
})

WorldTab:AddButton({
 Name = "Sisi Kaldir",
 Callback = function()
 game:GetService("Lighting").FogEnd = 100000
 Window:Notify({ Title = "Sis", Content = "Sis kaldirildi!", Duration = 2 })
 end
})

-- 26) WORKSPACE FALLEN PART KALDIR
WorldTab:AddButton({
 Name = "Fallen Parts Siniri Kaldir",
 Callback = function()
 workspace.FallenPartsDestroyHeight = -math.huge
 Window:Notify({ Title = "World", Content = "Part yok olma siniri kaldirildi!", Duration = 2 })
 end
})

-- 27) TUM ISIKLARI KAPAT
WorldTab:AddToggle({
 Name = "Tam Karanlik (Isiklari Kapat)",
 Default = false,
 Callback = function(v)
 local L = game:GetService("Lighting")
 if v then
 L.Brightness = 0
 L.GlobalShadows = true
 L.ClockTime = 0
 L.Ambient = Color3.fromRGB(0, 0, 0)
 L.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
 else
 L.Brightness = 2
 L.ClockTime = 12
 L.Ambient = Color3.fromRGB(70, 70, 70)
 L.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
 end
 Window:Notify({ Title = "Karanlik", Content = v and "Tam karanlik!" or "Isik normale dondu!", Duration = 2 })
 end
})

-- 28) KARAKTER TRAIL (Iz birakma)
WorldTab:AddSection({ "Karakter Trail" })
local trailActive = false
local trailConn = nil
WorldTab:AddToggle({
 Name = "Trail Iz Ac/Kapat",
 Default = false,
 Callback = function(v)
 trailActive = v
 if trailConn then trailConn:Disconnect() end
 if v then
 trailConn = RunService.Heartbeat:Connect(function()
 if not trailActive then trailConn:Disconnect() return end
 local char = LocalPlayer.Character
 local hrp = char and char:FindFirstChild("HumanoidRootPart")
 if not hrp then return end

 local trail = Instance.new("Part")
 trail.Size = Vector3.new(0.5, 0.5, 0.5)
 trail.CFrame = hrp.CFrame
 trail.Anchored = true
 trail.CanCollide = false
 trail.Material = Enum.Material.Neon
 trail.Color = Color3.fromHSV(math.random(), 1, 1)
 trail.Parent = workspace

 game:GetService("Debris"):AddItem(trail, 1)
 end)
 Window:Notify({ Title = "Trail", Content = "Trail ACIK! Arkan parlak iz birakacak.", Duration = 2 })
 end
 end
})

-- 29) BUYUTEÇ / ZOOM MAX
WorldTab:AddSection({ "Kamera" })
WorldTab:AddSlider({
 Name = "Kamera Uzaklik",
 Min = 5,
 Max = 200,
 Increment = 5,
 Default = 15,
 Callback = function(v)
 LocalPlayer.CameraMaxZoomDistance = v
 LocalPlayer.CameraMinZoomDistance = 0
 end
})

WorldTab:AddButton({
 Name = "Max Zoom (Kusbakisi)",
 Callback = function()
 LocalPlayer.CameraMaxZoomDistance = 500
 LocalPlayer.CameraMinZoomDistance = 0
 Window:Notify({ Title = "Kamera", Content = "Maksimum uzaklasma aktif!", Duration = 2 })
 end
})

-- SEKME 8: FLING PLUS v4
-- Daha guclu fling metodlari
local FlingPlusTab = Window:MakeTab({ Title = "Fling Plus v4", Icon = "rbxassetid://15309138473" })

-- 30) LAUNCH PLAYER - Hedefi yukari firlatma
FlingPlusTab:AddSection({ "Fling Metodlari" })
FlingPlusTab:AddButton({
 Name = "Launch (Hedefi Firlatma)",
 Callback = function()
 if not selectedPlayerName then
 Window:Notify({ Title = "Hata", Content = "Oyuncu secilmedi!", Duration = 2 })
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 if tHRP then
 -- AssemblyLinearVelocity ile firlatma (en yeni Roblox metodu)
 tHRP.AssemblyLinearVelocity = Vector3.new(
 math.random(-50, 50) * 100,
 500,
 math.random(-50, 50) * 100
 )
 Window:Notify({ Title = "Launch", Content = selectedPlayerName .. " firlatıldı!", Duration = 2 })
 end
 end
})

-- 31) SPIN FLING (HEDEF) - CFrame spin metodu
FlingPlusTab:AddButton({
 Name = "Spin Fling (Hedef)",
 Callback = function()
 if not selectedPlayerName then return end
 local target = Players:FindFirstChild(selectedPlayerName)
 if not target or not target.Character then return end
 local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
 if tHRP then
 local angle = 0
 local t = 0
 local conn
 conn = RunService.Heartbeat:Connect(function(dt)
 t = t + dt
 if t >= 0.5 then conn:Disconnect() return end
 angle = angle + 40
 tHRP.CFrame = tHRP.CFrame
 * CFrame.Angles(math.rad(angle), math.rad(angle), math.rad(angle))
 * CFrame.new(0, 1, 0)
 end)
 Window:Notify({ Title = "Spin Fling", Content = selectedPlayerName .. " fling yapildi!", Duration = 2 })
 end
 end
})

-- 32) FLING BALL - Headre buyuk bir part firlatma (Soluna Hub metodu)
FlingPlusTab:AddSection({ "Fling Ball" })
FlingPlusTab:AddButton({
 Name = "Fling Ball At",
 Callback = function()
 local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not myHRP then return end

 -- Buyuk parlak top olustur
 local ball = Instance.new("Part")
 ball.Size = Vector3.new(8, 8, 8)
 ball.Shape = Enum.PartType.Ball
 ball.Material = Enum.Material.Neon
 ball.Color = Color3.fromRGB(255, 50, 50)
 ball.CFrame = myHRP.CFrame * CFrame.new(0, 2, -5)
 ball.CanCollide = true
 ball.Parent = workspace

 -- Kamera yonunde firlatma
 ball.AssemblyLinearVelocity = workspace.CurrentCamera.CFrame.LookVector * 200

 game:GetService("Debris"):AddItem(ball, 5)
 Window:Notify({ Title = "Fling Ball", Content = "Fling Ball atildi!", Duration = 2 })
 end
})

print("ZYRONIS HUB ULTRA v3 - 30+ Yeni Ozellik Yuklendi!")
Window:Notify({
 Title = "ULTRA v3 Hazir!",
 Content = "30+ yeni ozellik yuklendi! Toplam 80+ ozellik.",
 Duration = 5
})
