local ZYRONIS_LIB_URL = "https://pastefy.app/KkevWErG/raw"

-- ============================================================
-- ZYRONIS YAMA KATMANI
-- Kütüphane uzak sunucudan geldiği için önce kaynağı indirip
-- satır bazında yamalıyoruz. Her yamanın kaç kez uygulandığı
-- ZyPatchLog içine düşer; hiç eşleşmezse sessizce sessiz kalır.
-- ============================================================
local ZyPatchLog = {}

local function ZyPatch(Src, Old, New, Label)
 local Count = 0
 local Out, Pos = {}, 1
 while true do
  local S, E = Src:find(Old, Pos, true)
  if not S then break end
  Out[#Out + 1] = Src:sub(Pos, S - 1)
  Out[#Out + 1] = New
  Count = Count + 1
  Pos = E + 1
 end
 Out[#Out + 1] = Src:sub(Pos)
 ZyPatchLog[#ZyPatchLog + 1] = { Label = Label, Count = Count }
 return table.concat(Out)
end

local ZyPrelude = [[
local ZY_UIS = game:GetService("UserInputService")
local ZY_touch = false
local ZY_xy = { X = 0, Y = 0 }
pcall(function()
 ZY_UIS.InputBegan:Connect(function(I)
  if I.UserInputType == Enum.UserInputType.Touch then ZY_touch = true end
 end)
 ZY_UIS.InputEnded:Connect(function(I)
  if I.UserInputType == Enum.UserInputType.Touch then ZY_touch = false end
 end)
end)
local function ZY_held()
 if ZY_UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return true end
 return ZY_touch == true
end
local function ZY_pos()
 local ok, p = pcall(function() return game:GetService("Players").LocalPlayer:GetMouse() end)
 if ok and p then return { X = p.X, Y = p.Y } end
 return { X = ZY_xy.X, Y = ZY_xy.Y }
end
]]

local _srcOk, _src = pcall(game.HttpGet, game, ZYRONIS_LIB_URL)
local _libOk, Library = false, nil

if _srcOk and type(_src) == "string" and #_src > 2000 then
 _src = ZyPrelude .. "\n" .. _src

 -- 1) MakeTab colon-call: paste=Window gelince config yutuluyordu (tüm sekmeler "Tab!" görünüyordu)
 _src = ZyPatch(_src,
  'if type(paste) == "table" then Configs = paste end',
  'if type(Configs) ~= "table" then Configs = paste end',
  "MakeTab config")

 -- 2) Dokunmatikte sürükleme/Slider ölü: MouseButton1 basılı kontrolü
 _src = ZyPatch(_src,
  'UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)',
  'ZY_held()',
  "dokunmatik basilma")

 -- 3) Sürükleme konumu donmuş Input nesnesinden gelmasin (dokunmatik + mouse)
 _src = ZyPatch(_src,
  'DragStart = Input.Position',
  'DragStart = Vector3.new(PlayerMouse.X, PlayerMouse.Y, 0)',
  "sürükleme başlangıcı")
 _src = ZyPatch(_src,
  'local delta = Input.Position - DragStart',
  'local delta = Vector3.new(PlayerMouse.X, PlayerMouse.Y, 0) - DragStart',
  "sürükleme delta")

 -- 4) Her karede 0.35sn tween üretiyordu (sürükleme gecikmesi + GC baskısı)
 _src = ZyPatch(_src,
  'CreateTween({Instance, "Position", Position, 0.35})',
  'Instance.Position = Position',
  "sürükleme tween")

 -- 5) Ekran ölçeği yalnızca Y'ye bakıyordu -> dar ekranda pencere taşardı
 _src = ZyPatch(_src,
  'local UIScale = ViewportSize.Y / 450',
  'local UIScale = (function() local VP = workspace.CurrentCamera.ViewportSize return math.min(VP.Y / 450, VP.X * 0.96 / 550) end)()',
  "ilk ölçek")
 _src = ZyPatch(_src,
  'NewScale = ViewportSize.Y / math.clamp(NewScale, 300, 2000)',
  'NewScale = (function() local VP = workspace.CurrentCamera.ViewportSize return math.min(VP.Y / 450, VP.X * 0.96 / 550) end)()',
  "SetScale ölçeği")

 -- 6) Dokunma hedefleri (sekme satırı 24px, satır 25px, kaydırma çubuğu 1.5px)
 _src = ZyPatch(_src, 'Size = UDim2.new(1, 0, 0, 24)', 'Size = UDim2.new(1, 0, 0, 30)', "sekme yüksekliği")
 _src = ZyPatch(_src, 'Size = UDim2.new(1, 0, 0, 25)', 'Size = UDim2.new(1, 0, 0, 32)', "satır yüksekliği")
 _src = ZyPatch(_src, 'ScrollBarThickness = 1.5', 'ScrollBarThickness = 5', "scrollbar")

 -- 7) ScreenGui: yeniden doğuşta silinmesin, hep üstte kalsın
 _src = ZyPatch(_src,
  'Name = "Nexus Library V1",',
  'Name = "Nexus Library V1", ResetOnSpawn = false, DisplayOrder = 500,',
  "ScreenGui özellikleri")

 -- 8) Pencere boyut sınırları telefona göre çok genişti
 _src = ZyPatch(_src,
  'math.clamp(Pos1.X.Offset, 430, 1000), math.clamp(Pos1.Y.Offset, 200, 500)',
  'math.clamp(Pos1.X.Offset, 300, 1400), math.clamp(Pos1.Y.Offset, 180, 720)',
  "pencere boyut limiti")

 -- 9) 16 slider x 0.3sn senkron tween = script açılışında ~4.8sn donma
 _src = ZyPatch(_src,
  'math.clamp(SliderPos, 0, 1), 0.5), 0.3, true }',
  'math.clamp(SliderPos, 0, 1), 0.5), 0 }',
  "slider açılış donması")

 _libOk, Library = pcall(function()
  return loadstring(_src)()
 end)
else
 ZyPatchLog[#ZyPatchLog + 1] = { Label = "HttpGet kaynak alınamadı", Count = 0 }
 _libOk, Library = pcall(function()
  return loadstring(game:HttpGet(ZYRONIS_LIB_URL))()
 end)
end
if not _libOk or type(Library) ~= "table" then
 local msg = "ZYRONIS: UI kutuphanesi yuklenemedi (loadstring/HttpGet). Adres: " .. ZYRONIS_LIB_URL
 pcall(function()
  local g = Instance.new("ScreenGui")
  g.Name = "ZYRONIS_LibError"
  g.ResetOnSpawn = false
  g.IgnoreGuiInset = true
  g.Parent = game:GetService("CoreGui")
  local t = Instance.new("TextLabel")
  t.Size = UDim2.new(1, -40, 0, 60)
  t.Position = UDim2.new(0, 20, 0, 60)
  t.BackgroundTransparency = 1
  t.Font = Enum.Font.GothamBold
  t.TextSize = 16
  t.TextColor3 = Color3.fromRGB(255, 80, 80)
  t.TextWrapped = true
  t.Text = msg
  t.Parent = g
 end)
 error(msg, 0)
end
workspace.FallenPartsDestroyHeight = -math.huge

-- ============================================================
-- POLYFILL: kütüphanede olmayan Window:Notify ve Tab:AddLabel
-- (bu metotlar çağrılmazsa script 1063. satırda patlar)
-- ============================================================
local NotifyGui = nil
local NotifyStack = {}
local NOTIFY_MAX = 5

local function GetNotifyGui()
 if NotifyGui and NotifyGui.Parent then return NotifyGui end
 local gui = Instance.new("ScreenGui")
 gui.Name = "ZYRONIS_Notify"
 gui.ResetOnSpawn = false
 gui.IgnoreGuiInset = true
 gui.DisplayOrder = 999999
 gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
 local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
 if not ok or not gui.Parent then
  gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
 end
 NotifyGui = gui
 return gui
end

local function SlotOffset(i)
 return (i - (NOTIFY_MAX - 1) / 2) * 70
end

local function PushToast(Configs)
 if type(Configs) == "string" then Configs = { Content = Configs } end
 if type(Configs) ~= "table" then Configs = {} end
 local title = tostring(Configs.Title or "ZYRONIS")
 local content = tostring(Configs.Content or "")
 local duration = tonumber(Configs.Duration) or 3

 local gui
 pcall(function() gui = GetNotifyGui() end)
 if not gui then return end

 while #NotifyStack >= NOTIFY_MAX do
  local old = table.remove(NotifyStack, 1)
  pcall(function() if old and old.Parent then old:Destroy() end end)
 end

 local toast = Instance.new("Frame")
 toast.Name = "Toast"
 toast.AnchorPoint = Vector2.new(1, 0.5)
 toast.Size = UDim2.new(0, 300, 0, 62)
 toast.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
 toast.BorderSizePixel = 0
 toast.ZIndex = 10
 toast.Parent = gui
 toast.Position = UDim2.new(1, 60, 0.5, SlotOffset(#NotifyStack))
 table.insert(NotifyStack, toast)

 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 8)
 corner.Parent = toast

 local accent = Instance.new("Frame")
 accent.Size = UDim2.new(0, 4, 1, 0)
 accent.Position = UDim2.new(0, 0, 0, 0)
 accent.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
 accent.BorderSizePixel = 0
 accent.ZIndex = 11
 accent.Parent = toast
 local ac = Instance.new("UICorner")
 ac.CornerRadius = UDim.new(0, 4)
 ac.Parent = accent

 local titleLabel = Instance.new("TextLabel")
 titleLabel.BackgroundTransparency = 1
 titleLabel.Position = UDim2.new(0, 14, 0, 8)
 titleLabel.Size = UDim2.new(1, -24, 0, 18)
 titleLabel.Font = Enum.Font.GothamBold
 titleLabel.TextSize = 14
 titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
 titleLabel.TextXAlignment = Enum.TextXAlignment.Left
 titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
 titleLabel.ZIndex = 11
 titleLabel.Text = title
 titleLabel.Parent = toast

 local contentLabel = Instance.new("TextLabel")
 contentLabel.BackgroundTransparency = 1
 contentLabel.Position = UDim2.new(0, 14, 0, 28)
 contentLabel.Size = UDim2.new(1, -24, 0, 26)
 contentLabel.Font = Enum.Font.Gotham
 contentLabel.TextSize = 12
 contentLabel.TextColor3 = Color3.fromRGB(185, 185, 185)
 contentLabel.TextXAlignment = Enum.TextXAlignment.Left
 contentLabel.TextYAlignment = Enum.TextYAlignment.Top
 contentLabel.TextWrapped = true
 contentLabel.ZIndex = 11
 contentLabel.Text = content
 contentLabel.Parent = toast

 local targetY = SlotOffset(#NotifyStack - 1)
 pcall(function()
  local T = game:GetService("TweenService")
  T:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
   Position = UDim2.new(1, -12, 0.5, targetY)
  }):Play()
 end)

 task.delay(duration, function()
  if not toast.Parent then return end
  local pcallOk = pcall(function()
   local T = game:GetService("TweenService")
   local out = T:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
    Position = UDim2.new(1, 60, 0.5, targetY)
   })
   out:Play()
   out.Completed:Wait()
  end)
  if not pcallOk then pcall(function() toast.Position = UDim2.new(1, 60, 0.5, targetY) end) end
  local idx = table.find(NotifyStack, toast)
  if idx then table.remove(NotifyStack, idx) end
  pcall(function() toast:Destroy() end)
 end)
