--==============================================================
--  CONES SCRIPT  v7  ·  no hooks · profiles · debug
--  Ключ: TimohaGay (спрашивается один раз на аккаунт) · Меню: P · Watermark: O
--==============================================================

local Players = game:GetService("Players")
local TS      = game:GetService("TweenService")
local LP      = Players.LocalPlayer
local VALID_KEY   = "TimohaGay"
local UID         = tostring((LP and LP.UserId) or 0)
local AUTH_FILE   = "cones/auth_" .. UID .. ".txt"   -- ключ помнится отдельно на каждый аккаунт
local LEGACY_AUTH = "cones/auth.txt"                 -- старый общий файл (для миграции)

local function LoadHub()

if getgenv and getgenv().HUB and getgenv().HUB.Unload then
    pcall(getgenv().HUB.Unload)
end

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace   = game:GetService("Workspace")
local Stats       = game:GetService("Stats")
local VU          = game:GetService("VirtualUser")
local CS          = game:GetService("CollectionService")
local VIM         = game:FindService("VirtualInputManager")
local TS          = game:GetService("TweenService")

local LP     = Players.LocalPlayer
local Mouse  = LP:GetMouse()
local Camera = Workspace.CurrentCamera

--==============================================================
-- 1. НАСТРОЙКИ
--==============================================================
local FOLDER   = "cones"
local PROFILES = FOLDER .. "/profiles"

local S = {
    -- hitbox
    HitboxOn = false, HitboxSize = 20, HitboxGlow = true,

    -- esp
    EspOn = false, EspBox = true, EspName = true, EspHealth = true,
    EspTracer = false, EspSkeleton = false, EspChams = false,
    EspArrows = false, EspDistance = 1000, EspFps = 40,
    TeamCheck = false, EspBehind = false,
    ColEnemy = {255,255,255}, ColAlly = {150,150,150}, ColFriend = {120,200,255},

    -- item esp
    ItemEspOn = false, ItemFilter = "", ItemTag = "", ItemDistance = 300,

    -- aim
    AimOn = false, AimFOV = 120, AimSmooth = 0.25, AimPart = "Head",
    AimVisible = false, ShowFOV = true, AimPredict = 0, StickyAim = true,
    AimAnchor = "Cursor", AimPriority = "Cursor",
    AimLock = false, AimSmartSmooth = true,

    -- trigger
    TriggerOn = false, TriggerFOV = 0, TriggerDelay = 0.1,
    TriggerVisible = true, TriggerRandom = 30, TriggerReaction = 90,
    TriggerMark = true,

    -- movement
    SpeedOn = false, SpeedVal = 32, SpeedMode = "WalkSpeed", AutoSprint = false,
    JumpOn = false, JumpVal = 90, InfJump = false, SpamJump = false,
    FlyOn = false, FlySpeed = 60, FlyMode = "BodyVelocity",
    NoclipOn = false, AntiAFK = true,
    AntiFling = false, AntiVoid = false, VoidY = -100,

    -- esp дополнительно
    EspWeapon = true, EspListOn = false, EspListMax = 8,
    RadarOn = false, RadarSize = 170, RadarRange = 250, RadarRotate = true,

    -- aim дополнительно
    AimOnFire = false, AimHumanize = true, AimJitter = 2,
    AimAutoSwitch = true, AimFallback = true,

    -- движение дополнительно
    GravityOn = false, GravityVal = 196, PlatformOn = false,
    TpTween = false, TpTweenTime = 0.4,
    Waypoints = {},

    -- ui
    Transparency = 0.15, Watermark = true, Notifications = true,
    Accent = {124,150,255},
    WinPos = {0,0}, WinSize = {600,430}, LastTab = "Hitbox", AutoLoad = true,
    UIScale = 1, QuickPanel = false, Favorites = {},
    Lang = "RU", GameProfile = true,

    -- списки
    Friends = {}, Prio = {}, Binds = {},

    -- клавиши (по умолчанию НЕ ЗАДАНЫ — биндит сам игрок в Config)
    KeyMenu = "", KeyWM = "", KeyAim = "",
    KeyFly = "", KeyNoclip = "", KeyClickTP = "",
    KeyPanic = "", KeyQuick = "",
}

--==============================================================
-- 2. MAID / DEBUG
--==============================================================
local HUB_ACTIVE = true
local Maid = { conns = {}, insts = {}, threads = {} }
function Maid:Conn(c) table.insert(self.conns, c) return c end
function Maid:Inst(i) table.insert(self.insts, i) return i end
function Maid:Thread(t) table.insert(self.threads, t) return t end

local debugLog = {}
local refreshDebug

local function logErr(tag, err)
    table.insert(debugLog, 1, os.date("%H:%M:%S") .. " [" .. tag .. "] " .. tostring(err))
    if #debugLog > 50 then table.remove(debugLog) end
    if refreshDebug then pcall(refreshDebug) end
end

local function safe(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then logErr(tag, err) end
    return ok
end

--==============================================================
-- 3. ТЕМА
--==============================================================
local function C3(t) return Color3.fromRGB(t[1], t[2], t[3]) end
local WHITE  = Color3.fromRGB(255,255,255)
local BLACK  = Color3.fromRGB(16,17,23)    -- панели
local DEEP   = Color3.fromRGB(10,11,15)    -- фон окна
local SUNK   = Color3.fromRGB(32,34,44)    -- вдавленные элементы
local uiTmp
local HOVER  = Color3.fromRGB(28,30,40)
local LINE   = Color3.fromRGB(120,130,165)
local TXT, TXT_DIM = Color3.fromRGB(236,238,245), Color3.fromRGB(124,128,144)
local RED    = Color3.fromRGB(255,105,120)
local FONT   = Enum.Font.GothamMedium
local FONT_B = Enum.Font.GothamBold

local accents = {}
local function accentOf() return C3(S.Accent) end
local function accent(inst, prop)
    prop = prop or "BackgroundColor3"
    table.insert(accents, { inst = inst, prop = prop })
    inst[prop] = accentOf()
    return inst
end
local function applyAccent()
    for i = #accents, 1, -1 do
        local a = accents[i]
        if a.inst and a.inst.Parent then a.inst[a.prop] = accentOf()
        else table.remove(accents, i) end
    end
end
local function round(inst, r)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, r or 6)
    return c
end
local function pad(inst, l, r, t, b)
    local p = Instance.new("UIPadding", inst)
    p.PaddingLeft = UDim.new(0, l or 0); p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0); p.PaddingBottom = UDim.new(0, b or 0)
    return p
end

local panels = {}
local function panel(inst, base)
    table.insert(panels, { inst = inst, base = base or 0 })
    inst.BackgroundTransparency = math.clamp((base or 0) + S.Transparency, 0, 1)
    return inst
end
local function applyTransparency()
    for i = #panels, 1, -1 do
        local p = panels[i]
        if p.inst and p.inst.Parent then
            p.inst.BackgroundTransparency = math.clamp(p.base + S.Transparency, 0, 1)
        else table.remove(panels, i) end
    end
end

local function border(p, tr, th)
    local s = Instance.new("UIStroke", p)
    s.Color = LINE; s.Transparency = tr or 0.8; s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end
local function txt(parent, text, size, col)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = col or TXT
    l.Font = FONT; l.TextSize = size or 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

--==============================================================
-- 3b. ЛОКАЛИЗАЦИЯ (RU / EN)
--==============================================================
local EN = {
    ["Хитбокс"] = "Hitbox", ["Подсветка"] = "Glow", ["Размер"] = "Size",
    ["Боксы"] = "Boxes", ["Ники"] = "Names", ["Полоска HP"] = "Health bar",
    ["Трейсеры"] = "Tracers", ["Скелет"] = "Skeleton",
    ["Стрелки за экраном"] = "Off-screen arrows",
    ["Оружие в руках"] = "Held weapon", ["Список врагов"] = "Enemy list",
    ["Радар"] = "Radar", ["Размер радара"] = "Radar size",
    ["Радиус радара"] = "Radar range",
    ["Вращать радар"] = "Rotate radar",
    ["Строк в списке"] = "List rows",
    ["Только враги"] = "Team check", ["Дистанция"] = "Distance",
    ["Частота обновления"] = "Refresh rate",
    ["Цвет врага"] = "Enemy color", ["Цвет союзника"] = "Ally color",
    ["Цвет друга"] = "Friend color",
    ["ESP предметов"] = "Item ESP", ["Имена"] = "Names", ["Теги"] = "Tags",
    ["Дистанция предметов"] = "Item distance",
    ["Аимбот"] = "Aimbot", ["Жёсткий лок"] = "Hard lock",
    ["Держать цель"] = "Sticky target",
    ["Только видимых"] = "Visible only",
    ["Умная плавность"] = "Smart smoothing",
    ["Показать FOV"] = "Show FOV", ["Центр FOV"] = "FOV anchor",
    ["Приоритет"] = "Priority", ["Часть тела"] = "Hit part",
    ["Плавность"] = "Smoothing",
    ["Аим при стрельбе (ЛКМ)"] = "Aim while firing (LMB)",
    ["Гуманизация"] = "Humanize", ["Сила дрожания"] = "Jitter",
    ["Автосмена цели"] = "Auto switch target",
    ["Запасная часть тела"] = "Body part fallback",
    ["Триггербот"] = "Triggerbot",
    ["Только видимых (триггер)"] = "Visible only (trigger)",
    ["Маркер цели"] = "Target marker",
    ["Триггер FOV (0 = точно)"] = "Trigger FOV (0 = exact)",
    ["Задержка"] = "Delay", ["Разброс задержки %"] = "Delay spread %",
    ["Реакция мс"] = "Reaction ms",
    ["Скорость"] = "Speed", ["Метод"] = "Method",
    ["Авто-спринт"] = "Auto sprint",
    ["Значение скорости"] = "Speed value",
    ["Прыжок"] = "Jump", ["Бесконечный прыжок"] = "Infinite jump",
    ["Спам-прыжок"] = "Jump spam", ["Полёт"] = "Fly",
    ["Метод полёта"] = "Fly method", ["Скорость полёта"] = "Fly speed",
    ["Гравитация"] = "Gravity", ["Значение гравитации"] = "Gravity value",
    ["Платформа под ногами"] = "Platform under feet",
    ["Плавный телепорт"] = "Smooth teleport",
    ["Время телепорта"] = "Teleport time",
    ["  раница пустоты Y"] = "Void border Y",
    ["Сбросить скорость и прыжок"] = "Reset speed and jump",
    ["Обновить список"] = "Refresh list",
    ["Очистить друзей"] = "Clear friends",
    ["Очистить приоритет"] = "Clear priority",
    ["Телепорт под курсор"] = "Teleport to cursor",
    ["Сброс персонажа"] = "Reset character",
    ["Добавить точку"] = "Add waypoint",
    ["Очистить точки"] = "Clear waypoints",
    ["Меню"] = "Menu", ["Аим"] = "Aim", ["Паника"] = "Panic",
    ["Быстрая панель"] = "Quick panel",
    ["Уведомления"] = "Notifications",
    ["Автозагрузка профиля"] = "Auto load profile",
    ["Профиль на игру"] = "Per-game profile",
    ["Акцентный цвет"] = "Accent color",
    ["Прозрачность"] = "Transparency",
    ["Масштаб UI"] = "UI scale", ["Язык"] = "Language",
    ["Сохранить"] = "Save", ["Загрузить"] = "Load",
    ["Сбросить окно"] = "Reset window",
    ["Скопировать конфиг"] = "Copy config",
    ["Вставить конфиг"] = "Paste config",
    ["Конфиг-строка"] = "Config string",
    ["Забыть ключ"] = "Forget key",
    ["Перезайти в сервер"] = "Rejoin server",
    ["Сменить сервер"] = "Server hop",
    ["ВЫГРУЗИТЬ СКРИПТ"] = "UNLOAD SCRIPT",
    ["Очистить лог"] = "Clear log",
    ["Тестовая ошибка"] = "Test error",
    ["Инфо об исполнителе"] = "Executor info",
}
local langLabels = {}
local function tr(s)
    if S.Lang == "EN" then return EN[s] or s end
    return s
end
local function langReg(inst, raw)
    table.insert(langLabels, { inst = inst, raw = raw })
    return inst
end
local function applyLang()
    for i = #langLabels, 1, -1 do
        local e = langLabels[i]
        if e.inst and e.inst.Parent then
            pcall(function() e.inst.Text = tr(e.raw) end)
        else table.remove(langLabels, i) end
    end
end

--==============================================================
-- 3c. ТУЛТИПЫ
--==============================================================
local TIPS = {
    ["Хитбокс"] = "Растягивает HumanoidRootPart врагов — попадать легче",
    ["Подсветка"] = "Делает увеличенный хитбокс видимым (Neon)",
    ["Список врагов"] = "Таблица слева: ник, HP, дистанция, оружие",
    ["Радар"] = "Круглый радар в углу с точками игроков",
    ["Оружие в руках"] = "Добавляет название Tool в ник ESP",
    ["Аимбот"] = "Наводит камеру на цель, пока зажата клавиша аима",
    ["Аим при стрельбе (ЛКМ)"] = "Аим работает, пока держишь левую кнопку мыши",
    ["Гуманизация"] = "Наведение по кривой с микро-дрожанием — менее заметно",
    ["Запасная часть тела"] = "Если голова за стеной — целится в торс или ноги",
    ["Автосмена цели"] = "Цель умерла или ушла — сразу берёт следующую",
    ["Триггербот"] = "Стреляет сам, когда враг под прицелом",
    ["Платформа под ногами"] = "Невидимая плита под персонажем — ходьба по воздуху",
    ["Плавный телепорт"] = "Перемещение твином вместо рывка — реже кикает",
    ["Гравитация"] = "Меняет Workspace.Gravity (локально)",
    ["Быстрая панель"] = "Узкая панель с избранными тумблерами (СКМ по тумблеру)",
    ["Профиль на игру"] = "Свой профиль для каждой игры по PlaceId",
    ["Масштаб UI"] = "Размер всего интерфейса — полезно на 4K и ноутбуках",
    ["Скопировать конфиг"] = "Конфиг в base64 в буфер обмена",
    ["Сменить сервер"] = "Перейти в случайный другой сервер этой игры",
    ["Забыть ключ"] = "Удаляет cones/auth.txt — ключ спросят снова",
}
local tipBar
local function setTip(text)
    if tipBar then tipBar.Text = text or "" end
end
local function tipFx(hit, name)
    if not hit then return end
    hit.MouseEnter:Connect(function() setTip(TIPS[name] or tr(name)) end)
    hit.MouseLeave:Connect(function() setTip("") end)
end

--==============================================================
-- 4. КОНТЕЙНЕРЫ
--==============================================================
local parentGui = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

local espGui = Maid:Inst(Instance.new("ScreenGui"))
espGui.Name = "Cones_Esp"; espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true; espGui.DisplayOrder = 5; espGui.Parent = parentGui

local gui = Maid:Inst(Instance.new("ScreenGui"))
gui.Name = "Cones_Menu"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10; gui.Parent = parentGui

--==============================================================
-- 5. УВЕДОМЛЕНИЯ / WATERMARK
--==============================================================
local notifHolder = Instance.new("Frame", gui)
notifHolder.Size = UDim2.new(0, 260, 1, -20)
notifHolder.Position = UDim2.new(1, -272, 0, 10)
notifHolder.BackgroundTransparency = 1
uiTmp = Instance.new("UIListLayout", notifHolder)
uiTmp.VerticalAlignment = Enum.VerticalAlignment.Bottom
uiTmp.HorizontalAlignment = Enum.HorizontalAlignment.Right
uiTmp.Padding = UDim.new(0, 4)

