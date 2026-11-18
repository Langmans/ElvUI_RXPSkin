-- The fonts. The text in the skinned windows gets the chosen SharedMedia font through ElvUI's
-- FontTemplate, which also brings ElvUI's outline and shadow styles and keeps the text in ElvUI's
-- own font updates. The size stays the addon's own.
--
-- Loreward, Navigator and Waymark use the game's font objects (GameFontNormal and the like), which
-- the whole UI shares, so they cannot be changed themselves. Instead the font strings inside the
-- skinned windows are taken one by one: swept when a window is skinned, shown again or resized,
-- and after RestedXP's renders. The addons set fonts on them again later (a new size, another font
-- object), so a hook on SetFont and SetFontObject of every font string puts the chosen font back
-- on the ones taken. Text anywhere else is left alone.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace

local Fonts = {}
ns.Fonts = Fonts

-- The font strings taken, and the windows whose text is taken. Weak keys.
local taken = setmetatable({}, { __mode = "k" }) ---@type table<FontString, boolean>
local roots = setmetatable({}, { __mode = "k" }) ---@type table<table, boolean>
-- Set while the plugin itself sets a font, so its own call is not taken for the addon's.
local busy = false
local hooked = false
-- The style for FontTemplate: "SHADOW" before the outline is ElvUI's way to ask for a shadow.
-- Built once and again in Fonts.Update, not on every SetFont.
local fontStyle ---@type string?

---The style ElvUI's FontTemplate takes for the outline and shadow settings.
---@param db ElvUIRXPSkinSettings
---@return string
function Fonts.Style(db)
    if not db.fontShadow then return db.fontStyle end
    return "SHADOW" .. (db.fontStyle == "NONE" and "" or db.fontStyle)
end

---Puts the chosen font on a font string, at the size it has.
---@param fs FontString
local function replace(fs)
    local _, size = fs:GetFont()
    fontStyle = fontStyle or Fonts.Style(ns.db())
    busy = true
    fs:FontTemplate(ns.db().font, size, fontStyle)
    busy = false
end

---The hook: after an addon set a font or font object on a font string taken, the chosen font again.
---@param fs FontString
local function onSetFont(fs)
    if busy or not taken[fs] or not ns.db().fonts then return end
    replace(fs)
end

local sweep -- below take

---Takes a font string, or the font strings in a frame and its children.
---@param region table
local function take(region)
    if region:GetObjectType() == "FontString" then
        if not taken[region] then
            taken[region] = true
            replace(region --[[@as FontString]])
        end
    elseif region.GetChildren then
        sweep(region:GetRegions())
        sweep(region:GetChildren())
    end
end

---@param ... table
sweep = function(...)
    for i = 1, select("#", ...) do
        take((select(i, ...)))
    end
end

---Hooks SetFont and SetFontObject on the metatable every font string shares; once.
local function hook()
    if hooked then return end
    hooked = true
    local methods = getmetatable(UIParent:CreateFontString()).__index --[[@as table]]
    hooksecurefunc(methods, "SetFont", onSetFont)
    hooksecurefunc(methods, "SetFontObject", onSetFont)
end

---Takes the text in a window not taken yet. Nothing with the fonts off.
---@param frame table
function Fonts.Sweep(frame)
    if not ns.db().fonts then return end
    hook()
    take(frame)
end

---Takes a window's text now and the text it gains later, when it is shown again or resized.
---@param frame table
function Fonts.Watch(frame)
    if roots[frame] then return end
    roots[frame] = true
    frame:HookScript("OnShow", Fonts.Sweep)
    frame:HookScript("OnSizeChanged", Fonts.Sweep)
    Fonts.Sweep(frame)
end

---After a setting changed: the text taken gets the new font or style, and with the fonts just
---switched on every window's text is taken. Switching them off takes effect after a reload.
function Fonts.Update()
    local db = ns.db()
    fontStyle = Fonts.Style(db)
    if not db.fonts then return end
    for fs in pairs(taken) do
        replace(fs)
    end
    for frame in pairs(roots) do
        Fonts.Sweep(frame)
    end
end