end

local _rawMakeWindow = Library.MakeWindow
if type(_rawMakeWindow) ~= "function" then
 error("ZYRONIS: kutuphane MakeWindow metodunu kaybetti (API degismis olabilir)", 0)
end
Library.MakeWindow = function(self, Configs)
 local Win = _rawMakeWindow(self, Configs)
 if type(Win) ~= "table" then
  error("ZYRONIS: MakeWindow tablo dondurmedi", 0)
 end

 Win.Notify = function(_, Configs2) PushToast(Configs2) end

 local _rawMakeTab = Win.MakeTab
 if type(_rawMakeTab) == "function" then
  Win.MakeTab = function(_, a, b)
   local cfg = b
   if type(cfg) ~= "table" then cfg = a end
   if type(cfg) ~= "table" then cfg = _ end
   if type(cfg) ~= "table" then cfg = {} end

   local Tab = _rawMakeTab(Win, nil, cfg)
   if type(Tab) ~= "table" then return Tab end

   if type(Tab.AddSection) == "function" then
    Tab.AddLabel = function(t, text)
     return t.AddSection(t, text)
    end
   end

   -- Kütüphane toggle/slider/dropdown oluştururken callback'i hemen çağırır;
   -- bu yüzden script yüklenirken 50+ kez tetikleniyordu (kamera, sis, gravity,
   -- hedef oyuncu = "" gibi yan etkiler). İlk çağrıyı yutuyoruz, arayüz aynen kurulur.
   local function ZyOnce(Name)
    local raw = Tab[Name]
    if type(raw) ~= "function" then return end
    Tab[Name] = function(t, elemCfg)
     if type(elemCfg) == "table" and type(elemCfg.Callback) == "function" then
      local UserCb, Seen = elemCfg.Callback, false
      elemCfg.Callback = function(...)
       if not Seen then Seen = true return end
       return UserCb(...)
      end
     end
     return raw(t, elemCfg)
    end
   end

   local _rawAddSlider = Tab.AddSlider
   if type(_rawAddSlider) == "function" then
    Tab.AddSlider = function(t, sliderCfg)
     if type(sliderCfg) == "table" and sliderCfg.Increment ~= nil and sliderCfg.Increase == nil then
      sliderCfg.Increase = sliderCfg.Increment
     end
     return _rawAddSlider(t, sliderCfg)
    end
   end

   ZyOnce("AddToggle")
   ZyOnce("AddSlider")
   ZyOnce("AddDropdown")

   return Tab
  end
 end

 return Win
end
-- ============================================================
-- POLYFILL SONU
-- ============================================================