local function notify(text, dur)
    if not S.Notifications then return end
    -- очередь: не больше 4 карточек одновременно
    local live = {}
    for _, ch in ipairs(notifHolder:GetChildren()) do
        if ch:IsA("Frame") then table.insert(live, ch) end
    end
    for i = 1, #live - 3 do
        if live[i] then pcall(function() live[i]:Destroy() end) end
    end
    local f = Instance.new("Frame", notifHolder)
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = BLACK; f.BorderSizePixel = 0
    panel(f, 0.05); round(f, 8); border(f, 0.85)
    local dot = Instance.new("Frame", f)
    dot.Size = UDim2.fromOffset(6, 6); dot.Position = UDim2.fromOffset(11, 12)
    dot.BorderSizePixel = 0; round(dot, 3); accent(dot)
    local t = txt(f, tostring(text), 12, TXT)
    t.Size = UDim2.new(1, -30, 1, 0); t.Position = UDim2.fromOffset(24, 0)
    t.TextTruncate = Enum.TextTruncate.AtEnd
    f.Position = UDim2.fromOffset(30, 0)
    TS:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.fromOffset(0, 0) }):Play()
    task.delay(dur or 2.5, function()
        if not f or not f.Parent then return end
        TS:Create(f, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
        TS:Create(t, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
        task.wait(0.2); if f then f:Destroy() end
    end)
end

--// общий масштаб UI
local uiScales = {}
local function scaleOf(inst)
    local s = Instance.new("UIScale", inst)
    s.Scale = S.UIScale or 1
    table.insert(uiScales, s)
    return s
end
local function applyScale()
    for i = #uiScales, 1, -1 do
        local s = uiScales[i]
        if s and s.Parent then s.Scale = math.clamp(S.UIScale or 1, 0.6, 2)
        else table.remove(uiScales, i) end
    end
end
scaleOf(notifHolder)

local wm = Instance.new("Frame", gui)
wm.Size = UDim2.fromOffset(290, 26)
wm.Position = UDim2.fromOffset(12, 12)
wm.BackgroundColor3 = BLACK; wm.BorderSizePixel = 0
panel(wm, 0.05); round(wm, 13); border(wm, 0.85)
scaleOf(wm)
uiTmp = Instance.new("Frame", wm)
uiTmp.Size = UDim2.fromOffset(6, 6); uiTmp.Position = UDim2.fromOffset(11, 10)
uiTmp.BorderSizePixel = 0; round(uiTmp, 3); accent(uiTmp)
local wmText = txt(wm, "CONES", 11, TXT)
wmText.Size = UDim2.new(1, -32, 1, 0); wmText.Position = UDim2.fromOffset(24, 0)

--==============================================================
-- 6. ОКНО
--==============================================================
local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(600, 430)
main.Position = UDim2.new(0.5, -300, 0.5, -215)
main.BackgroundColor3 = DEEP; main.BorderSizePixel = 0
main.Active, main.Draggable = true, true
panel(main, 0); round(main, 12); scaleOf(main)
uiTmp = Instance.new("UIStroke", main)
uiTmp.Thickness = 1; uiTmp.Transparency = 0.55
uiTmp.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
accent(uiTmp, "Color")

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = BLACK; header.BorderSizePixel = 0
panel(header, 0.1); round(header, 12)
uiTmp = Instance.new("Frame", header)
uiTmp.Size = UDim2.new(1, 0, 0, 14); uiTmp.Position = UDim2.new(0, 0, 1, -14)
uiTmp.BackgroundColor3 = BLACK; uiTmp.BorderSizePixel = 0
panel(uiTmp, 0.1)
uiTmp = Instance.new("Frame", header)
uiTmp.Size = UDim2.new(1, 0, 0, 1); uiTmp.Position = UDim2.new(0, 0, 1, -1)
uiTmp.BackgroundColor3 = LINE; uiTmp.BackgroundTransparency = 0.75
uiTmp.BorderSizePixel = 0

uiTmp = Instance.new("Frame", header)
uiTmp.Size = UDim2.fromOffset(8, 8); uiTmp.Position = UDim2.fromOffset(16, 18)
uiTmp.BorderSizePixel = 0; round(uiTmp, 4); accent(uiTmp)
uiTmp = txt(header, "CONES", 15, TXT)
uiTmp.Font = FONT_B
uiTmp.Size = UDim2.fromOffset(80, 44); uiTmp.Position = UDim2.fromOffset(31, 0)
uiTmp = txt(header, "v6", 10, TXT_DIM)
uiTmp.Size = UDim2.fromOffset(30, 44); uiTmp.Position = UDim2.fromOffset(94, 1)

local body = Instance.new("Frame", main)
body.Size = UDim2.new(1, 0, 1, -44)
body.Position = UDim2.fromOffset(0, 44)
body.BackgroundTransparency = 1

local function hBtn(text, x)
    local b = Instance.new("TextButton", header)
    b.Size = UDim2.fromOffset(24, 24); b.Position = UDim2.new(1, x, 0, 10)
    b.BackgroundColor3 = SUNK; b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0; b.Text = text
    b.TextColor3 = TXT_DIM; b.Font = FONT_B; b.TextSize = 12
    b.AutoButtonColor = false
    round(b, 6)
    b.MouseEnter:Connect(function()
        TS:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
        b.TextColor3 = TXT
    end)
    b.MouseLeave:Connect(function()
        TS:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.25 }):Play()
        b.TextColor3 = TXT_DIM
    end)
    return b
end
local minBtn  = hBtn("–", -60)
uiTmp = hBtn("×", -32)

local searchBox = Instance.new("TextBox", header)
searchBox.Size = UDim2.fromOffset(150, 24); searchBox.Position = UDim2.new(1, -220, 0, 10)
searchBox.BackgroundColor3 = SUNK; searchBox.BackgroundTransparency = 0.25
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "Поиск..."; searchBox.PlaceholderColor3 = TXT_DIM
searchBox.Text = ""; searchBox.TextColor3 = TXT
searchBox.Font = FONT; searchBox.TextSize = 11
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
round(searchBox, 6); pad(searchBox, 10, 8, 0, 0)

local minimized, savedH = false, 430
local function setMinimized(v)
    minimized = v
    if v then
        savedH = main.Size.Y.Offset
        body.Visible = false
        main.Size = UDim2.fromOffset(main.Size.X.Offset, 44)
        minBtn.Text = "+"
    else
        body.Visible = true
        main.Size = UDim2.fromOffset(main.Size.X.Offset, savedH)
        minBtn.Text = "–"
    end
end
Maid:Conn(minBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end))
Maid:Conn(uiTmp.MouseButton1Click:Connect(function() main.Visible = false end))

--// кнопка-резерв: клавиша меню по умолчанию не задана, без неё меню не открыть
-- do...end — чтобы не есть лишний локал из лимита 200 в LoadHub
do
local openBtn = Instance.new("TextButton", gui)
openBtn.Size = UDim2.fromOffset(58, 24)
openBtn.Position = UDim2.fromOffset(12, 12)
openBtn.BackgroundColor3 = BLACK
openBtn.BorderSizePixel = 0
openBtn.Text = "CONES"
openBtn.TextColor3 = TXT
openBtn.Font = FONT_B
openBtn.TextSize = 11
openBtn.AutoButtonColor = true
openBtn.Visible = false
panel(openBtn, 0.05); round(openBtn, 6); border(openBtn, 0.8); scaleOf(openBtn)
Maid:Conn(openBtn.MouseButton1Click:Connect(function()
    main.Visible = true
    pcall(function() espGui.Enabled = true end)
end))
Maid:Conn(main:GetPropertyChangedSignal("Visible"):Connect(function()
    openBtn.Visible = not main.Visible
end))
end

local tabHolder = Instance.new("ScrollingFrame", body)
tabHolder.Size = UDim2.new(1, -28, 0, 30)
tabHolder.Position = UDim2.fromOffset(14, 8)
tabHolder.BackgroundTransparency = 1; tabHolder.BorderSizePixel = 0
tabHolder.ScrollBarThickness = 0
tabHolder.ScrollingDirection = Enum.ScrollingDirection.X
tabHolder.CanvasSize = UDim2.new()
tabHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
uiTmp = Instance.new("UIListLayout", tabHolder)
uiTmp.FillDirection = Enum.FillDirection.Horizontal
uiTmp.Padding = UDim.new(0, 6)
uiTmp.VerticalAlignment = Enum.VerticalAlignment.Center

uiTmp = Instance.new("Frame", body)
uiTmp.Size = UDim2.new(1, -28, 0, 1); uiTmp.Position = UDim2.fromOffset(14, 44)
uiTmp.BackgroundColor3 = LINE; uiTmp.BackgroundTransparency = 0.8
uiTmp.BorderSizePixel = 0

local content = Instance.new("Frame", body)
content.Size = UDim2.new(1, 0, 1, -70)
content.Position = UDim2.fromOffset(0, 46)
content.BackgroundTransparency = 1

--// полоса тултипов внизу окна
uiTmp = Instance.new("Frame", body)
uiTmp.Size = UDim2.new(1, -28, 0, 1)
uiTmp.Position = UDim2.new(0, 14, 1, -24)
uiTmp.BackgroundColor3 = LINE; uiTmp.BackgroundTransparency = 0.85
uiTmp.BorderSizePixel = 0
tipBar = txt(body, "", 10, TXT_DIM)
tipBar.Size = UDim2.new(1, -28, 0, 20)
tipBar.Position = UDim2.new(0, 14, 1, -22)
tipBar.TextTruncate = Enum.TextTruncate.AtEnd

--// быстрая панель избранных тумблеров
local quickPanel = Instance.new("Frame", gui)
quickPanel.Size = UDim2.fromOffset(160, 0)
quickPanel.AutomaticSize = Enum.AutomaticSize.Y
quickPanel.Position = UDim2.fromOffset(12, 46)
quickPanel.BackgroundColor3 = BLACK; quickPanel.BorderSizePixel = 0
quickPanel.Visible = false
panel(quickPanel, 0.05); round(quickPanel, 8); border(quickPanel, 0.85)
scaleOf(quickPanel)
uiTmp = Instance.new("UIListLayout", quickPanel)
uiTmp.Padding = UDim.new(0, 2)
pad(quickPanel, 6, 6, 6, 6)
local quickRows, refreshQuick = {}, nil
local function updateQuick()
    quickPanel.Visible = S.QuickPanel and #S.Favorites > 0
    for _, r in ipairs(quickRows) do pcall(r.upd) end
end

-- ресайз
local grip = Instance.new("TextButton", main)
grip.Size = UDim2.fromOffset(16, 16)
grip.Position = UDim2.new(1, -18, 1, -18)
grip.BackgroundTransparency = 1; grip.Text = "◢"
grip.TextColor3 = TXT_DIM; grip.Font = FONT; grip.TextSize = 12
grip.AutoButtonColor = false
do
    local rz, startPos, startSize = false, nil, nil
    Maid:Conn(grip.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            rz = true; startPos = i.Position
            startSize = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
            main.Draggable = false
        end
    end))
    Maid:Conn(UIS.InputChanged:Connect(function(i)
        if rz and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startPos
            main.Size = UDim2.fromOffset(
                math.clamp(startSize.X + d.X, 520, 1200),
                math.clamp(startSize.Y + d.Y, 300, 900))
            savedH = main.Size.Y.Offset
        end
    end))
    Maid:Conn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            rz = false; main.Draggable = true
        end
    end))
end

--==============================================================
-- 7. ЭЛЕМЕНТЫ UI
--==============================================================
local pages, tabBtns, elements = {}, {}, {}
local bindMap = {}
local currentTab

local function selectTab(name)
    if not pages[name] then return end
    currentTab = name; S.LastTab = name
    for n, p in pairs(pages) do
        local on = (n == name)
        p.Visible = on
        local b = tabBtns[n].btn
        TS:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = on and accentOf() or SUNK,
            BackgroundTransparency = on and 0 or 0.3,
            TextColor3 = on and Color3.fromRGB(16,17,23) or TXT_DIM,
        }):Play()
    end
end

local function newTab(name)
    local b = Instance.new("TextButton", tabHolder)
    b.Size = UDim2.fromOffset(0, 26)
    b.AutomaticSize = Enum.AutomaticSize.X
    b.BackgroundColor3 = SUNK; b.BackgroundTransparency = 0.3
    b.BorderSizePixel = 0
    b.Text = name:upper(); b.TextColor3 = TXT_DIM
    b.Font = FONT_B; b.TextSize = 11
    b.AutoButtonColor = false
    round(b, 7); pad(b, 14, 14, 0, 0)

    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = LINE; page.ScrollBarImageTransparency = 0.5
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    local l = Instance.new("UIListLayout", page); l.Padding = UDim.new(0, 5)
    local pd = Instance.new("UIPadding", page)
    pd.PaddingTop = UDim.new(0, 10); pd.PaddingLeft = UDim.new(0, 14)
    pd.PaddingRight = UDim.new(0, 16); pd.PaddingBottom = UDim.new(0, 14)

    pages[name] = page
    tabBtns[name] = { btn = b, txt = b }
    Maid:Conn(b.MouseButton1Click:Connect(function() selectTab(name) end))
    return page
end

local function register(inst, text, tab, refresh)
    table.insert(elements, { inst = inst, label = text:lower(), tab = tab, refresh = refresh })
    if inst and inst:IsA("GuiObject") and TIPS[text] then
        Maid:Conn(inst.MouseEnter:Connect(function() setTip(TIPS[text]) end))
        Maid:Conn(inst.MouseLeave:Connect(function() setTip("") end))
    end
end

local function row(page, h)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundColor3 = BLACK; f.BorderSizePixel = 0
    panel(f, 0.1); round(f, 8)
    return f
end

local function hoverFx(f, hit, base)
    Maid:Conn(hit.MouseEnter:Connect(function()
        TS:Create(f, TweenInfo.new(0.12), { BackgroundColor3 = HOVER }):Play()
    end))
    Maid:Conn(hit.MouseLeave:Connect(function()
        TS:Create(f, TweenInfo.new(0.12), { BackgroundColor3 = BLACK }):Play()
    end))
end

local function Section(page, name)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1, 0, 0, 28); f.BackgroundTransparency = 1
    local d = Instance.new("Frame", f)
    d.Size = UDim2.fromOffset(14, 2); d.Position = UDim2.fromOffset(0, 17)
    d.BorderSizePixel = 0; round(d, 1); accent(d)
    local t = txt(f, tr(name):upper(), 10, TXT_DIM)
    t.Font = FONT_B
    t.Size = UDim2.new(1, -20, 1, 0); t.Position = UDim2.fromOffset(20, 0)
    t.TextYAlignment = Enum.TextYAlignment.Bottom
    langReg(t, name)
    return f
end

local function Toggle(page, tab, name, key, cb)
    local f = row(page, 34)
    local t = txt(f, tr(name), 12, S[key] and TXT or TXT_DIM)
    t.Size = UDim2.new(1, -130, 1, 0); t.Position = UDim2.fromOffset(14, 0)
    langReg(t, name)

    local bl = txt(f, "", 10, TXT_DIM)
    bl.Size = UDim2.fromOffset(66, 34); bl.Position = UDim2.new(1, -122, 0, 0)
    bl.TextXAlignment = Enum.TextXAlignment.Right

    local pill = Instance.new("Frame", f)
    pill.Size = UDim2.fromOffset(36, 18); pill.Position = UDim2.new(1, -50, 0, 8)
    pill.BackgroundColor3 = SUNK; pill.BorderSizePixel = 0
    round(pill, 9)
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.fromOffset(14, 14); knob.Position = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.fromRGB(120,124,140); knob.BorderSizePixel = 0
    round(knob, 7)

    local hit = Instance.new("TextButton", f)
    hit.Size = UDim2.fromScale(1, 1); hit.BackgroundTransparency = 1
    hit.Text = ""; hit.AutoButtonColor = false
    hoverFx(f, hit, 0.1)

    -- СКМ по тумблеру — в избранное (быстрая панель)
    Maid:Conn(hit.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
        local found
        for idx, k in ipairs(S.Favorites) do
            if k == key then found = idx break end
        end
        if found then table.remove(S.Favorites, found)
        elseif #S.Favorites >= 6 then notify("В ИЗБРАННОМ УЖЕ 6 ПУНКТОВ") return
        else table.insert(S.Favorites, key) end
        if refreshQuick then refreshQuick() end
        notify((found and "ИЗ ИЗБРАННОГО: " or "В ИЗБР  Н  ОЕ: ") .. tr(name))
    end))

    local function refresh()
        local on = S[key]
        TS:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = on and accentOf() or SUNK }):Play()
        TS:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(on and 20 or 2, 2),
            BackgroundColor3 = on and WHITE or Color3.fromRGB(120,124,140) }):Play()
        t.TextColor3 = on and TXT or TXT_DIM
        bl.Text = S.Binds[key] and (S.Binds[key]:upper()) or ""
    end
    local function toggle()
        S[key] = not S[key]; refresh()
        if cb then safe(name, cb, S[key]) end
        notify((S[key] and "[+] " or "[-] ") .. name)
    end
    bindMap[key] = { refresh = refresh, cb = cb, name = name }

    Maid:Conn(hit.MouseButton1Click:Connect(toggle))
    Maid:Conn(hit.MouseButton2Click:Connect(function()
        bl.Text = "[...]"
        local conn
        conn = UIS.InputBegan:Connect(function(i)
            local n
            if i.UserInputType == Enum.UserInputType.Keyboard then n = i.KeyCode.Name
            elseif i.UserInputType.Name:find("MouseButton") then n = i.UserInputType.Name end
            if n then
                if n == "Backspace" then S.Binds[key] = nil else S.Binds[key] = n end
                refresh(); conn:Disconnect()
                notify("БИНД: " .. name .. " > " .. (S.Binds[key] or "НЕТ"))
            end
        end)
    end))
    refresh()
    register(f, name, tab, refresh)
    return { refresh = refresh }
