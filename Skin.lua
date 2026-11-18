-- The skinning the three addons share. Their frames set their own backdrops again whenever they
-- redraw, so a skinned frame keeps a hook on SetBackdrop that puts ElvUI's template back. In
-- "keep" mode the owner's backdrop colour stays (RestedXP draws its states with it); in "force"
-- mode ElvUI's colours win every time (Loreward's parchment). The border is always ElvUI's.
-- In the translucent style windows get a see-through backdrop at the plugin's alpha and parts
-- nested in a window ("inner") none at all.
-- Widgets are found by what their Blizzard template leaves on them, and each is skinned once.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local S = E:GetModule("Skins") ---@type ElvUISkins

local Skin = {}
ns.Skin = Skin

-- The looks the plugin offers.
Skin.styles = { elvui = "elvui", translucent = "translucent" }
-- ElvUI's template for a frame without backdrop.
local NONE = "NoBackdrop"

-- Skinned frames, each with its template, whether ElvUI's colours are forced, whether it is nested
-- in a window, and the template it has now. Weak keys.
---@type table<table, { template: string, force: boolean, inner: boolean, current: string }>
local skinned = setmetatable({}, { __mode = "k" })
-- Frames being skinned right now, whose own hooks must not run.
local locked = setmetatable({}, { __mode = "k" })
-- Widgets already handed to ElvUI's Skins.
local handled = setmetatable({}, { __mode = "k" })

---The backdrop alpha of the translucent style, or nil in ElvUI's own.
---@return number?
function Skin.Alpha()
    local db = ns.db()
    return db.style == Skin.styles.translucent and db.alpha or nil
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
    local alpha = Skin.Alpha()
    info.current = alpha and info.inner and NONE or info.template
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
function Skin.Backdrop(frame, template, force, inner)
    if skinned[frame] then return end
    skinned[frame] = { template = template, force = not not force, inner = not not inner, current = template }
    apply(frame)
    hooksecurefunc(frame, "SetBackdrop", onSetBackdrop)
    hooksecurefunc(frame, "SetBackdropBorderColor", onBorderColor)
    if force then hooksecurefunc(frame, "SetBackdropColor", onBackdropColor) end
end

---Puts ElvUI's template on every skinned frame again, after its media or the style changed.
function Skin.Refresh()
    for frame in pairs(skinned) do
        apply(frame)
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
---@param frame table
local function widget(frame)
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
        Skin.Backdrop(frame, "Default", true, true)
    else
        walk(frame:GetChildren())
        return
    end
    handled[frame] = true
end

---@param ... table
walk = function(...)
    for i = 1, select("#", ...) do
        widget((select(i, ...)))
    end
end

---Skins the widgets inside a frame that are not yet.
---@param frame table
function Skin.Widgets(frame)
    walk(frame:GetChildren())
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

---A shadow round a window, as the variant in use puts one round the frames it skins: Eltruism's
---at its length and in its colour, WindTools' through its own CreateShadow. Nothing with the
---plugin's shadow switch off, and one shadow at most.
---@param frame table
function Skin.Shadow(frame)
    if frame.shadow or not ns.db().shadow then return end
    local variant = Skin.ShadowVariant()
    if variant == Skin.shadows.eltruism then
        local eltruism = _G.ElvUI_EltreumUI --[[@as EltruismAddon]]
        frame:CreateShadow(E.db.ElvUI_EltreumUI.skins.shadow.length)
        eltruism:ShadowColor(frame.shadow)
    elseif variant == Skin.shadows.windtools then
        local windTools = _G.WindTools --[[@as WindToolsGlobal]]
        windTools[1].Modules.Skins:CreateShadow(frame)
    end
end

---Skins a window and its widgets, and the widgets it gains later each time it is shown.
---@param frame table
---@param template string? with one, the window gets ElvUI's backdrop in its colours too
function Skin.Window(frame, template)
    if template then Skin.Backdrop(frame, template, true) end
    Skin.Shadow(frame)
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