local Window = Library:MakeWindow({
 Title = " ZYRONIS HUB | BROOKHAVEN RP ",
 SubTitle = "Ultimate Merged Edition - All Features"
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

-- ============================================================
-- MOBİL: ekran yönü/boyutu değişince ölçeği yeniden hesapla
-- ve pencereyi görünür alanda tut. (Kütüphane ölçeği yalnızca
-- yükleme anında bir kez hesapladığı için dönüşümde taşıyordu.)
-- ============================================================
task.spawn(function()
 local LastVP
 local function Apply()
  local ok, vp = pcall(function()
   local cam = workspace.CurrentCamera
   return cam and cam.ViewportSize
  end)
  if not ok or not vp then return end
  if LastVP and LastVP.X == vp.X and LastVP.Y == vp.Y then return end
  LastVP = Vector2.new(vp.X, vp.Y)

  pcall(function() if Library.SetScale then Library:SetScale(450) end end)

  pcall(function()
   local gui = game:GetService("CoreGui"):FindFirstChild("Nexus Library V1")
   if not gui then return end
   local hub = gui:FindFirstChild("Hub")
   if not hub then return end
   local scale = 1
   local sc = gui:FindFirstChild("Scale")
   if sc then scale = sc.Scale ~= 0 and sc.Scale or 1 end
   local w, h = hub.Size.X.Offset * scale, hub.Size.Y.Offset * scale
   local px = hub.Position.X.Offset * scale
   local py = hub.Position.Y.Offset * scale
   local minX = math.min(0, vp.X - w)
   local minY = math.min(0, vp.Y - h)
   local nx = math.clamp(px, minX, math.max(0, vp.X - w))
   local ny = math.clamp(py, minY, math.max(0, vp.Y - h))
   if w > vp.X then
    -- ölçek sığmıyorsa oranla küçült
    local fit = vp.X / w
    if sc then sc.Scale = scale * fit end
    scale = scale * fit
    w, h = vp.X, h * fit
   end
   hub.Position = UDim2.fromOffset(nx, ny)
  end)
 end
 Apply()
 local cam = workspace.CurrentCamera
 if cam then
  pcall(function()
   cam:GetPropertyChangedSignal("ViewportSize"):Connect(Apply)
  end)
 end
 while true do
  task.wait(2)
  local c = workspace.CurrentCamera
  if c ~= cam then
   cam = c
   pcall(function() cam:GetPropertyChangedSignal("ViewportSize"):Connect(Apply) end)
  end
  Apply()
 end
end)

-- SERVİSLER VE GLOBAL DEĞİŞKENLER
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
-- CurrentCamera respawn/spectate sirasinda degisebilir; bayat referans kullanma
task.spawn(function()
 while true do
  local c = workspace.CurrentCamera
  if c and c ~= Camera then Camera = c end
  task.wait(1)
 end
end)
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
-- ============================================================
-- SEKMELER: eski 29 sekme 10 temaya indirildi.
-- Eski degisken adlari (NameTab, CarTab, ...) korundu ve
-- asagida ilgili temanin takma adi olarak birakildi; boylece
-- yuzlerce AddSection/AddButton cagrisi aynen calismaya devam eder.
-- ============================================================
local InfoTab      = Window:MakeTab({ Title = " Bilgi",         Icon = "info"   })
local MovementTab  = Window:MakeTab({ Title = " Hareket",       Icon = "move"   })
local CharacterTab = Window:MakeTab({ Title = " Karakter",      Icon = "user"   })
local AvatarTab    = Window:MakeTab({ Title = " Oyuncu",        Icon = "users"  })
local TrollTab     = Window:MakeTab({ Title = " Troll & PVP",   Icon = "skull"  })
local ESPTab       = Window:MakeTab({ Title = " ESP & Gorunum", Icon = "eye"    })
local MapTab       = Window:MakeTab({ Title = " Arac & Harita", Icon = "car"    })
local HouseTab     = Window:MakeTab({ Title = " Dunya & Fizik", Icon = "globe"  })
local CommandsTab  = Window:MakeTab({ Title = " Ses & Chat",    Icon = "music"  })
local FakeLagTab   = Window:MakeTab({ Title = " Guclendir",     Icon = "gauge"  })

local NameTab      = CharacterTab   -- Isim & Bio
local ColorNameTab = CharacterTab   -- Renkli Isim
local SizeTab      = CharacterTab   -- Boyut ve Animasyon
local AvatarTab2   = CharacterTab   -- Avatar v2

local SpectateTab  = AvatarTab      -- Spectate

local TrollTabNew  = TrollTab       -- Troll Plus
local FETrollTab   = TrollTab       -- FE Troll v3
local FlingPlusTab = TrollTab       -- Fling Plus v4
local TeleTab      = TrollTab       -- Telekinesis

local VisualTab    = ESPTab         -- Gorsel
local RGBTab       = ESPTab         -- RGB ve Efektler
local ESPPlusTab   = ESPTab         -- ESP Plus

local CarTab       = MapTab         -- Arac Plus

local GravityTab   = HouseTab       -- Fizik & Gravity
local WorldTab     = HouseTab       -- Dunya Araclari

local AudioTab     = CommandsTab    -- Ses Oynatici
local ChatTab      = CommandsTab    -- Chat Araclari

local UtilTab      = FakeLagTab     -- Yardimci
local PowerTab     = FakeLagTab     -- Guclendir (eski)

local TweenService = game:GetService("TweenService")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Global Değişkenler
local selectedPlayerName = nil
local flyActive = false
local speedActive = false
local noclipActive = false
local infiniteJumpActive = false
local methodKill = "Bus"
local vehicleKillGen = 0

-- ===== FE YARDIMCISI =====
-- Diğer oyunculara yapılan CFrame değişiklikleri normalde sunucuya gitmez.
-- Önce ağ sahipliğini elimize almaya çalışırız, olmazsa en azından
-- yerel olarak doğru davranırız ve kullanıcıyı dürüst bilgilendiririz.
local _ownerCache = {}
local function ownsPart(root)
 if _ownerCache[root] ~= nil then return _ownerCache[root] end
 local ok = pcall(function() root:SetNetworkOwner(LocalPlayer) end)
 _ownerCache[root] = ok
 task.delay(2, function() _ownerCache[root] = nil end)
 return ok
end

local function tryReplicate(root, cframe, velocity)
 if not root or not root.Parent then return false end
 local owned = ownsPart(root)
 if velocity then
  pcall(function() root.AssemblyLinearVelocity = velocity end)
 end
 if cframe then
  pcall(function() root.CFrame = cframe end)
 end
 return owned
end

local function feNotice(feature, owned)
 if owned then return end
 Window:Notify({
  Title = " Uyarı",
  Content = feature .. " yerel olarak uygulandı (sunucu sahipliği sende değil, hedef bunu görmeyebilir)",
  Duration = 4
 })
end

-- ===== REMOTE YARDIMCISI (A8) =====
-- Remote yoksa/net hatada hata toast'u gosterir ve false dondurur; boylece
-- "basarili" toast'u yalnizca gercekten basarili cagrida acilir.
local RE_FOLDERS = { "RE", "RemoteEvents", "Remotes" }
local function GetRE(name)
 for _, folderName in ipairs(RE_FOLDERS) do
  local folder = ReplicatedStorage:FindFirstChild(folderName)
  if folder then
   local remote = folder:FindFirstChild(name)
   if remote then return remote end
  end
 end
 return nil
end

local function FireRE(name, ...)
 local remote = GetRE(name)
 if not remote then
  Window:Notify({ Title = " Hata", Content = "Remote bulunamadı: " .. name, Duration = 2 })
  return false
 end
 local args = { ... }
 local ok = pcall(function() remote:FireServer(unpack(args)) end)
 if not ok then
  Window:Notify({ Title = " Hata", Content = "Remote hatası: " .. name, Duration = 2 })
  return false
 end
 return true
end

local function InvokeRE(name, ...)
 local remote = GetRE(name)
 if not remote then
  Window:Notify({ Title = " Hata", Content = "Remote bulunamadı: " .. name, Duration = 2 })
  return false
 end
 local args = { ... }
 local ok, res = pcall(function() return remote:InvokeServer(unpack(args)) end)
 if not ok then
  Window:Notify({ Title = " Hata", Content = "Remote hatası: " .. name, Duration = 2 })
  return false
 end
 return true, res
end

_G.ESPData = {
 espEnabled = false,
 espType = "Ad + Yaş",
 selectedColor = "RGB"
}

-- BİLGİ SEKMESİ

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

InfoTab:AddSection({ "Sekme Yapisi (29 sekme 10 temaya indi)" })
InfoTab:AddParagraph({ "10 Sekme:", "Bilgi | Hareket | Karakter | Oyuncu | Troll & PVP | ESP & Gorunum | Arac & Harita | Dunya & Fizik | Ses & Chat | Guclendir" })
InfoTab:AddParagraph({ "Mobil:", "Dokunmatik kaydirma, dokunmatik surukleme, ucus paneli ve otomatik olcek destegi acik." })

InfoTab:AddSection({ "Sunucudaki Oyuncular" })
local playerCountLabel = InfoTab:AddParagraph({ "Oyuncu Sayısı:", tostring(#game.Players:GetPlayers()) })

local function UpdatePlayerCountLabel()
 if not playerCountLabel then return end
 pcall(function()
  playerCountLabel:Set("Oyuncu Sayısı:", tostring(#Players:GetPlayers()))
 end)
end

-- TROLL/PVP SEKMESİ

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
local playerDropdown = TrollTab:AddDropdown({
 Name = "Oyuncu Seç",
 Options = getPlayerList(),
 Callback = function(v)
  -- Set(getPlayerList()) kutuyu sifirlar (nil gonderir). Listede biri ciktiginda
  -- hedef hala sunucudaysa silme; yalnizca hedef kendisi ciktiyse birak.
  if type(v) ~= "string" or v == "" then
   if selectedPlayerName and not Players:FindFirstChild(selectedPlayerName) then
    selectedPlayerName = nil
    Window:Notify({
     Title = " Hedef",
     Content = "Hedef birakildi (oyuncu sunucudan cikti)",
     Duration = 2
    })
   end
   return
  end
  selectedPlayerName = v
  Window:Notify({
   Title = " Hedef",
   Content = v .. " seçildi!",
   Duration = 2
  })
 end
})

-- Dropdown liste anlik degil: katilan/ayrilan oyunculari ekle/temizle
local function refreshPlayerDropdown()
 pcall(function() playerDropdown:Set(getPlayerList()) end)
 UpdatePlayerCountLabel()
end

Players.PlayerAdded:Connect(function(plr)
 if plr == LocalPlayer then UpdatePlayerCountLabel() return end
 task.wait(0.5)
 -- Add mevcut secimi bozmaz, sadece yeni oyuncuyu listeye ekler
 pcall(function() playerDropdown:Add(plr.Name) end)
 UpdatePlayerCountLabel()
end)

Players.PlayerRemoving:Connect(function(plr)
 task.wait(0.2)
 -- Listeyi her ayrilista tazele; secim koruma mantigi callback'te
 refreshPlayerDropdown()
end)

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

 FireRE("1Clea1rTool1s", "ClearAllTools")
 task.wait(0.2)

 pcall(function() 
 ReplicatedStorage.RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "Couch") 
 end)
 task.wait(0.3)

 local tool = LocalPlayer.Backpack:FindFirstChild("Couch")
 if tool then tool.Parent = char end
 task.wait(0.1)

 -- B2: sanal tus basimi - mobilde fiziksel klavye gerektirmez
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

 angle = angle + 50
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

 local owned = tryReplicate(tRoot, root.CFrame + root.CFrame.LookVector * 3)
 Window:Notify({
 Title = " Bring",
 Content = selectedPlayerName .. " getirildi!" .. (owned and "" or " (yerel)"),
 Duration = 2
 })
 if not owned then
 feNotice("Bring", false)
 end
end

-- ===== LOOP BRING (tanımsızdı, 403/410. satırda scripti öldürüyordu) =====
local loopBringActive = false
local loopBringConn = nil

local function StartLoopBring()
 if not selectedPlayerName then
 Window:Notify({ Title = " Hata", Content = "Oyuncu seçilmedi", Duration = 2 })
 return
 end
 if loopBringConn then pcall(function() loopBringConn:Disconnect() end) loopBringConn = nil end
 loopBringActive = true
 local name = selectedPlayerName

 loopBringConn = RunService.Heartbeat:Connect(function()
 if not loopBringActive or selectedPlayerName ~= name then
 if loopBringConn then pcall(function() loopBringConn:Disconnect() end) loopBringConn = nil end
 loopBringActive = false
 return
 end
 local target = Players:FindFirstChild(selectedPlayerName)
 local tRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
 local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if tRoot and myRoot then
 tryReplicate(tRoot, myRoot.CFrame * CFrame.new(0, 0, -3))
 end
 end)

 Window:Notify({ Title = " Loop Bring", Content = "Başlatıldı: " .. tostring(selectedPlayerName), Duration = 2 })
end

local function StopLoopBring()
 loopBringActive = false
 if loopBringConn then pcall(function() loopBringConn:Disconnect() end) loopBringConn = nil end
 Window:Notify({ Title = " Loop Bring", Content = "Durduruldu", Duration = 2 })
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

 local owned = ownsPart(tRoot)

 if owned then
  local bodyVelocity = Instance.new("BodyVelocity")
  bodyVelocity.Velocity = Vector3.new(0, 0, 0)
  bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
  bodyVelocity.Parent = tRoot

  local function FlingSequence()
   for i = 1, 3 do
    bodyVelocity.Velocity = root.CFrame.LookVector * 300
    task.wait(0.1)
   end
   pcall(function() bodyVelocity:Destroy() end)
  end

  FlingSequence()
  Window:Notify({
   Title = " Fling",
   Content = selectedPlayerName .. " fırlatıldı!",
   Duration = 2
  })
 else
  for i = 1, 3 do
   pcall(function()
    tRoot.AssemblyLinearVelocity = root.CFrame.LookVector * 300
    tRoot.CFrame = tRoot.CFrame + root.CFrame.LookVector * 8
   end)
   task.wait(0.1)
  end
  Window:Notify({
   Title = " Fling",
   Content = selectedPlayerName .. " fırlatıldı (yerel)!",
   Duration = 2
  })
  feNotice("Fling", false)
 end
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
 vehicleKillGen = (vehicleKillGen or 0) + 1
 local myGen = vehicleKillGen
 local function TrackPlayer()
 local timeout = tick() + 20
 while tick() < timeout and vehicleKillGen == myGen do
 if selectedPlayerName then
 local targetPlayer = Players:FindFirstChild(selectedPlayerName)
 if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
 local targetRoot = targetPlayer.Character.HumanoidRootPart
 pcall(function() vehicle:SetPrimaryPartCFrame(targetRoot.CFrame * CFrame.new(0, 0, 10)) end)
 end
 end
 RunService.Heartbeat:Wait()
 end
 if vehicleKillGen == myGen then
  pcall(function()
   if originalPosition then humanoidRootPart.CFrame = originalPosition end
  end)
 end
 end
 task.spawn(TrackPlayer)

 Window:Notify({
 Title = " Araç",
 Content = vehicleType .. " ile saldırı başladı!",
 Duration = 3
 })
 else
 pcall(function() humanoidRootPart.CFrame = originalPosition end)
 Window:Notify({
 Title = " Hata",
 Content = "Araç oluşturulamadı, konumun geri alındı",
 Duration = 3
 })
 end
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
 bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
 bodyGyro.P = 100000
 bodyGyro.D = 500
 pcall(function() bodyGyro.CFrame = tRoot.CFrame end)
 ownsPart(tRoot)
 bodyGyro.Parent = tRoot

 task.wait(3)
 pcall(function() bodyGyro:Destroy() end)

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

local Move
do
 -- ===== MOBIL YARDIMCILARI (B1) =====
 -- Dokunmatikte klavye yok: Humanoid.MoveDirection (thumbstick) + JumpRequest
 -- ve kendi olusturdugumuz +/- pad ile dikey hareket. Masaustu WASD aynen calisir.
 local flyPadUp = false
 local flyPadDown = false
 local flyPadCarActive = false
 local flyPadJumpUntil = 0
 local flyPadGui = nil

 local function getHorizontalMove()
  local camCF = Camera.CFrame
  local move = Vector3.new(0, 0, 0)
  local keyUsed = false
  if UserInputService:IsKeyDown(Enum.KeyCode.W) then
   move = move + camCF.LookVector
   keyUsed = true
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.S) then
   move = move - camCF.LookVector
   keyUsed = true
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.D) then
   move = move + camCF.RightVector
   keyUsed = true
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.A) then
   move = move - camCF.RightVector
   keyUsed = true
  end
  if not keyUsed then
   -- Klavye basilmiyorsa thumbstick/yon tuslarinin verdigi MoveDirection
   local char = LocalPlayer.Character
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   if hum then
    local md = hum.MoveDirection
    if md.Magnitude > 0.05 then
     move = Vector3.new(md.X, 0, md.Z)
    end
   end
  end
  return move
 end

 local function getVerticalMove()
  local up = 0
  if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
  if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then up = up - 1 end
  if flyPadUp then up = up + 1 end
  if flyPadDown then up = up - 1 end
  if tick() < flyPadJumpUntil then up = up + 1 end
  return up
 end

 -- Suruste (koltukta): WASD yoksa oturulan VehicleSeat throttle/steer,
 -- o da yoksa thumbstick yonu. Klavye davranisi ayni kalir.
 local function carMove()
  local camCF = Camera.CFrame
  local move = Vector3.new(0, 0, 0)
  local keyUsed = false
  if UserInputService:IsKeyDown(Enum.KeyCode.W) then
   move = move + camCF.LookVector
   keyUsed = true
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.S) then
   move = move - camCF.LookVector
   keyUsed = true
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.D) then
   move = move + camCF.RightVector
   keyUsed = true
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.A) then
   move = move - camCF.RightVector
   keyUsed = true
  end
  if keyUsed then return move end

  local char = LocalPlayer.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  local seat = hum and hum.SeatPart
  if seat and seat:IsA("VehicleSeat") then
   local throttle = seat.Throttle
   local steer = seat.Steer
   if throttle ~= 0 or steer ~= 0 then
    return seat.CFrame.LookVector * throttle + seat.CFrame.RightVector * steer
   end
  end
  if hum then
   local md = hum.MoveDirection
   if md.Magnitude > 0.05 then
    return Vector3.new(md.X, 0, md.Z)
   end
  end
  return move
 end

 local function EnsureFlyPad()
  if flyPadGui and flyPadGui.Parent then return flyPadGui end
  local gui = Instance.new("ScreenGui")
  gui.Name = "ZYRONIS_FlyPad"
  gui.ResetOnSpawn = false
  gui.DisplayOrder = 501
  gui.IgnoreGuiInset = true
  gui.Enabled = false
  local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
  if not ok or not gui.Parent then
   gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
  end
  flyPadGui = gui

  local function MakePad(text, yOff, onDown, onUp)
   local b = Instance.new("TextButton")
   b.Name = "ZyronisPad" .. text
   b.AnchorPoint = Vector2.new(0.5, 0.5)
   b.Position = UDim2.new(1, -72, 0.5, yOff)
   b.Size = UDim2.new(0, 56, 0, 56) -- dokunma hedefi min 48x48 (B3)
   b.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
   b.BackgroundTransparency = 0.3
   b.TextColor3 = Color3.fromRGB(255, 255, 255)
   b.Font = Enum.Font.GothamBold
   b.TextSize = 32
   b.Text = text
   local corner = Instance.new("UICorner")
   corner.CornerRadius = UDim.new(0, 14)
   corner.Parent = b
   b.Parent = gui
   local activeInput = nil
   b.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
     activeInput = input
     onDown()
    end
   end)
   b.InputEnded:Connect(function(input)
    if activeInput and (input == nil or input == activeInput) then
     activeInput = nil
     onUp()
    end
   end)
   -- Guvenlik: touch InputEnded butone ulasmazsa global dinleyici temizlesin
   UserInputService.InputEnded:Connect(function(input)
    if activeInput and input == activeInput then
     activeInput = nil
     onUp()
    end
   end)
   return b
  end

  MakePad("+", -70, function() flyPadUp = true end, function() flyPadUp = false end)
  MakePad("-", 10, function() flyPadDown = true end, function() flyPadDown = false end)
  return gui
 end

 local function UpdateFlyPad()
  if not flyPadGui or not flyPadGui.Parent then return end
  local show = (flyActive or flyPadCarActive) == true and UserInputService.TouchEnabled == true
  flyPadGui.Enabled = show
  flyPadUp = false
  flyPadDown = false
 end

 -- Mobil ziplama butonu / Space -> yukari asagi destegi
 local _flyJumpConn = nil
 local function BindFlyJump(char)
  if _flyJumpConn then pcall(function() _flyJumpConn:Disconnect() end) _flyJumpConn = nil end
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if not hum then return end
  _flyJumpConn = hum.JumpRequest:Connect(function()
   if not flyActive and not flyPadCarActive then return end
   if UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end -- klavye zaten yonetiyor
   flyPadJumpUntil = tick() + 0.35
  end)
 end

 -- FLY FONKSIYONU
 local flySpeed = 50
 local flyConn = nil
 local flyBV, flyBG = nil, nil

 local function ClearFlyObjects()
  if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
  if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
  if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
 end

 local function ToggleFly(state)
  flyActive = state
  ClearFlyObjects()
  flyPadUp = false
  flyPadDown = false

  if flyActive then
   local root = RootPart
   if not root or not root.Parent then
    flyActive = false
    -- toggle kutusunu da kapat (callback icinde Set yutulur, o yuzden geciktir)
    task.delay(0.1, function() pcall(function() Move.flyToggle:Set(false) end) end)
    Window:Notify({ Title = " Uçma", Content = "Karakter yok, uçma başlatılamadı", Duration = 2 })
    return
   end

   local bodyVelocity = Instance.new("BodyVelocity")
   bodyVelocity.Velocity = Vector3.new(0, 0, 0)
   bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
   bodyVelocity.Parent = root

   local bodyGyro = Instance.new("BodyGyro")
   bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
   bodyGyro.Parent = root

   flyBV, flyBG = bodyVelocity, bodyGyro

   -- Fizik/girdi simulasyonu Heartbeat'te (RenderStepped degil, A12)
   flyConn = RunService.Heartbeat:Connect(function()
    if not flyActive then
     ClearFlyObjects()
     return
    end
    local r = RootPart
    if not r or not r.Parent then
     ClearFlyObjects()
     return
    end

    local moveDirection = getHorizontalMove()
    local upDown = getVerticalMove()
    if upDown ~= 0 then
     moveDirection = moveDirection + Vector3.new(0, upDown, 0)
    end

    bodyVelocity.Velocity = (moveDirection.Magnitude > 0 and moveDirection.Unit or Vector3.zero) * flySpeed
    bodyGyro.CFrame = Camera.CFrame
   end)

   pcall(EnsureFlyPad)
   UpdateFlyPad()

   Window:Notify({
    Title = " Uçma",
    Content = UserInputService.TouchEnabled and "Uçma başladı! Sagdaki + / - ile yukari-asagi" or "Uçma başladı!",
    Duration = 2
   })
  else
   UpdateFlyPad()
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

 local flyToggle = MovementTab:AddToggle({
  Name = "Uçma Aç/Kapat",
  Default = false,
  Callback = function(v)
  ToggleFly(v)
  end
 })

 -- SPEED FONKSIYONU
 local speedAmount = 30
 local speedConn = nil

 local function ToggleSpeed(state)
  speedActive = state
  if speedConn then pcall(function() speedConn:Disconnect() end) speedConn = nil end

  if speedActive then
   speedConn = RunService.Heartbeat:Connect(function()
    if not speedActive or not Character or not RootPart then
     if speedConn then pcall(function() speedConn:Disconnect() end) speedConn = nil end
     return
    end

    local moveDirection = getHorizontalMove()

    if moveDirection.Magnitude > 0 then
     RootPart.AssemblyLinearVelocity = moveDirection.Unit * speedAmount + Vector3.new(0, RootPart.AssemblyLinearVelocity.Y, 0)
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

 local speedToggle = MovementTab:AddToggle({
  Name = "Hız Boost Aç/Kapat",
  Default = false,
  Callback = function(v)
  ToggleSpeed(v)
  end
 })

 -- NOCLIP FONKSIYONU
 local noclipConnection = nil
 local noclipDescConn = nil
 local noclipSnapshot = {}
 local noclipChar = nil

 local function SnapshotNoclip()
  noclipSnapshot = {}
  local c = LocalPlayer.Character
  if not c then return end
  for _, part in pairs(c:GetDescendants()) do
   if part:IsA("BasePart") then
    noclipSnapshot[part] = part.CanCollide
   end
  end
 end

 local function RestoreNoclip()
  for part, value in pairs(noclipSnapshot) do
   if part.Parent then
    pcall(function() part.CanCollide = value end)
   end
  end
  noclipSnapshot = {}
 end

 local function ToggleNoclip(state)
  noclipActive = state

  if noclipConnection then pcall(function() noclipConnection:Disconnect() end) noclipConnection = nil end
  if noclipDescConn then pcall(function() noclipDescConn:Disconnect() end) noclipDescConn = nil end

  if noclipActive then
   -- A6: orijinal CanCollide degerlerini acilista sakla, kapatista aynen geri koy
   SnapshotNoclip()

   local c = LocalPlayer.Character
   if c then
    noclipChar = c
    noclipDescConn = c.DescendantAdded:Connect(function(d)
     if noclipActive and d:IsA("BasePart") then
      noclipSnapshot[d] = d.CanCollide
      pcall(function() d.CanCollide = false end)
     end
    end)
   end

   -- A12: her karede GetDescendants yerine snapshot uzerinden calis
   noclipConnection = RunService.Heartbeat:Connect(function()
    if not noclipActive then
     if noclipConnection then pcall(function() noclipConnection:Disconnect() end) noclipConnection = nil end
     noclipChar = nil
     return
    end
    local c = LocalPlayer.Character
    if not c then return end
    -- karakter sonradan olustu/degistiyse onbellek + baglantiyi tazele
    if noclipChar ~= c then
     noclipChar = c
     SnapshotNoclip()
     if noclipDescConn then pcall(function() noclipDescConn:Disconnect() end) noclipDescConn = nil end
     noclipDescConn = c.DescendantAdded:Connect(function(d)
      if noclipActive and d:IsA("BasePart") then
       noclipSnapshot[d] = d.CanCollide
       pcall(function() d.CanCollide = false end)
      end
     end)
    end
    for part in pairs(noclipSnapshot) do
     if part.Parent then
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
   noclipChar = nil
   RestoreNoclip()
  end
 end

 MovementTab:AddSection({ " Noclip" })
 local noclipToggle = MovementTab:AddToggle({
  Name = "Noclip Aç/Kapat",
  Default = false,
  Callback = function(v)
  ToggleNoclip(v)
  end
 })

 -- INFINITE JUMP FONKSIYONU (A1: gercek ac/kapat)
 local _ijConn = nil
 local _ijJumpConn = nil

 local function ijBindCharacter(char)
  if _ijJumpConn then pcall(function() _ijJumpConn:Disconnect() end) _ijJumpConn = nil end
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if not hum then return end
  -- Mobil ziplama butonu icin (Space'e basilmaz)
  _ijJumpConn = hum.JumpRequest:Connect(function()
   if not infiniteJumpActive then return end
   pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
  end)
 end

 local function StopInfiniteJump()
  infiniteJumpActive = false
  if _ijConn then pcall(function() _ijConn:Disconnect() end) _ijConn = nil end
  if _ijJumpConn then pcall(function() _ijJumpConn:Disconnect() end) _ijJumpConn = nil end
 end

 local function SetupInfiniteJump()
  infiniteJumpActive = true
  if not _ijConn then
   _ijConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not infiniteJumpActive or gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
     local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
     if humanoid then
      humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
     end
    end
   end)
  end
  ijBindCharacter(LocalPlayer.Character)

  Window:Notify({
   Title = " Sonsuz Zıplama",
   Content = "Sonsuz zıplama açıldı!",
   Duration = 2
  })
 end

 MovementTab:AddSection({ " Sonsuz Zıplama" })
 local infiniteJumpToggle = MovementTab:AddToggle({
  Name = "Sonsuz Zıplama Aç/Kapat",
  Default = false,
  Callback = function(v)
   if v then
    SetupInfiniteJump()
   else
    StopInfiniteJump()
   end
  end
 })

 Move = {
  h = getHorizontalMove,
  v = getVerticalMove,
  carMove = carMove,
  ensurePad = EnsureFlyPad,
  updatePad = UpdateFlyPad,
  setCar = function(on)
   flyPadCarActive = on == true
  end,
  bindJump = BindFlyJump,
  ToggleFly = ToggleFly,
  ToggleSpeed = ToggleSpeed,
  ToggleNoclip = ToggleNoclip,
  SetupInfiniteJump = SetupInfiniteJump,
  StopInfiniteJump = StopInfiniteJump,
  flyToggle = flyToggle,
  speedToggle = speedToggle,
  noclipToggle = noclipToggle,
  infiniteJumpToggle = infiniteJumpToggle,
 }
end

-- KARARKTERİSTİK SEKMESİ (Avatar)

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

 if InvokeRE("ChangeCharacterBody", unpack(args)) then
 Window:Notify({
 Title = " Başlık",
 Content = value .. " seçildi!",
 Duration = 2
 })
 end
 end
})