end

local function Slider(page, tab, name, key, min, max, step, cb)
    local f = row(page, 44)
    local t = txt(f, tr(name), 12, TXT_DIM)
    t.Size = UDim2.new(1, -100, 0, 18); t.Position = UDim2.fromOffset(14, 5)
    langReg(t, name)
    local v = txt(f, tostring(S[key]), 12, TXT)
    v.Font = FONT_B
    v.Size = UDim2.fromOffset(80, 18); v.Position = UDim2.new(1, -94, 0, 5)
    v.TextXAlignment = Enum.TextXAlignment.Right

    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(1, -28, 0, 4); bar.Position = UDim2.fromOffset(14, 30)
    bar.BackgroundColor3 = SUNK; bar.BorderSizePixel = 0
    round(bar, 2)
    local fill = Instance.new("Frame", bar)
    fill.BorderSizePixel = 0; round(fill, 2); accent(fill)
    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.fromOffset(10, 10); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = WHITE; knob.BorderSizePixel = 0; round(knob, 5)

    local function refresh()
        local a = math.clamp((S[key] - min) / (max - min), 0, 1)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        v.Text = tostring(S[key])
    end
    refresh()

    local dragging = false
    local function set(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.clamp(math.floor((min + (max - min) * rel) / step + 0.5) * step, min, max)
        S[key] = (step < 1) and tonumber(string.format("%.2f", val)) or val
        refresh()
        if cb then safe(name, cb, S[key]) end
    end
    Maid:Conn(f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = true; set(i.Position.X) end
    end))
    Maid:Conn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    Maid:Conn(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then set(i.Position.X) end
    end))
    register(f, name, tab, refresh)
end

local function Button(page, tab, name, cb, danger)
    local f = row(page, 34)
    local ln = Instance.new("Frame", f)
    ln.Size = UDim2.fromOffset(3, 16); ln.Position = UDim2.fromOffset(0, 9)
    ln.BorderSizePixel = 0; round(ln, 2)
    if danger then ln.BackgroundColor3 = RED else accent(ln) end
    local t = txt(f, tr(name), 12, danger and RED or TXT)
    t.Size = UDim2.new(1, -24, 1, 0); t.Position = UDim2.fromOffset(16, 0)
    langReg(t, name)
    local hit = Instance.new("TextButton", f)
    hit.Size = UDim2.fromScale(1, 1); hit.BackgroundTransparency = 1
    hit.Text = ""; hit.AutoButtonColor = false
    hoverFx(f, hit, 0.1)
    Maid:Conn(hit.MouseEnter:Connect(function()
        t.TextColor3 = danger and Color3.fromRGB(255,170,180) or WHITE end))
    Maid:Conn(hit.MouseLeave:Connect(function()
        t.TextColor3 = danger and RED or TXT end))
    Maid:Conn(hit.MouseButton1Click:Connect(function() safe(name, cb) end))
    register(f, name, tab)
    return f
end

local function Cycle(page, tab, name, key, list, cb)
    local f = row(page, 34)
    local t = txt(f, tr(name), 12, TXT_DIM)
    t.Size = UDim2.new(1, -180, 1, 0); t.Position = UDim2.fromOffset(14, 0)
    langReg(t, name)
    local chip = Instance.new("Frame", f)
    chip.Size = UDim2.fromOffset(156, 22); chip.Position = UDim2.new(1, -170, 0, 6)
    chip.BackgroundColor3 = SUNK; chip.BorderSizePixel = 0
    round(chip, 6)
    local v = txt(chip, "", 11, TXT)
    v.Size = UDim2.fromScale(1, 1)
    v.TextXAlignment = Enum.TextXAlignment.Center
    local function refresh() v.Text = tostring(S[key]) .. "   ›" end
    refresh()
    local hit = Instance.new("TextButton", f)
    hit.Size = UDim2.fromScale(1, 1); hit.BackgroundTransparency = 1
    hit.Text = ""; hit.AutoButtonColor = false
    hoverFx(f, hit, 0.1)
    Maid:Conn(hit.MouseButton1Click:Connect(function()
        local idx = (table.find(list, S[key]) or 1) % #list + 1
        S[key] = list[idx]; refresh()
        if cb then safe(name, cb, S[key]) end
    end))
    register(f, name, tab, refresh)
end

local function TextInput(page, tab, name, key, placeholder, cb)
    local f = row(page, 34)
    local t = txt(f, tr(name), 12, TXT_DIM)
    t.Size = UDim2.new(0.38, 0, 1, 0); t.Position = UDim2.fromOffset(14, 0)
    langReg(t, name)
    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(0.56, -22, 0, 22); box.Position = UDim2.new(0.42, 0, 0, 6)
    box.BackgroundColor3 = SUNK
    box.BorderSizePixel = 0; box.ClearTextOnFocus = false
    box.PlaceholderText = placeholder or ""; box.PlaceholderColor3 = TXT_DIM
    box.Text = tostring(S[key]); box.TextColor3 = TXT
    box.Font = FONT; box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    round(box, 6); pad(box, 8, 8, 0, 0)
    local function refresh() box.Text = tostring(S[key]) end
    Maid:Conn(box.FocusLost:Connect(function()
        S[key] = box.Text
        if cb then safe(name, cb, S[key]) end
    end))
    register(f, name, tab, refresh)
end

local function Keybind(page, tab, name, key)
    local f = row(page, 32)
    local t = txt(f, tr(name), 12, TXT_DIM)
    t.Size = UDim2.new(1, -150, 1, 0); t.Position = UDim2.fromOffset(14, 0)
    langReg(t, name)
    local kb = Instance.new("Frame", f)
    kb.Size = UDim2.fromOffset(126, 20); kb.Position = UDim2.new(1, -140, 0, 6)
    kb.BackgroundColor3 = SUNK; kb.BorderSizePixel = 0
    round(kb, 6)
    local kt = txt(kb, "", 11, TXT)
    kt.Font = FONT_B
    kt.Size = UDim2.fromScale(1, 1); kt.TextXAlignment = Enum.TextXAlignment.Center
    local function refresh()
        local v = S[key]
        if v == nil or v == "" then
            kt.Text = "НЕ ЗАДАНО"
            kt.TextColor3 = TXT_DIM
        else
            kt.Text = tostring(v):upper()
            kt.TextColor3 = TXT
        end
    end
    refresh()

    local hit = Instance.new("TextButton", f)
    hit.Size = UDim2.fromScale(1, 1); hit.BackgroundTransparency = 1
    hit.Text = ""; hit.AutoButtonColor = false

    local listening, conn = false, nil
    local function stopListen()
        listening = false
        if conn then conn:Disconnect(); conn = nil end
        refresh()
    end

    -- ЛКМ — начать бинд | Backspace/Delete — сбросить | Escape — отмена
    Maid:Conn(hit.MouseButton1Click:Connect(function()
        if listening then stopListen() return end
        listening = true
        kt.Text = "ЖМИ КЛАВИШУ..."
        kt.TextColor3 = accentOf()
        conn = UIS.InputBegan:Connect(function(i)
            local n
            if i.UserInputType == Enum.UserInputType.Keyboard then n = i.KeyCode.Name
            elseif i.UserInputType.Name:find("MouseButton") then n = i.UserInputType.Name end
            if not n then return end
            if n == "Escape" then stopListen() return end
            if n == "Backspace" or n == "Delete" then
                S[key] = ""
                stopListen()
                notify(tr(name) .. " > НЕ ЗАДАНО")
                return
            end
            S[key] = n
            stopListen()
            notify(tr(name) .. " > " .. n:upper())
        end)
    end))

    -- ПКМ — быстрый сброс бинда
    Maid:Conn(hit.MouseButton2Click:Connect(function()
        if listening then stopListen() end
        S[key] = ""
        refresh()
        notify(tr(name) .. " > НЕ ЗАДАНО")
    end))
    register(f, name, tab, refresh)
end

--// HSV пикер
local pickerPopup
local function ColorPicker(page, tab, name, key)
    local f = row(page, 34)
    local t = txt(f, tr(name), 12, TXT_DIM)
    t.Size = UDim2.new(1, -80, 1, 0); t.Position = UDim2.fromOffset(14, 0)
    langReg(t, name)
    local sw = Instance.new("Frame", f)
    sw.Size = UDim2.fromOffset(40, 18); sw.Position = UDim2.new(1, -54, 0, 8)
    sw.BackgroundColor3 = C3(S[key]); sw.BorderSizePixel = 0
    round(sw, 5); border(sw, 0.6)
    local function refresh()
        sw.BackgroundColor3 = C3(S[key])
        if key == "Accent" then
            applyAccent()
            if currentTab then selectTab(currentTab) end
        end
    end

    local hit = Instance.new("TextButton", f)
    hit.Size = UDim2.fromScale(1, 1); hit.BackgroundTransparency = 1
    hit.Text = ""; hit.AutoButtonColor = false
    hoverFx(f, hit, 0.1)

    Maid:Conn(hit.MouseButton1Click:Connect(function()
        if pickerPopup then pickerPopup:Destroy(); pickerPopup = nil end
        local p = Instance.new("Frame", gui)
        pickerPopup = p
        p.Size = UDim2.fromOffset(180, 150)
        p.Position = UDim2.fromOffset(f.AbsolutePosition.X - 190, f.AbsolutePosition.Y)
        p.BackgroundColor3 = BLACK; p.BackgroundTransparency = 0.05
        p.BorderSizePixel = 0; p.ZIndex = 50
        round(p, 10); border(p, 0.6)

        local h, s, v = Color3.fromRGB(unpack(S[key])):ToHSV()

        local sv = Instance.new("Frame", p)
        sv.Size = UDim2.fromOffset(160, 100); sv.Position = UDim2.fromOffset(10, 10)
        sv.BorderSizePixel = 0; sv.ZIndex = 51
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        local wG = Instance.new("Frame", sv)
        wG.Size = UDim2.fromScale(1,1); wG.BackgroundColor3 = WHITE
        wG.BorderSizePixel = 0; wG.ZIndex = 52
        local g1 = Instance.new("UIGradient", wG)
        g1.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }
        local bG = Instance.new("Frame", sv)
        bG.Size = UDim2.fromScale(1,1); bG.BackgroundColor3 = BLACK
        bG.BorderSizePixel = 0; bG.ZIndex = 53
        local g2 = Instance.new("UIGradient", bG)
        g2.Rotation = 90
        g2.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }
        local cur = Instance.new("Frame", sv)
        cur.Size = UDim2.fromOffset(4,4); cur.AnchorPoint = Vector2.new(0.5,0.5)
        cur.BackgroundColor3 = WHITE; cur.BorderSizePixel = 0; cur.ZIndex = 54

        local hue = Instance.new("Frame", p)
        hue.Size = UDim2.fromOffset(160, 12); hue.Position = UDim2.fromOffset(10, 116)
        hue.BorderSizePixel = 0; hue.ZIndex = 51
        local hg = Instance.new("UIGradient", hue)
        local ks = {}
        for i = 0, 6 do
            table.insert(ks, ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1)))
        end
        hg.Color = ColorSequence.new(ks)

        local okBtn = Instance.new("TextButton", p)
        okBtn.Size = UDim2.fromOffset(160, 14); okBtn.Position = UDim2.fromOffset(10, 132)
        okBtn.BackgroundTransparency = 1; okBtn.Text = "> ЗАКРЫТЬ"
        okBtn.TextColor3 = TXT_DIM; okBtn.Font = FONT; okBtn.TextSize = 10
        okBtn.ZIndex = 51
        okBtn.MouseButton1Click:Connect(function()
            if pickerPopup then pickerPopup:Destroy(); pickerPopup = nil end
        end)

        local function apply()
            local c = Color3.fromHSV(h, s, v)
            S[key] = { math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5) }
            sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            cur.Position = UDim2.fromScale(s, 1 - v)
            refresh()
        end
        apply()

        local dSv, dHue = false, false
        sv.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dSv = true end end)
        hue.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dHue = true end end)
        local c1 = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dSv, dHue = false, false end end)
        local c2 = UIS.InputChanged:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            if dSv then
                s = math.clamp((i.Position.X - sv.AbsolutePosition.X)/sv.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((i.Position.Y - sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y, 0, 1)
                apply()
            elseif dHue then
                h = math.clamp((i.Position.X - hue.AbsolutePosition.X)/hue.AbsoluteSize.X, 0, 1)
                apply()
            end
        end)
        p.Destroying:Connect(function() c1:Disconnect(); c2:Disconnect() end)
        Maid:Inst(p)
    end))
    register(f, name, tab, refresh)
end

Maid:Conn(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = searchBox.Text:lower()
    for _, e in ipairs(elements) do
        e.inst.Visible = (q == "") or (e.label:find(q, 1, true) ~= nil)
    end
end))

--==============================================================
-- 7b. БЫСТРАЯ ПАНЕЛЬ
--==============================================================
refreshQuick = function()
    for _, ch in ipairs(quickPanel:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    quickRows = {}
    for _, key in ipairs(S.Favorites) do
        local data = bindMap[key]
        if data then
            local b = Instance.new("TextButton", quickPanel)
            b.Size = UDim2.new(1, 0, 0, 22)
            b.BackgroundColor3 = SUNK; b.BackgroundTransparency = 0.2
            b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false
            round(b, 6)
            local dt = Instance.new("Frame", b)
            dt.Size = UDim2.fromOffset(6, 6); dt.Position = UDim2.fromOffset(8, 8)
            dt.BorderSizePixel = 0; round(dt, 3)
            local lb = txt(b, tr(data.name), 11, TXT_DIM)
            lb.Size = UDim2.new(1, -26, 1, 0); lb.Position = UDim2.fromOffset(20, 0)
            local function upd()
                local on = S[key]
                dt.BackgroundColor3 = on and accentOf() or Color3.fromRGB(70,74,88)
                lb.TextColor3 = on and TXT or TXT_DIM
                lb.Text = tr(data.name)
            end
            upd()
            b.MouseButton1Click:Connect(function()
                S[key] = not S[key]
                pcall(data.refresh)
                if data.cb then safe(data.name, data.cb, S[key]) end
                upd()
                notify((S[key] and "[+] " or "[-] ") .. tr(data.name))
            end)
            table.insert(quickRows, { upd = upd })
        end
    end
    updateQuick()
end

--==============================================================
-- 8. УТИЛИТЫ
--==============================================================
local function keyMatches(input, str)
    if not str or str == "" then return false end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode.Name == str
    end
    return input.UserInputType.Name == str
end
local function char() return LP.Character end
local function hrp() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p)
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return (c and h and h.Health > 0) and true or false, c, h
end
-- ОПТ 5: вместо линейного обхода — хеш-мапа с ленивой пересборкой.
-- Кеш по самой таблице (weak keys), инвалидация по длине списка.
local listSets = setmetatable({}, { __mode = "k" })
local function listSet(list)
    local c = listSets[list]
    if not c or c.n ~= #list then
        local map = {}
        for _, n in ipairs(list) do map[tostring(n):lower()] = true end
        c = { n = #list, map = map }
        listSets[list] = c
    end
    return c.map
end
local function inList(list, name)
    if #list == 0 then return false end
    return listSet(list)[name:lower()] == true
end
local function isFriend(p) return inList(S.Friends, p.Name) end
local function isPrio(p) return inList(S.Prio, p.Name) end
local function isEnemy(p)
    if isFriend(p) then return false end
    if S.TeamCheck and p.Team == LP.Team then return false end
    return true
end

--==============================================================
-- 9. HITBOX
--==============================================================
local original = {}
local function restoreHitbox(full)
    for part, o in pairs(original) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = o.Transparency
                part.BrickColor   = o.BrickColor
                part.Material     = o.Material
                if full then part.Size = o.Size; part.CanCollide = o.CanCollide end
            end)
        end
    end
    if full then original = {} end
