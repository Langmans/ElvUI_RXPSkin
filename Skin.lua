-- The skinning the three addons share. Their frames set their own backdrops again whenever they
-- redraw, so a skinned frame keeps a hook on SetBackdrop that puts ElvUI's template back. In
-- "keep" mode the owner's backdrop colour stays (RestedXP draws its states with it); in "force"
-- mode ElvUI's colours win every time (Loreward's parchment). The border is always ElvUI's.
-- The see-through styles apply to the HUD only, the frames that stay on screen while playing (the
-- guide window, Loreward's strip and cards, Waymark's panel); windows you open keep ElvUI's own
-- skin. In the translucent style the HUD gets a see-through backdrop at the plugin's alpha and
-- parts nested in it ("inner") none at all; in the transparent style the HUD has no backdrop or
-- shadow, only the text and the addons' own accents are left (as Eltruism's transparent chat).
-- Widgets are found by what their Blizzard template leaves on them, and each is skinned once.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local S = E:GetModule("Skins") ---@type ElvUISkins

local Skin = {}
ns.Skin = Skin

-- The looks the plugin offers.
Skin.styles = { elvui = "elvui", translucent = "translucent", transparent = "transparent" }
-- ElvUI's template for a frame without backdrop.
local NONE = "NoBackdrop"

-- Skinned frames, each with its template, whether ElvUI's colours are forced, whether it is nested
-- in a window, whether it is part of the HUD, and the template it has now. Weak keys.
---@type table<table, { template: string, force: boolean, inner: boolean, hud: boolean, current: string }>
local skinned = setmetatable({}, { __mode = "k" })
-- Frames being skinned right now, whose own hooks must not run.
local locked = setmetatable({}, { __mode = "k" })
-- Widgets already handed to ElvUI's Skins.
local handled = setmetatable({}, { __mode = "k" })
-- The windows that take a shadow, each with whether it is part of the HUD. Weak keys.
---@type table<table, boolean>
local shadowed = setmetatable({}, { __mode = "k" })
-- The windows whose widgets are skinned, each with whether it is part of the HUD. Weak keys.
---@type table<table, boolean>
local windows = setmetatable({}, { __mode = "k" })
local updateShadow -- with the shadows, below

---The backdrop alpha of the current style: the plugin's alpha in the translucent style, 0 in the
---transparent one, nil in ElvUI's own (the template's alpha).
---@return number?
function Skin.Alpha()
    local db = ns.db()
    if db.style == Skin.styles.transparent then return 0 end
    return db.style == Skin.styles.translucent and db.alpha or nil
end

---Whether the current style is the transparent one.
---@return boolean
function Skin.Transparent()
    return ns.db().style == Skin.styles.transparent
end