CharacterTab:AddSection({ " Kız Paketi" })

CharacterTab:AddButton({
 Name = "Kız Paketi 1 Uygula",
 Callback = function()
 local args = { [1] = "BundleGirlFace" }
 if InvokeRE("ChangeCharacterBody", unpack(args)) then
 Window:Notify({
 Title = " Bundle",
 Content = "Kız Paketi 1 uygulandı!",
 Duration = 2
 })
 end
 end
})

CharacterTab:AddSection({ " Erkek Paketi" })

CharacterTab:AddButton({
 Name = "Erkek Paketi 1 Uygula",
 Callback = function()
 local args = { [1] = "BundleBoyFace" }
 if InvokeRE("ChangeCharacterBody", unpack(args)) then
 Window:Notify({
 Title = " Bundle",
 Content = "Erkek Paketi 1 uygulandı!",
 Duration = 2
 })
 end
 end
})

-- İSİM & BİO SEKMESİ

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
 if FireRE("1RPNam1eTex1t", "RolePlayName", customName) then
 Window:Notify({
 Title = " İsim",
 Content = "İsim: " .. customName,
 Duration = 2
 })
 end
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
 if FireRE("1RPNam1eTex1t", "RolePlayName", name) then
 Window:Notify({
 Title = " İsim",
 Content = "İsim: " .. name,
 Duration = 2
 })
 end
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
 if FireRE("1RPNam1eTex1t", "RolePlayBio", customBio) then
 Window:Notify({
 Title = " Bio",
 Content = "Bio değiştirildi!",
 Duration = 2
 })
 end
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
 if FireRE("1RPNam1eTex1t", "RolePlayBio", bio) then
 Window:Notify({
 Title = " Bio",
 Content = "Bio: " .. bio,
 Duration = 2
 })
 end
 end
 })