end
local function tickHitbox()
    if not S.HitboxOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isEnemy(p) then
            local ok, c = alive(p)
            local part = ok and c:FindFirstChild("HumanoidRootPart")
            if part then
                if not original[part] then
                    original[part] = { Size = part.Size, Transparency = part.Transparency,
                        BrickColor = part.BrickColor, Material = part.Material,
                        CanCollide = part.CanCollide }
                end
                part.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
                part.CanCollide = false
                if S.HitboxGlow then
                    part.Transparency = 0.7
                    part.BrickColor = BrickColor.new("Institutional white")
                    part.Material = Enum.Material.Neon
                end
            end
        end
    end
end

--==============================================================
-- 10. ESP
--==============================================================
local espCache = {}
local sizeCache = setmetatable({}, { __mode = "k" })
local BONES_R15 = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}
local BONES_R6 = {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
    {"Torso","Left Leg"}, {"Torso","Right Leg"},
}

local function newLine(parent)
    local f = Instance.new("Frame", parent)
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BorderSizePixel = 0; f.Visible = false
    f.Size = UDim2.fromOffset(0, 1)
    return f
end
local function drawLine(f, a, b, col, thick)
    local d = b - a
    f.Size = UDim2.fromOffset(d.Magnitude, thick or 1)
    f.Position = UDim2.fromOffset((a.X + b.X)/2, (a.Y + b.Y)/2)
    f.Rotation = math.deg(math.atan2(d.Y, d.X))
    f.BackgroundColor3 = col
    f.Visible = true
end

local function makeEsp(p)
    local o = { bones = {} }
    o.holder = Instance.new("Frame", espGui)
    o.holder.BackgroundTransparency = 1; o.holder.Size = UDim2.fromScale(1,1)
    o.box = Instance.new("Frame", o.holder)
    o.box.BackgroundTransparency = 1; o.box.Visible = false
    o.boxStroke = Instance.new("UIStroke", o.box); o.boxStroke.Thickness = 1.4
    o.hpBg = Instance.new("Frame", o.holder)
    o.hpBg.BackgroundColor3 = BLACK; o.hpBg.BorderSizePixel = 0; o.hpBg.Visible = false
    o.hp = Instance.new("Frame", o.hpBg)
    o.hp.AnchorPoint = Vector2.new(0,1); o.hp.Position = UDim2.fromScale(0,1)
    o.hp.BorderSizePixel = 0
    o.label = Instance.new("TextLabel", o.holder)
    o.label.Size = UDim2.fromOffset(200, 14)
    o.label.BackgroundTransparency = 1; o.label.Visible = false
    o.label.Font = FONT; o.label.TextSize = 11; o.label.TextStrokeTransparency = 0.3
    o.tracer = newLine(o.holder)
    o.arrow = Instance.new("Frame", o.holder)
    o.arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    o.arrow.Size = UDim2.fromOffset(10, 3)
    o.arrow.BorderSizePixel = 0; o.arrow.Visible = false
    o.chams = Instance.new("Highlight", espGui)
    o.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    o.chams.FillTransparency = 0.6; o.chams.Enabled = false
    for i = 1, 14 do o.bones[i] = newLine(o.holder) end
    espCache[p] = o
    return o
end
local function hideEspFor(o)
    o.box.Visible = false; o.hpBg.Visible = false; o.label.Visible = false
    o.tracer.Visible = false; o.arrow.Visible = false; o.chams.Enabled = false
    for _, b in ipairs(o.bones) do b.Visible = false end
end
local function clearEsp(p)
    local o = espCache[p]
    if not o then return end
    pcall(function() o.holder:Destroy(); o.chams:Destroy() end)
    espCache[p] = nil
end
Maid:Conn(Players.PlayerRemoving:Connect(clearEsp))

local function charSize(c)
    local s = sizeCache[c]
    if not s then
        local _, sz = c:GetBoundingBox(); s = sz; sizeCache[c] = sz
    end
    return s
end

local function updateEsp()
    if not S.EspOn then
        for _, o in pairs(espCache) do hideEspFor(o) end
        return
    end
    local vp = Camera.ViewportSize
    local cf = Camera.CFrame
    local camPos, look = cf.Position, cf.LookVector
    local center = Vector2.new(vp.X/2, vp.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local o = espCache[p] or makeEsp(p)
            local ok, c, h = alive(p)
            local root = ok and c:FindFirstChild("HumanoidRootPart")
            if not root then hideEspFor(o) continue end

            local delta = root.Position - camPos
            local dist = delta.Magnitude
            if not isEnemy(p) and not isFriend(p) then hideEspFor(o) continue end
            if dist > S.EspDistance then hideEspFor(o) continue end

            local dot = look:Dot(delta.Unit)
            local behind = dot < 0
            local col = isFriend(p) and C3(S.ColFriend)
                or ((S.TeamCheck and p.Team == LP.Team) and C3(S.ColAlly) or C3(S.ColEnemy))

            if behind then
                hideEspFor(o)
                if S.EspArrows then
                    local rel = cf:PointToObjectSpace(root.Position)
                    local ang = math.atan2(rel.X, rel.Z)
                    local rad = math.min(vp.X, vp.Y) * 0.35
                    local px = center.X + math.sin(ang) * rad
                    local py = center.Y + math.cos(ang) * rad * 0.6
                    o.arrow.Position = UDim2.fromOffset(px, py)
                    o.arrow.Rotation = math.deg(ang)
                    o.arrow.BackgroundColor3 = col
                    o.arrow.Visible = true
                end
                continue
            end
            o.arrow.Visible = false

            local sz = charSize(c)
            local topW, visT = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, sz.Y/2, 0))
            local botW = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, sz.Y/2, 0))
            if not visT then hideEspFor(o) continue end

            local ht = math.abs(topW.Y - botW.Y)
            local w  = ht * 0.55
            local minX, minY = topW.X - w/2, math.min(topW.Y, botW.Y)

            if S.EspBox then
                o.box.Position = UDim2.fromOffset(minX, minY)
                o.box.Size = UDim2.fromOffset(w, ht)
                o.boxStroke.Color = col; o.box.Visible = true
            else o.box.Visible = false end

            if S.EspHealth then
                local pct = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
                o.hpBg.Position = UDim2.fromOffset(minX - 5, minY)
                o.hpBg.Size = UDim2.fromOffset(3, ht)
                o.hp.Size = UDim2.fromScale(1, pct)
                o.hp.BackgroundColor3 = Color3.fromRGB(255*(1-pct), 255*pct, 255*pct*0.4)
                o.hpBg.Visible = true
            else o.hpBg.Visible = false end

            if S.EspName then
                local wep = ""
                if S.EspWeapon then
                    local tool = c:FindFirstChildOfClass("Tool")
                    if tool then wep = " {" .. tool.Name .. "}" end
                end
                o.label.Text = string.format("%s%s [%dm]%s",
                    isPrio(p) and "* " or "", p.Name, math.floor(dist), wep)
                o.label.TextColor3 = col
                o.label.Position = UDim2.fromOffset(minX + w/2 - 100, minY - 15)
                o.label.Visible = true
            else o.label.Visible = false end

            if S.EspTracer then
                drawLine(o.tracer, Vector2.new(vp.X/2, vp.Y),
                    Vector2.new(minX + w/2, minY + ht), col, 1)
            else o.tracer.Visible = false end

            if S.EspSkeleton then
                local bones = c:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
                for i, pair in ipairs(bones) do
                    local a, b = c:FindFirstChild(pair[1]), c:FindFirstChild(pair[2])
                    local line = o.bones[i]
                    if a and b and line then
                        local pa, va = Camera:WorldToViewportPoint(a.Position)
                        local pb, vb = Camera:WorldToViewportPoint(b.Position)
                        if va and vb then
                            drawLine(line, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), col, 1)
                        else line.Visible = false end
                    elseif line then line.Visible = false end
                end
                for i = #bones + 1, #o.bones do o.bones[i].Visible = false end
            else
                for _, b in ipairs(o.bones) do b.Visible = false end
            end

            o.chams.Adornee = S.EspChams and c or nil
            o.chams.Enabled = S.EspChams
            o.chams.FillColor = col; o.chams.OutlineColor = col
        end
    end
end

