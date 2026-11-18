-- RestedXP Guides. Its windows draw from the active theme (Themes.lua): a table of colours and
-- textures, picked by name in RestedXP's profile, with a v2 copy of each made by ConvertThemes.
-- This adds an "ElvUI" theme whose colours are ElvUI's, refilled in place when ElvUI's media
-- change. A saved theme RestedXP does not know falls back to its default, so the name in its
-- profile is harmless when this plugin is off.
-- The v1 window's frames set RestedXP's own border texture on every redraw; Skin.Backdrop puts
-- ElvUI's template back and keeps RestedXP's colour, which marks the step states.

local _, ns = ... ---@type string, ElvUIRXPSkinNamespace
local E = ElvUI[1]
local Skin = ns.Skin

---@class ElvUIRXPSkinRestedXP: ElvUIRXPSkinAddon
local R = { ADDON = "RXPGuides", key = "restedxp", THEME = "ElvUI" }
ns.RestedXP = R

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
    fill(theme.background, m.backdropfadecolor)
    fill(theme.bottomFrameBG, m.backdropcolor)
    fill(theme.bottomFrameHighlight, m.rgbvaluecolor, 0.5)
    fill(theme.mapPins, m.rgbvaluecolor)
    theme.tooltip = m.hexvaluecolor
    theme.font = m.normFont
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

---Shows or hides the banners behind the guide name and the footer.
local function banners()
    local shown = not ns.db().hideArt
    rxp.RXPFrame.GuideName.bg:SetShown(shown)
    rxp.RXPFrame.Footer.bg:SetShown(shown)
end

---The active steps, built and pooled by SetStep, each with a number box.
local function skinSteps()
    for _, step in ipairs(rxp.RXPFrame.CurrentStepFrame.framePool) do
        Skin.Backdrop(step, "Transparent")
        Skin.Backdrop(step.number, "Transparent")
    end
end

---The step list below them, built by LoadGuide.
local function skinList()
    for _, row in ipairs(rxp.RXPFrame.ScrollChild.framePool) do
        Skin.Backdrop(row, "Default")
    end
end

function R:Load()
    rxp = LibStub("AceAddon-3.0"):GetAddon(self.ADDON, true) --[[@as RXPGuidesAddon]]
    if not rxp then return end
    color()
    rxp:RegisterTheme(theme)
    if rxp.v2:IsGuideWindowEnabled() then fixV2() end
    local frame = rxp.RXPFrame
    for _, key in ipairs({ "BottomFrame", "GuideName", "Footer" }) do
        Skin.Backdrop(frame[key], "Transparent")
    end
    Skin.Shadow(frame)
    hooksecurefunc(frame, "UpdateVisuals", banners)
    hooksecurefunc(rxp, "SetStep", skinSteps)
    hooksecurefunc(rxp, "LoadGuide", skinList)
    skinSteps()
    skinList()
    banners()
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
    banners()
    if active() then rxp.RenderFrame() end
end

---Puts RestedXP on the ElvUI theme and redraws it.
function R.UseTheme()
    if not rxp then return end
    rxp.settings.profile.activeTheme = R.THEME
    rxp.RenderFrame()
end

ns.AddAddon(R)