end

-- RENKLİ İSİM SEKMESİ

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
 local color = Color3.new(nameColorR / 255, nameColorG / 255, nameColorB / 255)
 if FireRE("1RPNam1eColo1r", "PickingRPNameColor", color) then
 Window:Notify({
 Title = " Renk",
 Content = "İsim rengi değiştirildi!",
 Duration = 2
 })
 end
 end
})

-- KOMUTLAR SEKMESİ

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
 if FireRE("1Clea1rTool1s", "ClearAllTools") then
 Window:Notify({
 Title = " Temizlik",
 Content = "Tüm araçlar temizlendi!",
 Duration = 2
 })
 end
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

ESPTab:AddSection(" ESP Ayarları")

-- GERCEK ESP RENDERER (onceki kod sadece deger yaziyordu, kimse cizmiyordu)
local mainESPStore = {}
local mainESPConn = nil
local mainESPPlayerConn = nil

local function mainESPColor()
 local sel = _G.ESPData.selectedColor
 if sel == "Kırmızı" then return Color3.fromRGB(255, 60, 60)
 elseif sel == "Yeşil" then return Color3.fromRGB(60, 255, 90)
 elseif sel == "Mavi" then return Color3.fromRGB(70, 140, 255)
 elseif sel == "Sarı" then return Color3.fromRGB(255, 225, 60)
 end
 return nil
end

local function mainESPText(plr)
 local t = _G.ESPData.espType
 local name = tostring(plr.DisplayName)
 local age = tostring(plr.AccountAge) .. "g"
 if t == "Sadece Ad" then return name
 elseif t == "Sadece Yaş" then return age
 end
 return name .. " | " .. age
end

local function mainESPClearBB(e)
 if e and e.bb then
  pcall(function() e.bb:Destroy() end)
  e.bb = nil
  e.label = nil
 end
end

local function mainESPBuildBB(plr, char)
 if not _G.ESPData.espEnabled then return end
 local e = mainESPStore[plr]
 if not e then return end
 local head = char and char:FindFirstChild("Head")
 if not head then return end

 mainESPClearBB(e)

 local bb = Instance.new("BillboardGui")
 bb.Name = "ZyronisESP"
 bb.Adornee = head
 bb.Size = UDim2.new(0, 220, 0, 44)
 bb.StudsOffset = Vector3.new(0, 3, 0)
 bb.AlwaysOnTop = false
 bb.LightInfluence = 0
 bb.MaxDistance = 150

 local label = Instance.new("TextLabel")
 label.Name = "Label"
 label.BackgroundTransparency = 1
 label.Size = UDim2.new(1, 0, 1, 0)
 label.Font = Enum.Font.GothamBold
 label.TextSize = 15
 label.TextStrokeTransparency = 0.35
 label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
 label.Text = mainESPText(plr)
 label.Parent = bb

 bb.Parent = head
 e.bb = bb
 e.label = label
end

local function mainESPRemove(plr)
 local e = mainESPStore[plr]
 if not e then return end
 if e.charConn then pcall(function() e.charConn:Disconnect() end) e.charConn = nil end
 mainESPClearBB(e)
 mainESPStore[plr] = nil
end

local function mainESPDisable()
 if mainESPConn then pcall(function() mainESPConn:Disconnect() end) mainESPConn = nil end
 if mainESPPlayerConn then pcall(function() mainESPPlayerConn:Disconnect() end) mainESPPlayerConn = nil end
 for plr in pairs(mainESPStore) do mainESPRemove(plr) end
 mainESPStore = {}
end

local function mainESPEnable()
 mainESPDisable()

 local function watch(plr)
  if plr == LocalPlayer or mainESPStore[plr] then return end
  local e = { charConn = nil, bb = nil, label = nil }
  mainESPStore[plr] = e
  e.charConn = plr.CharacterAdded:Connect(function(c)
   task.wait(0.3)
   if _G.ESPData.espEnabled then mainESPBuildBB(plr, c) end
  end)
  if plr.Character then mainESPBuildBB(plr, plr.Character) end
 end

 for _, plr in ipairs(Players:GetPlayers()) do watch(plr) end
 mainESPPlayerConn = Players.PlayerAdded:Connect(watch)

 mainESPConn = RunService.Heartbeat:Connect(function()
  if not _G.ESPData.espEnabled then
   mainESPDisable()
   return
  end
  local col = mainESPColor()
  local rgb = (col == nil)
  local now = tick()
  for plr, e in pairs(mainESPStore) do
   if not plr.Parent then
    mainESPRemove(plr)
   else
    local char = plr.Character
    if char and char:FindFirstChild("Head") then
     if not e.bb or not e.bb.Parent then mainESPBuildBB(plr, char) end
     if e.bb and e.bb.Parent then
      -- A12: ayni metni/her karede yazma; RGB rengi 10 Hz'e dusur
      if e.label then
       -- A12: metni ~5 Hz rate-limit (per oyuncu), degismeyince tekrar yazma
       if not e.lastText or now - e.lastText > 0.2 then
        e.lastText = now
        local txt = mainESPText(plr)
        if e.label.Text ~= txt then e.label.Text = txt end
       end
       if rgb then
        if not e.lastRGB or now - e.lastRGB > 0.1 then
         e.lastRGB = now
         e.label.TextColor3 = Color3.fromHSV((now * 0.15) % 1, 0.9, 1)
        end
       elseif col and e.label.TextColor3 ~= col then
        e.label.TextColor3 = col
       end
      end
     end
    else
     mainESPClearBB(e)
    end
   end
  end
 end)
end