--==============================================================
-- 11. ITEM ESP
--==============================================================
local itemList, itemDots = {}, {}
local function scanItems()
    itemList = {}
    if not S.ItemEspOn then return end
    if S.ItemTag ~= "" then
        for _, tag in ipairs(string.split(S.ItemTag, ",")) do
            tag = tag:gsub("^%s+", ""):gsub("%s+$", "")
            if tag ~= "" then
                for _, inst in ipairs(CS:GetTagged(tag)) do
                    if inst:IsA("BasePart") or inst:IsA("Model") then
                        table.insert(itemList, inst)
                    end
                end
            end
        end
    end
    if S.ItemFilter ~= "" then
        local names = {}
        for _, n in ipairs(string.split(S.ItemFilter, ",")) do
            n = n:gsub("^%s+", ""):gsub("%s+$", ""):lower()
            if n ~= "" then names[#names+1] = n end
        end
        if #names > 0 then
            for _, inst in ipairs(Workspace:GetDescendants()) do
                if inst:IsA("BasePart") or inst:IsA("Model") then
                    local ln = inst.Name:lower()
                    for _, n in ipairs(names) do
                        if ln:find(n, 1, true) then
                            table.insert(itemList, inst); break
                        end
                    end
                end
            end
        end
    end
end

local function getDot(i)
    local d = itemDots[i]
    if not d then
        d = { f = Instance.new("Frame", espGui) }
        d.f.Size = UDim2.fromOffset(4, 4)
        d.f.AnchorPoint = Vector2.new(0.5, 0.5)
        d.f.BackgroundColor3 = WHITE; d.f.BorderSizePixel = 0
        d.l = txt(d.f, "", 10, WHITE)
        d.l.Size = UDim2.fromOffset(160, 12); d.l.Position = UDim2.fromOffset(-78, -14)
        d.l.TextXAlignment = Enum.TextXAlignment.Center
        d.l.TextStrokeTransparency = 0.4
        itemDots[i] = d
    end
    return d
end

local function updateItems()
    if not S.ItemEspOn then
        for _, d in pairs(itemDots) do d.f.Visible = false end
        return
    end
    local camPos = Camera.CFrame.Position
    local shown = 0
    for _, inst in ipairs(itemList) do
        if inst and inst.Parent then
            local pos = inst:IsA("Model")
                and (inst.PrimaryPart and inst.PrimaryPart.Position
                     or inst:GetPivot().Position)
                or inst.Position
            local dist = (pos - camPos).Magnitude
            if dist <= S.ItemDistance then
                local sp, vis = Camera:WorldToViewportPoint(pos)
                if vis then
                    shown += 1
                    local d = getDot(shown)
                    d.f.Position = UDim2.fromOffset(sp.X, sp.Y)
                    d.l.Text = string.format("%s [%dm]", inst.Name, math.floor(dist))
                    d.f.Visible = true
                end
            end
        end
    end
    for i = shown + 1, #itemDots do itemDots[i].f.Visible = false end
end

--==============================================================
-- 12. AIM / TRIGGER
--==============================================================
local fovCircle = Instance.new("Frame", espGui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1; fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
uiTmp = Instance.new("UIStroke", fovCircle)
uiTmp.Color = WHITE; uiTmp.Thickness = 1; uiTmp.Transparency = 0.35

local trigMark = Instance.new("Frame", espGui)
trigMark.AnchorPoint = Vector2.new(0.5, 0.5)
trigMark.Size = UDim2.fromOffset(6, 6)
trigMark.BackgroundTransparency = 1; trigMark.BorderSizePixel = 0
trigMark.Visible = false
local trigStroke = Instance.new("UIStroke", trigMark)
trigStroke.Color = WHITE; trigStroke.Thickness = 1

--==============================================================
-- 11b. РАДАР / ТАБЛИЦА ВРАГОВ / СТАТИСТИКА
--==============================================================
local stats = { start = os.clock(), fpsSum = 0, fpsN = 0, locks = 0, kills = 0 }

local radar = Instance.new("Frame", espGui)
radar.Size = UDim2.fromOffset(S.RadarSize, S.RadarSize)
radar.AnchorPoint = Vector2.new(1, 0)
radar.Position = UDim2.new(1, -16, 0, 16)
radar.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
radar.BackgroundTransparency = 0.35
radar.BorderSizePixel = 0; radar.Visible = false
uiTmp = Instance.new("UICorner", radar)
uiTmp.CornerRadius = UDim.new(1, 0)
uiTmp = Instance.new("UIStroke", radar)
uiTmp.Thickness = 1; uiTmp.Transparency = 0.45
accent(uiTmp, "Color")
uiTmp = Instance.new("Frame", radar)
uiTmp.Size = UDim2.new(1, 0, 0, 1); uiTmp.Position = UDim2.new(0, 0, 0.5, 0)
uiTmp.BackgroundColor3 = LINE; uiTmp.BackgroundTransparency = 0.85; uiTmp.BorderSizePixel = 0
uiTmp = Instance.new("Frame", radar)
uiTmp.Size = UDim2.new(0, 1, 1, 0); uiTmp.Position = UDim2.new(0.5, 0, 0, 0)
uiTmp.BackgroundColor3 = LINE; uiTmp.BackgroundTransparency = 0.85; uiTmp.BorderSizePixel = 0
uiTmp = Instance.new("Frame", radar)
uiTmp.Size = UDim2.fromOffset(5, 5); uiTmp.AnchorPoint = Vector2.new(0.5, 0.5)
uiTmp.Position = UDim2.fromScale(0.5, 0.5); uiTmp.BorderSizePixel = 0
round(uiTmp, 3); accent(uiTmp)

local radarDots = {}
local function radarDot(p)
    local d = radarDots[p]
    if d and d.Parent then return d end
    d = Instance.new("Frame", radar)
    d.Size = UDim2.fromOffset(6, 6)
    d.AnchorPoint = Vector2.new(0.5, 0.5)
    d.BorderSizePixel = 0
    round(d, 3)
    radarDots[p] = d
    return d
end

local function updateRadar()
    if not S.RadarOn then
        if radar.Visible then radar.Visible = false end
        for _, d in pairs(radarDots) do if d.Parent then d.Visible = false end end
        return
    end
    local size = math.clamp(S.RadarSize, 100, 340)
    radar.Size = UDim2.fromOffset(size, size)
    radar.Visible = true
    local me = hrp()
    if not me then return end
    local range = math.max(S.RadarRange, 20)
    local half = size / 2 - 8
    local yaw = 0
    if S.RadarRotate then
        local lv = Camera.CFrame.LookVector
        yaw = math.atan2(lv.X, lv.Z)
    end
    local sy, cy = math.sin(-yaw), math.cos(-yaw)
    local seen = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ok, c = alive(p)
            local r = ok and c:FindFirstChild("HumanoidRootPart")
            if r and (isEnemy(p) or isFriend(p) or not S.TeamCheck) then
                local off = r.Position - me.Position
                local x, z = off.X, off.Z
                if S.RadarRotate then
                    x, z = x * cy - z * sy, x * sy + z * cy
                end
                if math.sqrt(x * x + z * z) <= range then
                    local dot = radarDot(p)
                    seen[p] = true
                    dot.Position = UDim2.new(0.5, (x / range) * half, 0.5, (-z / range) * half)
                    dot.BackgroundColor3 = isFriend(p) and C3(S.ColFriend)
                        or (isEnemy(p) and C3(S.ColEnemy) or C3(S.ColAlly))
                    dot.Visible = true
                end
            end
        end
    end
    for p, d in pairs(radarDots) do
        if not seen[p] then
            if d.Parent then d.Visible = false end
            if not p.Parent then pcall(function() d:Destroy() end); radarDots[p] = nil end
        end
    end
end

--// таблица врагов сбоку
local espList = Instance.new("Frame", espGui)
espList.Size = UDim2.fromOffset(252, 0)
espList.AutomaticSize = Enum.AutomaticSize.Y
espList.Position = UDim2.fromOffset(16, 120)
espList.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
espList.BackgroundTransparency = 0.35
espList.BorderSizePixel = 0; espList.Visible = false
round(espList, 8)
uiTmp = Instance.new("UIStroke", espList)
uiTmp.Thickness = 1; uiTmp.Transparency = 0.55
accent(uiTmp, "Color")
uiTmp = Instance.new("UIListLayout", espList)
uiTmp.Padding = UDim.new(0, 1)
pad(espList, 8, 8, 6, 6)
local elHead = txt(espList, "ВРАГИ", 10, TXT_DIM)
elHead.Size = UDim2.new(1, 0, 0, 14); elHead.Font = FONT_B

local espRows = {}
local function espRow(i)
    if espRows[i] then return espRows[i] end
    local f = Instance.new("Frame", espList)
    f.Size = UDim2.new(1, 0, 0, 15); f.BackgroundTransparency = 1
    local nm = txt(f, "", 11, TXT); nm.Size = UDim2.new(0.44, 0, 1, 0)
    nm.TextTruncate = Enum.TextTruncate.AtEnd
    local hp = txt(f, "", 11, TXT_DIM)
    hp.Size = UDim2.new(0.17, 0, 1, 0); hp.Position = UDim2.fromScale(0.44, 0)
    local ds = txt(f, "", 11, TXT_DIM)
    ds.Size = UDim2.new(0.15, 0, 1, 0); ds.Position = UDim2.fromScale(0.61, 0)
    local wp = txt(f, "", 11, TXT_DIM)
    wp.Size = UDim2.new(0.24, 0, 1, 0); wp.Position = UDim2.fromScale(0.76, 0)
    wp.TextTruncate = Enum.TextTruncate.AtEnd
    espRows[i] = { f = f, nm = nm, hp = hp, ds = ds, wp = wp }
    return espRows[i]
end

local function updateEspList()
    if not S.EspListOn then
        if espList.Visible then espList.Visible = false end
        return
    end
    espList.Visible = true
    local me = hrp()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (isEnemy(p) or isFriend(p)) then
            local ok, c, h = alive(p)
            local r = ok and c:FindFirstChild("HumanoidRootPart")
            if r and h then
                local tool = c:FindFirstChildOfClass("Tool")
                table.insert(list, {
                    name = p.Name,
                    hp = math.floor(h.Health),
                    dist = me and (r.Position - me.Position).Magnitude or 0,
                    wep = tool and tool.Name or "-",
                    friend = isFriend(p),
                })
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    local maxN = math.clamp(S.EspListMax, 3, 16)
    elHead.Text = (S.Lang == "EN" and "ENEMIES: " or "ВРАГИ: ") .. #list
    for i = 1, maxN do
        local rw = espRow(i)
        local e = list[i]
        if e then
            rw.f.Visible = true
            rw.nm.Text = e.name
            rw.nm.TextColor3 = e.friend and C3(S.ColFriend) or TXT
            rw.hp.Text = e.hp .. " HP"
            rw.ds.Text = math.floor(e.dist) .. "m"
            rw.wp.Text = e.wep
        else rw.f.Visible = false end
    end
    for i = maxN + 1, #espRows do espRows[i].f.Visible = false end
end

local aiming, target, lastShot, seenAt = false, nil, 0, nil

local function mousePos()
    local m = UIS:GetMouseLocation(); return Vector2.new(m.X, m.Y)
end
local function aimOrigin()
    if S.AimAnchor == "Center" then
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X/2, vp.Y/2)
    end
    return mousePos()
end
local function isVisible(part)
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    pr.FilterDescendantsInstances = { char(), Camera }
    local o = Camera.CFrame.Position
    local r = Workspace:Raycast(o, part.Position - o, pr)
    return (not r) or r.Instance:IsDescendantOf(part.Parent)
end
local function aimPos(part)
    if S.AimPredict > 0 then
        local v = part.AssemblyLinearVelocity or Vector3.zero
        return part.Position + v * S.AimPredict
    end
    return part.Position
end

local function findTarget(radius, checkVis, partName)
    local origin = aimOrigin()
    local camPos = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isEnemy(p) then
            local ok, c, h = alive(p)
            local part = ok and c:FindFirstChild(partName or S.AimPart)
            if ok and c and S.AimFallback then
                local function usable(pp)
                    if not pp then return false end
                    if not checkVis then return true end
                    return isVisible(pp)
                end
                if not usable(part) then
                    for _, nm in ipairs({ "UpperTorso", "Torso", "HumanoidRootPart",
                        "LowerTorso", "Head" }) do
                        local alt = c:FindFirstChild(nm)
                        if usable(alt) then part = alt break end
                    end
                end
            end
            if part then
                local sp, vis = Camera:WorldToViewportPoint(aimPos(part))
                if vis then
                    local screenD = (Vector2.new(sp.X, sp.Y) - origin).Magnitude
                    if screenD <= radius and (not checkVis or isVisible(part)) then
                        local score
                        if S.AimPriority == "Distance" then
                            score = (part.Position - camPos).Magnitude
                        elseif S.AimPriority == "Health" then
                            score = h.Health
                        elseif S.AimPriority == "Angle" then
                            score = screenD * 0.5 + (part.Position - camPos).Magnitude * 0.1
                        else
                            score = screenD
                        end
                        if isPrio(p) then score = score * 0.35 end
                        if score < bestScore then best, bestScore = part, score end
                    end
                end
            end
        end
    end
    return best
end

local function targetValid(part)
    if not part or not part.Parent then return false end
    local h = part.Parent:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    local sp, vis = Camera:WorldToViewportPoint(part.Position)
    if not vis then return false end
    if S.AimAutoSwitch and S.AimVisible and not isVisible(part) then return false end
    return (Vector2.new(sp.X, sp.Y) - aimOrigin()).Magnitude <= S.AimFOV * 1.5
end

local function shoot()
    if mouse1click then pcall(mouse1click) return true end
    if mouse1press and mouse1release then
        pcall(function() mouse1press(); task.wait(0.02); mouse1release() end)
        return true
    end
    if VIM then
        local m = mousePos()
        pcall(function()
            VIM:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
            task.wait(0.02)
            VIM:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
        end)
        return true
    end
    return false
end

local function triggerHit()
    local mp = mousePos()
    local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    pr.FilterDescendantsInstances = { char(), Camera }
    local res = Workspace:Raycast(ray.Origin, ray.Direction * 2000, pr)
    if res and res.Instance then
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local plr = Players:GetPlayerFromCharacter(model)
            local h = model:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and (not plr or (plr ~= LP and isEnemy(plr))) then
                return true
            end
        end
    end
    if S.TriggerFOV > 0 and findTarget(S.TriggerFOV, S.TriggerVisible, S.AimPart) then
        return true
    end
    return false
end

local function tickTrigger()
    local hitNow = S.TriggerOn and triggerHit() or false

    trigMark.Visible = S.TriggerOn and S.TriggerMark
    if trigMark.Visible then
        local mp = mousePos()
        trigMark.Position = UDim2.fromOffset(mp.X, mp.Y)
        trigStroke.Transparency = hitNow and 0 or 0.7
        trigMark.Size = UDim2.fromOffset(hitNow and 10 or 6, hitNow and 10 or 6)
    end
    if not S.TriggerOn then seenAt = nil return end

    if not hitNow then seenAt = nil return end
    if not seenAt then seenAt = tick() end
    if tick() - seenAt < S.TriggerReaction / 1000 then return end

    local jitter = 1 + (math.random() - 0.5) * 2 * (S.TriggerRandom / 100)
    if tick() - lastShot < S.TriggerDelay * jitter then return end
    lastShot = tick()
    shoot()
end

--==============================================================
-- 13. MOVEMENT
--==============================================================
local defaults = { ws = 16, jp = 50, jh = 7.2, ujp = false }
local function captureDefaults()
    local h = hum(); if not h then return end
    defaults.ws = h.WalkSpeed; defaults.jp = h.JumpPower
    defaults.jh = h.JumpHeight; defaults.ujp = h.UseJumpPower
end
local function applySpeed()
    local h = hum(); if not h then return end
    if S.SpeedOn and S.SpeedMode == "WalkSpeed" and not S.AutoSprint then
        h.WalkSpeed = S.SpeedVal
    elseif not S.SpeedOn then
        h.WalkSpeed = defaults.ws
    end
end
local function applyJump()
    local h = hum(); if not h then return end
    if S.JumpOn then
        h.UseJumpPower = true; h.JumpPower = S.JumpVal
    else
        h.UseJumpPower = defaults.ujp
        if defaults.ujp then h.JumpPower = defaults.jp else h.JumpHeight = defaults.jh end
    end
end

local flyBV, flyBG, flyAP, flyAO, flyAtt, noclipCache = nil, nil, nil, nil, nil, {}
local function stopFly()
    for _, v in ipairs({ flyBV, flyBG, flyAP, flyAO, flyAtt }) do
        if v then pcall(function() v:Destroy() end) end
    end
    flyBV, flyBG, flyAP, flyAO, flyAtt = nil, nil, nil, nil, nil
    local h = hum(); if h then h.PlatformStand = false end
end
local function startFly()
    local r = hrp(); if not r then return end
    stopFly()
    if S.FlyMode == "BodyVelocity" then
        flyBV = Instance.new("BodyVelocity", r)
        flyBV.MaxForce = Vector3.one * 9e9; flyBV.Velocity = Vector3.zero
        flyBG = Instance.new("BodyGyro", r)
        flyBG.MaxTorque = Vector3.one * 9e9; flyBG.P = 9e4
    elseif S.FlyMode == "AlignPosition" then
        flyAtt = Instance.new("Attachment", r)
        flyAP = Instance.new("AlignPosition", r)
        flyAP.Attachment0 = flyAtt; flyAP.Mode = Enum.PositionAlignmentMode.OneAttachment
        flyAP.MaxForce = 9e9; flyAP.Responsiveness = 60
        flyAP.Position = r.Position
        flyAO = Instance.new("AlignOrientation", r)
        flyAO.Attachment0 = flyAtt; flyAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        flyAO.MaxTorque = 9e9; flyAO.Responsiveness = 60
    end
end
local function flyDir()
    local d, cf = Vector3.zero, Camera.CFrame
    if UIS:IsKeyDown(Enum.KeyCode.W) then d += cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d += cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d -= Vector3.yAxis end
    return d.Magnitude > 0 and d.Unit or Vector3.zero
end
local function tickFly(dt)
    if not S.FlyOn then return end
    local r = hrp(); if not r then return end
    local dir = flyDir()
    if S.FlyMode == "CFrame" then
        local h = hum(); if h then h.PlatformStand = true end
        r.AssemblyLinearVelocity = Vector3.zero
        r.CFrame = r.CFrame + dir * S.FlySpeed * dt
    elseif S.FlyMode == "AlignPosition" then
        if not flyAP or flyAP.Parent ~= r then startFly() end
        if flyAP then
            flyAP.Position = r.Position + dir * S.FlySpeed * 0.12
            flyAO.CFrame = CFrame.new(Vector3.zero, Camera.CFrame.LookVector)
        end
    else
        if not flyBV or flyBV.Parent ~= r then startFly() end
        if flyBV then
            flyBV.Velocity = dir * S.FlySpeed
            flyBG.CFrame = Camera.CFrame
        end
    end
end

local function tickNoclip()
    local c = char(); if not c then return end
    if S.NoclipOn then
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                noclipCache[part] = true; part.CanCollide = false
            end
        end
    elseif next(noclipCache) then
        for part in pairs(noclipCache) do
            if part and part.Parent then part.CanCollide = true end
        end
        noclipCache = {}
    end
end

local lastSafe = nil
local function tickSafety(dt)
    local r = hrp(); if not r then return end
    local vel = r.AssemblyLinearVelocity
    if S.AntiFling and vel.Magnitude > 300 and not S.FlyOn then
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end
    if S.AntiVoid then
        if r.Position.Y < S.VoidY and lastSafe then
            r.CFrame = CFrame.new(lastSafe)
            r.AssemblyLinearVelocity = Vector3.zero
            notify("ANTI-VOID: ВОЗВРАТ")
        elseif r.Position.Y > S.VoidY + 20 and vel.Magnitude < 120 then
            lastSafe = r.Position + Vector3.new(0, 3, 0)
        end
    end
end

local function tickMoveSpeed(dt)
    local h, r = hum(), hrp()
    if not h or not r then return end
    if not S.SpeedOn then return end
    local moving = h.MoveDirection.Magnitude > 0
    if S.SpeedMode == "CFrame" then
        if h.WalkSpeed ~= defaults.ws then h.WalkSpeed = defaults.ws end
        if moving then
            local extra = math.max(S.SpeedVal - defaults.ws, 0)
            r.CFrame = r.CFrame + h.MoveDirection * extra * dt
        end
    else
        if S.AutoSprint then
            h.WalkSpeed = moving and S.SpeedVal or defaults.ws
        elseif math.abs(h.WalkSpeed - S.SpeedVal) > 0.1 then
            h.WalkSpeed = S.SpeedVal
        end
    end
end

local function teleportTo(pos)
    local r = hrp(); if not r then return end
    local goal = CFrame.new(pos + Vector3.new(0, 3, 0))
    if S.TpTween then
        local t = math.clamp(S.TpTweenTime, 0.05, 5)
        TS:Create(r, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = goal }):Play()
    else
        r.CFrame = goal
    end
end

--// гравитация
local defaultGravity = Workspace.Gravity
local function applyGravity()
    if S.GravityOn then
        Workspace.Gravity = math.clamp(S.GravityVal, 0, 500)
    else
        Workspace.Gravity = defaultGravity
    end
end

--// платформа под ногами (ходьба по воздуху)
local platPart
local function tickPlatform()
    if not S.PlatformOn then
        if platPart then pcall(function() platPart:Destroy() end); platPart = nil end
        return
    end
    local r = hrp(); if not r then return end
    if not platPart or not platPart.Parent then
        platPart = Instance.new("Part")
        platPart.Name = "ConesPlatform"
        platPart.Size = Vector3.new(7, 1, 7)
        platPart.Anchored = true; platPart.CanCollide = true
        platPart.Transparency = 0.85
        platPart.Material = Enum.Material.Neon
        platPart.Color = accentOf()
        platPart.Parent = Workspace
        Maid:Inst(platPart)
    end
    platPart.CFrame = CFrame.new(r.Position - Vector3.new(0, 3.6, 0))
end

--// PANIC — всё выключить и спрятать
local function panic()
    for _, k in ipairs({ "HitboxOn", "EspOn", "ItemEspOn", "RadarOn", "EspListOn",
        "AimOn", "TriggerOn", "SpeedOn", "JumpOn", "InfJump", "SpamJump",
        "FlyOn", "NoclipOn", "GravityOn", "PlatformOn", "QuickPanel", "Watermark" }) do
        S[k] = false
    end
    pcall(restoreHitbox, true)
    pcall(stopFly)
    pcall(tickNoclip)
    pcall(applySpeed); pcall(applyJump); pcall(applyGravity); pcall(tickPlatform)
    for p in pairs(espCache) do pcall(clearEsp, p) end
    pcall(updateRadar); pcall(updateEspList); pcall(updateItems)
    for _, d in pairs(bindMap) do pcall(d.refresh) end
    if refreshQuick then pcall(refreshQuick) end
    pcall(function() espGui.Enabled = false end)
    quickPanel.Visible = false
    wm.Visible = false
    main.Visible = false
end

Maid:Conn(UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))
Maid:Conn(LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
    end
end))
Maid:Conn(LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    sizeCache[c] = nil
    captureDefaults()
    if S.SpeedOn then applySpeed() end
    if S.JumpOn then applyJump() end
    if S.FlyOn then startFly() end
end))

--==============================================================
-- 14. ЦИКЛЫ
--==============================================================
local fpsAcc, fpsCount, fpsVal = 0, 0, 0
local espAcc = 0

