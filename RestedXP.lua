-- RestedXP Guides. Its windows draw from the active theme (Themes.lua): a table of colours and
-- textures, picked by name in RestedXP's profile, with a v2 copy of each made by ConvertThemes.
-- This adds an "ElvUI" theme whose colours are ElvUI's, refilled in place when ElvUI's media
-- change. A saved theme RestedXP does not know falls back to its default, so the name in its
-- profile is harmless when this plugin is off.
-- The v1 window's frames and the Active Targets frame set RestedXP's own border texture on every
-- redraw; Skin.Backdrop puts ElvUI's template back and keeps RestedXP's colour, which marks the
-- step states. The step list's scroll bar is ElvUI's, by default shown only while the pointer is
-- over the guide window. With the art switch on, RestedXP's banners
-- and logo give way to the player's class icon in an ElvUI frame, and its cog is tinted.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local Skin = ns.Skin

---@class ElvUIRXPSkinRestedXP: ElvUIRXPSkinAddon
---@field shadowFrame? Frame the frame the guide window's shadow goes round
---@field classIcon? table the player's class icon in an ElvUI frame, in place of RestedXP's logo
---@field scrollDriver? table the frame whose OnUpdate fades the scroll bar in and out on hover
local R = { ADDON = "RXPGuides", key = "restedxp", THEME = "ElvUI" }
ns.RestedXP = R
-- RestedXP's frames built on first use (Targeting.lua).
R.TARGET_FRAMES = { "RXPTargetFrame" }
-- Everything of RestedXP's stays on screen while playing: all of it follows the see-through styles.
local HUD = true
local S = E:GetModule("Skins") ---@type ElvUISkins

-- RestedXP's addon object, from Load on; nil without RestedXP.
local rxp ---@type RXPGuidesAddon
---@type RXPGuidesTheme
local theme = {
    name = R.THEME,
    displayName = "ElvUI",
    author = "ElvUI",
    applicable = true,
    background = {},
    bottomFrameBG = {},
    bottomFrameHighlight = {},
    mapPins = {},
    bgTextures = {},
}
-- The one border colour of the v2 copy, shared by all its border keys.
local border = {}

---Fills an { r, g, b, a } table from an ElvUI colour.
---@param t number[]
---@param c ElvUIColor
---@param a number? the alpha, default the colour's own or 1
local function fill(t, c, a)
    t[1], t[2], t[3], t[4] = c.r, c.g, c.b, a or c.a or 1
end

---The theme's values from ElvUI's media.
local function color()
    local m = E.media
    fill(theme.background, m.backdropfadecolor, Skin.Alpha())
    fill(theme.bottomFrameBG, m.backdropcolor)
    fill(theme.bottomFrameHighlight, m.rgbvaluecolor, 0.5)
    fill(theme.mapPins, m.rgbvaluecolor)
    theme.tooltip = m.hexvaluecolor
    local db = ns.db()
    theme.font = db.fonts and E.Libs.LSM:Fetch("font", (ns.Fonts.Current())) or m.normFont
    theme.bgTextures.edge, theme.bgTextures.bottom = m.blankTex, m.blankTex
end

---ConvertThemes gives the v2 copy every border in the highlight colour; ElvUI's is its border
---colour, one pixel wide.
local function fixV2()
    local copy = rxp.v2.themes[R.THEME]
    if not copy then return end
    fill(border, E.media.bordercolor)
    for key in pairs(copy.borderColors) do
        copy.borderColors[key] = border
    end
    copy.edge.edgeFile, copy.edge.edgeSize = E.media.blankTex, E.mult
end

---Whether RestedXP's profile has the ElvUI theme.
---@return boolean
local function active()
    return rxp.settings.profile.activeTheme == R.THEME
end

-- The game's sheet of class icons; each cell has a round rim, cropped by this much on every side.
local CLASS_ICONS = "Interface\\WorldStateFrame\\Icons-Classes"
local CROP = 0.02

---The player's class icon in an ElvUI frame, where RestedXP's logo sits on the guide name.
---@param guideName table
---@return table
local function makeClassIcon(guideName)
    local holder = CreateFrame("Frame", nil, guideName)
    holder:SetSize(30, 30)
    holder:SetPoint("CENTER", guideName, "LEFT", 16, 0)
    local icon = holder:CreateTexture(nil, "ARTWORK")
    icon:SetInside()
    icon:SetTexture(CLASS_ICONS)
    local _, class = UnitClass("player")
    -- The class's cell on the sheet: left, right, top, bottom.
    ---@type number[]
    local cell = CLASS_ICON_TCOORDS[class]
    icon:SetTexCoord(cell[1] + CROP, cell[2] - CROP, cell[3] + CROP, cell[4] - CROP)
    holder.icon = icon
    Skin.Backdrop(holder, "Default", true, true, HUD)
    return holder