ESPTab:AddToggle({
 Name = "ESP Aç/Kapat",
 Default = false,
 Callback = function(v)
 _G.ESPData.espEnabled = v
 if v then
  mainESPEnable()
  Window:Notify({
   Title = " ESP",
   Content = "ESP açıldı!",
   Duration = 2
  })
 else
  mainESPDisable()
  Window:Notify({
   Title = " ESP",
   Content = "ESP kapatıldı!",
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
  if _G.ESPData.espEnabled then mainESPEnable() end
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


ESPTab:AddParagraph({
 Title = "ESP Durumu",
 Text = "Bu anahtar AD + YAŞ / RENK ayarlarını kullanan billboard ESP'yi açar. Highlight ESP 'Gorsel' bolumundedir."
})

-- KARİKTER YÖNETİMİ
local antiFlingActive = false
local antiFlingConn = nil
local godmodeActive = false -- CharacterAdded handler'inda da kullanilir
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
 Character = newCharacter
 Humanoid = newCharacter:WaitForChild("Humanoid", 10) or newCharacter:FindFirstChildOfClass("Humanoid")
 RootPart = newCharacter:WaitForChild("HumanoidRootPart", 10) or newCharacter:FindFirstChild("HumanoidRootPart")

 -- Reset edilecek değişkenler
 flyActive = false
 speedActive = false
 noclipActive = false
 infiniteJumpActive = false

 -- A4: bayrak sifirlamak baglantilari/kaldirilan objeleri temizlemez;
 -- toggle'larin callback'leri calisarak motorlari gercekten durdurur.
 pcall(function() Move.flyToggle:Set(false) end)
 pcall(function() Move.speedToggle:Set(false) end)
 pcall(function() Move.noclipToggle:Set(false) end)
 pcall(function() Move.infiniteJumpToggle:Set(false) end)

 -- yeni karakterin Humanoid'u icin ziplama istegi baglantisini tazele
 pcall(function() Move.bindJump(newCharacter) end)

 -- A5: Godmode acikken yeni karaktere ayarlari yeniden uygula
 if godmodeActive then
  local hum = newCharacter:FindFirstChildOfClass("Humanoid")
  if hum then
   pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
   pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
   hum.BreakJointsOnDeath = false
  end
 end
 -- A5: Anti Fling acikken yeni karaktere de uygula (dongusu de her karede tazeler)
 if antiFlingActive then
  local aHum = newCharacter:FindFirstChildOfClass("Humanoid")
  if aHum then
   pcall(function() aHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
   pcall(function() aHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
  end
 end
end)

-- YENI OZELLIKLER - ARASTIRMADAN EKLENDI
-- Kaynak: Suki Hub (illremember), Cartola Hub,
-- Infinite Yield, open source BH scriptleri

-- Yeni global degiskenler
local orbitActive = false
local orbitConnection = nil
local orbitAngle = 0
local freezeActive = false
local invisibleActive = false
local invisibleDescConn = nil
local annoyActive = false
local annoyConnection = nil
local glitchActive = false
local glitchConnection = nil
local touchFlingEnabled = false
local touchFlingConns = {}
local touchFlingPlayers = {}
local highlightESP = {}
local carFlyActive = false
local carFlyConn = nil

-- TROLL SEKMESINE YENI FONKSIYONLAR

TrollTabNew:AddSection({ "Hedef Oyuncu" })
TrollTabNew:AddLabel("Not: Bu sekmedeki hedef oyuncu secimini kullanir")

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
local freezeToggle
local frozenTargetName = nil
local frozenHRP = nil

local function ClearFreezeOn(hrp)
 if not hrp then return end
 pcall(function()
  local a = hrp:FindFirstChild("ZyronisFreezePos")
  if a then a:Destroy() end
  local b = hrp:FindFirstChild("ZyronisFreezeBV")
  if b then b:Destroy() end
 end)
end

freezeToggle = TrollTabNew:AddToggle({
 Name = "Freeze Ac/Kapat",
 Default = false,
 Callback = function(v)
 freezeActive = v
 if v then
  local target = selectedPlayerName and Players:FindFirstChild(selectedPlayerName)
  local tHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
  if not tHRP then
   freezeActive = false
   Window:Notify({ Title = "Freeze", Content = "Hedef yok, freeze başlatılamadı!", Duration = 2 })
   task.delay(0.1, function() pcall(function() freezeToggle:Set(false) end) end)
   return
  end

  -- A2: kapaticinin calisacagi HRP'yi sakla (hedef respawn olursa bulunalim)
  frozenTargetName = selectedPlayerName
  frozenHRP = tHRP

  -- Client freeze: BodyPosition ile fikir Infinite Yield'den
  local owned = ownsPart(tHRP)
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

  Window:Notify({ Title = "Freeze", Content = frozenTargetName .. " donduruldu!" .. (owned and "" or " (yerel)"), Duration = 2 })
  if not owned then feNotice("Freeze", false) end
 else
  -- A2: once saklanan HRP, o yoksa hedefin mevcut karakteri uzerinden temizle
  ClearFreezeOn(frozenHRP)
  if frozenTargetName then
   local t = Players:FindFirstChild(frozenTargetName)
   if t and t.Character then
    for _, d in pairs(t.Character:GetDescendants()) do
     if d.Name == "ZyronisFreezePos" or d.Name == "ZyronisFreezeBV" then
      pcall(function() d:Destroy() end)
     end
    end
   end
  end
  frozenTargetName = nil
  frozenHRP = nil
  Window:Notify({ Title = "Freeze", Content = "Freeze serbest!", Duration = 2 })
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
  tryReplicate(th, savedPos)
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
  local owned = tryReplicate(tHRP, CFrame.new(0, -1000, 0), Vector3.new(0, -300, 0))
  Window:Notify({ Title = "Void", Content = selectedPlayerName .. " ucuruma gonderildi!" .. (owned and "" or " (yerel)"), Duration = 2 })
  if not owned then feNotice("Void", false) end
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
  tryReplicate(tHRP, highPos, Vector3.new(0, 300, 0))
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
  tryReplicate(tHRP, tHRP.CFrame
  * CFrame.Angles(math.rad(angle), math.rad(angle * 0.5), math.rad(angle))
  * CFrame.new(0, 0.5, 0))
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
 table.insert(touchFlingConns, LocalPlayer.CharacterAdded:Connect(function(c)
 c:WaitForChild("HumanoidRootPart", 5)
 if touchFlingEnabled then task.wait(0.3) connectTF(c) end
 end))
 Window:Notify({ Title = "Touch Fling", Content = "Aktif! Birine dokun.", Duration = 2 })
 end
 end
})

-- KARAKTER / GORSEL SEKMESI

-- INVISIBLE - LocalTransparencyModifier ile (Infinite Yield invisible)
VisualTab:AddSection({ "Gorunmezlik" })
VisualTab:AddToggle({
 Name = "Invisible Ac/Kapat",
 Default = false,
 Callback = function(v)
  invisibleActive = v
  local char = LocalPlayer.Character
  if invisibleDescConn then
   pcall(function() invisibleDescConn:Disconnect() end)
   invisibleDescConn = nil
  end
  if not char then
   Window:Notify({ Title = "Invisible", Content = v and "Karakter yok!" or "Normal gorunume donuldu!", Duration = 2 })
   return
  end

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
   invisibleDescConn = char.DescendantAdded:Connect(function(d)
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
                if h and (h.Health <= 0 or h:GetState() == Enum.HumanoidStateType.Dead) then
                    pcall(function() h.Health = math.max(1, h.MaxHealth) end)
                    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
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

local highlightActive = false
local highlightConns = {}

local function clearHighlights()
 highlightActive = false
 for _, h in pairs(highlightESP) do
  if h and h.Parent then pcall(function() h:Destroy() end) end
 end
 highlightESP = {}
 for _, c in pairs(highlightConns) do
  pcall(function() c:Disconnect() end)
 end
 highlightConns = {}
end

local function makeHighlight(char)
 if not char then return end
 local hl = Instance.new("Highlight")
 hl.Name = "ZyronisHL"
 hl.FillColor = Color3.fromRGB(255, 0, 0)
 hl.OutlineColor = Color3.fromRGB(255, 255, 255)
 hl.FillTransparency = 0.5
 hl.OutlineTransparency = 0
 hl.Adornee = char
 hl.Parent = char
 table.insert(highlightESP, hl)
end

VisualTab:AddToggle({
 Name = "Highlight ESP Ac/Kapat",
 Default = false,
 Callback = function(v)
  clearHighlights()
  if v then
   highlightActive = true
   local function addHighlight(plr)
    if plr == LocalPlayer or not highlightActive then return end
    if plr.Character then makeHighlight(plr.Character) end
    local c = plr.CharacterAdded:Connect(function(newChar)
     if not highlightActive then return end
     task.wait(0.5)
     if highlightActive then makeHighlight(newChar) end
    end)
    table.insert(highlightConns, c)
   end

   for _, plr in ipairs(Players:GetPlayers()) do addHighlight(plr) end
   table.insert(highlightConns, Players.PlayerAdded:Connect(addHighlight))

   Window:Notify({ Title = "Highlight ESP", Content = "Highlight ESP ACIK!", Duration = 2 })
  else
   Window:Notify({ Title = "Highlight ESP", Content = "Highlight ESP KAPALI!", Duration = 2 })
  end
 end
})

-- AVATAR KOPYALA SEKMESI
-- Kaynak: Soluna Hub avatar copy metodu

AvatarTab:AddSection({ "Oyuncu Avatarini Kopyala" })
AvatarTab:AddLabel("Not: Hedef secimi icin TROLL & PVP bolumundeki oyuncu secimini kullanir")

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

 -- RP ismini kopyala (A8: remote yoksa basari toast'u yalan olmasin)
 local rpNameRemoteOK = GetRE("1RPNam1eTex1t") ~= nil
 pcall(function()
  local remote = GetRE("1RPNam1eTex1t")
  local rpName = target.Character:FindFirstChild("RPName") or
   target.Character:FindFirstChildOfClass("BillboardGui")
  if remote and rpName then
   remote:FireServer("RolePlayName", target.DisplayName)
  end
 end)

 Window:Notify({
 Title = "Avatar Kopyala",
 Content = selectedPlayerName .. " avatari kopyalandi!" .. (rpNameRemoteOK and "" or " (RP ismi: remote yok)"),
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
 pcall(function()
   Move.setCar(v)
   if v then Move.ensurePad() end
   Move.updatePad()
  end)

 if v then
 -- A12: RenderStepped -> Heartbeat (fizik adimiyla ayni anda)
 carFlyConn = RunService.Heartbeat:Connect(function()
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

 -- Araci kamera yonunde ilerlet (B1: WASD + mobil throttle/steer/pad)
 local moveDir = Move.carMove()
 local vertical = Move.v()
 if vertical ~= 0 then
  moveDir = moveDir + Vector3.new(0, vertical, 0)
 end

 if vehicle and vehicle.PrimaryPart then
 if moveDir.Magnitude > 0 then
 vehicle:SetPrimaryPartCFrame(
 vehicle.PrimaryPart.CFrame + (moveDir.Unit * carFlySpeed * 0.1)
 )
 end
 end
 end)
 Window:Notify({ Title = "Car Fly", Content = "Araca bin ve W/Space ile uc! (mobilde: thumbstick + sagdaki +/-)", Duration = 3 })
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
 _G.hizBoostConn = RunService.Heartbeat:Connect(function()
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
local antiAfkConn = nil

-- RGB & OZEL ISIM SEKMESI
-- Kaynak: Soluna Hub RGB name metodu

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
 local lastSend = 0
 rgbNameConn = RunService.Heartbeat:Connect(function(dt)
 if not rgbNameActive then
 rgbNameConn:Disconnect()
 rgbNameConn = nil
 return
 end
 hue = (hue + dt * 0.5) % 1
 -- Sunucuya saniyede ~6 kez gonder (Once her karede = ~60/s idi)
 if tick() - lastSend < 0.16 then return end
 lastSend = tick()
 local color = Color3.fromHSV(hue, 1, 1)
 pcall(function()
  local remote = ReplicatedStorage.RE and ReplicatedStorage.RE:FindFirstChild("1RPNam1eColo1r")
  if remote then remote:FireServer("PickingRPNameColor", color) end
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
 -- A12: parca listesi her karede degil, karakter degisince (+2sn'de bir) yenilenir
 local cachedChar, cachedParts, lastRefresh = nil, {}, 0
 local function refreshParts(char)
  cachedChar = char
  cachedParts = {}
  lastRefresh = tick()
  for _, part in pairs(char:GetDescendants()) do
   if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
    table.insert(cachedParts, part)
   end
  end
 end
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
 if cachedChar ~= char or tick() - lastRefresh > 2 then
  refreshParts(char)
 end
 for _, part in pairs(cachedParts) do
 if part.Parent then
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
 -- A12: arac degisince (+2sn'de bir) yenilenen parca onbelligi
 local cachedVehicle, cachedParts, lastRefresh = nil, {}, 0
 rgbCarConn = RunService.Heartbeat:Connect(function(dt)
 if not rgbCarActive then rgbCarConn:Disconnect() return end
 hue = (hue + dt * 0.4) % 1
 local color = Color3.fromHSV(hue, 1, 1)
 local char = LocalPlayer.Character
 if not char then return end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hum or not hum.SeatPart then return end
 local vehicle = hum.SeatPart.Parent
 if not vehicle then return end
 if cachedVehicle ~= vehicle or tick() - lastRefresh > 2 then
  cachedVehicle = vehicle
  cachedParts = {}
  lastRefresh = tick()
  for _, part in pairs(vehicle:GetDescendants()) do
   if part:IsA("BasePart") then table.insert(cachedParts, part) end
  end
 end
 for _, part in pairs(cachedParts) do
 if part.Parent then
 part.Color = color
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

FakeLagTab:AddSection({ "Fake Lag (Sahte Gecikme)" })
FakeLagTab:AddLabel("Acikken periyodik olarak yukari sikrayip geri donersin")
FakeLagTab:AddLabel("Sunucu konumunu gec guncelledigi icin takilan gorunursun")
FakeLagTab:AddLabel("Not: bu esnada hedefin yaninda degilsin")

local fakeLagDelay = 1
FakeLagTab:AddSlider({
 Name = "Lag Suresi (saniye)",
 Min = 1,
 Max = 10,
 Increment = 1,
 Default = 3,
 Callback = function(v) fakeLagDelay = math.max(1, tonumber(v) or 1) end
})

local fakeLagGen = 0
local fakeLagReturnPos = nil

local function restoreFakeLagPos()
 if fakeLagReturnPos then
  local c = LocalPlayer.Character
  local h = c and c:FindFirstChild("HumanoidRootPart")
  if h and h.Parent then pcall(function() h.CFrame = fakeLagReturnPos end) end
  fakeLagReturnPos = nil
 end
end

FakeLagTab:AddToggle({
 Name = "Fake Lag Ac/Kapat",
 Default = false,
 Callback = function(v)
  fakeLagGen = fakeLagGen + 1
  fakeLagActive = v

  -- Onceki klonu/conn'u temizle (eski surumlerden kalanlari da)
  if fakeLagClone then pcall(function() fakeLagClone:Destroy() end) fakeLagClone = nil end
  if fakeLagConn then pcall(function() fakeLagConn:Disconnect() end) fakeLagConn = nil end

  if v then
   local myGen = fakeLagGen
   task.spawn(function()
    while fakeLagActive and fakeLagGen == myGen do
     local c = LocalPlayer.Character
     local h = c and c:FindFirstChild("HumanoidRootPart")
     if h then
      fakeLagReturnPos = h.CFrame
      pcall(function()
       h.CFrame = CFrame.new(math.random(-500, 500), 5000, math.random(-500, 500))
      end)
      task.wait(fakeLagDelay)
      restoreFakeLagPos()
      task.wait(0.5)
     else
      task.wait(0.2)
     end
    end
    restoreFakeLagPos()
   end)
   Window:Notify({ Title = "Fake Lag", Content = "Fake Lag ACIK! Takilan/kopuk goruneceksin.", Duration = 3 })
  else
   restoreFakeLagPos()
   Window:Notify({ Title = "Fake Lag", Content = "Fake Lag KAPALI!", Duration = 2 })
  end
 end
})

-- SPECTATE - Kamera kilitleme
-- Kaynak: Infinite Yield view metodu

SpectateTab:AddSection({ "Oyuncu Izle (Spectate)" })
SpectateTab:AddLabel("Not: Hedef secimi icin TROLL & PVP bolumundeki oyuncu secimini kullanir")

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

-- ZIL SPAM - Brookhaven zil remote event'i
HouseTab:AddSection({ "Zil Spam" })
HouseTab:AddLabel("Yakin oldugun evin ziline spam yapar")

local doorbellSpamActive = false
local doorbellSpamGen = 0
HouseTab:AddToggle({
 Name = "Zil Spam Ac/Kapat",
 Default = false,
 Callback = function(v)
  doorbellSpamGen = doorbellSpamGen + 1
  doorbellSpamActive = v
  if v then
   local myGen = doorbellSpamGen
   task.spawn(function()
    local lastScan = 0
    local doorbells = {}
    while doorbellSpamActive and doorbellSpamGen == myGen do
     -- Descendant taramasini 1.5 sn'de bir yap (Once 10/sn idi)
     if tick() - lastScan > 1.5 then
      lastScan = tick()
      doorbells = {}
      pcall(function()
       for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Doorbell" and obj:IsA("BasePart") then
         table.insert(doorbells, obj)
        end
       end
      end)
     end
     pcall(function()
      local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if hrp then
       for _, obj in ipairs(doorbells) do
        if obj.Parent and (obj.Position - hrp.Position).Magnitude < 50 then
         firetouchinterest(hrp, obj, 0)
         firetouchinterest(hrp, obj, 1)
        end
       end
      end
     end)
     task.wait(0.25)
    end
   end)
   Window:Notify({ Title = "Zil Spam", Content = "Zil Spam ACIK!", Duration = 2 })
  else
   Window:Notify({ Title = "Zil Spam", Content = "Zil Spam KAPALI!", Duration = 2 })
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
 local lastScan = 0
 local doorCache = {}
 _G.kapiNoclipConn = RunService.Heartbeat:Connect(function()
 if not _G.kapiNoclipActive then
 _G.kapiNoclipConn:Disconnect()
 _G.kapiNoclipConn = nil
 return
 end
 -- Tam workspace taramasi 0.5 sn'de bir (Once her karede idi)
 if tick() - lastScan > 0.5 then
 lastScan = tick()
 doorCache = {}
 pcall(function()
 for _, obj in pairs(workspace:GetDescendants()) do
 if obj:IsA("BasePart") and (obj.Name:find("Door") or obj.Name:find("door") or obj.Name:find("Gate")) then
 table.insert(doorCache, obj)
 end
 end
 end)
 end
 for _, obj in ipairs(doorCache) do
 if obj.Parent then obj.CanCollide = false end
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

AudioTab:AddSection({ "Ses Oynat (Herkese)" })
AudioTab:AddLabel("Brookhaven ses remote'u ile sunucuya ses calinir")

local customAudioId = ""
AudioTab:AddTextBox({
 Name = "Ses ID Gir",
 Default = "",
 PlaceholderText = "Sadece rakam gir: 1234567890",
 ClearText = true,
 Callback = function(v)
 customAudioId = v
 end
})

AudioTab:AddButton({
 Name = "Ses Oynat",
 Callback = function()
 -- A9: rbxassetid://123 gibi girislerde once rakamlari ayikla
 local idStr = tostring(customAudioId or ""):gsub("%D", "")
 if idStr == "" then
  Window:Notify({ Title = "Hata", Content = "Ses ID girmedin (sadece rakam)!", Duration = 2 })
  return
 end
 local idNum = tonumber(idStr)
 if not idNum then
  Window:Notify({ Title = "Hata", Content = "Gecersiz Ses ID!", Duration = 2 })
  return
 end

 -- A8/A9: remote var mi ayri ogren; gonderimi dogrula, toast'u ona gore ac
 local remoteFound = false
 local sentToServer = false
 pcall(function()
  local re = ReplicatedStorage:FindFirstChild("RE") or ReplicatedStorage:FindFirstChild("RemoteEvents")
   or ReplicatedStorage:FindFirstChild("Remotes")
  if re then
   local audioRE = re:FindFirstChild("1Mus1ic") or re:FindFirstChild("Music") or re:FindFirstChild("1Sou1nd")
   if audioRE then
    remoteFound = true
    audioRE:FireServer("PlayMusic", idNum)
    sentToServer = true
   end
  end
 end)

 -- Lokal ses (her zaman calisir)
 -- A9: once kendimiz acan onceki sesleri kapat, sonra yenisini ac (birikmesin)
 local SS = game:GetService("SoundService")
 for _, old in pairs(SS:GetChildren()) do
  if old:IsA("Sound") and old.Name == "ZyronisSound" then
   pcall(function() old:Stop() old:Destroy() end)
  end
 end
 local sound = Instance.new("Sound")
 sound.Name = "ZyronisSound"
 sound.SoundId = "rbxassetid://" .. idStr
 sound.Volume = 1
 sound.Parent = SS
 sound.Ended:Connect(function() pcall(function() sound:Destroy() end) end)
 sound:Play()

 Window:Notify({
  Title = "Ses",
  Content = sentToServer and "Ses sunucuya gonderildi + lokal oynatiliyor!"
   or (remoteFound and "Ses gonderilemedi, yalnizca lokal oynatiliyor!"
   or "Remote bulunamadi, ses yalnizca sende oynuyor!"),
  Duration = 3
 })
 end
})

AudioTab:AddButton({
 Name = "Sesi Durdur",
 Callback = function()
 -- A9: yalnizca hub'un acigi sesleri durdur (oyunun kendi sesini ezme)
 local stopped = 0
 for _, s in pairs(game:GetService("SoundService"):GetChildren()) do
  if s:IsA("Sound") and s.Name == "ZyronisSound" then
   pcall(function() s:Stop() s:Destroy() end)
   stopped = stopped + 1
  end
 end
 Window:Notify({ Title = "Ses", Content = stopped > 0 and "Ses durduruldu!" or "Oynatan ses yok!", Duration = 2 })
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
 local SS = game:GetService("SoundService")
 for _, old in pairs(SS:GetChildren()) do
  if old:IsA("Sound") and old.Name == "ZyronisSound" then
   pcall(function() old:Stop() old:Destroy() end)
  end
 end
 local sound = Instance.new("Sound")
 sound.Name = "ZyronisSound"
 sound.SoundId = "rbxassetid://" .. soundId
 sound.Volume = 1
 sound.Parent = SS
 sound.Ended:Connect(function() pcall(function() sound:Destroy() end) end)
 sound:Play()
 Window:Notify({ Title = "Ses", Content = soundName .. " oynatiliyor!", Duration = 2 })
 end
 })
end

-- CHAT SPAM & ARACLARI
-- Kaynak: Soluna Hub chat spambot

ChatTab:AddSection({ "Chat Spam" })

local chatSpamMsg = "ZYRONIS HUB"
local chatSpamDelay = 1
local chatSpamGen = 0

local function sendChatMessage(msg)
 if type(msg) ~= "string" or msg == "" then return end
 local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
 if legacy and legacy:FindFirstChild("SayMessageRequest") then
  pcall(function()
   legacy.SayMessageRequest:FireServer(msg, "All")
  end)
  return
 end
 -- Yeni TextChatService yolu (Legacy chat kaldirildi)
 pcall(function()
  local tcs = game:GetService("TextChatService")
  local channels = tcs:FindFirstChild("TextChannels")
  local general = channels and channels:FindFirstChild("RBXGeneral")
  if general and general.SendAsync then
   general:SendAsync(msg)
  end
 end)
end

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
 Callback = function(v) chatSpamDelay = math.max(1, tonumber(v) or 1) end
})

ChatTab:AddToggle({
 Name = "Chat Spam Ac/Kapat",
 Default = false,
 Callback = function(v)
  chatSpamGen = chatSpamGen + 1
  chatSpamActive = v
  if v then
   local myGen = chatSpamGen
   task.spawn(function()
    while chatSpamActive and chatSpamGen == myGen do
     sendChatMessage(chatSpamMsg)
     task.wait(chatSpamDelay)
    end
   end)
   Window:Notify({ Title = "Chat Spam", Content = "Chat Spam ACIK!", Duration = 2 })
  else
   Window:Notify({ Title = "Chat Spam", Content = "Chat Spam KAPALI!", Duration = 2 })
  end
 end
})

-- HORN SPAM - Araç kornasindan spam
ChatTab:AddSection({ "Klakson Spam" })
local hornSpamGen = 0
ChatTab:AddToggle({
 Name = "Klakson Spam Ac/Kapat",
 Default = false,
 Callback = function(v)
  hornSpamGen = hornSpamGen + 1
  hornSpamActive = v

  if v then
   local myGen = hornSpamGen
   task.spawn(function()
    while hornSpamActive and hornSpamGen == myGen do
     pcall(function()
      local char = LocalPlayer.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if hum and hum.SeatPart then
       local horn = GetRE("1Player1sCa1r")
       if horn then horn:FireServer("Horn") end
      end
     end)
     task.wait(0.1)
    end
   end)
   if GetRE("1Player1sCa1r") then
    Window:Notify({ Title = "Klakson", Content = "Klakson Spam ACIK! Araca bin.", Duration = 2 })
   else
    Window:Notify({ Title = " Hata", Content = "Remote bulunamadı (Klakson), spam calismayabilir.", Duration = 3 })
   end
  end
 end
})

-- BOYUT DEGISTIR
-- Kaynak: Infinite Yield hipheight + Soluna karakter buyutme

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
 local fps = math.floor(workspace:GetRealPhysicsFPS() + 0.5)
 Window:Notify({
 Title = "Sunucu Bilgisi",
 Content = "Oyuncular: " .. playerCount .. " | FPS: " .. fps .. " | JobID: " .. game.JobId:sub(1,8),
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
if not RE then
 -- RE yoksa her fonksiyon kendi "Remote bulunamadi" dalina duser (nil uzerinde hata vermez)
 RE = Instance.new("Folder")
 RE.Name = "ZYRONIS_RE_MISSING"
 Window:Notify({
  Title = " FE Troll v3",
  Content = "ReplicatedStorage.RE bulunamadi - v3 ozellikleri pasif olacak",
  Duration = 6
 })
end

-- SEKME 1: FE TROLL (GERCEK REMOTE EVENTS)

-- 1) PIGGYBACK ALL - Herkesi birbirine bindirme
FETrollTab:AddSection({ "Piggyback / Bindirme" })
FETrollTab:AddButton({
 Name = "Herkesi Birbirine Bindir",
 Callback = function()
 local RE_trigger = RE:FindFirstChild("1Playe1rTrigge1rEven1t")
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
 local RE_trigger = GetRE("1Playe1rTrigge1rEven1t")
 if not RE_trigger then
 Window:Notify({ Title = " Hata", Content = "Remote bulunamadı, ziplatma yapılamadı!", Duration = 2 })
 return
 end
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
 local soundRE = GetRE("1Gu1nSound1s")
 local sent = false
 if soundRE then
 sent = pcall(function() soundRE:FireServer(Players, 7083236436, 1) end)
 end
 -- Lokal de cal
 local s = Instance.new("Sound", workspace)
 s.SoundId = "rbxassetid://7083236436"
 s.Volume = 5
 s:Play()
 game:GetService("Debris"):AddItem(s, 5)
 if sent then
 Window:Notify({ Title = "Scare", Content = "Herkes korkutuldu!", Duration = 2 })
 else
 Window:Notify({ Title = "Scare", Content = "Remote yok, ses yalnizca sende calindi!", Duration = 3 })
 end
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
 local soundRE = GetRE("1Gu1nSound1s")
 local sent = false
 if soundRE then
 sent = pcall(function() soundRE:FireServer(Players, feSongId, 1) end)
 end
 -- A9: onceki döngülü parçayi kapat ki ust üste binmesin
 for _, old in pairs(workspace:GetChildren()) do
  if old:IsA("Sound") and old.Name == "ZyronisFEMusic" then
   pcall(function() old:Stop() old:Destroy() end)
  end
 end
 local s = Instance.new("Sound", workspace)
 s.SoundId = "rbxassetid://" .. feSongId
 s.Volume = 1
 s.Looped = true
 s.Name = "ZyronisFEMusic"
 s:Play()
 if sent then
 Window:Notify({ Title = "Muzik", Content = "Sarki sunucuya gonderildi: " .. feSongId, Duration = 2 })
 else
 Window:Notify({ Title = "Muzik", Content = "Remote yok, sarki yalnizca sende caliniyor", Duration = 3 })
 end
 end
})

FETrollTab:AddButton({
 Name = "Muzigi Durdur",
 Callback = function()
 local stopped = 0
 for _, s in pairs(workspace:GetChildren()) do
  if s:IsA("Sound") and s.Name == "ZyronisFEMusic" then
   pcall(function() s:Stop() s:Destroy() end)
   stopped = stopped + 1
  end
 end
 Window:Notify({ Title = "Muzik", Content = stopped > 0 and "Muzik durduruldu!" or "Oynatan muzik yok!", Duration = 2 })
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
 if houseMusicId == "" then
 Window:Notify({ Title = "Hata", Content = "Muzik ID gir!", Duration = 2 })
 return
 end
 if FireRE("1Player1sHous1e", "PickHouseMusicText", houseMusicId) then
 Window:Notify({ Title = "Ev Muzigi", Content = "Ev muzigi degistirildi!", Duration = 2 })
 end
 end
})

-- SEKME 2: AVATAR / DIS GORUNUS
-- GERCEK U1pdateAvatar12324 remote eventi

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
 if FireRE("U1pdateAvatar12324", "skintone", selectedSkin) then
 Window:Notify({ Title = "Avatar", Content = "Ten rengi: " .. selectedSkin, Duration = 2 })
 end
 end
})

-- 7) FE RAINBOW SKIN (GERCEK REMOTE)
local rainbowSkinActive = false
local rainbowSkinGen = 0
AvatarTab2:AddToggle({
 Name = "FE Rainbow Skin Ac/Kapat",
 Default = false,
 Callback = function(v)
  rainbowSkinGen = rainbowSkinGen + 1
  rainbowSkinActive = v
  if v then
   local myGen = rainbowSkinGen
   task.spawn(function()
    local skins = {"Light reddish violet","Carnation Pink","Lime green","Pink","Really Red","Cocoa","Rust","Light blue"}
    local i = 1
    while rainbowSkinActive and rainbowSkinGen == myGen do
     local avatarRE = RE:FindFirstChild("U1pdateAvatar12324")
     if avatarRE then
      pcall(function() avatarRE:FireServer("skintone", skins[i]) end)
     end
     i = (i % #skins) + 1
     task.wait(0.5)
    end
   end)
   Window:Notify({ Title = "Rainbow Skin", Content = "FE Rainbow Skin ACIK!", Duration = 2 })
  else
   Window:Notify({ Title = "Rainbow Skin", Content = "FE Rainbow Skin KAPALI!", Duration = 2 })
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
 if rpName == "" then
 Window:Notify({ Title = "Hata", Content = "RP isim bos olamaz!", Duration = 2 })
 return
 end
 if FireRE("1RPNam1eTex1t", "RolePlayName", rpName) then
 Window:Notify({ Title = "RP Isim", Content = "RP ismin: " .. rpName, Duration = 2 })
 end
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
 if FireRE("1RPNam1eColo1r", "PickingRPNameColor", colorVal) then
 Window:Notify({ Title = "Isim Rengi", Content = colorName .. " renk uygulandi!", Duration = 2 })
 end
 end
 })
end

-- SEKME 3: GRAVITY & FIZIK

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
local superJumpGen = 0
PowerTab:AddToggle({
 Name = "Otomatik Super Ziplama",
 Default = false,
 Callback = function(v)
  superJumpGen = superJumpGen + 1
  superJumpActive = v
  if v then
   local myGen = superJumpGen
   task.spawn(function()
    while superJumpActive and superJumpGen == myGen do
     local char = LocalPlayer.Character
     local hum = char and char:FindFirstChildOfClass("Humanoid")
     if hum then
      hum:ChangeState(Enum.HumanoidStateType.Jumping)
     end
     task.wait(0.6)
    end
   end)
   Window:Notify({ Title = "Auto Jump", Content = "Otomatik ziplama ACIK!", Duration = 2 })
  else
   Window:Notify({ Title = "Auto Jump", Content = "Otomatik ziplama KAPALI!", Duration = 2 })
  end
 end
})

-- SEKME 5: ESP PLUS

-- 18) MESAFE ESP + SAGLIK BAR
ESPPlusTab:AddSection({ "BillboardGui ESP (Mesafe + HP)" })
local billboardESP = {}
local billboardActive = false
local billboardConns = {}
local billboardUpdateConn = nil
local billboardData = {} -- bb -> {info, hum} (A12: her karede resolve etme)

local function clearBillboardESP()
 billboardActive = false
 for _, c in pairs(billboardConns) do pcall(function() c:Disconnect() end) end
 billboardConns = {}
 if billboardUpdateConn then pcall(function() billboardUpdateConn:Disconnect() end) billboardUpdateConn = nil end
 for _, b in pairs(billboardESP) do
  if b and b.Parent then pcall(function() b:Destroy() end) end
 end
 billboardESP = {}
 billboardData = {}
end

ESPPlusTab:AddToggle({
 Name = "Billboard ESP Ac/Kapat",
 Default = false,
 Callback = function(v)
  clearBillboardESP()

  if v then
   billboardActive = true
   local function attachBB(plr, char)
    if not char then return end
    local head = char:WaitForChild("Head", 3)
    if not head then return end
    if not billboardActive then return end

    local bb = Instance.new("BillboardGui")
    -- A7: ana ESP ile ayni ad/offset uzerine binmesin
    bb.Name = "ZyronisESPPlus"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 120, 0, 50)
    bb.StudsOffset = Vector3.new(0, 6, 0)
    bb.Parent = head

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    nameLbl.TextScaled = true
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.Text = plr.Name

    local infoLbl = Instance.new("TextLabel", bb)
    infoLbl.Name = "Info"
    infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
    infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLbl.TextScaled = true
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.Text = "..."

    table.insert(billboardESP, bb)
    billboardData[bb] = { info = infoLbl }
   end

   local function makeESP(plr)
    if plr == LocalPlayer then return end
    if plr.Character then attachBB(plr, plr.Character) end
    table.insert(billboardConns, plr.CharacterAdded:Connect(function(c)
     if billboardActive then attachBB(plr, c) end
    end))
   end

   for _, plr in ipairs(Players:GetPlayers()) do makeESP(plr) end
   table.insert(billboardConns, Players.PlayerAdded:Connect(function(plr)
    if billboardActive then makeESP(plr) end
   end))

   -- Tek bir guncelleme dongusu (Once oyuncu basina ayri Heartbeat vardi)
   -- A12: ~5 Hz throttle + Info/Humanoid billboard basina bir kez resolve
   local espTick = 0
   billboardUpdateConn = RunService.Heartbeat:Connect(function()
    if not billboardActive then
     clearBillboardESP()
     return
    end
    espTick = espTick + 1
    if espTick % 12 ~= 0 then return end -- 60/12 = ~5 Hz
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for i = #billboardESP, 1, -1 do
     local bb = billboardESP[i]
     if not bb or not bb.Parent then
      -- O(n^2) table.find yerine sondan silme
      billboardData[bb] = nil
      table.remove(billboardESP, i)
     else
      local head = bb.Parent
      local d = billboardData[bb]
      if not d then
       d = { info = bb:FindFirstChild("Info") }
       billboardData[bb] = d
      end
      local infoLbl = d.info
      if not infoLbl or not infoLbl.Parent then
       infoLbl = bb:FindFirstChild("Info")
       d.info = infoLbl
      end
      if infoLbl and head:IsA("BasePart") then
       local char = head.Parent
       local tHRP = char and char:FindFirstChild("HumanoidRootPart")
       local hum = d.hum
       if not hum or not hum.Parent or hum.Parent ~= char then
        hum = char and char:FindFirstChildOfClass("Humanoid")
        d.hum = hum
       end
       if myHRP and tHRP and hum then
        local dist = math.floor((myHRP.Position - tHRP.Position).Magnitude)
        local txt = "HP:" .. math.floor(hum.Health) .. " | " .. dist .. "m"
        if infoLbl.Text ~= txt then infoLbl.Text = txt end
       end
      end
     end
    end
   end)

   Window:Notify({ Title = "ESP Plus", Content = "Billboard ESP ACIK!", Duration = 2 })
  else
   Window:Notify({ Title = "ESP Plus", Content = "Billboard ESP KAPALI!", Duration = 2 })
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

TeleTab:AddSection({ "Oyuncu Cek / It" })
TeleTab:AddLabel("Not: Hedef secimi icin TROLL & PVP bolumundeki oyuncu secimini kullanir")

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
  local owned = tryReplicate(tHRP, myHRP.CFrame * CFrame.new(3, 0, 0))
  Window:Notify({ Title = "Telekinesis", Content = selectedPlayerName .. " yanına cekildı!" .. (owned and "" or " (yerel)"), Duration = 2 })
  if not owned then feNotice("Telekinesis", false) end
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
  if th then tryReplicate(th, th.CFrame + Vector3.new(0, 1, 0)) end
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

-- 26) TUM ISIKLARI KAPAT
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
-- A12: saniyede ~60 Part uretmek yerine gercek Trail + 2 Attachment
local function trailClear(char)
 local hrp = char and char:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 for _, child in pairs(hrp:GetChildren()) do
  if child.Name == "ZyronisTrail" or child.Name == "ZyronisTrailA1" or child.Name == "ZyronisTrailA2" then
   pcall(function() child:Destroy() end)
  end
 end
end

local function trailBuild(char)
 local hrp = char and char:WaitForChild("HumanoidRootPart", 5)
 if not hrp then return end
 trailClear(char)
 if not trailActive then return end

 local a1 = Instance.new("Attachment")
 a1.Name = "ZyronisTrailA1"
 a1.Position = Vector3.new(0, 1, 0)
 a1.Parent = hrp

 local a2 = Instance.new("Attachment")
 a2.Name = "ZyronisTrailA2"
 a2.Position = Vector3.new(0, -1, 0)
 a2.Parent = hrp

 local trail = Instance.new("Trail")
 trail.Name = "ZyronisTrail"
 trail.Attachment0 = a1
 trail.Attachment1 = a2
 trail.Color = ColorSequence.new(Color3.fromRGB(255, 80, 200), Color3.fromRGB(80, 160, 255))
 trail.Transparency = NumberSequence.new({
  NumberSequenceKeypoint.new(0, 0.1),
  NumberSequenceKeypoint.new(1, 1)
 })
 trail.Lifetime = 1
 trail.MinLength = 0.1
 trail.FaceCamera = true
 trail.Parent = hrp
end

WorldTab:AddToggle({
 Name = "Trail Iz Ac/Kapat",
 Default = false,
 Callback = function(v)
 trailActive = v
 if trailConn then trailConn:Disconnect() trailConn = nil end

 if v then
  trailBuild(LocalPlayer.Character)
  trailConn = LocalPlayer.CharacterAdded:Connect(function(c)
   if trailActive then task.wait(0.3) trailBuild(c) end
  end)
  Window:Notify({ Title = "Trail", Content = "Trail ACIK! Arkan parlak iz birakacak.", Duration = 2 })
 else
  trailClear(LocalPlayer.Character)
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