Maid:Conn(RunService.RenderStepped:Connect(function(dt)
    fpsAcc += dt; fpsCount += 1
    if fpsAcc >= 0.5 then
        fpsVal = math.floor(fpsCount / fpsAcc); fpsAcc, fpsCount = 0, 0
        stats.fpsSum += fpsVal; stats.fpsN += 1

        -- ОПТ 1: watermark и пинг теперь 2 раза/сек, а не каждый кадр
        if wm.Visible ~= S.Watermark then wm.Visible = S.Watermark end
        if S.Watermark then
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            wmText.Text = string.format("CONES | %s | %d FPS | %d MS", LP.Name, fpsVal, ping)
        end
    end

    espAcc += dt
    if espAcc >= 1 / math.max(S.EspFps, 1) then
        espAcc = 0
        safe("esp", updateEsp)
        safe("items", updateItems)
        safe("radar", updateRadar)
        -- ОПТ 3: updateEspList вынесен в отдельный цикл 0.4с (ниже)
    end

    safe("fly", tickFly, dt)
    safe("speed", tickMoveSpeed, dt)
    safe("trigger", tickTrigger)

    -- ОПТ 2: пишем Size/Position только когда значение реально меняется
    local showFov = S.ShowFOV and S.AimOn
    if fovCircle.Visible ~= showFov then fovCircle.Visible = showFov end
    if showFov then
        local d = S.AimFOV * 2
        if fovCircle.Size.X.Offset ~= d then
            fovCircle.Size = UDim2.fromOffset(d, d)
        end
        local o = aimOrigin()
        if fovCircle.Position.X.Offset ~= o.X or fovCircle.Position.Y.Offset ~= o.Y then
            fovCircle.Position = UDim2.fromOffset(o.X, o.Y)
        end
    end

    -- аим также работает, пока зажата ЛКМ (если включено)
    local firing = false
    if S.AimOnFire then
        firing = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end
    local aimActive = aiming or firing

    if S.AimOn and aimActive then
        -- автосмена: цель умерла / ушла — берём следующую
        if target and target.Parent then
            local th = target.Parent:FindFirstChildOfClass("Humanoid")
            if not th or th.Health <= 0 then
                stats.kills += 1
                target = nil
            end
        end
        if not (S.StickyAim and targetValid(target)) then
            local newT = findTarget(S.AimFOV, S.AimVisible, S.AimPart)
            if newT and newT ~= target then stats.locks += 1 end
            target = newT
        end
        if target and target.Parent then
            local aimAt = aimPos(target)
            if S.AimHumanize then
                local j = math.max(S.AimJitter, 0) * 0.01
                local tt = os.clock() * 6.5
                aimAt = aimAt + Vector3.new(
                    math.sin(tt) * j,
                    math.cos(tt * 1.4) * j * 0.7,
                    math.sin(tt * 0.8) * j)
            end
            local goal = CFrame.new(Camera.CFrame.Position, aimAt)
            if S.AimLock then
                Camera.CFrame = goal
            else
                local ang = math.acos(math.clamp(
                    Camera.CFrame.LookVector:Dot(
                        (aimAt - Camera.CFrame.Position).Unit), -1, 1))
                local sm = S.AimSmooth
                if S.AimSmartSmooth then
                    sm = sm * math.clamp(1 - ang / math.rad(60), 0.25, 1)
                end
                if S.AimHumanize then
                    -- кривая: плавный старт, быстрое доведение
                    local k = math.clamp(1 - ang / math.rad(45), 0, 1)
                    sm = sm * (0.5 + 0.5 * (k * k))
                    sm = sm * (0.9 + math.random() * 0.2)
                end
                Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(sm, 0.01, 1))
            end
        end
    elseif not aimActive and not aiming then
        target = nil
    end
end))

Maid:Thread(task.spawn(function()
    while task.wait(0.15) do
        if not HUB_ACTIVE then break end
        safe("hitbox", tickHitbox)
        safe("noclip", tickNoclip)
        safe("safety", tickSafety)
        safe("platform", tickPlatform)
        safe("quick", updateQuick)
        if S.JumpOn then
            local h = hum()
            if h and (not h.UseJumpPower or math.abs(h.JumpPower - S.JumpVal) > 0.1) then
                h.UseJumpPower = true; h.JumpPower = S.JumpVal
            end
        end
        if S.SpamJump then
            local h = hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end))

Maid:Thread(task.spawn(function()
    while task.wait(1.5) do
        if not HUB_ACTIVE then break end
        safe("scanItems", scanItems)
    end
end))

-- ОПТ 3: список игроков в UI — свой медленный цикл вместо ESP-частоты
Maid:Thread(task.spawn(function()
    while task.wait(0.4) do
        if not HUB_ACTIVE then break end
        if S.EspListOn then
            safe("esplist", updateEspList)
        elseif espList.Visible then
            espList.Visible = false
        end
    end
end))

Maid:Conn(UIS.InputBegan:Connect(function(input, processed)
    -- бинды не срабатывают во время ввода текста (чат, поиск, поля)
    if processed or UIS:GetFocusedTextBox() then return end
    for key, data in pairs(bindMap) do
        if S.Binds[key] and keyMatches(input, S.Binds[key]) then
            S[key] = not S[key]
            data.refresh()
            if data.cb then safe(data.name, data.cb, S[key]) end
            notify((S[key] and "[+] " or "[-] ") .. data.name)
        end
    end
    if keyMatches(input, S.KeyMenu) then
        main.Visible = not main.Visible
        pcall(function() espGui.Enabled = true end)
    elseif keyMatches(input, S.KeyWM) then
        S.Watermark = not S.Watermark; wm.Visible = S.Watermark
    elseif keyMatches(input, S.KeyAim) then
        aiming = true
        if S.AimOn and not S.StickyAim then
            target = findTarget(S.AimFOV, S.AimVisible, S.AimPart)
        end
    elseif keyMatches(input, S.KeyFly) then
        S.FlyOn = not S.FlyOn
        if S.FlyOn then startFly() else stopFly() end
        if bindMap.FlyOn then bindMap.FlyOn.refresh() end
        notify((S.FlyOn and "[+] " or "[-] ") .. "FLY")
    elseif keyMatches(input, S.KeyNoclip) then
        S.NoclipOn = not S.NoclipOn
        if bindMap.NoclipOn then bindMap.NoclipOn.refresh() end
        notify((S.NoclipOn and "[+] " or "[-] ") .. "NOCLIP")
    elseif keyMatches(input, S.KeyClickTP) then
        if Mouse.Target then teleportTo(Mouse.Hit.Position) end
    elseif keyMatches(input, S.KeyQuick) then
        S.QuickPanel = not S.QuickPanel
        if refreshQuick then refreshQuick() end
        updateQuick()
        notify((S.QuickPanel and "[+] " or "[-] ") .. "БЫСТРАЯ ПАНЕЛЬ")
    elseif keyMatches(input, S.KeyPanic) then
        panic()
        local mk = (S.KeyMenu ~= nil and S.KeyMenu ~= "") and S.KeyMenu or "кнопка CONES в углу"
        print("[CONES] PANIC — всё выключено, " .. mk .. " — вернуть меню")
    end
end))
Maid:Conn(UIS.InputEnded:Connect(function(input)
    if keyMatches(input, S.KeyAim) then aiming, target = false, nil end
end))

--==============================================================
-- СЕКЦИИ 15-18 ВЫНЕСЕНЫ В ФУНКЦИЮ:
-- в Luau лимит 200 локальных переменных на одну функцию
--==============================================================
local function BuildRest()

--==============================================================
-- 15. ПРОФИЛИ КОНФИГА
--==============================================================
local fileOk = (writefile and readfile and isfile) and true or false
local currentProfile = "default"
local refreshProfiles

local function ensureFolders()
    if not fileOk or not makefolder then return end
    pcall(function()
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        if not isfolder(PROFILES) then makefolder(PROFILES) end
    end)
end

local function applyConfig()
    for _, e in ipairs(elements) do
        if e.refresh then pcall(e.refresh) end
    end
    applyTransparency()
    applyAccent()
    applyScale()
    applyLang()
    applyGravity()
    if refreshQuick then pcall(refreshQuick) end
    updateQuick()
    captureDefaults()
    applySpeed(); applyJump()
    if S.FlyOn then startFly() else stopFly() end
    wm.Visible = S.Watermark
    if S.WinPos and S.WinPos[1] then
        main.Position = UDim2.fromOffset(S.WinPos[1], S.WinPos[2])
    end
    if S.WinSize and S.WinSize[1] then
        main.Size = UDim2.fromOffset(S.WinSize[1], S.WinSize[2])
        savedH = S.WinSize[2]
    end
    if S.LastTab and pages[S.LastTab] then selectTab(S.LastTab) end
    scanItems()
end

local function saveConfig(name)
    if not fileOk then notify("НЕТ ДОСТУПА К ФАЙЛАМ") return end
    ensureFolders()
    name = name or currentProfile
    S.WinPos  = { main.Position.X.Offset, main.Position.Y.Offset }
    S.WinSize = { main.Size.X.Offset, minimized and savedH or main.Size.Y.Offset }
    local ok = pcall(function()
        writefile(PROFILES .. "/" .. name .. ".json", HttpService:JSONEncode(S))
    end)
    notify(ok and ("СОХРАНЁН: " .. name) or "ОШИБКА СОХРАНЕНИЯ")
    if ok and refreshProfiles then refreshProfiles() end
end

local function loadConfig(name)
    if not fileOk then return false end
    name = name or currentProfile
    local path = PROFILES .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok = pcall(function()
        local data = HttpService:JSONDecode(readfile(path))
        for k, v in pairs(data) do if S[k] ~= nil then S[k] = v end end
    end)
    if ok then currentProfile = name end
    return ok
end

local function deleteProfile(name)
    if not (fileOk and delfile) then return end
    pcall(function() delfile(PROFILES .. "/" .. name .. ".json") end)
    if refreshProfiles then refreshProfiles() end
end

local function listProfiles()
    local out = {}
    if not (fileOk and listfiles and isfolder and isfolder(PROFILES)) then return out end
    pcall(function()
        for _, f in ipairs(listfiles(PROFILES)) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end)
    return out
end

--==============================================================
-- 16. UNLOAD
--==============================================================
local function Unload()
    HUB_ACTIVE = false
    S.EspOn, S.ItemEspOn, S.HitboxOn = false, false, false
    S.NoclipOn, S.FlyOn, S.SpeedOn, S.JumpOn = false, false, false, false
    S.TriggerOn, S.AimOn, S.SpamJump = false, false, false
    pcall(applySpeed); pcall(applyJump)
    pcall(restoreHitbox, true)
    pcall(stopFly); pcall(tickNoclip)
    for p in pairs(espCache) do pcall(clearEsp, p) end
    S.GravityOn, S.PlatformOn = false, false
    pcall(applyGravity); pcall(tickPlatform)
    pcall(function() Workspace.Gravity = defaultGravity end)
    for _, d in pairs(itemDots) do pcall(function() d.f:Destroy() end) end
    for _, c in ipairs(Maid.conns) do pcall(function() c:Disconnect() end) end
    for _, t in ipairs(Maid.threads) do pcall(task.cancel, t) end
    for _, i in ipairs(Maid.insts) do pcall(function() i:Destroy() end) end
    if getgenv then getgenv().HUB = nil end
end

--==============================================================
-- 17. ВКЛАДКИ
--==============================================================
ensureFolders()
local function gameProfile() return "place_" .. tostring(game.PlaceId) end
if S.AutoLoad then
    local loaded = false
    if S.GameProfile then loaded = loadConfig(gameProfile()) == true end
    if not loaded then pcall(loadConfig, "default") end
end
captureDefaults()
applyTransparency()

--// HITBOX
local pHit = newTab("Hitbox")
Section(pHit, "hitbox")
Toggle(pHit, "Hitbox", "Хитбокс", "HitboxOn", function(on)
    if not on then restoreHitbox(true) end end)
Toggle(pHit, "Hitbox", "Подсветка", "HitboxGlow", function(on)
    if not on then restoreHitbox(false) end end)
Slider(pHit, "Hitbox", "Размер", "HitboxSize", 1, 100, 1)

--// ESP
local pEsp = newTab("ESP")
Section(pEsp, "игроки")
Toggle(pEsp, "ESP", "ESP", "EspOn")
Toggle(pEsp, "ESP", "Боксы", "EspBox")
Toggle(pEsp, "ESP", "Ники", "EspName")
Toggle(pEsp, "ESP", "Полоска HP", "EspHealth")
Toggle(pEsp, "ESP", "Трейсеры", "EspTracer")
Toggle(pEsp, "ESP", "Скелет", "EspSkeleton")
Toggle(pEsp, "ESP", "Chams", "EspChams")
Toggle(pEsp, "ESP", "Стрелки за экраном", "EspArrows")
Toggle(pEsp, "ESP", "Оружие в нике", "EspWeapon")
Section(pEsp, "таблица врагов")
Toggle(pEsp, "ESP", "Таблица врагов", "EspListOn", function() updateEspList() end)
Slider(pEsp, "ESP", "Строк в таблице", "EspListMax", 3, 16, 1)
Section(pEsp, "радар")
Toggle(pEsp, "ESP", "Радар", "RadarOn", function() updateRadar() end)
Toggle(pEsp, "ESP", "Вращать по камере", "RadarRotate")
Slider(pEsp, "ESP", "Размер радара", "RadarSize", 100, 340, 10)
Slider(pEsp, "ESP", "Радиус радара", "RadarRange", 50, 1000, 25)
Section(pEsp, "фильтры")
Toggle(pEsp, "ESP", "Только враги", "TeamCheck")
Slider(pEsp, "ESP", "Дистанция", "EspDistance", 50, 5000, 50)
Slider(pEsp, "ESP", "Частота обновления", "EspFps", 10, 144, 2)
ColorPicker(pEsp, "ESP", "Цвет врага", "ColEnemy")
ColorPicker(pEsp, "ESP", "Цвет союзника", "ColAlly")
ColorPicker(pEsp, "ESP", "Цвет друг  ", "ColFriend")
Section(pEsp, "предметы")
Toggle(pEsp, "ESP", "ESP предметов", "ItemEspOn", function() scanItems() end)
TextInput(pEsp, "ESP", "Имена", "ItemFilter", "ammo, medkit", function() scanItems() end)
TextInput(pEsp, "ESP", "Теги", "ItemTag", "Loot", function() scanItems() end)
Slider(pEsp, "ESP", "Дистанция предметов", "ItemDistance", 20, 2000, 20)

--// AIM
local pAim = newTab("Aim")
Section(pAim, "аимбот")
Toggle(pAim, "Aim", "Аимбот", "AimOn")
Toggle(pAim, "Aim", "Жёсткий лок", "AimLock")
Toggle(pAim, "Aim", "Держать цель", "StickyAim")
Toggle(pAim, "Aim", "Только видимых", "AimVisible")
Toggle(pAim, "Aim", "Умная плавность", "AimSmartSmooth")
Toggle(pAim, "Aim", "Аим при зажатой ЛКМ", "AimOnFire")
Toggle(pAim, "Aim", "Гуманизация", "AimHumanize")
Toggle(pAim, "Aim", "Автосмена цели", "AimAutoSwitch")
Toggle(pAim, "Aim", "Замена части тела", "AimFallback")
Toggle(pAim, "Aim", "Показать FOV", "ShowFOV")
Cycle(pAim, "Aim", "Центр FOV", "AimAnchor", { "Cursor", "Center" })
Cycle(pAim, "Aim", "Приоритет", "AimPriority", { "Cursor", "Distance", "Health", "Angle" })
Cycle(pAim, "Aim", "Часть тела", "AimPart", { "Head", "HumanoidRootPart", "Torso" })
Slider(pAim, "Aim", "FOV", "AimFOV", 10, 800, 5)
Slider(pAim, "Aim", "Плавность", "AimSmooth", 0.02, 1, 0.02)
Slider(pAim, "Aim", "Prediction", "AimPredict", 0, 0.5, 0.01)
Slider(pAim, "Aim", "Дрожание прицела", "AimJitter", 0, 12, 1)

