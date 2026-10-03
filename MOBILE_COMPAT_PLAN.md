# ZYRONIS Hub — Mobile Compatibility Plan (Research Deliverable)

**Scope:** Research only — no code was modified. This document is the implementation plan.
**Targets:**
- **LIB** = redzlib "Nexus Library V5" (ScreenGui `"Nexus Library V1"`), remote-loaded from `https://pastefy.app/KkevWErG/raw` (ZYRONIS.lua:1). Fetch verified **byte-identical** to the local 2902-line cache — line numbers below refer to that source.
- **SCRIPT** = `ZYRONIS.lua` (3886 lines).

**Placement rule:** the library is remote and uneditable at runtime → **every fix is SCRIPT-side** (polyfill/wrapper/instance-patcher), except two items that need the executor's `readfile/writefile`. Optional alternate path in §6: host your own library copy and patch LIB directly.

---

## Part A — Findings (with line numbers)

### P0 (hub is effectively unusable on a phone)

| # | Defect | Location | Detail |
|---|--------|----------|--------|
| A1 | **Window scale computed once, Y-only, unclamped** | LIB 894-895 | `ViewportSize` captured **once at module load**; `UIScale = ViewportSize.Y / 450`. No X clamp, no `GetPropertyChangedSignal("ViewportSize")` anywhere in 2902 lines. Portrait phone (e.g. 500×900) → scale **2.0** → the 550×380 window becomes **1100×760 px = mostly off-screen**. Rotation/resize never re-evaluates. |
| A2 | **Window is offset-only, not screen-fit** | LIB 59, 1446-1451, 1685 | `UDim2.fromOffset(UISizeX, UISizeY)`, default `Save.UISize = {550, 380}` (only clamp: 430..1000 × 200..500 via `ControlSize`). No viewport check, no `fromScale`. Saved offsets reload even larger than the screen. |
| A3 | **Window drag is dead on touch** | LIB 1165-1199 (pattern also 1141-1147) | `InputBegan` accepts `Touch` (1185) but the move loop is `while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)` (1189) → **always false on touch devices** → loop exits immediately. Window cannot be repositioned by finger. Same pattern drives `ConnectSave`. |
| A4 | **All sliders are dead on touch** | LIB 2645-2687 (esp. 2659-2660) | Identical `IsMouseButtonPressed` loop; also flips `ScrollingEnabled=false` (2659). Script has **17 `AddSlider` call sites** (speed, fly speed, esp, aimbot FOV, etc.) — every one is unusable on mobile. |

### P1 (usable but hostile on touch)