---The background colour of a template: ElvUI's faded one for "Transparent", the frame's own alpha
---(the translucent style's) over the template's.
---@param frame table
---@param template string
---@return number, number, number, number
local function templateColor(frame, template)
    local c = template == "Transparent" and E.media.backdropfadecolor or E.media.backdropcolor
    return c.r, c.g, c.b, frame.customBackdropAlpha or (template == "Transparent" and c.a) or 1
end

---Puts ElvUI's template on a keep-mode frame, then the colour it had back. The frame stays out
---of ElvUI's colour updates, which would overwrite the owner's colour.
---@param frame table
---@param template string
---@param r number? nil when the frame had no backdrop
---@param g number
---@param b number
---@param a number
local function keepColor(frame, template, r, g, b, a)
    frame:SetTemplate(template, nil, true)
    if r and template ~= NONE then frame:SetBackdropColor(r, g, b, a) end
end

---Puts ElvUI's template on a skinned frame, in the current style; in keep mode its colour from
---before comes back.
---@param frame table
local function apply(frame)
    local info = skinned[frame]
    -- Outside the HUD, ElvUI's own style whatever the setting.
    local alpha = info.hud and Skin.Alpha() or nil
    local transparent = info.hud and Skin.Transparent()
    info.current = (transparent or (alpha and info.inner)) and NONE or info.template
    -- ElvUI's SetTemplate takes this alpha over the template's.
    frame.customBackdropAlpha = not info.inner and alpha or nil
    locked[frame] = true
    if info.force or not frame.GetBackdropColor then
        frame:SetTemplate(info.current)
    else
        keepColor(frame, info.current, frame:GetBackdropColor())
    end
    locked[frame] = nil
end

---@param frame table
local function onSetBackdrop(frame)
    if not locked[frame] then apply(frame) end
end

---@param frame table
local function onBackdropColor(frame)
    local current = skinned[frame].current
    if locked[frame] or current == NONE then return end
    locked[frame] = true
    frame:SetBackdropColor(templateColor(frame, current))
    locked[frame] = nil
end

---@param frame table
local function onBorderColor(frame)
    if locked[frame] then return end
    locked[frame] = true
    local c = E.media.bordercolor
    frame:SetBackdropBorderColor(c.r, c.g, c.b, 1)
    locked[frame] = nil
end

---Gives a frame ElvUI's template now and every time its owner sets its backdrop again.
---@param frame table
---@param template string "Default" or "Transparent"
---@param force boolean? ElvUI's background colour over the owner's
---@param inner boolean? nested in a window: no backdrop in the translucent style
---@param hud boolean? part of the HUD: follows the see-through styles; else always ElvUI's style
function Skin.Backdrop(frame, template, force, inner, hud)
    if skinned[frame] then return end
    skinned[frame] = {
        template = template,
        force = not not force,
        inner = not not inner,
        hud = not not hud,
        current = template,
    }
    apply(frame)
    hooksecurefunc(frame, "SetBackdrop", onSetBackdrop)
    hooksecurefunc(frame, "SetBackdropBorderColor", onBorderColor)
    if force then hooksecurefunc(frame, "SetBackdropColor", onBackdropColor) end
end

---Puts ElvUI's template on every skinned frame again, and the shadows in line with the switch,
---after the media or a setting changed.
function Skin.Refresh()
    for frame in pairs(skinned) do
        apply(frame)
    end
    for frame in pairs(shadowed) do
        updateShadow(frame)
    end
end

---Whether a button is a UIPanelCloseButton: its normal texture is the red exit button.
---@param button table
---@return boolean
local function isCloseButton(button)
    ---@type table?
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    return normal ~= nil and normal.GetAtlas ~= nil and normal:GetAtlas() == "RedButton-Exit"
end

local walk -- below widget

---Skins one widget by its template's marks, then the widgets inside it.
---@param hud boolean the window it is in is part of the HUD
---@param frame table
local function widget(hud, frame)
    if handled[frame] then return end
    local kind = frame:GetObjectType() ---@type string
    -- The Left, Middle and Right textures of a panel button or a drop-down menu.
    local panel = (frame.Left and frame.Middle and frame.Right) ~= nil
    if kind == "Button" and panel then
        S:HandleButton(frame)
    elseif kind == "Button" and isCloseButton(frame) then
        S:HandleCloseButton(frame)
    elseif kind == "CheckButton" and frame.Text then
        S:HandleCheckBox(frame)
    elseif kind == "Slider" and frame.GetThumbTexture then
        S:HandleSliderFrame(frame)
    elseif kind == "Frame" and panel and frame.Button then
        S:HandleDropDownBox(frame)
    elseif kind == "EditBox" and frame.SetBackdrop then
        Skin.Backdrop(frame, "Default", true, true, hud)
    else
        walk(hud, frame:GetChildren())
        return
    end
    handled[frame] = true
end

---@param hud boolean
---@param ... table
walk = function(hud, ...)
    for i = 1, select("#", ...) do
        widget(hud, (select(i, ...)))
    end
end

---Skins the widgets inside a window that are not yet.
---@param frame table
function Skin.Widgets(frame)
    walk(windows[frame] == true, frame:GetChildren())
end

-- The shadow variants: the ElvUI edit whose shadows the skinned windows get.
Skin.shadows = { eltruism = "eltruism", windtools = "windtools" }

---Whether Eltruism or WindTools is loaded, whatever its own options say.
---@return boolean
function Skin.ShadowAddonLoaded()
    return _G.ElvUI_EltreumUI ~= nil or _G.WindTools ~= nil
end

---The shadow variant in use: Eltruism's when it is loaded with its shadows on, else WindTools'
---when it is loaded with its skins and its shadows on, else none. Each only with its own option
---on, so the windows look like the rest of that edit's frames.
---@return string? variant one of Skin.shadows
function Skin.ShadowVariant()
    if _G.ElvUI_EltreumUI then
        ---@type EltruismShadowSettings
        local shadow = E.db.ElvUI_EltreumUI.skins.shadow
        if shadow.enable then return Skin.shadows.eltruism end
    end
    if _G.WindTools then
        ---@type WindToolsSkinSettings
        local skins = E.private.WT.skins
        if skins.enable and skins.shadow then return Skin.shadows.windtools end
    end
    return nil
end

---Shows a window's shadow, made the first time as the variant in use makes one (Eltruism's at its
---length and in its colour, WindTools' through its own CreateShadow); hides it with the plugin's
---switch off, no variant, or on the HUD in the transparent style, which has no box to cast one.
---A shadow once made stays in its variant's look.
---@param frame table
updateShadow = function(frame)
    local hud = shadowed[frame]
    local variant = ns.db().shadow and not (hud and Skin.Transparent()) and Skin.ShadowVariant()
    if not variant then
        if frame.shadow then frame.shadow:Hide() end
        return
    end
    if not frame.shadow then
        if variant == Skin.shadows.eltruism then
            local eltruism = _G.ElvUI_EltreumUI --[[@as EltruismAddon]]
            frame:CreateShadow(E.db.ElvUI_EltreumUI.skins.shadow.length)
            eltruism:ShadowColor(frame.shadow)
        else
            local windTools = _G.WindTools --[[@as WindToolsGlobal]]
            windTools[1].Modules.Skins:CreateShadow(frame)
        end
    end
    if frame.shadow then frame.shadow:Show() end
end

---Gives a window a shadow, as the ElvUI edit in use puts one round the frames it skins, and keeps
---it following the plugin's shadow switch.
---@param frame table
---@param hud boolean? part of the HUD: no shadow in the transparent style
function Skin.Shadow(frame, hud)
    shadowed[frame] = not not hud
    updateShadow(frame)
end

---Skins a window and its widgets, and the widgets it gains later each time it is shown.
---@param frame table
---@param template string? with one, the window gets ElvUI's backdrop in its colours too
---@param hud boolean? part of the HUD: it and its widgets follow the see-through styles
function Skin.Window(frame, template, hud)
    windows[frame] = not not hud
    if template then Skin.Backdrop(frame, template, true, false, hud) end
    Skin.Shadow(frame, hud)
    ns.Fonts.Watch(frame)
    Skin.Widgets(frame)
    frame:HookScript("OnShow", Skin.Widgets)
end

---Waits for named frames an addon builds on first use, and hands each to `fn` once it exists.
---Looks twice a second and stops once all are there.
---@param names string[]
---@param fn fun(frame: table)
function Skin.Watch(names, fn)
    local pending = {}
    for i, frameName in ipairs(names) do
        pending[i] = frameName
    end
    ---@param ticker FunctionContainer
    C_Timer.NewTicker(0.5, function(ticker)
        for i = #pending, 1, -1 do
            local frame = _G[pending[i]] ---@type table?
            if frame then
                table.remove(pending, i)
                fn(frame)
            end
        end
        if #pending == 0 then ticker:Cancel() end
    end)
end