Section(pAim, "триггербот")
Toggle(pAim, "Aim", "Триггербот", "TriggerOn", function(on)
    if on and not (mouse1click or mouse1press or VIM) then
        notify("НЕТ ФУНКЦИЙ КЛИКА В ИСПОЛНИТЕЛЕ") end
end)
Toggle(pAim, "Aim", "Только видимых (триггер)", "TriggerVisible")
Toggle(pAim, "Aim", "Маркер цели", "TriggerMark")
Slider(pAim, "Aim", "Триггер FOV (0 = точно)", "TriggerFOV", 0, 200, 5)
Slider(pAim, "Aim", "Задержка", "TriggerDelay", 0.02, 1, 0.02)
Slider(pAim, "Aim", "Разброс задержки %", "TriggerRandom", 0, 80, 5)
Slider(pAim, "Aim", "Реакция мс", "TriggerReaction", 0, 400, 10)

--// MOVE
local pMove = newTab("Move")
Section(pMove, "скорость")
Toggle(pMove, "Move", "Скорость", "SpeedOn", applySpeed)
Cycle(pMove, "Move", "Метод", "SpeedMode", { "WalkSpeed", "CFrame" }, applySpeed)
Toggle(pMove, "Move", "Авто-спринт", "AutoSprint", applySpeed)
Slider(pMove, "Move", "Значение скорости", "SpeedVal", 16, 300, 2, function()
    if S.SpeedOn then applySpeed() end end)
Section(pMove, "прыжок")
Toggle(pMove, "Move", "Прыжок", "JumpOn", applyJump)
Slider(pMove, "Move", "JumpPower", "JumpVal", 50, 400, 5, function()
    if S.JumpOn then applyJump() end end)
Toggle(pMove, "Move", "Бесконечный прыжок", "InfJump")
Toggle(pMove, "Move", "Спам-прыжок", "SpamJump")
Section(pMove, "полёт")
Toggle(pMove, "Move", "Полёт", "FlyOn", function(on)
    if on then startFly() else stopFly() end end)
Cycle(pMove, "Move", "Метод полёта", "FlyMode",
    { "BodyVelocity", "AlignPosition", "CFrame" }, function()
        if S.FlyOn then startFly() end end)
Slider(pMove, "Move", "Скорость полёта", "FlySpeed", 10, 400, 5)
Section(pMove, "защита")
Toggle(pMove, "Move", "Noclip", "NoclipOn")
Toggle(pMove, "Move", "Anti-AFK", "AntiAFK")
Toggle(pMove, "Move", "Anti-fling", "AntiFling")
Toggle(pMove, "Move", "Anti-void", "AntiVoid")
Slider(pMove, "Move", "Граница пустоты Y", "VoidY", -500, 0, 10)
Section(pMove, "гравитация")
Toggle(pMove, "Move", "Своя гравитация", "GravityOn", applyGravity)
Slider(pMove, "Move", "Значение гравитации", "GravityVal", 0, 400, 4, function()
    if S.GravityOn then applyGravity() end end)
Toggle(pMove, "Move", "Платформа под ногами", "PlatformOn", function() tickPlatform() end)
Section(pMove, "телепорт")
Toggle(pMove, "Move", "Плавный телепорт", "TpTween")
Slider(pMove, "Move", "Время телепорта", "TpTweenTime", 0.1, 3, 0.1)
Button(pMove, "Move", "Сбросить скорость и прыжок", function()
    S.SpeedOn, S.JumpOn = false, false
    if bindMap.SpeedOn then bindMap.SpeedOn.refresh() end
    if bindMap.JumpOn then bindMap.JumpOn.refresh() end
    captureDefaults(); applySpeed(); applyJump()
    notify("ЗНАЧЕНИЯ ИГРЫ ВОССТАНОВЛЕНЫ")
end)

--// PLAYERS
local pPl = newTab("Players")
Section(pPl, "список")
local plrList = Instance.new("ScrollingFrame", pPl)
plrList.Size = UDim2.new(1, 0, 0, 180)
plrList.BackgroundColor3 = BLACK; plrList.BorderSizePixel = 0
plrList.ScrollBarThickness = 3; plrList.ScrollBarImageColor3 = LINE
plrList.ScrollBarImageTransparency = 0.5
plrList.CanvasSize = UDim2.new(); plrList.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel(plrList, 0.1); round(plrList, 8)
local pll = Instance.new("UIListLayout", plrList); pll.Padding = UDim.new(0, 2)
pad(plrList, 0, 0, 6, 6)
register(plrList, "игроки список", "Players")

local function toggleIn(list, name)
    for i, n in ipairs(list) do
        if n:lower() == name:lower() then table.remove(list, i) return false end
    end
    table.insert(list, name); return true
end