| # | Defect | Location | Detail |
|---|--------|----------|--------|
| A5 | **Touch targets too small** | LIB 1713-1726 (Close/Minimize **14×14 px**), 1303-1306 (rows `Size=(1,0,0,25)` + `AutomaticSize.Y`, Name `"Option"`), 1934-1936 (tab buttons `Size=(1,0,0,24)`, TextSize 10), 1482 (TopBar h=28), 1771-1798 (floating min button 35×35 @ `fromScale(0.15,0.15)`), 2436 (dropdown options h=21), toggle holder 35×18. Physical px = value × UIScale k; with width-driven k≈0.9 on phones these land at **12-34 px**, well under the 40-44 px recommendation. |
| A6 | **Text fixed & undersized** | LIB (fixed `TextSize` 8/10/12/14 throughout; `TextScaled` only at 2235 dropdown label, 2734 textbox) | At k≈0.9, body text renders ~7-9 px physical. |
| A7 | **Scroll affordance invisible on mobile** | LIB 1515-1537 (`"Tab Scroll"`), 1968-1990 (containers) | Native touch scrolling **works**, but `ScrollBarThickness = 1.5` bars are **auto-hidden by Roblox on touch devices** (devforum: mobile hides scrollbars; no property forces them visible) → users don't discover tabs/sections. |
| A8 | **ScreenGui flags unset** | LIB 1097-1104 | Only `Name` is set → `ResetOnSpawn` defaults **true** (window can vanish on respawn), `DisplayOrder = 0` (may sit under game HUD), `IgnoreGuiInset = false`. Script's own toast GUI already does this right (ZYRONIS 10-11, 40-43). |
| A9 | **Keyboard-only features** | SCRIPT 794-799 (fly W/A/S/D/Space/Ctrl), 847-850 (speed boost only applies velocity while WASD held), 943 (infinite jump on `KeyCode.Space`), 2118-2121 (car fly W/S/Space/Ctrl). **Not** a problem: 389 (`VirtualInputManager:SendKeyEvent(F)` is synthetic → works on mobile). | No `TouchEnabled`/`TouchTap`/`JumpRequest` handling anywhere in ZYRONIS.lua. |
| A10 | **Saved size never reloads** | LIB 946-958 reads `"Nexus library V1.json"`, 1699 writes `"Nexus library V5.json"` | Persistence is broken (P2-severity bug, but it also means bad sizes can't be recovered once saved). |

### P2 (polish / perf)

| # | Defect | Location |
|---|--------|----------|
| A11 | Particles: `Heartbeat` spawn loop; `math.random(containerSize.X - 10)` errors if `AbsoluteSize.X ≤ 10`; battery/CPU cost on low-end phones | LIB 1548-1656, 1571 |
| A12 | `ClickSound` `DescendantAdded` poll with `task.wait(0.1)` per added instance | LIB 1120-1130 |
| A13 | Desktop layout (side tabs, 550px window) on a 5" portrait screen; no fullscreen/bottom-tab mode | design-level |
| A14 | Dropdown option height (`count*25+10`, options 21 px) is **library-only** — script-side changes would clip the dropdown | LIB 2309, 2436, 2336 (scale upvalue used in clamp) |

---

## Part B — Research summary (what good mobile hub UIs do)

1. **Touch drag pattern** (Orion / pastebin mobile samples): `GuiObject.InputBegan(Touch)` + `UserInputService.InputChanged` + `InputEnded`, with an ~8 px movement threshold to separate taps from drags; divide delta by the current `UIScale` value. Never gate a loop on `IsMouseButtonPressed(MouseButton1)`.
2. **Responsive scale:** `k = math.clamp(math.min(vp.Y/refH, (vp.X*0.96)/refW), min, max)`, recompute on `ViewportSize` change (listen on `workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize")`, and re-acquire the camera because executors replace it), optionally subtract `GuiService:GetGuiInsets()`.
3. **Sizing:** prefer `UDim2.fromScale` / `UIAspectRatioConstraint` / `SizeConstraint.RelativeYY` for anything that must track the viewport (Roblox docs); keep offsets only for touch-target padding.
4. **Mobile hubs** (KrnlMobileGUI etc.): windows ~0.6-0.8 of screen width, **40-44 px** buttons, floating minimize button ≥44 px.
5. **Scrollbars on mobile are hidden by design** → add an explicit affordance (custom always-visible indicator or a hint), don't rely on the built-in bar.
6. **Hit-target rule:** physical ≥ 36-44 px after scaling; since physical = offset × k, offsets must be `ceil(targetPx / k)`.
7. Existing precedent in this repo: `Zyroniis.lua` already contains touch patterns (TouchTap / custom finger drag) usable as reference.

---

## Part C — Implementation plan

All fixes: **SCRIPT = ZYRONIS.lua** unless stated. Injection points already exist.

### P0-1 — Dynamic clamped scale + viewport tracking

**Where:** after library load (before `Library:MakeWindow` at L194); needs `Scale` instance (created at LIB 1097-1104, so it exists immediately after load).
**API note:** call the public `Library:SetScale` (LIB 1419-1422) so the library's internal scale upvalue (used by drag math at 1176 and dropdown clamp at 2336) stays in sync. `SetScale(x)` sets `k = staleY / clamp(x,300,2000)` where `staleY` is the load-time `ViewportSize.Y` — recover it as `ScaleObj.Scale * 450`, then call `SetScale(staleY / desiredK)`.

```lua
local ScreenGui = game.CoreGui:FindFirstChild("Nexus Library V1")
local ScaleObj  = ScreenGui and ScreenGui:FindFirstChild("Scale")
local REF_W, REF_H = 550, 380

local function desiredK()
  local vp = workspace.CurrentCamera.ViewportSize
  return math.clamp(math.min(vp.Y / REF_H, (vp.X * 0.96) / REF_W), 0.7, 1.6), vp
end

local function applyScale()
  if not ScaleObj then return end
  local k, vp = desiredK()
  local staleY = ScaleObj.Scale * 450          -- reverse of LIB 895
  Library:SetScale(staleY / k)                 -- keeps LIB upvalues in sync
  if math.abs(ScaleObj.Scale - k) > 0.02 then
    ScaleObj.Scale = k                         -- fallback if SetScale's 300..2000 clamp bit
  end
  -- re-seat window on screen (A1/A2 fallout)
  local hub = ScreenGui:FindFirstChild("Hub")
  if hub then
    local p, s = hub.AbsolutePosition, hub.AbsoluteSize
    if p.X < 0 or p.Y < 0 or p.X + s.X > vp.X or p.Y + s.Y > vp.Y then
      hub.Position = UDim2.fromOffset(math.max(8, (vp.X - s.X) / 2),
                                      math.max(8, (vp.Y - s.Y) / 2))
    end
  end
end
applyScale()

local lastCam = workspace.CurrentCamera
lastCam:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
task.spawn(function()                            -- executors swap CurrentCamera
  while task.wait(1) do
    local cam = workspace.CurrentCamera
    if cam and cam ~= lastCam then
      lastCam = cam
      cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
      applyScale()
    end
  end
end)
```

### P0-2 — Window fit to screen (before first build)

**Where:** inside the existing `Library.MakeWindow` wrapper, **before** `_rawMakeWindow` is called (ZYRONIS 154-155). `Save.UISize` is read at LIB 1446.

```lua
local k, vp = desiredK()
Library.Save.UISize = {
  math.clamp(vp.X * 0.94 / k, 430, 550),
  math.clamp(vp.Y * 0.72 / k, 200, 380),
}
```
(With k chosen so `550*k ≤ 0.96*vp.X`, keeping 550×380 also works — belt & braces for tiny screens.)

### P0-3 — Touch drag for TopBar + floating minimize button

**Where:** new local function; call it once after `Library:MakeWindow` (L199) and after `AddMinimizeButton` (L201-209). Touch-gated so desktop mouse drag (LIB 1165-1199) is untouched. Do **not** patch LIB's loop — it self-terminates on touch anyway.

```lua
local function attachTouchDrag(handle, frame)
  local dragging, startXY, startPos = false, nil, nil
  local THRESH = 8
  handle.Active = true
  handle.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging  = true
    startXY   = Vector2.new(input.Position.X, input.Position.Y)
    startPos  = frame.Position
  end)
  UserInputService.InputChanged:Connect(function(input)
    if not dragging or input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = Vector2.new(input.Position.X, input.Position.Y) - startXY
    if d.Magnitude < THRESH then return end          -- tap-vs-drag threshold
    local k = ScaleObj and ScaleObj.Scale or 1
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / k,
                               startPos.Y.Scale, startPos.Y.Offset + d.Y / k)
  end)
  UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then dragging = false end
  end)
end

attachTouchDrag(ScreenGui.Hub.TopBar or ScreenGui.Hub:FindFirstChildWhichIsA("Frame", true),
                ScreenGui.Hub)   -- verify TopBar instance name at LIB 1482
attachTouchDrag(ScreenGui:FindFirstChildWhichIsA("ImageButton"), ScreenGui.Hub) -- min button (LIB 1771-1798); only its *drag* is broken — its tap toggle still fires MouseButton1Click
```
Threshold keeps the 14×14 Close/Minimize taps working (no movement → no drag). If the handle can't be located by name, capture it from the `AddMinimizeButton` return value if any, or scan `ScreenGui` children post-build.

### P0-4 — Touch sliders (reuse existing wrapper)

**Where:** ZYRONIS **174-182** already wraps `Tab.AddSlider` (Increment→Increase). Extend it: capture `(Min, Max, Increment, Callback)`, let the raw call build the visual, then `task.defer` attach a touch handler to that tab's next `SliderBar`.

```lua
Tab.AddSlider = function(t, sliderCfg)
  if type(sliderCfg) == "table" and sliderCfg.Increment ~= nil and sliderCfg.Increase == nil then
    sliderCfg.Increase = sliderCfg.Increment
  end
  local ret = _rawAddSlider(t, sliderCfg)
  if UserInputService.TouchEnabled and type(sliderCfg) == "table" then
    task.defer(function()
      local bar = <this tab's Container>:FindFirstChild("SliderBar", true)  -- nth-match strategy below
      if not bar then return end
      local min, max, inc = sliderCfg.Min, sliderCfg.Max, sliderCfg.Increment or 1
      local cb, dragging = sliderCfg.Callback, false
      local icon = bar:FindFirstChildWhichIsA("Frame", true)                 -- SliderIcon (6x12)
      local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = min + math.floor(rel * (max - min) / inc + 0.5) * inc      -- match LIB rounding (verify 2660-2675)
        v = math.clamp(v, min, max)
        if icon then icon.Position = UDim2.fromScale(rel, icon.Position.Scale.Y) end
        <update LabelVal text above icon — find TextLabel sibling>
        if cb then cb(v) end
      end
      bar.Active = true
      bar.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        <set this tab's content container ScrollingEnabled = false>          -- mirror LIB 2659
        setFromX(inp.Position.X)
      end)
      UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.Touch then setFromX(inp.Position.X) end
      end)
      UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and dragging then
          dragging = false
          <restore ScrollingEnabled = true>
        end
      end)
    end)
  end
  return ret
end
```
**Slider↔instance matching:** sliders appear in creation order under the tab's container — keep a per-tab counter of wrapped calls and pick the nth `SliderBar` (`:GetDescendants()` filtered, nth match). **Verify callback actually fires** in the smoke test; if the label/icon geometry differs, adjust the two `<...>` discovery lines. Desktop path untouched (LIB handles mouse).

### P1-1 — Adaptive hit targets + text (post-build pass)

**Where:** once after `Library:MakeWindow` + first tabs exist (or on `ScreenGui.ChildAdded` for late elements). `k = ScaleObj.Scale`; `local px = function(v) return math.ceil(v / k) end` converts a physical-px goal to an offset.

- **Close/Minimize 14×14 → physical 32:** resize every 14×14 `GuiButton` to `UDim2.fromOffset(32,32)` and re-anchor to its original corner (LIB 1713-1726 top-right offsets — preserve the 6 px inset; re-read those lines when implementing).
- **Floating minimize 35×35 → physical 48:** set `Size = UDim2.fromOffset(px(48), px(48))` (keeps `fromScale` position valid).
- **Rows `"Option"`:** add/adjust a `UIPadding` with `PaddingTop = PaddingBottom = UDim.new(0, (px(38) - 25)/2)` so `AutomaticSize.Y` (LIB 1303) grows the row. **Fallback** if absolutely-positioned children don't follow padding: set `row.Size = UDim2.new(1,0,0,px(38))` and each child's `Size.Y` accordingly — verify visually, rows are the highest-traffic target.
- **Tab buttons 24 → physical 36:** `Size = UDim2.new(1,0,0,px(36))` (fixed size, safe; LIB 1934-1936).
- **TopBar 28 → physical 40:** change height, then subtract the same delta from `MainScroll.Size` and `Containers.Size` Y-offsets (they derive from `-TopBar.Size.Y.Offset`, LIB 1515-1537 / 1968-1990).
- **Toggles (35×18) and dropdown options (21):** leave alone (A14 — dropdown clips; toggle knob geometry is tight). Optionally enlarge only the toggle holder after visual check.
- **Text:** for each descendant with fixed `TextSize`, `if TextSize * k < 11 then TextSize = math.ceil(11 / k) end` (tab titles target 12 physical). Never touch `TextScaled` instances (2235, 2734).

### P1-2 — ScreenGui flags (one-liner, after load)

```lua
ScreenGui.DisplayOrder    = 100     -- above game HUD (compare: toast GUI uses 999999, ZYRONIS 43)
ScreenGui.ResetOnSpawn    = false   -- hub must survive respawn
ScreenGui.IgnoreGuiInset  = true    -- optional; only if the hub is clipped by the top bar
```

### P1-3 — Visible scroll affordance

Built-in bar can't be forced on (research #5). Options, pick one:
1. Custom always-visible indicator: thin 3 px `Frame` in the window's right edge, Y-position = `f(MainScroll.CanvasPosition.Y / CanvasSize)` updated on `CanvasPosition` change — ~15 lines, script-side, no library change.
2. Static hint label ("↓ kaydır") at first build; cheapest.

### P1-4 — Touch movement fallbacks (ZYRONIS)

- **Fly (794-799) & car fly (2118-2121):** when `UserInputService.TouchEnabled`, replace the four `IsKeyDown(W/A/S/D)` lines with `local md = Character.Humanoid.MoveDirection` (joystick feeds it): `moveDirection = Camera.CFrame.LookVector*md.Z + Camera.CFrame.RightVector*md.X` (or simply use `md` rotated by camera). Up/down: add two 44×44 touch buttons (script-created, bottom-right, `DisplayOrder` above hub) setting `flyUp`/`flyDown` booleans replacing Space/LeftControl.
- **Speed boost (847-850):** same `Humanoid.MoveDirection` substitution so boost applies while the joystick is held.
- **Infinite jump (943):** when `TouchEnabled`, connect `UserInputService.JumpRequest` (fires from the mobile jump button) instead of listening for `KeyCode.Space`.
- **Leave alone:** 389 (synthetic VIM event — mobile-safe), 150-189 wrappers (input-agnostic).

### P2 — Cleanup (nice-to-have)

1. **Persist fix (A10):** at the very top of ZYRONIS.lua *before* the library loads: `pcall(function() if isfile("Nexus library V5.json") then writefile("Nexus library V1.json", readfile("Nexus library V5.json")) end end)` — mirrors LIB 946 vs 1699.
2. **Particles (A11):** after load, find the particle container loop's instances and either destroy them (`ScreenGui` descendant scan for the particle frames) or reduce rate when `TouchEnabled`; guard the `math.random(size.X - 10)` by hiding the container if `AbsoluteSize.X < 40`.
3. **Layout (A13):** defer — fullscreen/bottom-tab redesign only if P0/P1 still feel cramped.

### Do-not-touch list

- Dropdown option height / `count*25+10` (LIB 2309, 2436) — script edits clip the list.
- LIB's mouse drag/save/slider loops — leave them; our touch handlers coexist (touch-gated).
- `TextScaled` instances (2235, 2734).
- Icon image tables / L860-892 bulk data.

---

## Part D — Mobile smoke-test checklist

Device: Android executor (Delta/Fluxus-class) + iOS if available; portrait first, then rotation.

**Boot & layout**
- [ ] Fresh load: window fully on-screen, ≥8 px margin on all sides, nothing clipped
- [ ] All tab titles readable (no <10 px physical text); tab bar scrollable by swipe
- [ ] Toast notifications appear above game HUD and are readable
- [ ] Rotate device → window rescales and stays on-screen within ~1 s; rotate back → original layout
- [ ] Kill & relaunch script → saved window size/tab loads correctly (P2-1)

**Interaction**
- [ ] Drag window by TopBar (and by header area only — Close/Minimize still tappable as taps)
- [ ] Minimize → floating button appears → drag it → tap restores window
- [ ] Close (top-right) works with one thumb
- [ ] Every row/toggle/tab press registers first try (no double-tap needed)
- [ ] All 17 sliders: drag by finger, value + callback change (test speed, fly speed, FOV)
- [ ] Dropdown: open, scroll, select; list does not clip; closes on outside tap
- [ ] Scrolled sections: swipe works; custom/hint scroll affordance visible (P1-3)
- [ ] Notifications/buttons during gameplay (e.g. fly toggle) reachable without drag

**Features**
- [ ] Fly on: joystick moves you; up/down buttons work; disable cleanly
- [ ] Infinite jump fires from the mobile jump button
- [ ] Speed boost applies while joystick held
- [ ] Car fly usable with touch controls
- [ ] Noclip/esp/aimbot toggles survive screen rotation while active

**Stability / perf**
- [ ] Respawn → window still present (`ResetOnSpawn=false`)
- [ ] 10 min idle in a busy area: no stutter from particles, battery sane (P2-2)
- [ ] Chat/HUD overlap check (`DisplayOrder`); open/close in-game backpack while hub open

---

## Appendix — Line-number index

**LIB (pastefy raw, byte-identical to cache, 2902 lines):** 59 Save.UISize · 894-895 ViewportSize/UIScale · 946-958 read V1.json · 1097-1104 ScreenGui+Scale · 1120-1130 ClickSound · 1141-1147 ConnectSave · 1165-1199 MakeDrag (1185 Touch, 1189 mouse loop, 1176 delta/k) · 1303-1306 Option rows · 1419-1422 SetScale · 1446-1451 window build/"Hub" · 1482 TopBar · 1515-1537 Tab Scroll · 1548-1656 particles (1571 random) · 1685-1699 size clamps + V5.json write · 1713-1726 14×14 buttons · 1771-1798 AddMinimizeButton · 1934-1936 tab buttons · 1968-1990 containers · 2235/2734 TextScaled · 2309/2336/2436 dropdown · 2645-2687 slider (2659 ScrollingEnabled, 2660 mouse loop)

**SCRIPT (ZYRONIS.lua):** 1-25 loader (URL:1) · 10-11/40-43 toast GUI flags · 150-189 wrappers · **174-182 AddSlider wrapper (P0-4 hook)** · 194-199 MakeWindow (P0-2 hook) · 201-209 minimize button · 389 VIM (OK) · 794-799 fly keys · 847-850 speed keys · 943 Space · 2118-2121 car-fly keys