end

---The settings cog: with the art switch on, grey and in ElvUI's value colour, white under the
---pointer; off, as RestedXP draws it.
---@param cog table
---@param hover boolean?
local function tintCog(cog, hover)
    local texture = cog:GetNormalTexture() ---@type table?
    if not texture then return end
    local on = ns.db().hideArt
    texture:SetDesaturated(on)
    local c = on and not hover and E.media.rgbvaluecolor or nil
    if c then
        texture:SetVertexColor(c.r, c.g, c.b, 1)
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end
end

---@param cog table
local function cogEnter(cog)
    tintCog(cog, true)
end

---RestedXP's art or ElvUI's in its place: the banners behind the guide name and the footer, the
---logo with its class icon, and the cog. RestedXP sets them again on each render.
local function art()
    local on = ns.db().hideArt
    local frame = rxp.RXPFrame
    frame.GuideName.bg:SetShown(not on)
    frame.Footer.bg:SetShown(not on)
    frame.GuideName.icon:SetShown(not on)
    frame.GuideName.classIcon:SetShown(not on)
    local holder = R.classIcon
    if holder then holder:SetShown(on) end
    tintCog(frame.Footer.cog)
end

---The active steps, built and pooled by SetStep, each with a number box.
local function skinSteps()
    for _, step in ipairs(rxp.RXPFrame.CurrentStepFrame.framePool) do
        Skin.Backdrop(step, "Transparent", false, false, HUD)
        Skin.Backdrop(step.number, "Transparent", false, true, HUD)
    end
    ns.Fonts.Sweep(rxp.RXPFrame.CurrentStepFrame)
end

---The step list below them, built by LoadGuide: rows inside the list's window.
local function skinList()
    for _, row in ipairs(rxp.RXPFrame.ScrollChild.framePool) do
        Skin.Backdrop(row, "Default", false, true, HUD)
    end
    ns.Fonts.Sweep(rxp.RXPFrame.ScrollChild)
end

-- How bright a row of the step list is: finished, still to do, current. RestedXP's own: all at
-- 66%, the current one at 100%.
local DONE, AHEAD, CURRENT = 0.35, 0.8, 1
local RXP_REST = 0.66
-- The accent bar at the left of each row, made once per row. Weak keys.
---@type table<Frame, Texture>
local accents = setmetatable({}, { __mode = "k" })

---A row's accent bar: ElvUI's value colour down its left edge.
---@param row Frame
---@return Texture
function R.accentOf(row)
    local accent = accents[row]
    if not accent then
        accent = row:CreateTexture(nil, "OVERLAY")
        accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        accent:SetWidth(3)
        accent:Hide()
        accents[row] = accent
    end
    return accent
end

---Marks the step list: the current step(s) lit with an accent bar and the number in ElvUI's value
---colour, finished steps (before the guide's progress) dimmed, the rest a little. RestedXP sets the
---rows' alpha again in SetStep and BottomFrame.UpdateFrame; a row it hides (alpha 0, a step above
---your level) stays hidden. With the switch off, RestedXP's own look.
local function markSteps()
    local on = ns.db().markSteps
    -- Nothing before a guide is loaded.
    local progress = rxp.GetGuideProgress() or 0
    local value = E.media.rgbvaluecolor
    ---@type number[]?
    local text = rxp.activeTheme and rxp.activeTheme.textColor
    for _, row in ipairs(rxp.RXPFrame.ScrollChild.framePool) do
        local step = row.step
        if step and row:GetAlpha() > 0 then
            local current = step.active == true
            local alpha
            if not on then
                alpha = current and CURRENT or RXP_REST
            elseif current then
                alpha = CURRENT
            else
                alpha = (step.completed or step.index < progress) and DONE or AHEAD
            end
            row:SetAlpha(alpha)
            local accent = R.accentOf(row)
            accent:SetColorTexture(value.r, value.g, value.b, 1)
            accent:SetShown(on and current)
            ---@type FontString?
            local number = row.number and row.number.text
            if number and on and current then
                number:SetTextColor(value.r, value.g, value.b)
            elseif number and text then
                number:SetTextColor(text[1], text[2], text[3])
            end
        end
    end
end

---The step list's scroll bar in ElvUI's style. RestedXP's UpdateScrollBar does nothing but put
---the theme's arrows and knob on it, on every render, through the RXPFrame table; it is replaced
---so ElvUI's stay.
local function skinScrollBar()
    S:HandleScrollBar(rxp.RXPFrame.ScrollFrame.ScrollBar)
    rxp.RXPFrame.UpdateScrollBar = function() end