local refreshPlayers
refreshPlayers = function()
    for _, ch in ipairs(plrList:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local r = Instance.new("Frame", plrList)
            r.Size = UDim2.new(1, 0, 0, 26)
            r.BackgroundColor3 = BLACK; r.BackgroundTransparency = 1
            r.BorderSizePixel = 0
            local l = txt(r, "", 12, TXT_DIM)
            l.Size = UDim2.new(1, -120, 1, 0); l.Position = UDim2.fromOffset(12, 0)
            local function upd()
                l.Text = string.format("%s%s%s",
                    isPrio(p) and "* " or "", isFriend(p) and "+ " or "", p.Name)
                l.TextColor3 = isFriend(p) and C3(S.ColFriend)
                    or (isPrio(p) and TXT or TXT_DIM)
            end
            upd()
            local function mini(text, x, cb)
                local b = Instance.new("TextButton", r)
                b.Size = UDim2.fromOffset(32, 18)
                b.Position = UDim2.new(1, x, 0, 4)
                b.BackgroundColor3 = SUNK; b.BackgroundTransparency = 0.15
                b.BorderSizePixel = 0; b.Text = text
                b.TextColor3 = TXT; b.Font = FONT_B; b.TextSize = 9
                b.AutoButtonColor = false
                round(b, 5)
                b.MouseEnter:Connect(function() b.BackgroundColor3 = accentOf(); b.TextColor3 = BLACK end)
                b.MouseLeave:Connect(function() b.BackgroundColor3 = SUNK; b.TextColor3 = TXT end)
                b.MouseButton1Click:Connect(cb)
                return b
            end
            mini("TP", -110, function()
                local ok, c = alive(p)
                local root = ok and c:FindFirstChild("HumanoidRootPart")
                if root then teleportTo(root.Position); notify("TP > " .. p.Name) end
            end)
            mini("FR", -74, function()
                local added = toggleIn(S.Friends, p.Name); upd()
                notify((added and "ДРУГ: " or "УБРАН: ") .. p.Name)
            end)
            mini("PRI", -38, function()
                local added = toggleIn(S.Prio, p.Name); upd()
                notify((added and "ПРИОРИТЕТ: " or "УБРАН: ") .. p.Name)
            end)
        end
    end
end
refreshPlayers()
Maid:Conn(Players.PlayerAdded:Connect(refreshPlayers))
Maid:Conn(Players.PlayerRemoving:Connect(refreshPlayers))

Section(pPl, "действия")
Button(pPl, "Players", "Обновить список", refreshPlayers)
Button(pPl, "Players", "Очистить друзей", function()
    S.Friends = {}; refreshPlayers(); notify("СПИСОК ДРУЗЕЙ ОЧИЩЕН") end)
Button(pPl, "Players", "Очистить приоритет", function()
    S.Prio = {}; refreshPlayers(); notify("ПРИОРИТЕТ ОЧИЩЕН") end)
Button(pPl, "Players", "Телепорт под курсор", function()
    if Mouse.Target then teleportTo(Mouse.Hit.Position) end end)
Button(pPl, "Players", "Сброс персонажа", function()
    local h = hum(); if h then h.Health = 0 end end)

--// CONFIG
--// точки телепорта (waypoints)
Section(pPl, "точки телепорта")
local wpBox = Instance.new("TextBox", pPl)
wpBox.Size = UDim2.new(1, 0, 0, 30)
wpBox.BackgroundColor3 = BLACK; wpBox.BorderSizePixel = 0
wpBox.PlaceholderText = " ИМЯ ТОЧКИ"
wpBox.PlaceholderColor3 = TXT_DIM
wpBox.Text = ""; wpBox.TextColor3 = TXT
wpBox.Font = FONT; wpBox.TextSize = 12
wpBox.TextXAlignment = Enum.TextXAlignment.Left
wpBox.ClearTextOnFocus = false
panel(wpBox, 0.1); round(wpBox, 8); pad(wpBox, 14, 10, 0, 0)
register(wpBox, "имя точки", "Players")

local wpList = Instance.new("ScrollingFrame", pPl)
wpList.Size = UDim2.new(1, 0, 0, 110)
wpList.BackgroundColor3 = BLACK; wpList.BorderSizePixel = 0
wpList.ScrollBarThickness = 3; wpList.ScrollBarImageColor3 = LINE
wpList.ScrollBarImageTransparency = 0.5
wpList.CanvasSize = UDim2.new(); wpList.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel(wpList, 0.1); round(wpList, 8)
local wfl = Instance.new("UIListLayout", wpList); wfl.Padding = UDim.new(0, 2)
pad(wpList, 0, 0, 6, 6)
register(wpList, "список точек", "Players")

local refreshWaypoints
refreshWaypoints = function()
    for _, ch in ipairs(wpList:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    for i, w in ipairs(S.Waypoints or {}) do
        local r = Instance.new("Frame", wpList)
        r.Size = UDim2.new(1, 0, 0, 24)
        r.BackgroundTransparency = 1; r.BorderSizePixel = 0
        local l = txt(r, string.format("%s  [%d, %d, %d]", tostring(w.name),
            math.floor(w.x or 0), math.floor(w.y or 0), math.floor(w.z or 0)), 12, TXT_DIM)
        l.Size = UDim2.new(1, -84, 1, 0); l.Position = UDim2.fromOffset(12, 0)
        l.TextTruncate = Enum.TextTruncate.AtEnd
        local function mini(text, x, col, cb)
            local b = Instance.new("TextButton", r)
            b.Size = UDim2.fromOffset(32, 18); b.Position = UDim2.new(1, x, 0, 3)
            b.BackgroundColor3 = SUNK; b.BackgroundTransparency = 0.15
            b.BorderSizePixel = 0; b.Text = text
            b.TextColor3 = col; b.Font = FONT_B; b.TextSize = 9
            b.AutoButtonColor = false; round(b, 5)
            b.MouseButton1Click:Connect(cb)
        end
        mini("TP", -74, TXT, function()
            teleportTo(Vector3.new(w.x, w.y, w.z))
            notify("TP > " .. tostring(w.name))
        end)
        mini("DEL", -38, RED, function()
            table.remove(S.Waypoints, i)
            refreshWaypoints(); notify("ТОЧКА УДАЛЕНА")
        end)
    end
end
refreshWaypoints()

Button(pPl, "Players", "Добавить точку здесь", function()
    local r = hrp()
    if not r then notify("НЕТ ПЕРСОНАЖА") return end
    local n = wpBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then n = "точка " .. (#S.Waypoints + 1) end
    S.Waypoints = S.Waypoints or {}
    table.insert(S.Waypoints, {
        name = n, x = r.Position.X, y = r.Position.Y, z = r.Position.Z,
    })
    wpBox.Text = ""
    refreshWaypoints()
    notify("ТОЧКА: " .. n)
end)
Button(pPl, "Players", "Очистить точки", function()
    S.Waypoints = {}
    refreshWaypoints(); notify("ТОЧКИ ОЧИЩЕНЫ")
end, true)

local pSet = newTab("Config")
Section(pSet, "клавиши")
Keybind(pSet, "UI", "Меню", "KeyMenu")
Keybind(pSet, "UI", "Watermark", "KeyWM")
Keybind(pSet, "UI", "Аим", "KeyAim")
Keybind(pSet, "UI", "Полёт", "KeyFly")
Keybind(pSet, "UI", "Noclip", "KeyNoclip")
Keybind(pSet, "UI", "Click TP", "KeyClickTP")
Section(pSet, "интерфейс")
Toggle(pSet, "UI", "Watermark", "Watermark", function(on) wm.Visible = on end)
Toggle(pSet, "UI", "Уведомления", "Notifications")
Toggle(pSet, "UI", "Автозагрузка профиля", "AutoLoad")
ColorPicker(pSet, "UI", "Акцентный цвет", "Accent")
Slider(pSet, "UI", "Прозрачность", "Transparency", 0, 0.9, 0.05, function()
    applyTransparency(); if currentTab then selectTab(currentTab) end end)

Section(pSet, "профили")
local profBox = Instance.new("TextBox", pSet)
profBox.Size = UDim2.new(1, 0, 0, 24)
profBox.BackgroundColor3 = BLACK; profBox.BorderSizePixel = 0
profBox.PlaceholderText = "Имя профиля"
profBox.PlaceholderColor3 = TXT_DIM
profBox.Text = currentProfile; profBox.TextColor3 = TXT
profBox.Font = FONT; profBox.TextSize = 12
profBox.TextXAlignment = Enum.TextXAlignment.Left
profBox.ClearTextOnFocus = false
panel(profBox, 0.1); round(profBox, 8); pad(profBox, 14, 10, 0, 0)
register(profBox, "имя профиля", "Config")

local profList = Instance.new("ScrollingFrame", pSet)
profList.Size = UDim2.new(1, 0, 0, 100)
profList.BackgroundColor3 = BLACK; profList.BorderSizePixel = 0
profList.ScrollBarThickness = 3; profList.ScrollBarImageColor3 = LINE
profList.ScrollBarImageTransparency = 0.5
profList.CanvasSize = UDim2.new(); profList.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel(profList, 0.1); round(profList, 8)
local pfl = Instance.new("UIListLayout", profList); pfl.Padding = UDim.new(0, 2)
pad(profList, 0, 0, 6, 6)
register(profList, "список профилей", "Config")

refreshProfiles = function()
    for _, ch in ipairs(profList:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    for _, name in ipairs(listProfiles()) do
        local r = Instance.new("Frame", profList)
        r.Size = UDim2.new(1, 0, 0, 24)
        r.BackgroundTransparency = 1; r.BorderSizePixel = 0
        local l = txt(r, name .. ((name == currentProfile) and "  •" or ""), 12,
            (name == currentProfile) and TXT or TXT_DIM)
        l.Size = UDim2.new(1, -84, 1, 0); l.Position = UDim2.fromOffset(12, 0)
        local function mini(text, x, col, cb)
            local b = Instance.new("TextButton", r)
            b.Size = UDim2.fromOffset(32, 18); b.Position = UDim2.new(1, x, 0, 3)
            b.BackgroundColor3 = SUNK; b.BackgroundTransparency = 0.15
            b.BorderSizePixel = 0; b.Text = text
            b.TextColor3 = col; b.Font = FONT_B; b.TextSize = 9
            b.AutoButtonColor = false; round(b, 5)
            b.MouseButton1Click:Connect(cb)
        end
        mini("LD", -74, TXT, function()
            if loadConfig(name) then
                applyConfig(); profBox.Text = name
                refreshProfiles(); notify("ЗАГРУЖЕН: " .. name)
            else notify("ОШИБКА ЗАГРУЗКИ") end
        end)
        mini("DEL", -38, RED, function()
            deleteProfile(name); notify("УДАЛЁН: " .. name)
        end)
    end
end
refreshProfiles()

Button(pSet, "Config", "Сохранить профиль", function()
    local n = profBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then n = "default" end
    currentProfile = n
    saveConfig(n)
end)
Button(pSet, "Config", "Загрузить профиль", function()
    local n = profBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then n = "default" end
    if loadConfig(n) then
        applyConfig(); refreshProfiles(); notify("ЗАГРУЖЕН: " .. n)
    else notify("ПРОФИЛЬ НЕ НАЙДЕН") end
end)
--// интерфейс / темы / язык / ключ / сервер
Section(pSet, "масштаб и язык")
Slider(pSet, "UI", "Масштаб UI", "UIScale", 0.6, 2, 0.05, function() applyScale() end)
Cycle(pSet, "UI", "Язык / Language", "Lang", { "RU", "EN" }, function() applyLang() end)
Toggle(pSet, "UI", "Быстрая панель", "QuickPanel", function()
    if refreshQuick then refreshQuick() end
    updateQuick()
end)
Toggle(pSet, "UI", "Профиль под игру", "GameProfile")
Keybind(pSet, "UI", "Паника (всё выкл)", "KeyPanic")
Keybind(pSet, "UI", "Быстрая панель", "KeyQuick")

Section(pSet, "темы")
local THEMES = {
    { name = "Aurora",  c = { 124, 150, 255 } },
    { name = "Emerald", c = { 110, 230, 170 } },
    { name = "Rose",    c = { 255, 120, 170 } },
    { name = "Amber",   c = { 255, 190,  90 } },
    { name = "Mono",    c = { 225, 228, 238 } },
}
for _, th in ipairs(THEMES) do
    Button(pSet, "UI", "Тема: " .. th.name, function()
        S.Accent = { th.c[1], th.c[2], th.c[3] }
        applyAccent()
        for _, e in ipairs(elements) do if e.refresh then pcall(e.refresh) end end
        if refreshQuick then refreshQuick() end
        notify("ТЕМА: " .. th.name)
    end)
end

Section(pSet, "импорт / экспорт")
local B64C = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64enc(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
        return B64C:sub(c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end
local function b64dec(data)
    data = data:gsub("[^" .. B64C .. "=]", "")
    return (data:gsub("=", ""):gsub(".", function(x)
        local r, f = "", (B64C:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

local cfgBox = Instance.new("TextBox", pSet)
cfgBox.Size = UDim2.new(1, 0, 0, 30)
cfgBox.BackgroundColor3 = BLACK; cfgBox.BorderSizePixel = 0
cfgBox.PlaceholderText = " СТРОКА КОНФИГА (BASE64)"
cfgBox.PlaceholderColor3 = TXT_DIM
cfgBox.Text = ""; cfgBox.TextColor3 = TXT
cfgBox.Font = FONT; cfgBox.TextSize = 12
cfgBox.TextXAlignment = Enum.TextXAlignment.Left
cfgBox.ClearTextOnFocus = false
panel(cfgBox, 0.1); round(cfgBox, 8); pad(cfgBox, 14, 10, 0, 0)
register(cfgBox, "строка конфига", "Config")

Button(pSet, "Config", "Скопировать конфиг", function()
    local ok, str = pcall(function() return b64enc(HttpService:JSONEncode(S)) end)
    if not ok then notify("ОШИБКА ЭКСПОРТА") return end
    cfgBox.Text = str
    if setclipboard then
        pcall(setclipboard, str)
        notify("КОНФИГ В БУФЕРЕ")
    else
        notify("НЕТ setclipboard — СКОПИРУЙ ИЗ ПОЛЯ")
    end
end)
Button(pSet, "Config", "Вставить конфиг", function()
    local raw = cfgBox.Text:gsub("%s+", "")
    if raw == "" then notify("ПУСТАЯ СТРОКА") return end
    local ok = pcall(function()
        local data = HttpService:JSONDecode(b64dec(raw))
        for k, v in pairs(data) do if S[k] ~= nil then S[k] = v end end
    end)
    if ok then
        applyConfig(); refreshWaypoints()
        notify("КОНФИГ ПРИМЕНЁН")
    else
        notify("НЕВЕРНАЯ СТРОКА")
    end
end)

Section(pSet, "ключ и сервер")
Button(pSet, "Config", "Забыть ключ", function()
    if getgenv then getgenv().CONES_AUTH = nil end
    local gone = false
    if delfile and isfile then
        for _, f in ipairs({ AUTH_FILE, LEGACY_AUTH }) do
            local ok, res = pcall(isfile, f)
            if ok and res == true then pcall(delfile, f); gone = true end
        end
    end
    notify(gone and "КЛЮЧ ЗАБЫТ — СПРОСИТ В СЛЕДУЮЩИЙ РАЗ" or "ФАЙЛ КЛЮЧА НЕ НАЙДЕН")
end)
Button(pSet, "Config", "Перезайти в сервер", function()
    notify("РЕДЖОИН...")
    local TPS = game:GetService("TeleportService")
    pcall(function() TPS:Teleport(game.PlaceId, LP) end)
end)
Button(pSet, "Config", "Сменить сервер", function()
    local TPS = game:GetService("TeleportService")
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId ..
        "/servers/Public?sortOrder=Asc&limit=100"
    local ok, res = pcall(function()
        local body
        if game.HttpGet then body = game:HttpGet(url)
        elseif HttpGet then body = HttpGet(url) end
        return HttpService:JSONDecode(body)
    end)
    if ok and res and res.data then
        for _, srv in ipairs(res.data) do
            if srv.id ~= game.JobId and srv.playing and srv.maxPlayers
                and srv.playing < srv.maxPlayers then
                notify("ПЕРЕХОД В ДРУГОЙ СЕРВЕР...")
                pcall(function() TPS:TeleportToPlaceInstance(game.PlaceId, srv.id, LP) end)
                return
            end
        end
        notify("СВОБОДНЫХ СЕРВЕРОВ НЕТ — РЕДЖОИН")
    else
        notify("НЕТ ДОСТУПА К API — РЕДЖОИН")
    end
    pcall(function() TPS:Teleport(game.PlaceId, LP) end)
end)
Button(pSet, "Config", "Сохранить как профиль игры", function()
    currentProfile = gameProfile()
    profBox.Text = currentProfile
    saveConfig(currentProfile)
end)

Button(pSet, "Config", "Сбросить окно", function()
    main.Position = UDim2.new(0.5, -300, 0.5, -215)
    main.Size = UDim2.fromOffset(600, 430)
    savedH = 430
    if minimized then setMinimized(false) end
end)
Button(pSet, "Config", "ВЫГРУЗИТЬ СКРИПТ", function() Unload() end, true)

--// DEBUG
local pDbg = newTab("Debug")
Section(pDbg, "лог")
local dbgList = Instance.new("ScrollingFrame", pDbg)
dbgList.Size = UDim2.new(1, 0, 0, 230)
dbgList.BackgroundColor3 = BLACK; dbgList.BorderSizePixel = 0
dbgList.ScrollBarThickness = 3; dbgList.ScrollBarImageColor3 = LINE
dbgList.ScrollBarImageTransparency = 0.5
dbgList.CanvasSize = UDim2.new(); dbgList.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel(dbgList, 0.1); round(dbgList, 8)
local dl = Instance.new("UIListLayout", dbgList)
dl.Padding = UDim.new(0, 1)
pad(dbgList, 0, 0, 6, 6)
register(dbgList, "лог ошибок", "Debug")

refreshDebug = function()
    for _, ch in ipairs(dbgList:GetChildren()) do
        if ch:IsA("TextLabel") then ch:Destroy() end
    end
    for _, line in ipairs(debugLog) do
        local l = txt(dbgList, line, 11, RED)
        l.Font = Enum.Font.Code
        l.Size = UDim2.new(1, -16, 0, 15)
        l.Position = UDim2.fromOffset(12, 0)
        l.TextTruncate = Enum.TextTruncate.AtEnd
    end
end
refreshDebug()

Section(pDbg, "статистика сессии")
local statFrame = Instance.new("Frame", pDbg)
statFrame.Size = UDim2.new(1, 0, 0, 96)
statFrame.BackgroundColor3 = BLACK; statFrame.BorderSizePixel = 0
panel(statFrame, 0.1); round(statFrame, 8)
local statLbl = txt(statFrame, "", 11, TXT_DIM)
statLbl.Size = UDim2.new(1, -24, 1, -12)
statLbl.Position = UDim2.fromOffset(14, 6)
statLbl.TextYAlignment = Enum.TextYAlignment.Top
statLbl.TextXAlignment = Enum.TextXAlignment.Left
register(statFrame, "статистика сессии", "Debug")
Maid:Thread(task.spawn(function()
    while task.wait(1) do
        if not HUB_ACTIVE then break end
        local el = os.clock() - stats.start
        local avg = stats.fpsN > 0 and math.floor(stats.fpsSum / stats.fpsN) or 0
        statLbl.Text = string.format(
            "ВРЕМЯ СЕССИИ: %02d:%02d\nСРЕДНИЙ FPS: %d\nЗАХВАТОВ ЦЕЛИ: %d\nКИЛЛОВ (ОЦЕНКА): %d\nИГРОКОВ НА СЕРВЕРЕ: %d",
            math.floor(el / 60), math.floor(el % 60), avg,
            stats.locks, stats.kills, #Players:GetPlayers())
    end
end))

Section(pDbg, "действия")
Button(pDbg, "Debug", "Очистить лог", function()
    debugLog = {}; refreshDebug(); notify("ЛОГ ОЧИЩЕН")
end)
Button(pDbg, "Debug", "Тестовая ошибка", function()
    safe("test", function() error("проверка логгера") end)
end)
Button(pDbg, "Debug", "Инфо об исполнителе", function()
    logErr("info", string.format("files=%s click=%s vim=%s gethui=%s",
        tostring(fileOk),
        tostring(mouse1click ~= nil or mouse1press ~= nil),
        tostring(VIM ~= nil),
        tostring(gethui ~= nil)))
end)

--==============================================================
-- 18. СТАРТ
--==============================================================
selectTab(pages[S.LastTab] and S.LastTab or "Hitbox")
applyConfig()
do
    local function keyName(v)
        return (v ~= nil and v ~= "") and tostring(v):upper() or "не задано"
    end
    notify("Cones v7 загружен  ·  меню: " .. keyName(S.KeyMenu)
        .. "  ·  паника: " .. keyName(S.KeyPanic)
        .. "  ·  бинды — вкладка Config", 6)
end

if getgenv then
    getgenv().HUB = {
        Settings = S,
        Unload   = Unload,
        Notify   = notify,
        Save     = saveConfig,
        Load     = function(n)
            if loadConfig(n) then applyConfig() return true end
            return false
        end,
    }
end

end -- BuildRest

BuildRest()

end -- LoadHub

--==============================================================
--  ОКНО КЛЮЧА
--==============================================================
local function ShowKeyWindow()

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "ConesKey"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.DisplayOrder = 999
keyGui.Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

local ACC = Color3.fromRGB(124, 150, 255)
local function kround(inst, r)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, r)
    return c
end

local shade = Instance.new("Frame", keyGui)
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(4, 5, 8)
shade.BackgroundTransparency = 0.35
shade.BorderSizePixel = 0

local win = Instance.new("Frame", keyGui)
win.Size = UDim2.fromOffset(330, 230)
win.Position = UDim2.new(0.5, -165, 0.5, -115)
win.BackgroundColor3 = Color3.fromRGB(10, 11, 15)
win.BackgroundTransparency = 0.05
win.BorderSizePixel = 0
win.Active, win.Draggable = true, true
kround(win, 14)
local ws = Instance.new("UIStroke", win)
ws.Color = ACC; ws.Transparency = 0.5; ws.Thickness = 1
ws.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bar = Instance.new("Frame", win)
bar.Size = UDim2.fromOffset(10, 10)
bar.Position = UDim2.new(0.5, -47, 0, 40)
bar.BackgroundColor3 = ACC
bar.BorderSizePixel = 0
kround(bar, 5)

local hdr = Instance.new("TextLabel", win)
hdr.Size = UDim2.new(1, 0, 0, 30); hdr.Position = UDim2.fromOffset(12, 30)
hdr.BackgroundTransparency = 1
hdr.Text = "CONES"
hdr.TextColor3 = Color3.fromRGB(236, 238, 245)
hdr.Font = Enum.Font.GothamBold
hdr.TextSize = 22

local sub = Instance.new("TextLabel", win)
sub.Size = UDim2.new(1, 0, 0, 16)
sub.Position = UDim2.fromOffset(0, 64)
sub.BackgroundTransparency = 1
sub.Text = "введите ключ доступа"
sub.TextColor3 = Color3.fromRGB(124, 128, 144)
sub.Font = Enum.Font.GothamMedium
sub.TextSize = 12

local box = Instance.new("TextBox", win)
box.Size = UDim2.new(1, -48, 0, 34)
box.Position = UDim2.fromOffset(24, 104)
box.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
box.BackgroundTransparency = 0.15
box.BorderSizePixel = 0
box.PlaceholderText = "ключ"
box.PlaceholderColor3 = Color3.fromRGB(110, 114, 130)
box.Text = ""
box.TextColor3 = Color3.fromRGB(236, 238, 245)
box.Font = Enum.Font.GothamMedium
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
kround(box, 8)
local bp = Instance.new("UIPadding", box)
bp.PaddingLeft = UDim.new(0, 12); bp.PaddingRight = UDim.new(0, 12)
local bs = Instance.new("UIStroke", box)
bs.Color = ACC; bs.Transparency = 0.75; bs.Thickness = 1

local status = Instance.new("TextLabel", win)
status.Size = UDim2.new(1, -48, 0, 14)
status.Position = UDim2.fromOffset(24, 142)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 105, 120)
status.Font = Enum.Font.GothamMedium
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left

local btn = Instance.new("TextButton", win)
btn.Size = UDim2.new(1, -48, 0, 34)
btn.Position = UDim2.fromOffset(24, 166)
btn.BackgroundColor3 = ACC
btn.BackgroundTransparency = 0.15
btn.BorderSizePixel = 0
btn.Text = "Активировать"
btn.TextColor3 = Color3.fromRGB(12, 13, 18)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.AutoButtonColor = false
kround(btn, 8)
btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0 end)
btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.15 end)

local attempts, locked = 0, false

local function shake()
    local base = win.Position
    for i = 1, 6 do
        win.Position = base + UDim2.fromOffset((i % 2 == 0) and 7 or -7, 0)
        task.wait(0.03)
    end
    win.Position = base
end

local function check()
    if locked then return end
    local input = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if input == VALID_KEY then
        locked = true
        status.TextColor3 = Color3.new(1, 1, 1)
        status.Text = "OK · ЗАГРУЗКА"
        bs.Transparency = 0.2
        btn.Text = "УСПЕШНО"
        task.wait(0.5)
        if getgenv then getgenv().CONES_AUTH = UID end
        if writefile then
            pcall(function()
                if makefolder and isfolder and not isfolder("cones") then makefolder("cones") end
                writefile(AUTH_FILE, UID .. "|" .. VALID_KEY)
            end)
        end
        keyGui:Destroy()
        local ok, err = pcall(LoadHub)
        if not ok then warn("[Cones] Ошибка загрузки: " .. tostring(err)) end
    else
        attempts += 1
        bs.Color = Color3.fromRGB(255, 110, 110)
        bs.Transparency = 0.3
        status.Text = "НЕВЕРНЫЙ КЛЮЧ · " .. attempts .. "/5"
        task.spawn(shake)
        if attempts >= 5 then
            locked = true
            status.Text = "ДОСТУП ЗАБЛОКИРОВАН"
            btn.Text = "ЗАБЛОКИРОВАНО"
            box.TextEditable = false
        else
            task.delay(1.5, function()
                if not locked then
                    bs.Color = Color3.new(1, 1, 1)
                    bs.Transparency = 0.7
                    status.Text = ""
                end
            end)
        end
    end
end

btn.MouseButton1Click:Connect(check)
box.FocusLost:Connect(function(enter) if enter then check() end end)

end -- ShowKeyWindow

--==============================================================
--  АВТОВХОД ПО СОХРАНЁННОМУ КЛЮЧУ (cones/auth.txt)
--==============================================================
local savedAuth = false

-- 1) флаг сессии: повторный запуск загрузчика ключ не спросит
if getgenv and getgenv().CONES_AUTH == UID then savedAuth = true end

-- 2) файл ключа именно этого аккаунта
if not savedAuth and isfile then
    local ok, res = pcall(isfile, AUTH_FILE)
    if ok and res == true then
        local ok2, body = pcall(readfile, AUTH_FILE)
        if ok2 and type(body) == "string" and body:find(VALID_KEY, 1, true) then
            savedAuth = true
        elseif delfile then
            pcall(delfile, AUTH_FILE)   -- ключ сменился, файл устарел
        end
    end
end

-- 3) миграция старого общего cones/auth.txt на файл аккаунта
if not savedAuth and isfile then
    local ok, res = pcall(isfile, LEGACY_AUTH)
    if ok and res == true then
        savedAuth = true
        if writefile then
            pcall(function()
                if makefolder and isfolder and not isfolder("cones") then makefolder("cones") end
                writefile(AUTH_FILE, UID .. "|" .. VALID_KEY)
            end)
        end
    end
end

if savedAuth and getgenv then getgenv().CONES_AUTH = UID end

if savedAuth then
    local ok, err = pcall(LoadHub)
    if not ok then
        warn("[Cones] Ошибка загрузки: " .. tostring(err))
        ShowKeyWindow()
    end
else
    ShowKeyWindow()
end