end

-- The scroll bar on hover, as the Carrot tracker has its own: how often the pointer is looked
-- for, and how long the bar takes to fade in and out.
local HOVER_EVERY, FADE_IN, FADE_OUT = 0.1, 0.15, 0.4
local since, over = 0, false

---Looks a few times a second (only while the guide window shows) whether the pointer is over
---it, and fades the scroll bar in or out when that changed.
---@param _ table the driver
---@param elapsed number
local function hoverScroll(_, elapsed)
    since = since + elapsed
    if since < HOVER_EVERY then return end
    since = 0
    local now = rxp.RXPFrame:IsMouseOver()
    if now == over then return end
    over = now
    local bar = rxp.RXPFrame.ScrollFrame.ScrollBar
    if now then
        E:UIFrameFadeIn(bar, FADE_IN, bar:GetAlpha(), 1)
    else
        E:UIFrameFadeOut(bar, FADE_OUT, bar:GetAlpha(), 0)
    end
end

---The scroll bar hidden until the pointer is over the guide window, or always in sight.
local function scrollMode()
    local on = ns.db().scrollHover
    local driver = R.scrollDriver
    if driver then driver:SetShown(on) end
    over = false
    rxp.RXPFrame.ScrollFrame.ScrollBar:SetAlpha(on and 0 or 1)
end

---The Active Targets frame and its title tab, built on first use; RestedXP sets both backdrops
---again on every render, in the theme's colour.
---@param frame table
local function skinTargets(frame)
    Skin.Backdrop(frame, "Transparent", false, false, HUD)
    Skin.Backdrop(frame.title, "Transparent", false, true, HUD)
    Skin.Shadow(frame, HUD)
    ns.Fonts.Watch(frame)
end

function R:Load()
    rxp = LibStub("AceAddon-3.0"):GetAddon(self.ADDON, true) --[[@as RXPGuidesAddon]]
    if not rxp then return end
    color()
    rxp:RegisterTheme(theme)
    if rxp.v2:IsGuideWindowEnabled() then fixV2() end
    local frame = rxp.RXPFrame
    for _, key in ipairs({ "BottomFrame", "GuideName", "Footer" }) do
        Skin.Backdrop(frame[key], "Transparent", false, false, HUD)
    end
    -- RXPFrame is 3 pixels wider on each side than its step list and footer, so a shadow round it
    -- shows as a second edge beside the list; this frame covers just the two, under them.
    local holder = CreateFrame("Frame", nil, frame)
    holder:SetPoint("TOPLEFT", frame.BottomFrame, "TOPLEFT")
    holder:SetPoint("BOTTOMRIGHT", frame.Footer, "BOTTOMRIGHT")
    holder:SetFrameLevel(math.max(frame.BottomFrame:GetFrameLevel() - 1, 0))
    R.shadowFrame = holder
    Skin.Shadow(holder, HUD)
    R.classIcon = makeClassIcon(frame.GuideName)
    frame.Footer.cog:HookScript("OnEnter", cogEnter)
    frame.Footer.cog:HookScript("OnLeave", tintCog)
    hooksecurefunc(frame, "UpdateVisuals", art)
    hooksecurefunc(rxp, "SetStep", skinSteps)
    hooksecurefunc(rxp, "SetStep", markSteps)
    hooksecurefunc(frame.BottomFrame, "UpdateFrame", markSteps)
    hooksecurefunc(rxp, "LoadGuide", skinList)
    ns.Names.Hook(rxp)
    ns.Fonts.Watch(frame)
    skinSteps()
    skinList()
    skinScrollBar()
    -- Its OnUpdate runs only while it is shown, inside the guide window.
    R.scrollDriver = CreateFrame("Frame", nil, frame)
    R.scrollDriver:SetScript("OnUpdate", hoverScroll)
    scrollMode()
    Skin.Watch(R.TARGET_FRAMES, skinTargets)
    art()
    -- RestedXP read its saved theme before this one existed.
    if active() then rxp.RenderFrame() end
end

function R:Update()
    if not rxp then return end
    color()
    if rxp.v2:IsGuideWindowEnabled() then
        rxp.v2:ConvertThemes()
        fixV2()
    end
    art()
    scrollMode()
    markSteps()
    if active() then rxp.RenderFrame() end
end

---Puts RestedXP on the ElvUI theme and redraws it.
function R.UseTheme()
    if not rxp then return end
    rxp.settings.profile.activeTheme = R.THEME
    rxp.RenderFrame()
end

ns.AddAddon(R)
